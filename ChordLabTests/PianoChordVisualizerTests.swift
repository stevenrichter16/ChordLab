//
//  PianoChordVisualizerTests.swift
//  ChordLabTests
//
//  Tests for TheoryEngine methods used by Piano Chord Visualizer
//

import XCTest
import Tonic
@testable import ChordLab

final class PianoChordVisualizerTests: XCTestCase {
    
    var theoryEngine: TheoryEngine!
    
    override func setUp() {
        super.setUp()
        theoryEngine = TheoryEngine()
    }
    
    override func tearDown() {
        theoryEngine = nil
        super.tearDown()
    }
    
    // MARK: - getDiatonicChords() Tests
    
    func testGetDiatonicChords_CMajor() {
        // Given
        theoryEngine.setKey("C", scaleType: "major")
        
        // When
        let chords = theoryEngine.getDiatonicChords()
        
        // Then
        XCTAssertEqual(chords.count, 7, "Should return 7 diatonic triads")
        
        // Verify chord symbols
        let expectedSymbols = ["C", "Dm", "Em", "F", "G", "Am", "B°"]
        let actualSymbols = chords.map { $0.description }
        XCTAssertEqual(actualSymbols, expectedSymbols, "Should return correct chord symbols for C major")
        
        // Verify chord types
        XCTAssertEqual(chords[0].type, .major, "I should be major")
        XCTAssertEqual(chords[1].type, .minor, "ii should be minor")
        XCTAssertEqual(chords[2].type, .minor, "iii should be minor")
        XCTAssertEqual(chords[3].type, .major, "IV should be major")
        XCTAssertEqual(chords[4].type, .major, "V should be major")
        XCTAssertEqual(chords[5].type, .minor, "vi should be minor")
        XCTAssertEqual(chords[6].type, .dim, "vii° should be diminished")
    }
    
    func testGetDiatonicChords_GMajor() {
        // Given
        theoryEngine.setKey("G", scaleType: "major")
        
        // When
        let chords = theoryEngine.getDiatonicChords()
        
        // Then
        let expectedSymbols = ["G", "Am", "Bm", "C", "D", "Em", "F♯°"]
        let actualSymbols = chords.map { $0.description }
        XCTAssertEqual(actualSymbols, expectedSymbols, "Should return correct chord symbols for G major")
    }
    
    func testGetDiatonicChords_DMajor() {
        // Given
        theoryEngine.setKey("D", scaleType: "major")
        
        // When
        let chords = theoryEngine.getDiatonicChords()
        
        // Then
        let expectedSymbols = ["D", "Em", "F♯m", "G", "A", "Bm", "C♯°"]
        let actualSymbols = chords.map { $0.description }
        XCTAssertEqual(actualSymbols, expectedSymbols, "Should return correct chord symbols for D major")
    }
    
    func testGetDiatonicChords_FMajor() {
        // Given
        theoryEngine.setKey("F", scaleType: "major")
        
        // When
        let chords = theoryEngine.getDiatonicChords()
        
        // Then
        let expectedSymbols = ["F", "Gm", "Am", "B♭", "C", "Dm", "E°"]
        let actualSymbols = chords.map { $0.description }
        XCTAssertEqual(actualSymbols, expectedSymbols, "Should return correct chord symbols for F major")
    }
    
    func testGetDiatonicChords_AllWhiteKeys() {
        // Test all white keys to ensure they work correctly
        let whiteKeys = ["C", "D", "E", "F", "G", "A", "B"]
        
        for key in whiteKeys {
            theoryEngine.setKey(key, scaleType: "major")
            let chords = theoryEngine.getDiatonicChords()
            
            XCTAssertEqual(chords.count, 7, "Key \(key) should have 7 diatonic triads")
            XCTAssertFalse(chords.isEmpty, "Key \(key) should not return empty chord array")
            
            // Verify pattern of chord types (Major-minor-minor-Major-Major-minor-diminished)
            let expectedTypes: [ChordType] = [.major, .minor, .minor, .major, .major, .minor, .dim]
            let actualTypes = chords.map { $0.type }
            XCTAssertEqual(actualTypes, expectedTypes, "Key \(key) should follow the major scale chord pattern")
        }
    }
    
    // MARK: - getRomanNumeral() Tests
    
