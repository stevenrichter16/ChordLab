//
//  AudioEngine.swift
//  ChordLab
//
//  Audio playback service using AVFoundation
//

import AVFoundation
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
    
    // Playback
    private var sequencer: AudioSequencer?
    private var metronome: Metronome?
    
    init() {
        setupAudioEngine()
        setupAudioSession()
    }
    
    // MARK: - Setup
    
    private func setupAudioEngine() {
        // Attach nodes
        engine.attach(samplerNode)
        engine.attach(reverb)
        
        // Setup reverb
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 20
        
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
    
    func playChord(_ chord: Chord, velocity: UInt8 = 80, duration: Double = 2.0) {
        if !engine.isRunning {
            start()
            guard engine.isRunning else { return }
        }
        
        let notes = chord.noteClasses.enumerated().map { index, noteClass in
            // Determine octave for proper voicing
            let baseOctave = 4
            var octave = baseOctave
            
            // Ensure notes are in ascending order
            if index > 0 {
                // Get the canonical note for each NoteClass
                let previousNoteClass = chord.noteClasses[index - 1]
                
                // Use the semitone values to compare pitch classes
                let previousSemitone = previousNoteClass.intValue
                let currentSemitone = noteClass.intValue
                
                // If current note is lower than previous, move to next octave
                if currentSemitone < previousSemitone {
                    octave = baseOctave + 1
                }
            }
            
            // Create a Note from the NoteClass using its canonical representation
            let canonicalNote = noteClass.canonicalNote
            return Note(canonicalNote.letter, accidental: canonicalNote.accidental, octave: octave)
        }
        
        // Play all notes
        for note in notes {
            playNote(note, velocity: velocity, duration: 0)
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
        let notes = chord.noteClasses.enumerated().map { index, noteClass in
            let baseOctave = 4
            var octave = baseOctave
            
            if index > 0 {
                // Get the canonical note for each NoteClass
                let previousNoteClass = chord.noteClasses[index - 1]
                
                // Use the semitone values to compare pitch classes
                let previousSemitone = previousNoteClass.intValue
                let currentSemitone = noteClass.intValue
                
                // If current note is lower than previous, move to next octave
                if currentSemitone < previousSemitone {
                    octave = baseOctave + 1
                }
            }
            
            // Create a Note from the NoteClass using its canonical representation
            let canonicalNote = noteClass.canonicalNote
            return Note(canonicalNote.letter, accidental: canonicalNote.accidental, octave: octave)
        }
        
        for note in notes {
            samplerNode.stopNote(UInt8(note.pitch.midiNoteNumber), onChannel: 0)
        }
        
        isPlaying = false
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
    
    func playProgression(_ progression: [TheoryEngine.ProgressionChord], loop: Bool = false) {
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
    let progression: [TheoryEngine.ProgressionChord]
    var tempo: Double
    weak var audioEngine: AudioEngine?
    
    private var timer: Timer?
    private var currentIndex = 0
    private var isLooping = false
    
    init(progression: [TheoryEngine.ProgressionChord], tempo: Double, audioEngine: AudioEngine) {
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
        audioEngine?.playChord(item.chord, velocity: UInt8(item.velocity), duration: item.duration)
        
        // Schedule next chord
        let interval = (60.0 / tempo) * item.duration
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
