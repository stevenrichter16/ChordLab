import XCTest
import SwiftUI
import Tonic
@testable import ChordLab

@MainActor
final class PianoViewTests: XCTestCase {
    var theoryEngine: TheoryEngine!
    var audioEngine: AudioEngine!
    
    override func setUp() {
        super.setUp()
        theoryEngine = TheoryEngine()
        audioEngine = AudioEngine()
    }
    
    override func tearDown() {
        theoryEngine = nil
        audioEngine = nil
        super.tearDown()
    }
    
    // Test 1: Verify ScalePianoView can be created
    func testScalePianoViewCreation() {
        let view = ScalePianoView()
            .environment(theoryEngine)
            .environment(audioEngine)
        
        XCTAssertNotNil(view)
    }
    
    // Test 2: Test scale notes for C major
    func testCMajorScaleNotes() {
        theoryEngine.currentKey = "C"
        theoryEngine.currentScaleType = "major"
        
        let scaleNotes = theoryEngine.getCurrentScaleNotes()
        
        // C major scale notes
        let expectedNotes: [NoteClass] = [.C, .D, .E, .F, .G, .A, .B]
        
        for note in expectedNotes {
            XCTAssertTrue(scaleNotes.contains(note), "\(note) should be in C major scale")
        }
        
        XCTAssertEqual(scaleNotes.count, 7, "Major scale should have 7 notes")
    }
    
    // Test 3: Test scale notes for G major
    func testGMajorScaleNotes() {
        theoryEngine.currentKey = "G"
        theoryEngine.currentScaleType = "major"
        
        let scaleNotes = theoryEngine.getCurrentScaleNotes()
        
        // G major has F# instead of F
        XCTAssertTrue(scaleNotes.contains(.G))
        XCTAssertTrue(scaleNotes.contains(.A))
        XCTAssertTrue(scaleNotes.contains(.B))
        XCTAssertTrue(scaleNotes.contains(.C))
        XCTAssertTrue(scaleNotes.contains(.D))
        XCTAssertTrue(scaleNotes.contains(.E))
        XCTAssertTrue(scaleNotes.contains(.Fs))
        XCTAssertFalse(scaleNotes.contains(.F))
    }
    
    // Test 4: Test root note identification
    func testRootNoteIdentification() {
        let testCases = ["C", "D", "E", "F", "G", "A", "B"]
        
        for key in testCases {
            theoryEngine.currentKey = key
            let rootNote = NoteClass(key)
            XCTAssertNotNil(rootNote, "Should create NoteClass from key: \(key)")
        }
    }
    
    // Test 5: Test note to MIDI conversion
    func testNoteToMidi() {
        // C3 (middle C in Tonic/Yamaha standard) should be MIDI 60
        let middleC = Note(.C, accidental: .natural, octave: 3)
        XCTAssertEqual(middleC.pitch.midiNoteNumber, 60)
        
        // C4 should be MIDI 72
        let c4 = Note(.C, accidental: .natural, octave: 4)
        XCTAssertEqual(c4.pitch.midiNoteNumber, 72)
        
        // A4 (440 Hz) should be MIDI 81
        let a4 = Note(.A, accidental: .natural, octave: 4)
        XCTAssertEqual(a4.pitch.midiNoteNumber, 81)
    }
    
    // Test 6: Test different scale types
    func testDifferentScaleTypes() {
        theoryEngine.currentKey = "C"
        
        // Major scale
        theoryEngine.currentScaleType = "major"
        let majorScale = theoryEngine.getCurrentScaleNotes()
        XCTAssertTrue(majorScale.contains(.E))
        XCTAssertTrue(majorScale.contains(.B))
        
        // Natural Minor scale
        theoryEngine.currentScaleType = "minor"
        let minorScale = theoryEngine.getCurrentScaleNotes()
        XCTAssertTrue(minorScale.contains(.Eb))
        XCTAssertTrue(minorScale.contains(.Bb))
    }
}