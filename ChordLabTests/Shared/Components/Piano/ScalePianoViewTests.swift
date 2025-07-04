//import XCTest
//import SwiftUI
//import Tonic
//@testable import ChordLab
//
//@MainActor
//final class ScalePianoViewTests: XCTestCase {
//    var theoryEngine: TheoryEngine!
//    var audioEngine: AudioEngine!
//    
//    override func setUp() {
//        super.setUp()
//        theoryEngine = TheoryEngine()
//        audioEngine = AudioEngine()
//    }
//    
//    override func tearDown() {
//        theoryEngine = nil
//        audioEngine = nil
//        super.tearDown()
//    }
//    
//    // Test 1: Verify view can be created
//    func testViewCreation() {
//        let view = ScalePianoView()
//            .environment(theoryEngine)
//            .environment(audioEngine)
//        
//        XCTAssertNotNil(view)
//    }
//    
//    // Test 2: Test white key helper component
//    func testWhiteKeyView() {
//        let whiteKey = WhiteKeyView(
//            noteClass: .C,
//            octave: 4,
//            theoryEngine: theoryEngine,
//            audioEngine: audioEngine
//        )
//        
//        XCTAssertNotNil(whiteKey)
//    }
//    
//    // Test 3: Test black key helper component
//    func testBlackKeyView() {
//        let blackKey = BlackKeyView(
//            noteClass: .Cs,
//            octave: 4,
//            theoryEngine: theoryEngine,
//            audioEngine: audioEngine
//        )
//        
//        XCTAssertNotNil(blackKey)
//    }
//    
//    // Test 4: Test scale highlighting logic
//    func testScaleHighlighting() {
//        // Set C major scale
//        theoryEngine.currentKey = "C"
//        theoryEngine.currentScaleType = "major"
//        
//        let scaleNotes = theoryEngine.getCurrentScaleNotes()
//        
//        // C major should contain C, D, E, F, G, A, B
//        XCTAssertTrue(scaleNotes.contains(.C))
//        XCTAssertTrue(scaleNotes.contains(.D))
//        XCTAssertTrue(scaleNotes.contains(.E))
//        XCTAssertTrue(scaleNotes.contains(.F))
//        XCTAssertTrue(scaleNotes.contains(.G))
//        XCTAssertTrue(scaleNotes.contains(.A))
//        XCTAssertTrue(scaleNotes.contains(.B))
//        
//        // Should not contain sharps/flats
//        XCTAssertFalse(scaleNotes.contains(.Cs))
//        XCTAssertFalse(scaleNotes.contains(.Ds))
//    }
//    
//    // Test 5: Test root note detection
//    func testRootNoteDetection() {
//        theoryEngine.currentKey = "D"
//        
//        let rootNote = NoteClass(theoryEngine.currentKey)
//        XCTAssertEqual(rootNote, .D)
//        
//        // Change to G
//        theoryEngine.currentKey = "G"
//        let newRootNote = NoteClass(theoryEngine.currentKey)
//        XCTAssertEqual(newRootNote, .G)
//    }
//    
//    // Test 6: Test different scales
//    func testDifferentScales() {
//        theoryEngine.currentKey = "C"
//        
//        // Test major scale
//        theoryEngine.currentScaleType = "major"
//        let majorNotes = theoryEngine.getCurrentScaleNotes()
//        XCTAssertEqual(majorNotes.count, 7)
//        
//        // Test minor scale
//        theoryEngine.currentScaleType = "minor"
//        let minorNotes = theoryEngine.getCurrentScaleNotes()
//        XCTAssertEqual(minorNotes.count, 7)
//        
//        // Minor should have Eb instead of E
//        XCTAssertTrue(minorNotes.contains(.Eb))
//        XCTAssertFalse(minorNotes.contains(.E))
//    }
//    
//    // Test 7: Test note creation from NoteClass
//    func testNoteCreation() {
//        let noteClasses: [NoteClass] = [.C, .Cs, .D, .Eb, .E, .F, .Fs, .G, .Ab, .A, .Bb, .B]
//        
//        for noteClass in noteClasses {
//            let canonicalNote = noteClass.canonicalNote
//            let note = Note(canonicalNote.letter, accidental: canonicalNote.accidental, octave: 4)
//            
//            XCTAssertNotNil(note)
//            XCTAssertEqual(note.noteClass, noteClass)
//        }
//    }
//}
