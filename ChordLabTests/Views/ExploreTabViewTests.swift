//
//  ExploreTabViewTests.swift
//  ChordLabTests
//
//  Tests for ExploreTabView
//

import XCTest
import SwiftUI
import Tonic
@testable import ChordLab

final class ExploreTabViewTests: XCTestCase {
    var theoryEngine: TheoryEngine!
    var audioEngine: AudioEngine!
    
    override func setUp() {
        super.setUp()
        theoryEngine = TheoryEngine()
        audioEngine = AudioEngine()
    }
    
    override func tearDown() {
        theoryEngine = nil
        audioEngine = nil
        super.tearDown()
    }
    
    func testExploreTabViewInitializes() {
        // Given
        let view = ExploreTabView()
            .environment(theoryEngine)
            .environment(audioEngine)
        
        // Then
        XCTAssertNotNil(view)
    }
    
    func testCategoryPillProperties() {
        // Given
        let categories = ["All", "Major", "Minor", "Seventh", "Extended", "Altered"]
        
        for category in categories {
            // When
            var selectedCategory = ""
            let pill = CategoryPill(
                title: category,
                isSelected: false
            ) {
                selectedCategory = category
            }
            
            // Then
            XCTAssertEqual(pill.title, category)
            XCTAssertFalse(pill.isSelected)
            
            // Test action
            pill.action()
            XCTAssertEqual(selectedCategory, category)
        }
    }
    
    func testCategoryPillSelectedState() {
        // Given
        let pill = CategoryPill(
            title: "Major",
            isSelected: true
        ) {}
        
        // Then
        XCTAssertTrue(pill.isSelected)
    }
    
    func testChordCardProperties() {
        // Given
        let chord = Chord(.A, type: .min7)
        var playCount = 0
        
        // When
        let card = ChordCard(chord: chord) {
            playCount += 1
        }
        
        // Then
        XCTAssertEqual(card.chord.description, "Am7")
        
        // Test action
        card.action()
        XCTAssertEqual(playCount, 1)
        
        card.action()
        XCTAssertEqual(playCount, 2)
    }
    
    func testExploreViewWithDifferentChordTypes() {
        // Test that the view handles different chord types correctly
        let chordTypes: [(NoteClass, ChordType, String)] = [
            (.C, .major, "C"),
            (.D, .minor, "Dm"),
            (.E, .dim, "E°"),
            (.F, .maj7, "Fmaj7"),
            (.G, .dom7, "G7"),
            (.A, .min7, "Am7"),
            (.B, .halfDim7, "Bø7")
        ]
        
        for (root, type, expectedDescription) in chordTypes {
            // Given
            let chord = Chord(root, type: type)
            
            // When
            let card = ChordCard(chord: chord) {}
            
            // Then
            XCTAssertEqual(card.chord.description, expectedDescription)
        }
    }
}