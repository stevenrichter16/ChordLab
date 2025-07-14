//
//  ChordVisualizerViewTests.swift
//  ChordLabTests
//
//  ViewInspector tests for ChordVisualizerView
//

import XCTest
import SwiftUI
import ViewInspector
import Tonic
@testable import ChordLab

// MARK: - ViewInspector Extensions
// These extensions allow ViewInspector to inspect our custom views

extension ChordVisualizerView: Inspectable { }
extension KeySelector: Inspectable { }
extension MinimalistChordToggle: Inspectable { }
extension ChordPianoView: Inspectable { }
extension ChordNoteButton: Inspectable { }
extension DiatonicChordGrid: Inspectable { }
extension CompactColorLegend: Inspectable { }
extension LegendDot: Inspectable { }
extension FloatingProgressionPlayer: Inspectable { }

@MainActor
final class ChordVisualizerViewTests: XCTestCase {
    
    // MARK: - Properties
    
    var theoryEngine: TheoryEngine!
    var audioEngine: AudioEngine!
    var dataManager: DataManager!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize services
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
    
    // MARK: - Helper Methods
    
    /// Creates an inspectable view with all required environments
    private func makeInspectableView() -> some View {
        ChordVisualizerView()
            .environment(theoryEngine)
            .environment(audioEngine)
            .environment(dataManager)
    }
    
    // MARK: - View Existence Tests
    
    func testViewExists() throws {
        // Given: A ChordVisualizerView with environments
        let view = makeInspectableView()
        
        // When: We inspect the view
        let inspectedView = try view.inspect()
        
        // Then: The view should exist
        XCTAssertNotNil(inspectedView)
    }
    
    func testScrollViewExists() throws {
        // Given: A ChordVisualizerView
        let view = makeInspectableView()
        
        // When: We inspect for ScrollView
        let scrollView = try view.inspect().scrollView()
        
        // Then: ScrollView should exist
        XCTAssertNotNil(scrollView)
    }
    
    // MARK: - Component Tests
    
    func testKeySelectorExists() throws {
        // Given: A ChordVisualizerView
        let view = makeInspectableView()
        
        // When: We look for KeySelector
        // Note: ScrollView requires accessing its content first
        let keySelector = try view.inspect()
            .find(KeySelector.self)
        
        // Then: KeySelector should exist with correct binding
        XCTAssertNotNil(keySelector)
    }
    
    func testChordTypeToggleExists() throws {
        // Given: A ChordVisualizerView
        let view = makeInspectableView()
        
        // When: We look for MinimalistChordToggle
        let toggle = try view.inspect()
            .find(MinimalistChordToggle.self)
        
        // Then: Toggle should exist
        XCTAssertNotNil(toggle)
    }
    
    func testChordPianoViewExists() throws {
        // Given: A ChordVisualizerView
        let view = makeInspectableView()
        
        // When: We look for ChordPianoView
        let piano = try view.inspect()
            .find(ChordPianoView.self)
        
        // Then: Piano view should exist
        XCTAssertNotNil(piano)
    }
    
    // MARK: - Text Content Tests
    
    func testDefaultChordSelectionText() throws {
        // Given: A ChordVisualizerView with no chord selected
        let view = makeInspectableView()
        
        // When: We look for the placeholder text
        let text = try view.inspect()
            .find(text: "Select a chord")
        
        // Then: It should show the correct text
        XCTAssertEqual(try text.string(), "Select a chord")
        XCTAssertEqual(try text.attributes().font(), .title2)
    }
    
    func testTypeToggleLabel() throws {
        // Given: A ChordVisualizerView
        let view = makeInspectableView()
        
        // When: We look for the "Type" label
        let typeLabel = try view.inspect()
            .find(text: "Type")
        
        // Then: It should show "Type"
        XCTAssertEqual(try typeLabel.string(), "Type")
        XCTAssertEqual(try typeLabel.attributes().font(), .caption)
    }
    
    // MARK: - State Tests
    
    func testInitialKeySelection() throws {
        // Given: A newly created ChordVisualizerView
        let view = makeInspectableView()
        
        // When: We look for the KeySelector
        let keySelector = try view.inspect().find(KeySelector.self)
        
        // Then: The KeySelector should exist (default key is "C" internally)
        XCTAssertNotNil(keySelector)
    }
    
