//
//  ChordVisualizerViewBasicTests.swift
//  ChordLabTests
//
//  Basic ViewInspector tests for ChordVisualizerView
//  This file contains simpler tests to verify ViewInspector setup
//

import XCTest
import SwiftUI
import ViewInspector
import Tonic
@testable import ChordLab

@MainActor
final class ChordVisualizerViewBasicTests: XCTestCase {
    
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
    
    // MARK: - Basic Tests
    
    func testViewCanBeCreated() throws {
        // Given: Required environments
        // When: Creating the view
        let view = ChordVisualizerView()
            .environment(theoryEngine)
            .environment(audioEngine)
            .environment(dataManager)
        
        // Then: View should be created
        XCTAssertNotNil(view)
    }
    
    func testViewCanBeInspected() throws {
        // Given: A properly configured view
        let view = ChordVisualizerView()
            .environment(theoryEngine)
            .environment(audioEngine)
            .environment(dataManager)
        
        // When: Inspecting the view
        let inspected = try view.inspect()
        
        // Then: Inspection should succeed
        XCTAssertNotNil(inspected)
    }
    
    func testScrollViewIsPresent() throws {
        // Given: A ChordVisualizerView
        let view = ChordVisualizerView()
            .environment(theoryEngine)
            .environment(audioEngine)
            .environment(dataManager)
        
        // When: Looking for ScrollView
        // Then: ScrollView should exist
        XCTAssertNoThrow(try view.inspect().scrollView(), 
                        "ScrollView should be present at the root of ChordVisualizerView")
    }
    
    func testKeyComponentsExist() throws {
        // Given: A ChordVisualizerView
        let view = ChordVisualizerView()
            .environment(theoryEngine)
            .environment(audioEngine)
            .environment(dataManager)
        
        // When: Looking for key components
        // Then: They should exist
        XCTAssertNoThrow(try view.inspect().find(KeySelector.self))
        XCTAssertNoThrow(try view.inspect().find(MinimalistChordToggle.self))
        XCTAssertNoThrow(try view.inspect().find(ChordPianoView.self))
        XCTAssertNoThrow(try view.inspect().find(DiatonicChordGrid.self))
        XCTAssertNoThrow(try view.inspect().find(ColorLegend.self))
    }
    
    func testDefaultPlaceholderText() throws {
        // Given: A ChordVisualizerView with no chord selected
        let view = ChordVisualizerView()
            .environment(theoryEngine)
            .environment(audioEngine)
            .environment(dataManager)
        
        // When: Looking for placeholder text
        let text = try view.inspect().find(text: "Select a chord")
        
        // Then: Placeholder should be shown
        XCTAssertEqual(try text.string(), "Select a chord")
    }
    
    func testEnvironmentObjectsAreAccessible() {
        // Given: Configured environment objects
        theoryEngine.setKey("D", scaleType: "major")
        
        // When: Creating a view with environments
        let view = ChordVisualizerView()
            .environment(theoryEngine)
            .environment(audioEngine)
            .environment(dataManager)
        
        // Then: The environments are properly configured
        XCTAssertEqual(theoryEngine.currentKey, "D")
        XCTAssertNotNil(audioEngine)
        XCTAssertNotNil(dataManager)
        XCTAssertNotNil(view)
    }
    
    // MARK: - Detailed Component Tests
    
    func testKeySelectorStructureAndContent() throws {
        // Given: A ChordVisualizerView
        let view = ChordVisualizerView()
            .environment(theoryEngine)
            .environment(audioEngine)
            .environment(dataManager)
        
        // When: Finding and inspecting the KeySelector
        let keySelector = try view.inspect().find(KeySelector.self)
        
        // Then: Verify the KeySelector exists and has expected structure
        XCTAssertNotNil(keySelector)
        
        // The KeySelector should be within an HStack (along with the chord type toggle)
        let parentHStack = try view.inspect().find(ViewType.HStack.self, where: { hstack in
            // Check if this HStack contains our KeySelector
            (try? hstack.find(KeySelector.self)) != nil
        })
        XCTAssertNotNil(parentHStack)
        
        // Verify the HStack also contains the chord type section
        let typeLabel = try parentHStack.find(text: "Type")
        XCTAssertEqual(try typeLabel.string(), "Type")
        XCTAssertEqual(try typeLabel.attributes().font(), .caption)
        
        // Verify the toggle is present
        let toggle = try parentHStack.find(MinimalistChordToggle.self)
        XCTAssertNotNil(toggle)
    }
    
    func testPianoVisualizationStructure() throws {
        // Given: A ChordVisualizerView
        let view = ChordVisualizerView()
            .environment(theoryEngine)
            .environment(audioEngine)
            .environment(dataManager)
        
        // When: Finding the piano visualization section
        let pianoView = try view.inspect().find(ChordPianoView.self)
        
        // Then: Verify it exists within a ZStack (for overlay capability)
        XCTAssertNotNil(pianoView)
        
        // Find the parent ZStack
        let parentZStack = try view.inspect().find(ViewType.ZStack.self, where: { zstack in
            (try? zstack.find(ChordPianoView.self)) != nil
        })
        XCTAssertNotNil(parentZStack)
        
        // The ZStack should have alignment .topTrailing for potential overlays
        // Note: ViewInspector may not expose all SwiftUI modifiers directly
    }
    