    func testGetRomanNumeral_DiatonicChords_CMajor() {
        // Given
        theoryEngine.setKey("C", scaleType: "major")
        
        // When/Then - Test each diatonic chord
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "C"), "I")
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "Dm"), "ii")
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "Em"), "iii")
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "F"), "IV")
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "G"), "V")
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "Am"), "vi")
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "B°"), "vii°")
    }
    
    func testGetRomanNumeral_DiatonicChords_GMajor() {
        // Given
        theoryEngine.setKey("G", scaleType: "major")
        
        // When/Then
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "G"), "I")
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "Am"), "ii")
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "Bm"), "iii")
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "C"), "IV")
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "D"), "V")
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "Em"), "vi")
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "F#°"), "vii°")
    }
    
    func testGetRomanNumeral_NonDiatonicChords() {
        // Given
        theoryEngine.setKey("C", scaleType: "major")
        
        // When/Then - Test borrowed chords
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "Eb"), "♭III")
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "Ab"), "♭VI")
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "Bb"), "♭VII")
        
        // Note: Fm returns "iv" because F is found in the scale (as IV normally)
        // The current implementation doesn't detect borrowed chord qualities
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "Fm"), "iv")
    }
    
    func testGetRomanNumeral_InvalidChord() {
        // Given
        theoryEngine.setKey("C", scaleType: "major")
        
        // When/Then
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "InvalidChord"), "?")
    }
    
    // MARK: - determineFunction() Tests
    
    func testDetermineFunction_BasicRomanNumerals() {
        // Test uppercase (major) numerals
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "I"), .tonic)
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "IV"), .subdominant)
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "V"), .dominant)
        
        // Test lowercase (minor) numerals
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "ii"), .supertonic)
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "iii"), .mediant)
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "vi"), .submediant)
        
        // Test diminished
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "vii°"), .leadingTone)
    }
    
    func testDetermineFunction_SeventhChords() {
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "IMAJ7"), .tonic)
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "IIM7"), .supertonic)
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "V7"), .dominant)
    }
    
    func testDetermineFunction_ChromaticChords() {
        // Borrowed or chromatic chords should return .chromatic
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "♭III"), .chromatic)
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "♭VI"), .chromatic)
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "V/V"), .chromatic)
    }
    
    // MARK: - Integration Tests
    
    func testDiatonicChordsWithRomanNumerals() {
        // Given
        theoryEngine.setKey("C", scaleType: "major")
        
        // When
        let chords = theoryEngine.getDiatonicChords()
        let romanNumerals = chords.map { theoryEngine.getRomanNumeral(for: $0.description) }
        
        // Then
        let expectedRomanNumerals = ["I", "ii", "iii", "IV", "V", "vi", "vii°"]
        XCTAssertEqual(romanNumerals, expectedRomanNumerals, "Roman numerals should match expected pattern")
    }
    
    func testDiatonicChordsWithFunctions() {
        // Given
        theoryEngine.setKey("C", scaleType: "major")
        
        // When
        let chords = theoryEngine.getDiatonicChords()
        let functions = chords.map { chord in
            let roman = theoryEngine.getRomanNumeral(for: chord.description)
            return theoryEngine.determineFunction(romanNumeral: roman)
        }
        
        // Then
        let expectedFunctions: [ChordFunction] = [
            .tonic,
            .supertonic,
            .mediant,
            .subdominant,
            .dominant,
            .submediant,
            .leadingTone
        ]
        XCTAssertEqual(functions, expectedFunctions, "Functions should match scale degrees")
    }
    
    // MARK: - Edge Cases
    
    func testGetDiatonicChords_NoKeySet() {
        // Given - Create a fresh instance with no key set
        let freshEngine = TheoryEngine()
        
        // When
        let chords = freshEngine.getDiatonicChords()
        
        // Then - Should still work with default key (C major)
        XCTAssertEqual(chords.count, 7, "Should return 7 chords even with default key")
    }
    
    func testChordNoteClasses() {
        // Given
        theoryEngine.setKey("C", scaleType: "major")
        
        // When
        let chords = theoryEngine.getDiatonicChords()
        let firstChord = chords[0] // C major
        
        // Then
        let expectedNotes: [NoteClass] = [.C, .E, .G]
        XCTAssertEqual(firstChord.noteClasses, expectedNotes, "C major should contain C, E, G")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceGetDiatonicChords() {
        measure {
            for _ in 0..<100 {
                _ = theoryEngine.getDiatonicChords()
            }
        }
    }
}

