//
//  SavedProgressionTests.swift
//  ChordLabTests
//
//  Tests for SavedProgression model
//

import XCTest
@testable import ChordLab

final class SavedProgressionTests: XCTestCase {
    
    func testLegacyInitializer() {
        // Test the legacy initializer still works
        let progression = SavedProgression(
            name: "Test Progression",
            chords: ["C", "F", "G", "C"],
            key: "C",
            scale: "major",
            tempo: 120
        )
        
        XCTAssertEqual(progression.name, "Test Progression")
        XCTAssertEqual(progression.chords, ["C", "F", "G", "C"])
        XCTAssertEqual(progression.key, "C")
        XCTAssertEqual(progression.scale, "major")
        XCTAssertEqual(progression.tempo, 120)
        XCTAssertEqual(progression.chordCount, 4)
    }
    
    func testProgressionChordInitializer() {
        // Test the new ProgressionChord-based initializer
        let chords = [
            ProgressionChord(chordSymbol: "Cmaj7", romanNumeral: "I", noteNames: ["C", "E", "G", "B"], function: "Tonic", duration: 1.0),
            ProgressionChord(chordSymbol: "Dm7", romanNumeral: "ii", noteNames: ["D", "F", "A", "C"], function: "Supertonic", duration: 1.0),
            ProgressionChord(chordSymbol: "G7", romanNumeral: "V", noteNames: ["G", "B", "D", "F"], function: "Dominant", duration: 1.0),
            ProgressionChord(chordSymbol: "Cmaj7", romanNumeral: "I", noteNames: ["C", "E", "G", "B"], function: "Tonic", duration: 1.0)
        ]
        
        let progression = SavedProgression(
            name: "Jazz Progression",
            progressionChords: chords,
            key: "C",
            tempo: 120
        )
        
        XCTAssertEqual(progression.name, "Jazz Progression")
        XCTAssertEqual(progression.key, "C")
        XCTAssertEqual(progression.progressionChords.count, 4)
        XCTAssertEqual(progression.progressionChords[0].chordSymbol, "Cmaj7")
        XCTAssertEqual(progression.progressionChords[1].romanNumeral, "ii")
        XCTAssertEqual(progression.chords, ["Cmaj7", "Dm7", "G7", "Cmaj7"]) // Legacy compatibility
    }
    
    func testDurationCalculation() {
        // Test duration calculation based on tempo and beats
        let chords = [
            ProgressionChord(chordSymbol: "C", duration: 2.0), // 2 beats
            ProgressionChord(chordSymbol: "F", duration: 2.0), // 2 beats
            ProgressionChord(chordSymbol: "G", duration: 2.0), // 2 beats
            ProgressionChord(chordSymbol: "C", duration: 2.0)  // 2 beats
        ]
        
        let progression = SavedProgression(
            name: "8 Beat Progression",
            progressionChords: chords,
            key: "C",
            tempo: 120 // 120 BPM = 2 beats per second
        )
        
        // 8 beats at 120 BPM = 4 seconds
        XCTAssertEqual(progression.duration, 4.0, accuracy: 0.01)
    }
    
    func testProgressionChordGetterSetter() {
        // Test the computed property for progressionChords
        let progression = SavedProgression(
            name: "Test",
            chords: ["Am", "F", "C", "G"],
            key: "C"
        )
        
        // Initially uses legacy data
        XCTAssertEqual(progression.progressionChords.count, 4)
        XCTAssertEqual(progression.progressionChords[0].chordSymbol, "Am")
        
        // Update with new ProgressionChord data
        let newChords = [
            ProgressionChord(chordSymbol: "Am7", romanNumeral: "vi", function: "Submediant"),
            ProgressionChord(chordSymbol: "Fmaj7", romanNumeral: "IV", function: "Subdominant")
        ]
        progression.progressionChords = newChords
        
        XCTAssertEqual(progression.progressionChords.count, 2)
        XCTAssertEqual(progression.progressionChords[0].chordSymbol, "Am7")
        XCTAssertEqual(progression.progressionChords[1].romanNumeral, "IV")
    }
    
    func testMetadataFields() {
        // Test new metadata fields
        let progression = SavedProgression(
            name: "Tagged Progression",
            chords: ["C", "G"],
            key: "C"
        )
        
        // Test tags
        progression.tags = ["jazz", "beginner", "ii-V-I"]
        XCTAssertEqual(progression.tags.count, 3)
        XCTAssertTrue(progression.tags.contains("jazz"))
        
        // Test favorite
        XCTAssertFalse(progression.isFavorite)
        progression.isFavorite = true
        XCTAssertTrue(progression.isFavorite)
        
        // Test play tracking
        XCTAssertEqual(progression.playCount, 0)
        XCTAssertNil(progression.lastPlayedAt)
        
        progression.playCount = 5
        let now = Date()
        progression.lastPlayedAt = now
        
        XCTAssertEqual(progression.playCount, 5)
        XCTAssertEqual(progression.lastPlayedAt, now)
    }
    
    func testDateFields() {
        // Test date tracking
        let before = Date()
        let progression = SavedProgression(
            name: "Test",
            chords: ["C"],
            key: "C"
        )
        let after = Date()
        
        // dateCreated should be set in init
        XCTAssertTrue(progression.dateCreated >= before)
        XCTAssertTrue(progression.dateCreated <= after)
        XCTAssertEqual(progression.dateCreated, progression.dateModified)
        
        // Simulate modification
        Thread.sleep(forTimeInterval: 0.1)
        progression.dateModified = Date()
        XCTAssertTrue(progression.dateModified > progression.dateCreated)
    }
}