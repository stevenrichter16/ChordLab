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

    // Playback
    private var sequencer: AudioSequencer?
    private var metronome: Metronome?

    init() {
        setupAudioEngine()
        setupAudioSession()
        loadInstrument()
    }

    // MARK: - Instrument

    /// Loads the bundled GeneralUser GS piano into the sampler.
    /// Without a sound bank, AVAudioUnitSampler falls back to a thin sine tone.
    private func loadInstrument() {
        // Synchronized folders may bundle resources flat or with structure;
        // check both locations before giving up
        let url = Bundle.main.url(forResource: "GeneralUser", withExtension: "sf2")
            ?? Bundle.main.url(forResource: "GeneralUser", withExtension: "sf2", subdirectory: "Resources/Sounds")
            ?? Bundle.main.url(forResource: "GeneralUser", withExtension: "sf2", subdirectory: "Sounds")

        guard let url else {
            print("GeneralUser.sf2 not found in bundle - using default sampler tone")
            return
        }

        do {
            try samplerNode.loadSoundBankInstrument(
                at: url,
                program: 0, // Acoustic Grand Piano
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: UInt8(kAUSampler_DefaultBankLSB)
            )
            isInstrumentLoaded = true
        } catch {
            print("Failed to load SoundFont: \(error)")
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
    
    func playNote(_ note: Note, velocity: UInt8 = 80, duration: Double = 1.0) {
        if !engine.isRunning {
            start()
            guard engine.isRunning else { return }
        }
        
        let noteNumber = UInt8(note.pitch.midiNoteNumber)
        
        samplerNode.startNote(noteNumber, withVelocity: velocity, onChannel: 0)
        
        if duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                self?.samplerNode.stopNote(noteNumber, onChannel: 0)
            }
        }
    }
    
    // MARK: - Chord Playback
    
    func playChord(_ chord: Chord, velocity: UInt8 = 80, duration: Double = 0.5) {
        if !engine.isRunning {
            start()
            guard engine.isRunning else { return }
        }

        let notes = voicedNotes(for: chord)

        // Play all notes with slight timing offset and adjusted velocities
        for (index, note) in notes.enumerated() {
            // Scale velocity down as chords get denser. The raw sine fallback
            // needs a much heavier cut than the sampled piano to avoid mud.
            let noteCount = notes.count
            let scalePercent: Int
            if isInstrumentLoaded {
                scalePercent = noteCount <= 3 ? 80 : 70
            } else {
                scalePercent = noteCount <= 3 ? 50 : 40
            }

            let calculated = Int(velocity) * scalePercent / 100
            let adjustedVelocity = UInt8(min(calculated, 127))
            
            // Add micro-delay between notes (like guitar strumming)
            let delay = Double(index) * 0.015  // 15ms between each note for more separation
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playNote(note, velocity: adjustedVelocity, duration: 0)
            }
        }
        
        // Schedule note off
        if duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                self?.stopChordNotes(chord)
            }
        }
        
        isPlaying = true
    }
    
    private func stopChordNotes(_ chord: Chord) {
        for note in voicedNotes(for: chord) {
            samplerNode.stopNote(UInt8(note.pitch.midiNoteNumber), onChannel: 0)
        }

        isPlaying = false
    }

    /// Ascending close voicing starting at the base octave.
    /// The octave must accumulate across the whole chord: once the pitch class
    /// wraps (e.g. G7 = G-B-D-F, where D wraps past B), every later note stays
    /// in the higher octave instead of folding back down.
    func voicedNotes(for chord: Chord, baseOctave: Int = 4) -> [Note] {
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
    
    // MARK: - Control
    
    func stopAllNotes() {
        for noteNumber in UInt8(0)...UInt8(127) {
            samplerNode.stopNote(noteNumber, onChannel: 0)
        }
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

        // Stop the chord just before the next one starts: a repeated chord
        // re-triggers the same MIDI notes, and a stop scheduled past the
        // re-trigger would silence the new chord almost immediately
        audioEngine?.playChord(item.chord, velocity: UInt8(item.velocity), duration: interval * 0.9)

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