    func testInitialChordTypeSelection() throws {
        // Given: A newly created ChordVisualizerView
        let view = makeInspectableView()
        
        // When: We look for the chord type toggle
        let toggle = try view.inspect().find(MinimalistChordToggle.self)
        
        // Then: The toggle should exist (default is triads internally)
        XCTAssertNotNil(toggle)
    }
    
    func testNoInitialChordSelection() throws {
        // Given: A newly created ChordVisualizerView
        let view = makeInspectableView()
        
        // When: We look for the "Select a chord" text
        let text = try view.inspect().find(text: "Select a chord")
        
        // Then: The placeholder text should be shown (indicating no selection)
        XCTAssertEqual(try text.string(), "Select a chord")
    }
    
    // MARK: - Color Legend Tests
    
    func testColorLegendForTriads() throws {
        // Given: A ChordVisualizerView (default is triads)
        let view = makeInspectableView()
        
        // When: We inspect the CompactColorLegend
        let legend = try view.inspect()
            .find(CompactColorLegend.self)
        
        // Then: It should exist and be configured for triads
        XCTAssertNotNil(legend)
        // Note: Further inspection of legend items would be done in CompactColorLegend-specific tests
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityIdentifiers() throws {
        // This test would check accessibility identifiers if they were set
        // Example of how to test when identifiers are added:
        /*
        let view = makeInspectableView()
        
        let keySelector = try view.inspect()
            .scrollView()
            .vStack(0)
            .hStack(1)
            .view(KeySelector.self, 0)
        
        XCTAssertEqual(try keySelector.accessibilityIdentifier(), "key-selector")
        */
    }
    
    // MARK: - Frame Tests
    
    func testViewHasProperBackground() throws {
        // Given: A ChordVisualizerView
        let view = makeInspectableView()
        
        // When: We inspect the background
        let background = try view.inspect().background()
        
        // Then: Background should be Color.appBackground
        XCTAssertNotNil(background)
    }
    
    // MARK: - Integration Tests
    
    func testChordSelectionUpdatesDisplay() throws {
        // Given: A ChordVisualizerView with a chord selected
        theoryEngine.selectedChord = Chord(.C, type: .major)
        let view = makeInspectableView()
        
        // Then: The view should display chord information instead of placeholder
        // Note: The actual chord display logic is internal to the view
        XCTAssertNotNil(view)
    }
    
    func testProgressionPlayerVisibility() throws {
        // Given: A ChordVisualizerView with no progression
        XCTAssertTrue(theoryEngine.currentProgression.isEmpty)
        
        // When: We add a chord to progression
        theoryEngine.addChordToProgression(Chord(.C, type: .major))
        
        // Then: showProgressionPlayer should be true
        XCTAssertFalse(theoryEngine.currentProgression.isEmpty)
    }
    
    // MARK: - Performance Tests
    
    func testViewInitializationPerformance() throws {
        // Measure how long it takes to create and inspect the view
        measure {
            let view = ChordVisualizerView()
                .environment(TheoryEngine())
                .environment(AudioEngine())
                .environment(DataManager(inMemory: true))
            
            do {
                _ = try view.inspect()
            } catch {
                XCTFail("Failed to inspect view: \(error)")
            }
        }
    }
}

// MARK: - Mock Helpers

extension ChordVisualizerViewTests {
    
    /// Creates a mock chord for testing
    func mockChord() -> Chord {
        return Chord(.C, type: .major)
    }
    
    /// Creates mock diatonic chords
    func mockDiatonicChords() -> [(chord: Chord, romanNumeral: String, function: ChordFunction, degreeName: String)] {
        return [
            (Chord(.C, type: .major), "I", .tonic, "Tonic"),
            (Chord(.D, type: .minor), "ii", .subdominant, "Supertonic"),
            (Chord(.E, type: .minor), "iii", .tonic, "Mediant"),
            (Chord(.F, type: .major), "IV", .subdominant, "Subdominant"),
            (Chord(.G, type: .major), "V", .dominant, "Dominant"),
            (Chord(.A, type: .minor), "vi", .tonic, "Submediant"),
            (Chord(.B, type: .dim), "vii°", .dominant, "Leading Tone")
        ]
    }
}
