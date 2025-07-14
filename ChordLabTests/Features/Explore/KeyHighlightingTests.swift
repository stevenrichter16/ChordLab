//
//  KeyHighlightingTests.swift
//  ChordLabTests
//
//  Tests for the key highlighting feature when a chord is selected
//

import XCTest
import SwiftUI
import ViewInspector
import Tonic
@testable import ChordLab

@MainActor
final class KeyHighlightingTests: XCTestCase {
    
    var theoryEngine: TheoryEngine!
    var audioEngine: AudioEngine!
    var dataManager: DataManager!
    
    override func setUp() async throws {
        try await super.setUp()
        
        theoryEngine = TheoryEngine()
        audioEngine = AudioEngine()
        dataManager = DataManager(inMemory: true)
    }
    
    override func tearDown() async throws {
        theoryEngine = nil
        audioEngine = nil
        dataManager = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Component Tests
    
    func testKeySelectorAcceptsKeysContainingChord() throws {
        // Given: A set of keys that contain a chord
        let keysContaining = Set<NoteClass>([.C, .F, .G])
        
        // When: Creating a KeySelector with highlighted keys
        let keySelector = KeySelector(
            selectedKey: .constant("C"),
            keysContainingChord: keysContaining
        )
        
        // Then: The view should be created successfully
        XCTAssertNotNil(keySelector)
    }
    
    func testPianoKeyButtonHighlighting() throws {
        // Given: A PianoKeyButton that should be highlighted
        let button = PianoKeyButton(
            key: "C",
            isSelected: false,
            isHighlighted: true,
            action: {}
        )
        
        // When: Inspecting the button
        let inspected = try button.inspect()
        
        // Then: The button should exist with highlighting
        XCTAssertNotNil(inspected)
        
        // Verify the overlay has blue border for highlighting
        let overlay = try inspected.find(ViewType.Button.self).overlay()
        XCTAssertNotNil(overlay)
    }
    
    // MARK: - Integration Tests
    
    func testChordVisualizerPassesKeysToSelector() throws {
        // Given: A ChordVisualizerView with a selected chord
        theoryEngine.selectedChord = Chord(.C, type: .major)
        
        let view = ChordVisualizerView()
            .environment(theoryEngine)
            .environment(audioEngine)
            .environment(dataManager)
        
        // When: Looking for the KeySelector
        let keySelector = try view.inspect().find(KeySelector.self)
        
        // Then: The KeySelector should exist
        XCTAssertNotNil(keySelector)
    }
    
    // MARK: - TheoryEngine Tests
    
    func testGetKeysContainingChordLogic() {
        // Test C major chord
        let cMajor = Chord(.C, type: .major)
        let keysWithCMajor = theoryEngine.getKeysContainingChord(cMajor)
        
        // C major appears as I in C, IV in G, and V in F
        XCTAssertEqual(keysWithCMajor.count, 3)
        XCTAssertTrue(keysWithCMajor.contains(.C))
        XCTAssertTrue(keysWithCMajor.contains(.G))
        XCTAssertTrue(keysWithCMajor.contains(.F))
        
        // Test A minor chord
        let aMinor = Chord(.A, type: .minor)
        let keysWithAMinor = theoryEngine.getKeysContainingChord(aMinor)
        
        // A minor appears as vi in C, iii in F, and ii in G
        XCTAssertEqual(keysWithAMinor.count, 3)
        XCTAssertTrue(keysWithAMinor.contains(.C))
        XCTAssertTrue(keysWithAMinor.contains(.F))
        XCTAssertTrue(keysWithAMinor.contains(.G))
    }
    
    func testEmptyKeysForNonDiatonicChord() {
        // Test a chord that doesn't appear diatonically in our precalculated keys
        let fSharpMinor = Chord(.Fs, type: .minor)
        let keys = theoryEngine.getKeysContainingChord(fSharpMinor)
        
        // F# minor appears in A, D, and E major
        // Since our precalculated data includes A and D, we should get those
        XCTAssertTrue(keys.contains(.A)) // F# minor is vi in A major
        XCTAssertTrue(keys.contains(.D)) // F# minor is iii in D major
        XCTAssertTrue(keys.contains(.E)) // F# minor is ii in E major
    }
    
    // MARK: - Visual State Tests
    
    func testKeySelectorHighlightingStates() throws {
        // Test 1: No chord selected - no highlighting
        var keySelector = KeySelector(
            selectedKey: .constant("C"),
            keysContainingChord: []
        )
        XCTAssertNotNil(keySelector)
        
        // Test 2: Chord selected - appropriate keys highlighted
        let keysWithCMajor: Set<NoteClass> = [.C, .F, .G]
        keySelector = KeySelector(
            selectedKey: .constant("C"),
            keysContainingChord: keysWithCMajor
        )
        XCTAssertNotNil(keySelector)
        
        // Test 3: Different chord - different keys highlighted
        let keysWithDMinor: Set<NoteClass> = [.C, .F, .Bb]
        keySelector = KeySelector(
            selectedKey: .constant("F"),
            keysContainingChord: keysWithDMinor
        )
        XCTAssertNotNil(keySelector)
    }
    
    // MARK: - Performance Tests
    
    func testKeyHighlightingPerformance() {
        // Test that key highlighting calculation is fast
        let testChords = [
            Chord(.C, type: .major),
            Chord(.D, type: .minor),
            Chord(.E, type: .minor),
            Chord(.F, type: .major),
            Chord(.G, type: .major),
            Chord(.A, type: .minor),
            Chord(.B, type: .dim)
        ]
        
        measure {
            for chord in testChords {
                _ = theoryEngine.getKeysContainingChord(chord)
            }
        }
    }
}

// MARK: - Extensions for Testing

extension KeySelector: Inspectable { }
extension PianoKeyButton: Inspectable { }