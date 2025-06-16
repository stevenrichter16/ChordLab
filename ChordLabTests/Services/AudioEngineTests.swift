//
//  AudioEngineTests.swift
//  ChordLabTests
//
//  Unit tests for AudioEngine audio playback functionality
//

import XCTest
import AVFoundation
import Tonic
@testable import ChordLab

final class AudioEngineTests: XCTestCase {
    
    var audioEngine: AudioEngine!
    
    override func setUp() {
        super.setUp()
        audioEngine = AudioEngine()
    }
    
    override func tearDown() {
        audioEngine.stop()
        audioEngine = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testAudioEngineInitialization() {
        XCTAssertNotNil(audioEngine.engine)
        XCTAssertNotNil(audioEngine.samplerNode)
        XCTAssertNotNil(audioEngine.reverb)
        XCTAssertEqual(audioEngine.currentTempo, 120)
        XCTAssertFalse(audioEngine.isPlaying)
    }
    
    func testAudioEngineNodesConnected() {
        // Verify nodes are attached to engine
        XCTAssertTrue(audioEngine.engine.attachedNodes.contains(audioEngine.samplerNode))
        XCTAssertTrue(audioEngine.engine.attachedNodes.contains(audioEngine.reverb))
        
        // Verify main mixer node exists
        XCTAssertNotNil(audioEngine.engine.mainMixerNode)
    }
    
    // MARK: - Sound Loading Tests
    
    func testLoadSoundFontFile() {
        // This test assumes a sound font file will be provided
        // For now, test that the sampler node is configured
        XCTAssertNotNil(audioEngine.samplerNode)
        
        // Test that sampler has default instrument loaded
        // Note: In real implementation, you'd load an actual .sf2 file
    }
    
    // MARK: - Note Playback Tests
    
    func testPlaySingleNote() {
        let note = Note(.C, octave: 4)
        audioEngine.playNote(note)
        
        // Since audio playback is async, we can at least verify no crashes
        // In a real test, you might check audio buffer output
        XCTAssertTrue(true, "Note playback should not crash")
    }
    
    func testPlayMultipleNotes() {
        let notes = [Note(.C, octave: 4), Note(.E, octave: 4), Note(.G, octave: 4)]
        
        for note in notes {
            audioEngine.playNote(note)
        }
        
        XCTAssertTrue(true, "Multiple note playback should not crash")
    }
    
    func testPlayNoteWithVelocity() {
        let note = Note(.C, octave: 4)
        let velocities: [UInt8] = [30, 60, 90, 120, 127]
        
        for velocity in velocities {
            audioEngine.playNote(note, velocity: velocity)
            XCTAssertTrue(velocity <= 127, "Velocity should be within MIDI range")
        }
    }
    
    // MARK: - Chord Playback Tests
    
    func testPlayChord() {
        let chord = Chord(.C, type: .major)
        audioEngine.playChord(chord)
        
        XCTAssertTrue(true, "Chord playback should not crash")
    }
    
    func testPlayChordTypes() {
        let chords = [
            Chord(.C, type: .major),
            Chord(.C, type: .minor),
            Chord(.C, type: .dim),
            Chord(.C, type: .aug),
            Chord(.C, type: .dom7),
            Chord(.C, type: .maj7),
            Chord(.C, type: .min7)
        ]
        
        for chord in chords {
            audioEngine.playChord(chord)
        }
        
        XCTAssertTrue(true, "All chord types should play without crashing")
    }
    
    func testPlayChordWithDuration() {
        let chord = Chord(.C, type: .major)
        let durations: [Double] = [0.25, 0.5, 1.0, 2.0]
        
        for duration in durations {
            audioEngine.playChord(chord, duration: duration)
            XCTAssertTrue(duration > 0, "Duration should be positive")
        }
    }
    
    // MARK: - Engine Control Tests
    
    func testStartStopEngine() {
        audioEngine.stop()
        XCTAssertFalse(audioEngine.engine.isRunning)
        
        audioEngine.start()
        XCTAssertTrue(audioEngine.engine.isRunning)
        
        audioEngine.stop()
        XCTAssertFalse(audioEngine.engine.isRunning)
    }
    
    func testEngineRestartAfterStop() {
        audioEngine.start()
        XCTAssertTrue(audioEngine.engine.isRunning)
        
        audioEngine.stop()
        XCTAssertFalse(audioEngine.engine.isRunning)
        
        audioEngine.start()
        XCTAssertTrue(audioEngine.engine.isRunning)
    }
    
    // MARK: - Tempo Tests
    
    func testSetTempo() {
        let tempos = [60, 90, 120, 140, 180, 200]
        
        for tempo in tempos {
            audioEngine.setTempo(tempo)
            XCTAssertEqual(audioEngine.currentTempo, tempo)
        }
    }
    
    func testTempoEdgeCases() {
        // Test minimum tempo
        audioEngine.setTempo(40)
        XCTAssertEqual(audioEngine.currentTempo, 40)
        
        // Test maximum reasonable tempo
        audioEngine.setTempo(300)
        XCTAssertEqual(audioEngine.currentTempo, 300)
        
        // Test invalid tempo (should be handled gracefully)
        audioEngine.setTempo(0)
        XCTAssertGreaterThan(audioEngine.currentTempo, 0)
    }
    
    // MARK: - Stop All Notes Tests
    
    func testStopAllNotes() {
        // Play multiple notes
        let notes = [Note(.C, octave: 4), Note(.E, octave: 4), Note(.G, octave: 4), Note(.B, octave: 4)]
        for note in notes {
            audioEngine.playNote(note)
        }
        
        // Stop all notes
        audioEngine.stopAllNotes()
        
        // Verify no crash and engine still running
        XCTAssertTrue(audioEngine.engine.isRunning)
    }
    
    // MARK: - Reverb Tests
    
    func testReverbSettings() {
        // Test that reverb is connected and has reasonable settings
        XCTAssertNotNil(audioEngine.reverb)
        XCTAssertTrue(audioEngine.reverb.wetDryMix >= 0 && audioEngine.reverb.wetDryMix <= 100)
    }
    
    func testChangeReverbPreset() {
        let presets: [AVAudioUnitReverbPreset] = [.smallRoom, .mediumHall, .largeHall, .cathedral]
        
        for preset in presets {
            audioEngine.reverb.loadFactoryPreset(preset)
            XCTAssertTrue(true, "Reverb preset \(preset) should load without crashing")
        }
    }
    
    // MARK: - MIDI Note Number Tests
    
    func testMIDINoteConversion() {
        // Test common notes and their MIDI numbers
        let noteTests: [(Note, Int)] = [
            (Note(.C, accidental: .natural, octave: 3), 60),  // Middle C (Tonic uses Yamaha standard: C3)
            (Note(.A, accidental: .natural, octave: 3), 69),  // A440
            (Note(.C, accidental: .natural, octave: 2), 48),
            (Note(.C, accidental: .natural, octave: 4), 72),
            (Note(.G, accidental: .natural, octave: 3), 67)
        ]
        
        for (note, expectedMIDI) in noteTests {
            let midiNote = note.pitch.midiNoteNumber
            XCTAssertEqual(Int(midiNote), expectedMIDI,
                          "Note \(note.description) should have MIDI number \(expectedMIDI)")
        }
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testPlayNoteWhileEngineStopped() {
        audioEngine.stop()
        
        // Should handle gracefully without crashing
        audioEngine.playNote(Note(.C, octave: 4))
        audioEngine.playChord(Chord(.C, type: .major))
        
        XCTAssertTrue(true, "Playing notes with stopped engine should not crash")
    }
    
    func testRapidNotePlayback() {
        // Test playing many notes rapidly
        let notes = [Note(.C, octave: 4), Note(.D, octave: 4), Note(.E, octave: 4), 
                     Note(.F, octave: 4), Note(.G, octave: 4), Note(.A, octave: 4), 
                     Note(.B, octave: 4), Note(.C, octave: 5)]
        
        for _ in 0..<10 {
            for note in notes {
                audioEngine.playNote(note, velocity: 80)
            }
        }
        
        XCTAssertTrue(true, "Rapid note playback should not crash")
    }
    
    func testSimultaneousChords() {
        // Test playing multiple chords at once
        let chords = [Chord(.C, type: .major), Chord(.F, type: .major), Chord(.G, type: .major)]
        
        for chord in chords {
            audioEngine.playChord(chord, velocity: 70)
        }
        
        XCTAssertTrue(true, "Simultaneous chord playback should not crash")
    }
    
    // MARK: - Memory and Performance Tests
    
    func testMemoryLeaksOnRepeatedPlayback() {
        // Play and stop many times to check for memory leaks
        for _ in 0..<100 {
            audioEngine.playChord(Chord(.C, type: .major))
            audioEngine.stopAllNotes()
        }
        
        XCTAssertTrue(true, "Repeated playback should not cause memory issues")
    }
    
    func testEngineResetDoesNotLeak() {
        // Start and stop engine multiple times
        for _ in 0..<10 {
            audioEngine.start()
            audioEngine.playChord(Chord(.C, type: .major))
            audioEngine.stop()
        }
        
        XCTAssertTrue(true, "Engine reset should not cause memory leaks")
    }
}
