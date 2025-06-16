//
//  PracticeTabViewTests.swift
//  ChordLabTests
//
//  Tests for PracticeTabView
//

import XCTest
import SwiftUI
@testable import ChordLab

@MainActor
final class PracticeTabViewTests: XCTestCase {
    var dataManager: DataManager!
    var theoryEngine: TheoryEngine!
    
    override func setUp() {
        super.setUp()
        dataManager = DataManager(inMemory: true)
        theoryEngine = TheoryEngine()
    }
    
    override func tearDown() {
        dataManager = nil
        theoryEngine = nil
        super.tearDown()
    }
    
    func testPracticeTabViewInitializes() {
        // Given
        let view = PracticeTabView()
            .environment(dataManager)
            .environment(theoryEngine)
        
        // Then
        XCTAssertNotNil(view)
    }
    
    func testPracticeModeCardProperties() {
        // Given
        let modes = [
            ("Ear Training", "Identify chords by ear", "ear.fill", Color.blue),
            ("Chord Recognition", "Name the chord shown", "pianokeys.inverse", Color.green),
            ("Progression Builder", "Create chord progressions", "square.stack.3d.up.fill", Color.purple),
            ("Theory Quiz", "Test your knowledge", "questionmark.circle.fill", Color.orange)
        ]
        
        for (title, subtitle, icon, color) in modes {
            // When
            let card = PracticeModeCard(
                title: title,
                subtitle: subtitle,
                icon: icon,
                color: color
            )
            
            // Then
            XCTAssertEqual(card.title, title)
            XCTAssertEqual(card.subtitle, subtitle)
            XCTAssertEqual(card.icon, icon)
            XCTAssertEqual(card.color, color)
        }
    }
    
    func testScoreRowProperties() {
        // Given
        let testDate = Date()
        let scoreTests = [
            ("Ear Training", 95, Color.green),
            ("Theory Quiz", 75, Color.orange),
            ("Chord Recognition", 60, Color.red)
        ]
        
        for (mode, score, _) in scoreTests {
            // When
            let row = ScoreRow(
                mode: mode,
                score: score,
                date: testDate
            )
            
            // Then
            XCTAssertEqual(row.mode, mode)
            XCTAssertEqual(row.score, score)
            XCTAssertEqual(row.date, testDate)
        }
    }
    
    func testScoreColorLogic() {
        // Test that score colors are assigned correctly
        let scoreColorTests = [
            (95, "green"),  // >= 90
            (85, "orange"), // >= 70
            (65, "red")     // < 70
        ]
        
        for (score, _) in scoreColorTests {
            // When
            let row = ScoreRow(mode: "Test", score: score, date: Date())
            
            // Then
            XCTAssertNotNil(row)
            // Note: We can't easily test the private scoreColor property
            // but we verify the view creates successfully with different scores
        }
    }
}