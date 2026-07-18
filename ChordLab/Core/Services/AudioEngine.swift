//
//  AudioEngine.swift
//  ChordLab
//
//  Audio playback service using AVFoundation
//

import AVFoundation
import AudioToolbox
import Tonic

@Observable
final class AudioEngine {
    // Audio components
    let engine = AVAudioEngine()
    let samplerNode = AVAudioUnitSampler()
    let reverb = AVAudioUnitReverb()
    private var oscillatorNodes: [AVAudioSourceNode] = []

    // State
    var isPlaying = false
    var currentTempo: Int = 120
    private var currentVolume: Float = 0.7
    private(set) var isInstrumentLoaded = false
    private(set) var currentInstrument: Instrument

    // Playback
    private var sequencer: AudioSequencer?
    private var metronome: Metronome?

    init() {
        currentInstrument = Instrument(
            rawValue: UserDefaults.standard.integer(forKey: "instrumentProgram")
        ) ?? .piano

        setupAudioEngine()
        setupAudioSession()
        loadInstrumentAsync()
    }

    // MARK: - Instrument

    /// The melodic voices offered in Settings; raw values are General MIDI
    /// program numbers, all present in the bundled GeneralUser GS bank
    enum Instrument: Int, CaseIterable, Identifiable {
        case piano = 0
        case electricPiano = 4
        case vibraphone = 11
        case nylonGuitar = 24
        case strings = 48

        var id: Int { rawValue }

        var displayName: String {
            switch self {
            case .piano: return "Grand Piano"
            case .electricPiano: return "Electric Piano"
            case .vibraphone: return "Vibraphone"
            case .nylonGuitar: return "Nylon Guitar"
            case .strings: return "Strings"
            }
        }
    }

    /// Switches the sampler to another General MIDI voice and persists the
    /// choice. The bank reload happens off the main thread, like at launch.
    func setInstrument(_ instrument: Instrument) {
        guard instrument != currentInstrument else { return }

        currentInstrument = instrument
        UserDefaults.standard.set(instrument.rawValue, forKey: "instrumentProgram")

        // Kill anything sounding so no note sustains across the voice swap
        stopAllNotes()
        loadInstrumentAsync()
    }

    /// Bank loads run on one serial queue: without it, a slow in-flight
    /// load (the ~1s launch parse) can finish AFTER a newer selection's
    /// load and leave the sampler on the wrong voice
    private static let instrumentLoadQueue = DispatchQueue(
        label: "com.chordlab.instrument-load",
        qos: .userInitiated
    )

