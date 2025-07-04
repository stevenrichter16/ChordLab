//
//  TheoryEngineSeventhsTests.swift
//  ChordLabTests
//
//  Tests for seventh chord functionality
//

import XCTest
import Tonic
@testable import ChordLab

final class TheoryEngineSeventhsTests: XCTestCase {
    var theoryEngine: TheoryEngine!
    
    override func setUp() {
        super.setUp()
        theoryEngine = TheoryEngine()
    }
    
    override func tearDown() {
        theoryEngine = nil
        super.tearDown()
    }
    
    // MARK: - getSeventhChords Tests
    
    func testGetSeventhChordsInCMajor() {
        // Given
        theoryEngine.setKey("C", scaleType: "major")
        
        // When
        let seventhChords = theoryEngine.getSeventhChords()
        
        // Then
        XCTAssertEqual(seventhChords.count, 7)
        
        // Verify chord types
        XCTAssertEqual(seventhChords[0].type, .maj7)  // Cmaj7
        XCTAssertEqual(seventhChords[1].type, .min7)  // Dm7
        XCTAssertEqual(seventhChords[2].type, .min7)  // Em7
        XCTAssertEqual(seventhChords[3].type, .maj7)  // Fmaj7
        XCTAssertEqual(seventhChords[4].type, .dom7)  // G7
        XCTAssertEqual(seventhChords[5].type, .min7)  // Am7
        XCTAssertEqual(seventhChords[6].type, .halfDim7)  // Bø7
        
        // Verify roots
        XCTAssertEqual(seventhChords[0].root, .C)
        XCTAssertEqual(seventhChords[1].root, .D)
        XCTAssertEqual(seventhChords[2].root, .E)
        XCTAssertEqual(seventhChords[3].root, .F)
        XCTAssertEqual(seventhChords[4].root, .G)
        XCTAssertEqual(seventhChords[5].root, .A)
        XCTAssertEqual(seventhChords[6].root, .B)
    }
    
    func testGetSeventhChordsInGMajor() {
        // Given
        theoryEngine.setKey("G", scaleType: "major")
        
        // When
        let seventhChords = theoryEngine.getSeventhChords()
        
        // Then
        XCTAssertEqual(seventhChords.count, 7)
        XCTAssertEqual(seventhChords[0].root, .G)
        XCTAssertEqual(seventhChords[0].type, .maj7)
        XCTAssertEqual(seventhChords[4].root, .D)
        XCTAssertEqual(seventhChords[4].type, .dom7)  // D7 is dominant
    }
    
    // MARK: - getSeventhChordsWithAnalysis Tests
    
    func testGetSeventhChordsWithAnalysis() {
        // Given
        theoryEngine.setKey("C", scaleType: "major")
        
        // When
        let chordsWithAnalysis = theoryEngine.getSeventhChordsWithAnalysis()
        
        // Then
        XCTAssertEqual(chordsWithAnalysis.count, 7)
        
        // Check first chord (Cmaj7)
        let firstChord = chordsWithAnalysis[0]
        XCTAssertEqual(firstChord.chord.root, .C)
        XCTAssertEqual(firstChord.chord.type, .maj7)
        XCTAssertEqual(firstChord.romanNumeral, "Imaj7")
        XCTAssertEqual(firstChord.function, .tonic)
        XCTAssertEqual(firstChord.degreeName, "Tonic")
        
        // Check dominant chord (G7)
        let dominantChord = chordsWithAnalysis[4]
        XCTAssertEqual(dominantChord.chord.root, .G)
        XCTAssertEqual(dominantChord.chord.type, .dom7)
        XCTAssertEqual(dominantChord.romanNumeral, "V7")
        XCTAssertEqual(dominantChord.function, .dominant)
        XCTAssertEqual(dominantChord.degreeName, "Dominant")
        
        // Check half-diminished chord (Bø7)
        let halfDimChord = chordsWithAnalysis[6]
        XCTAssertEqual(halfDimChord.chord.root, .B)
        XCTAssertEqual(halfDimChord.chord.type, .halfDim7)
        XCTAssertEqual(halfDimChord.romanNumeral, "vii°7")
        XCTAssertEqual(halfDimChord.function, .leadingTone)
        XCTAssertEqual(halfDimChord.degreeName, "Leading Tone")
    }
    
    // MARK: - getChordToneRoles Tests
    
    func testGetChordToneRolesForSeventhChord() {
        // Given
        let cmaj7 = Chord(.C, type: .maj7)
        
        // When
        let roles = theoryEngine.getChordToneRoles(for: cmaj7)
        
        // Then
        XCTAssertEqual(roles.count, 4)
        XCTAssertEqual(roles[0].note, .C)
        XCTAssertEqual(roles[0].role, "Root")
        XCTAssertEqual(roles[1].note, .E)
        XCTAssertEqual(roles[1].role, "Third")
        XCTAssertEqual(roles[2].note, .G)
        XCTAssertEqual(roles[2].role, "Fifth")
        XCTAssertEqual(roles[3].note, .B)
        XCTAssertEqual(roles[3].role, "Seventh")
    }
    
    func testGetChordToneRolesForTriad() {
        // Given
        let cMajor = Chord(.C, type: .major)
        
        // When
        let roles = theoryEngine.getChordToneRoles(for: cMajor)
        
        // Then
        XCTAssertEqual(roles.count, 3)
        XCTAssertEqual(roles[0].role, "Root")
        XCTAssertEqual(roles[1].role, "Third")
        XCTAssertEqual(roles[2].role, "Fifth")
    }
    
    // MARK: - Roman Numeral Tests
    
    func testRomanNumeralsForSeventhChords() {
        // Given
        theoryEngine.setKey("C", scaleType: "major")
        let chordsWithAnalysis = theoryEngine.getSeventhChordsWithAnalysis()
        
        // Then
        let expectedRomanNumerals = ["Imaj7", "ii7", "iii7", "IVmaj7", "V7", "vi7", "vii°7"]
        
        for (index, expected) in expectedRomanNumerals.enumerated() {
            XCTAssertEqual(chordsWithAnalysis[index].romanNumeral, expected,
                          "Roman numeral at index \(index) should be \(expected)")
        }
    }
}