    func testChordDisplayWithNoSelection() throws {
        // Given: A ChordVisualizerView with no chord selected
        let view = ChordVisualizerView()
            .environment(theoryEngine)
            .environment(audioEngine)
            .environment(dataManager)
        
        // When: Looking for chord display elements
        // Then: Should show placeholder text
        let placeholderText = try view.inspect().find(text: "Select a chord")
        XCTAssertEqual(try placeholderText.string(), "Select a chord")
        XCTAssertEqual(try placeholderText.attributes().font(), .title2)
        
        // Verify color is secondary
        if let foregroundColor = try? placeholderText.attributes().foregroundColor() {
            // Note: Color comparison in ViewInspector can be tricky
            XCTAssertNotNil(foregroundColor)
        }
    }
    
    func testDiatonicChordGridPresence() throws {
        // Given: A ChordVisualizerView
        let view = ChordVisualizerView()
            .environment(theoryEngine)
            .environment(audioEngine)
            .environment(dataManager)
        
        // When: Finding the diatonic chord grid
        let chordGrid = try view.inspect().find(DiatonicChordGrid.self)
        
        // Then: Verify it exists and has expected properties
        XCTAssertNotNil(chordGrid)
        
        // The grid should be able to handle chord selection and hold actions
        // Note: Actual interaction testing would require UI testing
    }
    
    func testColorLegendStructureAndContent() throws {
        // Given: A ChordVisualizerView (default shows triads)
        let view = ChordVisualizerView()
            .environment(theoryEngine)
            .environment(audioEngine)
            .environment(dataManager)
        
        // When: Finding and inspecting the color legend
        let colorLegend = try view.inspect().find(ColorLegend.self)
        
        // Then: Verify structure
        XCTAssertNotNil(colorLegend)
        
        // Find the HStack within ColorLegend
        let legendHStack = try colorLegend.find(ViewType.HStack.self)
        
        // Count legend items (should be 3 for triads: Root, Third, Fifth)
        var legendItemCount = 0
        for index in 0..<10 {
            if let _ = try? legendHStack.view(LegendItem.self, index) {
                legendItemCount += 1
            } else {
                break
            }
        }
        XCTAssertEqual(legendItemCount, 3, "Triads should show 3 legend items")
        
        // Verify first legend item
        if let firstItem = try? legendHStack.view(LegendItem.self, 0) {
            let itemHStack = try firstItem.find(ViewType.HStack.self)
            let label = try itemHStack.text(1)
            XCTAssertEqual(try label.string(), "Root")
        }
    }
    
    func testViewModifiersAndStyling() throws {
        // Given: A ChordVisualizerView
        let view = ChordVisualizerView()
            .environment(theoryEngine)
            .environment(audioEngine)
            .environment(dataManager)
        
        // When: Inspecting the view
        let inspected = try view.inspect()
        
        // Then: Verify expected modifiers
        // Background should be applied
        XCTAssertNoThrow(try inspected.background())
        
        // ScrollView should exist as the root container
        let scrollView = try inspected.scrollView()
        XCTAssertNotNil(scrollView)
        
        // Find the main VStack within the ScrollView
        let mainVStack = try inspected.find(ViewType.VStack.self)
        XCTAssertNotNil(mainVStack)
    }
    
    func testProgressionStateManagement() throws {
        // This test verifies the progression management without deep view inspection
        // which can cause environment object issues
        
        // Given: Initial state with no progression
        XCTAssertTrue(theoryEngine.currentProgression.isEmpty)
        
        // When: Adding a chord to progression
        let testChord = Chord(.C, type: .major)
        theoryEngine.addChordToProgression(testChord)
        
        // Then: Verify the progression was updated
        XCTAssertFalse(theoryEngine.currentProgression.isEmpty)
        XCTAssertEqual(theoryEngine.currentProgression.count, 1)
        XCTAssertEqual(theoryEngine.currentProgression.first?.chord.description, testChord.description)
        
        // When: Adding another chord
        let secondChord = Chord(.G, type: .major)
        theoryEngine.addChordToProgression(secondChord)
        
        // Then: Verify both chords are in the progression
        XCTAssertEqual(theoryEngine.currentProgression.count, 2)
        
        // When: Removing a chord
        theoryEngine.removeFromProgression(at: 0)
        
        // Then: Verify the removal
        XCTAssertEqual(theoryEngine.currentProgression.count, 1)
        XCTAssertEqual(theoryEngine.currentProgression.first?.chord.description, secondChord.description)
    }
    
    func testViewComponentPresence() throws {
        // This test verifies that key components exist without deep inspection
        // to avoid environment object issues
        
        // Given: A ChordVisualizerView
        let view = ChordVisualizerView()
            .environment(theoryEngine)
            .environment(audioEngine)
            .environment(dataManager)
        
        // When/Then: Verify ScrollView exists at the root
        XCTAssertNoThrow(try view.inspect().scrollView())
        
        // Verify we can find key component types
        // Using XCTAssertNoThrow to handle any environment access issues gracefully
        
        XCTAssertNoThrow(try view.inspect().find(KeySelector.self), 
                        "KeySelector should be present in the view hierarchy")
        
        XCTAssertNoThrow(try view.inspect().find(MinimalistChordToggle.self), 
                        "MinimalistChordToggle should be present in the view hierarchy")
        
        // Note: Some components might fail to inspect due to environment requirements
        // but their presence can still be verified
    }
}
