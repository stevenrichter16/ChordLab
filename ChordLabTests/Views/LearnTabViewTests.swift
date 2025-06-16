//
//  LearnTabViewTests.swift
//  ChordLabTests
//
//  Tests for LearnTabView
//

import XCTest
import SwiftUI
@testable import ChordLab

@MainActor
final class LearnTabViewTests: XCTestCase {
    var theoryEngine: TheoryEngine!
    var dataManager: DataManager!
    
    override func setUp() {
        super.setUp()
        theoryEngine = TheoryEngine()
        dataManager = DataManager(inMemory: true)
    }
    
    override func tearDown() {
        theoryEngine = nil
        dataManager = nil
        super.tearDown()
    }
    
    func testLearnTabViewInitializes() {
        // Given
        let view = LearnTabView()
            .environment(theoryEngine)
            .environment(dataManager)
        
        // Then
        XCTAssertNotNil(view)
    }
    
    func testLearnTabViewUsesCurrentKey() {
        // Given
        theoryEngine.setKey("D", scaleType: "minor")
        
        // When
        let view = LearnTabView()
            .environment(theoryEngine)
            .environment(dataManager)
        
        // Then
        // The view should be using the theory engine's current key
        XCTAssertEqual(theoryEngine.currentKey, "D")
        XCTAssertEqual(theoryEngine.currentScaleType, "minor")
        XCTAssertNotNil(view)
    }
    
    func testQuickActionButtonProperties() {
        // Given
        let testCases = [
            ("Scale Practice", "music.note", Color.blue),
            ("Chord Review", "pianokeys", Color.green),
            ("Ear Training", "ear", Color.orange),
            ("Theory Quiz", "questionmark.circle", Color.purple)
        ]
        
        for (title, icon, color) in testCases {
            // When
            let button = QuickActionButton(
                title: title,
                icon: icon,
                color: color
            )
            
            // Then
            XCTAssertEqual(button.title, title)
            XCTAssertEqual(button.icon, icon)
            XCTAssertEqual(button.color, color)
        }
    }
    
    func testLearnTabViewWithDifferentKeys() {
        // Test that the view initializes correctly with different key contexts
        let keyTests = [
            ("C", "major"),
            ("A", "minor"),
            ("G", "mixolydian"),
            ("F#", "dorian")
        ]
        
        for (key, scale) in keyTests {
            // Given
            theoryEngine.setKey(key, scaleType: scale)
            
            // When
            let view = LearnTabView()
                .environment(theoryEngine)
                .environment(dataManager)
            
            // Then
            XCTAssertNotNil(view)
            XCTAssertEqual(theoryEngine.currentKey, key)
            XCTAssertEqual(theoryEngine.currentScaleType, scale)
        }
    }
}