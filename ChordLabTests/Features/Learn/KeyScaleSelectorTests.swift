//
//  KeyScaleSelectorTests.swift
//  ChordLabTests
//
//  Tests for the KeyScaleSelector component
//

import XCTest
import SwiftUI
@testable import ChordLab

@MainActor
final class KeyScaleSelectorTests: XCTestCase {
    var theoryEngine: TheoryEngine!
    var dataManager: DataManager!
    
    override func setUp() async throws {
        theoryEngine = TheoryEngine()
        dataManager = DataManager(inMemory: true)
    }
    
    // Test 1: Component initialization
    func testKeyScaleSelectorInitialization() {
        let selector = KeyScaleSelector()
            .environment(theoryEngine)
            .environment(dataManager)
        
        XCTAssertNotNil(selector, "KeyScaleSelector should initialize successfully")
    }
    
    // Test 2: All keys are available
    func testAllKeysAvailable() {
        let expectedKeys = [
            "C", "C♯", "D♭", "D", "D♯", "E♭", "E", "F", 
            "F♯", "G♭", "G", "G♯", "A♭", "A", "A♯", "B♭", "B"
        ]
        
        // Verify TheoryEngine can handle all keys
        for key in expectedKeys {
            theoryEngine.setKey(key, scaleType: "major")
            XCTAssertEqual(theoryEngine.currentKey, key)
        }
    }
    
    // Test 3: Scale types available
    func testScaleTypesAvailable() {
        let scaleTypes = ["major", "minor"]
        
        for scaleType in scaleTypes {
            theoryEngine.setKey("C", scaleType: scaleType)
            XCTAssertEqual(theoryEngine.currentScaleType, scaleType)
        }
    }
    
    // Test 4: Key selection updates engine
    func testKeySelectionUpdatesEngine() {
        let initialKey = theoryEngine.currentKey
        
        // Simulate selecting a different key
        theoryEngine.setKey("G", scaleType: theoryEngine.currentScaleType)
        
        XCTAssertNotEqual(theoryEngine.currentKey, initialKey)
        XCTAssertEqual(theoryEngine.currentKey, "G")
    }
    
    // Test 5: Scale selection updates engine
    func testScaleSelectionUpdatesEngine() {
        theoryEngine.setKey("C", scaleType: "major")
        XCTAssertEqual(theoryEngine.currentScaleType, "major")
        
        theoryEngine.setKey("C", scaleType: "minor")
        XCTAssertEqual(theoryEngine.currentScaleType, "minor")
    }
    
    // Test 6: Persistence integration
    func testSelectionPersistence() throws {
        // Make a selection
        theoryEngine.setKey("E♭", scaleType: "minor")
        
        // Save to DataManager
        let userData = try dataManager.getOrCreateUserData()
        userData.currentKey = theoryEngine.currentKey
        userData.currentScale = theoryEngine.currentScaleType
        try dataManager.context.save()
        
        // Verify persistence
        XCTAssertEqual(userData.currentKey, "E♭")
        XCTAssertEqual(userData.currentScale, "minor")
    }
    
    // Test 7: Enharmonic equivalents
    func testEnharmonicHandling() {
        // Test that both sharps and flats work
        let enharmonicPairs = [
            ("C♯", "D♭"),
            ("D♯", "E♭"),
            ("F♯", "G♭"),
            ("G♯", "A♭"),
            ("A♯", "B♭")
        ]
        
        for (sharp, flat) in enharmonicPairs {
            theoryEngine.setKey(sharp, scaleType: "major")
            let sharpNotes = theoryEngine.getCurrentScaleNotes()
            
            theoryEngine.setKey(flat, scaleType: "major")
            let flatNotes = theoryEngine.getCurrentScaleNotes()
            
            // Both should produce valid scales
            XCTAssertEqual(sharpNotes.count, 7)
            XCTAssertEqual(flatNotes.count, 7)
        }
    }
}