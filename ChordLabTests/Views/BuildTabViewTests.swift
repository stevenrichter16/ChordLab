//
//  BuildTabViewTests.swift
//  ChordLabTests
//
//  Tests for BuildTabView
//

import XCTest
import SwiftUI
import Tonic
@testable import ChordLab

final class BuildTabViewTests: XCTestCase {
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
    
    func testBuildTabViewInitializes() {
        // Given
        let view = BuildTabView()
            .environment(theoryEngine)
            .environment(audioEngine)
        
        // Then
        XCTAssertNotNil(view)
    }
    
    func testBuildTabViewWithEmptyProgression() {
        // Given
        theoryEngine.clearProgression()
        
        // When
        let view = BuildTabView()
            .environment(theoryEngine)
            .environment(audioEngine)
        
        // Then
        XCTAssertTrue(theoryEngine.currentProgression.isEmpty)
        XCTAssertNotNil(view)
    }
    
    func testBuildTabViewWithProgression() {
        // Given
        let chords = [
            Chord(.C, type: .major),
            Chord(.F, type: .major),
            Chord(.G, type: .major)
        ]
        
        for chord in chords {
            theoryEngine.addChordToProgression(chord)
        }
        
        // When
        let view = BuildTabView()
            .environment(theoryEngine)
            .environment(audioEngine)
        
        // Then
        XCTAssertEqual(theoryEngine.currentProgression.count, 3)
        XCTAssertNotNil(view)
    }
    
    func testTimelineChordViewProperties() {
        // Given
        let chord = Chord(.D, type: .min7)
        let index = 2
        
        // When
        let view = TimelineChordView(chord: chord, index: index)
        
        // Then
        XCTAssertEqual(view.chord.description, "Dm7")
        XCTAssertEqual(view.index, 2)
    }
    
    func testSuggestionChordViewProperties() {
        // Given
        let chord = Chord(.E, type: .maj7)
        var actionCalled = false
        
        // When
        let view = SuggestionChordView(chord: chord) {
            actionCalled = true
        }
        
        // Then
        XCTAssertEqual(view.chord.description, "Emaj7")
        XCTAssertNotNil(view.action)
        
        // Simulate action
        view.action()
        XCTAssertTrue(actionCalled)
    }
    
    func testClearProgressionFunctionality() {
        // Given
        theoryEngine.addChordToProgression(Chord(.C, type: .major))
        theoryEngine.addChordToProgression(Chord(.G, type: .major))
        XCTAssertEqual(theoryEngine.currentProgression.count, 2)
        
        // When
        theoryEngine.clearProgression()
        
        // Then
        XCTAssertTrue(theoryEngine.currentProgression.isEmpty)
    }
    
    func testChordSuggestions() {
        // Given
        theoryEngine.setKey("C", scaleType: "major")
        
        // When
        let suggestions = theoryEngine.getChordSuggestions(after: [])
        
        // Then
        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertLessThanOrEqual(suggestions.count, 6)
    }
}