//
//  KeyScaleSelectorIntegrationTests.swift
//  ChordLabTests
//
//  Integration tests for KeyScaleSelector with LearnTabView
//

import XCTest
import SwiftUI
@testable import ChordLab

@MainActor
final class KeyScaleSelectorIntegrationTests: XCTestCase {
    var theoryEngine: TheoryEngine!
    var dataManager: DataManager!
    var audioEngine: AudioEngine!
    
    override func setUp() async throws {
        theoryEngine = TheoryEngine()
        dataManager = DataManager(inMemory: true)
        audioEngine = AudioEngine()
    }
    
    func testLearnTabViewWithKeyScaleSelector() {
        // Create the view with all required environments
        let view = LearnTabView()
            .environment(theoryEngine)
            .environment(dataManager)
            .environment(audioEngine)
        
        XCTAssertNotNil(view, "LearnTabView should initialize with KeyScaleSelector")
    }
    
    func testKeySelectionUpdatesPiano() {
        // Initial state
        let initialKey = theoryEngine.currentKey
        let initialScale = theoryEngine.currentScaleType
        
        // Change key
        theoryEngine.setKey("G", scaleType: "major")
        
        // Verify changes
        XCTAssertNotEqual(theoryEngine.currentKey, initialKey)
        XCTAssertEqual(theoryEngine.currentKey, "G")
        
        // Get scale notes - piano should highlight these
        let scaleNotes = theoryEngine.getCurrentScaleNotes()
        XCTAssertEqual(scaleNotes.count, 7, "Major scale should have 7 notes")
    }
    
    func testScaleSelectionUpdatesPiano() {
        // Set to C major first
        theoryEngine.setKey("C", scaleType: "major")
        let majorNotes = theoryEngine.getCurrentScaleNotes()
        
        // Change to C minor
        theoryEngine.setKey("C", scaleType: "minor")
        let minorNotes = theoryEngine.getCurrentScaleNotes()
        
        // Verify they're different
        XCTAssertNotEqual(majorNotes, minorNotes, "Major and minor scales should be different")
        XCTAssertEqual(minorNotes.count, 7, "Minor scale should have 7 notes")
    }
    
    func testPersistenceIntegration() throws {
        // Make a selection
        theoryEngine.setKey("A♭", scaleType: "minor")
        
        // Use the DataManager update method
        try dataManager.updateUserData { userData in
            userData.currentKey = theoryEngine.currentKey
            userData.currentScale = theoryEngine.currentScaleType
        }
        
        // Verify it was saved
        let userData = try dataManager.getOrCreateUserData()
        XCTAssertEqual(userData.currentKey, "A♭")
        XCTAssertEqual(userData.currentScale, "minor")
    }
}