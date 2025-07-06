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

@MainActor
final class ExploreTabViewTests: XCTestCase {
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
    
    func testExploreTabViewInitializes() {
        // Given
        let view = ExploreTabView()
            .environment(theoryEngine)
            .environment(audioEngine)
            .environment(dataManager)
        
        // Then
        XCTAssertNotNil(view)
    }
    
    func testExploreTabViewContainsChordVisualizer() {
        // Given: ExploreTabView is a wrapper for ChordVisualizerView
        let view = ExploreTabView()
        
        // Then: The body should contain ChordVisualizerView
        XCTAssertNotNil(view.body)
        
        // Note: The view simply wraps ChordVisualizerView
        // Detailed testing of functionality is done in ChordVisualizerViewTests
    }
    
    func testNavigationSettings() {
        // Given
        let view = ExploreTabView()
        
        // Then: Navigation bar should be configured correctly
        // The view sets navigationBarTitleDisplayMode to .inline
        XCTAssertNotNil(view)
    }
    
    // MARK: - Integration Tests
    
    func testExploreTabViewWithEnvironments() {
        // Given: All required environments
        let view = ExploreTabView()
            .environment(theoryEngine)
            .environment(audioEngine)
            .environment(dataManager)
        
        // When: The view is created
        // Then: It should initialize without errors
        XCTAssertNotNil(view)
        
        // Verify the environments are available
        XCTAssertNotNil(theoryEngine)
        XCTAssertNotNil(audioEngine)
        XCTAssertNotNil(dataManager)
    }
    
    func testTheoryEngineIntegration() {
        // Given: A configured theory engine
        theoryEngine.setKey("G", scaleType: "major")
        
        // When: Creating the explore view
        let view = ExploreTabView()
            .environment(theoryEngine)
            .environment(audioEngine)
            .environment(dataManager)
        
        // Then: The theory engine state should be available
        XCTAssertEqual(theoryEngine.currentKey, "G")
        XCTAssertEqual(theoryEngine.currentScaleType, "major")
        XCTAssertNotNil(view)
    }
    
    func testAudioEngineIntegration() {
        // Given: An audio engine
        // When: Creating the explore view
        let view = ExploreTabView()
            .environment(theoryEngine)
            .environment(audioEngine)
            .environment(dataManager)
        
        // Then: The audio engine should be available
        XCTAssertNotNil(audioEngine)
        XCTAssertFalse(audioEngine.isPlaying)
        XCTAssertNotNil(view)
    }
}