    /// Loads the selected GeneralUser GS voice into the sampler off the main
    /// thread — parsing the 31 MB bank synchronously would stall cold launch.
    /// Playback falls back to the sampler's default tone until
    /// `isInstrumentLoaded` flips; `playChord` reads the flag at play time.
    private func loadInstrumentAsync() {
        let sampler = samplerNode
        let program = UInt8(currentInstrument.rawValue)

        Self.instrumentLoadQueue.async { [weak self] in
            // Synchronized folders may bundle resources flat or with
            // structure; check both locations before giving up
            let url = Bundle.main.url(forResource: "GeneralUser", withExtension: "sf2")
                ?? Bundle.main.url(forResource: "GeneralUser", withExtension: "sf2", subdirectory: "Resources/Sounds")
                ?? Bundle.main.url(forResource: "GeneralUser", withExtension: "sf2", subdirectory: "Sounds")

            guard let url else {
                print("GeneralUser.sf2 not found in bundle - using default sampler tone")
                return
            }

            do {
                try sampler.loadSoundBankInstrument(
                    at: url,
                    program: program,
                    bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                    bankLSB: UInt8(kAUSampler_DefaultBankLSB)
                )
                DispatchQueue.main.async {
                    self?.isInstrumentLoaded = true
                }
            } catch {
                print("Failed to load SoundFont: \(error)")
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupAudioEngine() {
        // Attach nodes
        engine.attach(samplerNode)
        engine.attach(reverb)
        
        // Setup reverb - more subtle for cleaner sound
        reverb.loadFactoryPreset(.smallRoom)
        reverb.wetDryMix = 10
        
        // Connect nodes
        engine.connect(samplerNode, to: reverb, format: nil)
        engine.connect(reverb, to: engine.mainMixerNode, format: nil)
        
        // Configure main mixer
        engine.mainMixerNode.outputVolume = currentVolume
        
        // Start engine
        start()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func start() {
        guard !engine.isRunning else { return }
        
        do {
            try engine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func stop() {
        if engine.isRunning {
            engine.stop()
        }
    }
        
    // MARK: - Note Playback

    // Ownership ledger for scheduled note-offs: each play invocation claims
    // its MIDI notes with a generation stamp, and a pending note-off only
    // fires for notes it still owns. Re-triggering a note therefore cancels
    // the older stop instead of being silenced by it (the replay-cutoff bug).
    private var noteOwners: [UInt8: Int] = [:]
    private var playbackGeneration = 0

    func playNote(_ note: Note, velocity: UInt8 = 80, duration: Double = 1.0) {
        if !engine.isRunning {
            start()
            guard engine.isRunning else { return }
        }

        let noteNumber = UInt8(note.pitch.midiNoteNumber)
        playbackGeneration += 1
        let generation = playbackGeneration
        noteOwners[noteNumber] = generation

        samplerNode.startNote(noteNumber, withVelocity: velocity, onChannel: 0)

        if duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                guard let self, self.noteOwners[noteNumber] == generation else { return }
                self.samplerNode.stopNote(noteNumber, onChannel: 0)
            }
        }
    }

    /// Short metronome click (system tick sound), kept here so views don't
    /// need AudioToolbox
    func playClick() {
        AudioServicesPlaySystemSound(SystemSoundID(1306))
    }

    /// User preference: double the progression root an octave down.
    /// Toggleable in Settings > Sound; defaults to on.
    var bassDoublingEnabled: Bool {
        UserDefaults.standard.object(forKey: "bassDoublingEnabled") as? Bool ?? true
    }

    // MARK: - Chord Playback

    func playChord(_ chord: Chord, velocity: UInt8 = 80, duration: Double = 0.5, includeBass: Bool = false) {
        if !engine.isRunning {
            start()
            guard engine.isRunning else { return }
        }

        let notes = voicedNotes(for: chord)
        var noteNumbers = notes.map { UInt8($0.pitch.midiNoteNumber) }

        // Root doubled an octave below for warmth (progression playback only)
        if includeBass, let rootNumber = noteNumbers.first, rootNumber >= 12 {
            let bassNumber = rootNumber - 12
            if !noteNumbers.contains(bassNumber) {
                noteNumbers.insert(bassNumber, at: 0)
            }
        }

        playbackGeneration += 1
        let generation = playbackGeneration
        for noteNumber in noteNumbers {
            noteOwners[noteNumber] = generation
        }

        // Scale velocity down as chords get denser. The raw sine fallback
        // needs a much heavier cut than the sampled piano to avoid mud.
        let scalePercent: Int
        if isInstrumentLoaded {
            scalePercent = notes.count <= 3 ? 80 : 70
        } else {
            scalePercent = notes.count <= 3 ? 50 : 40
        }
        let adjustedVelocity = UInt8(min(Int(velocity) * scalePercent / 100, 127))

        // Play all notes with a micro-delay between them (like guitar strumming)
        for (index, noteNumber) in noteNumbers.enumerated() {
            let delay = Double(index) * 0.015  // 15ms between each note

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, self.noteOwners[noteNumber] == generation else { return }
                self.samplerNode.startNote(noteNumber, withVelocity: adjustedVelocity, onChannel: 0)
            }
        }

        // Schedule note-offs, honoring ownership
        if duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                guard let self else { return }

                for noteNumber in noteNumbers where self.noteOwners[noteNumber] == generation {
                    self.samplerNode.stopNote(noteNumber, onChannel: 0)
                }

                if self.playbackGeneration == generation {
                    self.isPlaying = false
                }
            }
        }

        isPlaying = true
    }

    /// Ascending close voicing starting at the base octave.
    /// The octave must accumulate across the whole chord: once the pitch class
    /// wraps (e.g. G7 = G-B-D-F, where D wraps past B), every later note stays
    /// in the higher octave instead of folding back down.
    /// Static so non-audio code (MIDI export) shares the exact voicing
    /// without spinning up an AVAudioEngine.
    static func voicedNotes(for chord: Chord, baseOctave: Int = 4) -> [Note] {
        var octave = baseOctave
        var previousSemitone: Int?

        return chord.noteClasses.map { noteClass in
            let semitone = noteClass.intValue
            if let previous = previousSemitone, semitone < previous {
                octave += 1
            }
            previousSemitone = semitone

            let canonicalNote = noteClass.canonicalNote
            return Note(canonicalNote.letter, accidental: canonicalNote.accidental, octave: octave)
        }
    }

    func voicedNotes(for chord: Chord, baseOctave: Int = 4) -> [Note] {
        Self.voicedNotes(for: chord, baseOctave: baseOctave)
    }
    
    /// Note-off length for a chord occupying `interval` seconds of a
    /// progression. Interior chords stop just short of the next slot so an
    /// identical repeated chord re-triggers cleanly; the final chord of a
    /// non-looping pass gets room to ring out instead of being clipped.
    func chordSlotDuration(interval: TimeInterval, isLast: Bool) -> TimeInterval {
        isLast ? max(interval * 0.9, 1.2) : interval * 0.9
    }

    // MARK: - Control

    func stopAllNotes() {
        for noteNumber in UInt8(0)...UInt8(127) {
            samplerNode.stopNote(noteNumber, onChannel: 0)
        }
        // Orphan every pending scheduled note-off so it can't silence
        // notes started after this point
        noteOwners.removeAll()
        isPlaying = false
    }
    
    func setTempo(_ tempo: Int) {
        currentTempo = max(1, tempo) // Ensure tempo is at least 1
        sequencer?.tempo = Double(currentTempo)
    }
    
    func setVolume(_ volume: Float) {
        currentVolume = max(0, min(1, volume))
        engine.mainMixerNode.outputVolume = currentVolume
    }
    
    // MARK: - Progression Playback
    
    func playProgression(_ progression: [TheoryEngine.PlaybackChord], loop: Bool = false) {
        stopPlayback()
        
        sequencer = AudioSequencer(
            progression: progression,
            tempo: Double(currentTempo),
            audioEngine: self
        )
        
        sequencer?.play(loop: loop)
        isPlaying = true
    }
    
    func stopPlayback() {
        sequencer?.stop()
        sequencer = nil
        stopAllNotes()
    }
    
    // MARK: - Metronome
    
    func startMetronome() {
        metronome = Metronome(tempo: Double(currentTempo))
        metronome?.start()
    }
    
    func stopMetronome() {
        metronome?.stop()
        metronome = nil
    }
}

// MARK: - Audio Sequencer

class AudioSequencer {
    let progression: [TheoryEngine.PlaybackChord]
    var tempo: Double
    weak var audioEngine: AudioEngine?
    