// MARK: - Helper Methods for PCV

extension PianoChordVisualizerTests {
    
    func testChordVisualizationData() {
        // Test that we can get all the data needed for visualization
        theoryEngine.setKey("C", scaleType: "major")
        
        let chords = theoryEngine.getDiatonicChords()
        
        for (index, chord) in chords.enumerated() {
            let romanNumeral = theoryEngine.getRomanNumeral(for: chord.description)
            let function = theoryEngine.determineFunction(romanNumeral: romanNumeral)
            
            // Verify we have all necessary data
            XCTAssertFalse(chord.description.isEmpty, "Chord \(index) should have a description")
            XCTAssertFalse(romanNumeral.isEmpty, "Chord \(index) should have a Roman numeral")
            XCTAssertNotNil(function, "Chord \(index) should have a function")
            
            // Verify chord has exactly 3 notes (triad)
            XCTAssertEqual(chord.noteClasses.count, 3, "Chord \(index) should be a triad")
        }
    }
    
    func testScaleDegreeNames() {
        // Define expected scale degree names for UI display
        let scaleDegreeNames = [
            "Tonic",
            "Supertonic", 
            "Mediant",
            "Subdominant",
            "Dominant",
            "Submediant",
            "Leading Tone"
        ]
        
        theoryEngine.setKey("C", scaleType: "major")
        let chords = theoryEngine.getDiatonicChords()
        
        XCTAssertEqual(chords.count, scaleDegreeNames.count, "Should have names for all scale degrees")
    }
    
    // MARK: - New Helper Method Tests
    
    func testGetScaleDegreeName() {
        // Test valid indices
        XCTAssertEqual(theoryEngine.getScaleDegreeName(for: 0), "Tonic")
        XCTAssertEqual(theoryEngine.getScaleDegreeName(for: 1), "Supertonic")
        XCTAssertEqual(theoryEngine.getScaleDegreeName(for: 2), "Mediant")
        XCTAssertEqual(theoryEngine.getScaleDegreeName(for: 3), "Subdominant")
        XCTAssertEqual(theoryEngine.getScaleDegreeName(for: 4), "Dominant")
        XCTAssertEqual(theoryEngine.getScaleDegreeName(for: 5), "Submediant")
        XCTAssertEqual(theoryEngine.getScaleDegreeName(for: 6), "Leading Tone")
        
        // Test invalid indices
        XCTAssertEqual(theoryEngine.getScaleDegreeName(for: -1), "Unknown")
        XCTAssertEqual(theoryEngine.getScaleDegreeName(for: 7), "Unknown")
        XCTAssertEqual(theoryEngine.getScaleDegreeName(for: 100), "Unknown")
    }
    
    func testGetChordToneRoles() {
        // Given
        theoryEngine.setKey("C", scaleType: "major")
        let chords = theoryEngine.getDiatonicChords()
        
        // Test C major triad
        let cMajor = chords[0]
        let roles = theoryEngine.getChordToneRoles(for: cMajor)
        
        XCTAssertEqual(roles.count, 3, "Should return 3 chord tone roles")
        XCTAssertEqual(roles[0].note, NoteClass.C, "First note should be C")
        XCTAssertEqual(roles[0].role, "Root", "First role should be Root")
        XCTAssertEqual(roles[1].note, NoteClass.E, "Second note should be E")
        XCTAssertEqual(roles[1].role, "Third", "Second role should be Third")
        XCTAssertEqual(roles[2].note, NoteClass.G, "Third note should be G")
        XCTAssertEqual(roles[2].role, "Fifth", "Third role should be Fifth")
        
        // Test D minor triad
        let dMinor = chords[1]
        let dMinorRoles = theoryEngine.getChordToneRoles(for: dMinor)
        
        XCTAssertEqual(dMinorRoles[0].note, NoteClass.D, "Root should be D")
        XCTAssertEqual(dMinorRoles[1].note, NoteClass.F, "Third should be F")
        XCTAssertEqual(dMinorRoles[2].note, NoteClass.A, "Fifth should be A")
    }
    
