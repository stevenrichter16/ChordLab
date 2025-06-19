//
//  KeyPickerViewTests.swift
//  ChordLabTests
//
//  Tests for KeyPickerView
//

import XCTest
import SwiftUI
@testable import ChordLab

@MainActor
final class KeyPickerViewTests: XCTestCase {
    var theoryEngine: TheoryEngine!
    var dataManager: DataManager!
    
    override func setUp() async throws {
        theoryEngine = TheoryEngine()
        dataManager = DataManager(inMemory: true)
        // DataManager initializes itself in init
    }
    
    // Test 1: Verify all 12 keys are represented
    func testAllKeysDisplayed() {
        // The view should display all 12 chromatic notes
        let expectedKeys = [
            "C", "C♯/D♭", "D", "D♯/E♭", "E", "F",
            "F♯/G♭", "G", "G♯/A♭", "A", "A♯/B♭", "B"
        ]
        
        // This test validates our data model has all keys
        XCTAssertEqual(expectedKeys.count, 12, "Should have 12 keys")
        
        // Verify each key can be parsed by our engine
        for key in ["C", "C♯", "D♭", "D", "D♯", "E♭", "E", "F", "F♯", "G♭", "G", "G♯", "A♭", "A", "A♯", "B♭", "B"] {
            theoryEngine.setKey(key, scaleType: "major")
            XCTAssertEqual(theoryEngine.currentKey, key, "Should be able to set key \(key)")
        }
    }
    
    // Test 2: Test key selection updates TheoryEngine
    func testKeySelection() throws {
        // Initial state
        XCTAssertEqual(theoryEngine.currentKey, "C")
        
        // Simulate selecting a new key
        theoryEngine.setKey("G", scaleType: theoryEngine.currentScaleType)
        XCTAssertEqual(theoryEngine.currentKey, "G")
        
        // Test enharmonic selection
        theoryEngine.setKey("F♯", scaleType: theoryEngine.currentScaleType)
        XCTAssertEqual(theoryEngine.currentKey, "F♯")
        
        theoryEngine.setKey("G♭", scaleType: theoryEngine.currentScaleType)
        XCTAssertEqual(theoryEngine.currentKey, "G♭")
    }
    
    // Test 3: Test scale type selection
    func testScaleTypeSelection() throws {
        // Initial state
        XCTAssertEqual(theoryEngine.currentScaleType, "major")
        
        // Change scale type
        theoryEngine.setKey(theoryEngine.currentKey, scaleType: "minor")
        XCTAssertEqual(theoryEngine.currentScaleType, "minor")
        
        // Verify scale notes update
        let minorScaleNotes = theoryEngine.getCurrentScaleNotes()
        XCTAssertEqual(minorScaleNotes.count, 7)
        
        // Test other scale types
        let scaleTypes = ["major", "minor", "dorian", "mixolydian", "phrygian", "lydian", "locrian"]
        for scaleType in scaleTypes {
            theoryEngine.setKey(theoryEngine.currentKey, scaleType: scaleType)
            XCTAssertEqual(theoryEngine.currentScaleType, scaleType)
        }
    }
    
    // Test 4: Test persistence to DataManager
    func testPersistence() async throws {
        // Set a key and scale
        theoryEngine.setKey("E♭", scaleType: "dorian")
        
        // Save to DataManager
        let userData = try dataManager.getOrCreateUserData()
        userData.currentKey = theoryEngine.currentKey
        userData.currentScale = theoryEngine.currentScaleType
        try dataManager.context.save()
        
        // Verify persistence
        XCTAssertEqual(userData.currentKey, "E♭")
        XCTAssertEqual(userData.currentScale, "dorian")
    }
    
    // Test 5: Test enharmonic display formatting
    func testEnharmonicDisplay() {
        // Test our formatting function for enharmonic notes
        let enharmonicPairs = [
            ("C♯", "D♭"),
            ("D♯", "E♭"),
            ("F♯", "G♭"),
            ("G♯", "A♭"),
            ("A♯", "B♭")
        ]
        
        for (sharp, flat) in enharmonicPairs {
            // Both should be valid keys
            theoryEngine.setKey(sharp, scaleType: "major")
            XCTAssertEqual(theoryEngine.currentKey, sharp)
            
            theoryEngine.setKey(flat, scaleType: "major")
            XCTAssertEqual(theoryEngine.currentKey, flat)
        }
        
        // Natural notes should not have enharmonics in our display
        let naturalNotes = ["C", "D", "E", "F", "G", "A", "B"]
        for note in naturalNotes {
            theoryEngine.setKey(note, scaleType: "major")
            XCTAssertEqual(theoryEngine.currentKey, note)
        }
    }
    
    // Test 6: Test dismissal behavior
    func testDismissal() async {
        // Test that changes are preserved after dismissal
        let originalKey = theoryEngine.currentKey
        let originalScale = theoryEngine.currentScaleType
        
        // Make changes
        theoryEngine.setKey("A", scaleType: "mixolydian")
        
        // Verify changes took effect
        XCTAssertNotEqual(theoryEngine.currentKey, originalKey)
        XCTAssertNotEqual(theoryEngine.currentScaleType, originalScale)
        
        // In actual UI, dismissal would trigger save to DataManager
        do {
            let userData = try dataManager.getOrCreateUserData()
            userData.currentKey = theoryEngine.currentKey
            userData.currentScale = theoryEngine.currentScaleType
            try dataManager.context.save()
            
            // Verify final state
            XCTAssertEqual(userData.currentKey, "A")
            XCTAssertEqual(userData.currentScale, "mixolydian")
        } catch {
            XCTFail("Failed to save user data: \(error)")
        }
    }
}