    private var timer: Timer?
    private var currentIndex = 0
    private var isLooping = false
    
    init(progression: [TheoryEngine.PlaybackChord], tempo: Double, audioEngine: AudioEngine) {
        self.progression = progression
        self.tempo = tempo
        self.audioEngine = audioEngine
    }
    
    func play(loop: Bool) {
        isLooping = loop
        currentIndex = 0
        playNext()
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func playNext() {
        guard currentIndex < progression.count else {
            if isLooping {
                currentIndex = 0
                playNext()
            } else {
                audioEngine?.isPlaying = false
            }
            return
        }
        
        let item = progression[currentIndex]
        let interval = (60.0 / tempo) * item.duration
        let isLast = currentIndex == progression.count - 1 && !isLooping
        let duration = audioEngine?.chordSlotDuration(interval: interval, isLast: isLast) ?? interval * 0.9

        audioEngine?.playChord(
            item.chord,
            velocity: UInt8(item.velocity),
            duration: duration,
            includeBass: audioEngine?.bassDoublingEnabled ?? false
        )

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.currentIndex += 1
            self?.playNext()
        }
    }
}

// MARK: - Metronome

class Metronome {
    var tempo: Double
    private var timer: Timer?
    private let clickSound = SystemSoundID(1306)
    
    init(tempo: Double) {
        self.tempo = tempo
    }
    
    func start() {
        let interval = 60.0 / tempo
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            AudioServicesPlaySystemSound(self.clickSound)
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