    func testGetChordToneRoles_AllDiatonicChords() {
        // Given
        theoryEngine.setKey("G", scaleType: "major")
        let chords = theoryEngine.getDiatonicChords()
        
        // Test all chords have proper roles
        for chord in chords {
            let roles = theoryEngine.getChordToneRoles(for: chord)
            
            XCTAssertEqual(roles.count, 3, "\(chord.description) should have 3 roles")
            XCTAssertEqual(roles[0].role, "Root")
            XCTAssertEqual(roles[1].role, "Third")
            XCTAssertEqual(roles[2].role, "Fifth")
            
            // Verify the root note matches the chord root
            XCTAssertEqual(roles[0].note, chord.root, "\(chord.description) root should match")
        }
    }
    
    func testGetDiatonicChordsWithAnalysis() {
        // Given
        theoryEngine.setKey("C", scaleType: "major")
        
        // When
        let analysis = theoryEngine.getDiatonicChordsWithAnalysis()
        
        // Then
        XCTAssertEqual(analysis.count, 7, "Should return 7 analyzed chords")
        
        // Test first chord (C major - Tonic)
        let first = analysis[0]
        XCTAssertEqual(first.chord.description, "C")
        XCTAssertEqual(first.romanNumeral, "I")
        XCTAssertEqual(first.function, .tonic)
        XCTAssertEqual(first.degreeName, "Tonic")
        
        // Test second chord (D minor - Supertonic)
        let second = analysis[1]
        XCTAssertEqual(second.chord.description, "Dm")
        XCTAssertEqual(second.romanNumeral, "ii")
        XCTAssertEqual(second.function, .supertonic)
        XCTAssertEqual(second.degreeName, "Supertonic")
        
        // Test fifth chord (G major - Dominant)
        let fifth = analysis[4]
        XCTAssertEqual(fifth.chord.description, "G")
        XCTAssertEqual(fifth.romanNumeral, "V")
        XCTAssertEqual(fifth.function, .dominant)
        XCTAssertEqual(fifth.degreeName, "Dominant")
        
        // Test seventh chord (B diminished - Leading Tone)
        let seventh = analysis[6]
        XCTAssertEqual(seventh.chord.description, "B°")
        XCTAssertEqual(seventh.romanNumeral, "vii°")
        XCTAssertEqual(seventh.function, .leadingTone)
        XCTAssertEqual(seventh.degreeName, "Leading Tone")
    }
    
    func testGetDiatonicChordsWithAnalysis_DifferentKeys() {
        // Test multiple keys
        let testKeys = ["C", "G", "D", "A", "E", "B", "F"]
        
        for key in testKeys {
            theoryEngine.setKey(key, scaleType: "major")
            let analysis = theoryEngine.getDiatonicChordsWithAnalysis()
            
            XCTAssertEqual(analysis.count, 7, "Key \(key) should have 7 analyzed chords")
            
            // Verify all components are present
            for (index, item) in analysis.enumerated() {
                XCTAssertFalse(item.chord.description.isEmpty, "Chord description should not be empty")
                XCTAssertFalse(item.romanNumeral.isEmpty, "Roman numeral should not be empty")
                XCTAssertNotNil(item.function, "Function should not be nil")
                XCTAssertEqual(item.degreeName, theoryEngine.getScaleDegreeName(for: index), "Degree name should match index")
            }
        }
    }
    
    // MARK: - Integration Test for PCV
    
    func testCompleteChordVisualizationFlow() {
        // Simulate the complete flow for Piano Chord Visualizer
        theoryEngine.setKey("D", scaleType: "major")
        
        // Get all chord data
        let chordData = theoryEngine.getDiatonicChordsWithAnalysis()
        
        // Simulate selecting the first chord (D major)
        let selectedChord = chordData[0]
        let chordTones = theoryEngine.getChordToneRoles(for: selectedChord.chord)
        
        // Verify we have all necessary data for visualization
        XCTAssertEqual(selectedChord.chord.description, "D", "Should be D major")
        XCTAssertEqual(selectedChord.romanNumeral, "I", "Should be I")
        XCTAssertEqual(selectedChord.function, .tonic, "Should be tonic function")
        XCTAssertEqual(selectedChord.degreeName, "Tonic", "Should be Tonic")
        
        // Verify chord tones for piano highlighting
        XCTAssertEqual(chordTones.count, 3, "Should have 3 tones")
        XCTAssertEqual(chordTones[0].note.description, "D", "Root should be D")
        XCTAssertEqual(chordTones[1].note.description, "F♯", "Third should be F#")
        XCTAssertEqual(chordTones[2].note.description, "A", "Fifth should be A")
    }
}
