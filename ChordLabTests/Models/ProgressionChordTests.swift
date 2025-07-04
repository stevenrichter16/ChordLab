//
//  ProgressionChordTests.swift
//  ChordLabTests
//
//  Tests for ProgressionChord struct
//

import XCTest
@testable import ChordLab

final class ProgressionChordTests: XCTestCase {
    
    func testInitialization() {
        // Test full initialization
        let chord = ProgressionChord(
            chordSymbol: "Cmaj7",
            romanNumeral: "I",
            noteNames: ["C", "E", "G", "B"],
            function: "Tonic",
            duration: 2.0
        )
        
        XCTAssertEqual(chord.chordSymbol, "Cmaj7")
        XCTAssertEqual(chord.romanNumeral, "I")
        XCTAssertEqual(chord.noteNames, ["C", "E", "G", "B"])
        XCTAssertEqual(chord.function, "Tonic")
        XCTAssertEqual(chord.duration, 2.0)
    }
    
    func testDefaultInitialization() {
        // Test initialization with defaults
        let chord = ProgressionChord(chordSymbol: "Am")
        
        XCTAssertEqual(chord.chordSymbol, "Am")
        XCTAssertEqual(chord.romanNumeral, "")
        XCTAssertEqual(chord.noteNames, [])
        XCTAssertEqual(chord.function, "")
        XCTAssertEqual(chord.duration, 1.0)
    }
    
    func testCodable() {
        // Test encoding and decoding
        let original = ProgressionChord(
            chordSymbol: "Dm7",
            romanNumeral: "ii",
            noteNames: ["D", "F", "A", "C"],
            function: "Supertonic",
            duration: 1.5
        )
        
        // Encode
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(original) else {
            XCTFail("Failed to encode ProgressionChord")
            return
        }
        
        // Decode
        let decoder = JSONDecoder()
        guard let decoded = try? decoder.decode(ProgressionChord.self, from: data) else {
            XCTFail("Failed to decode ProgressionChord")
            return
        }
        
        // Verify
        XCTAssertEqual(decoded.chordSymbol, original.chordSymbol)
        XCTAssertEqual(decoded.romanNumeral, original.romanNumeral)
        XCTAssertEqual(decoded.noteNames, original.noteNames)
        XCTAssertEqual(decoded.function, original.function)
        XCTAssertEqual(decoded.duration, original.duration)
    }
    
    func testJSONDataConversion() {
        // Test convenience methods
        let chord = ProgressionChord(
            chordSymbol: "G7",
            romanNumeral: "V",
            noteNames: ["G", "B", "D", "F"],
            function: "Dominant",
            duration: 1.0
        )
        
        // Convert to JSON data
        guard let jsonData = chord.jsonData else {
            XCTFail("Failed to convert to JSON data")
            return
        }
        
        // Convert back from JSON data
        guard let restored = ProgressionChord.from(jsonData: jsonData) else {
            XCTFail("Failed to restore from JSON data")
            return
        }
        
        XCTAssertEqual(restored, chord)
    }
    
    func testEquatable() {
        // Test equality
        let chord1 = ProgressionChord(
            chordSymbol: "C",
            romanNumeral: "I",
            noteNames: ["C", "E", "G"],
            function: "Tonic",
            duration: 1.0
        )
        
        let chord2 = ProgressionChord(
            chordSymbol: "C",
            romanNumeral: "I",
            noteNames: ["C", "E", "G"],
            function: "Tonic",
            duration: 1.0
        )
        
        let chord3 = ProgressionChord(
            chordSymbol: "F",
            romanNumeral: "IV",
            noteNames: ["F", "A", "C"],
            function: "Subdominant",
            duration: 1.0
        )
        
        XCTAssertEqual(chord1, chord2)
        XCTAssertNotEqual(chord1, chord3)
    }
}