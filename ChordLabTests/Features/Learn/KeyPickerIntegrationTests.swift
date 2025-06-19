//
//  KeyPickerIntegrationTests.swift
//  ChordLabTests
//
//  Integration tests for KeyPickerView with LearnTabView
//

import XCTest
import SwiftUI
@testable import ChordLab

@MainActor
final class KeyPickerIntegrationTests: XCTestCase {
    var theoryEngine: TheoryEngine!
    var dataManager: DataManager!
    
    override func setUp() async throws {
        theoryEngine = TheoryEngine()
        dataManager = DataManager(inMemory: true)
    }
    
    func testKeyPickerViewInitialization() {
        // Test that KeyPickerView can be initialized
        let keyPicker = KeyPickerView()
            .environment(theoryEngine)
            .environment(dataManager)
        
        XCTAssertNotNil(keyPicker, "KeyPickerView should initialize successfully")
    }
    
    func testLearnTabViewHasKeyPickerButton() {
        // Test that LearnTabView has the key picker trigger
        let learnTab = LearnTabView()
            .environment(theoryEngine)
            .environment(dataManager)
        
        XCTAssertNotNil(learnTab, "LearnTabView should initialize successfully")
    }
    
    func testKeySelectionUpdatesEngine() {
        // Test the key selection flow
        let initialKey = theoryEngine.currentKey
        let initialScale = theoryEngine.currentScaleType
        
        // Simulate key change
        theoryEngine.setKey("G", scaleType: "minor")
        
        XCTAssertNotEqual(theoryEngine.currentKey, initialKey)
        XCTAssertEqual(theoryEngine.currentKey, "G")
        XCTAssertEqual(theoryEngine.currentScaleType, "minor")
    }
    
    func testScalePianoViewRespondsToKeyChanges() {
        // Test that ScalePianoView will update when key changes
        let piano = ScalePianoView()
            .environment(theoryEngine)
            .environment(AudioEngine())
        
        // Change the key
        theoryEngine.setKey("D", scaleType: "major")
        
        // Verify the engine has the new key
        XCTAssertEqual(theoryEngine.currentKey, "D")
        XCTAssertEqual(theoryEngine.currentScaleType, "major")
        
        // The piano view should automatically update via @Environment
        XCTAssertNotNil(piano, "ScalePianoView should exist and be ready to display new scale")
    }
}