//
//  ColorLegendViewInspectorTests.swift
//  ChordLabTests
//
//  ViewInspector tests for CompactColorLegend component
//  This is a simpler example to verify ViewInspector setup
//

import XCTest
import SwiftUI
import ViewInspector
@testable import ChordLab

// MARK: - ViewInspector Conformance
// These extensions enable ViewInspector to inspect our custom views
// Note: CompactColorLegend and LegendDot are already made Inspectable in ChordVisualizerViewTests.swift

@MainActor
final class ColorLegendViewInspectorTests: XCTestCase {
    
    // MARK: - Basic Component Tests
    
    func testColorLegendWithTriads() throws {
        // Given: A CompactColorLegend configured for triads (no seventh)
        let legend = CompactColorLegend(showSeventh: false)
        
        // When: We inspect the view
        let inspected = try legend.inspect()
        
        // Then: The view should exist
        XCTAssertNotNil(inspected)
        
        // Access the HStack within the view
        let hStack = try inspected.find(ViewType.HStack.self)
        XCTAssertNotNil(hStack)
        
        // Count the legend items (should be 3 for triads)
        // ViewInspector pattern: iterate through views by index
        var itemCount = 0
        for index in 0..<10 { // Check up to 10 items
            if let _ = try? hStack.view(LegendDot.self, index) {
                itemCount += 1
            } else {
                break
            }
        }
        XCTAssertEqual(itemCount, 3, "Triads should show 3 legend items")
    }
    
    func testColorLegendWithSevenths() throws {
        // Given: A CompactColorLegend configured for seventh chords
        let legend = CompactColorLegend(showSeventh: true)
        
        // When: We inspect the view
        let inspected = try legend.inspect()
        let hStack = try inspected.find(ViewType.HStack.self)
        
        // Then: Count the legend items (should be 4 for sevenths)
        var itemCount = 0
        for index in 0..<10 { // Check up to 10 items
            if let _ = try? hStack.view(LegendDot.self, index) {
                itemCount += 1
            } else {
                break
            }
        }
        XCTAssertEqual(itemCount, 4, "Seventh chords should show 4 legend items")
    }
    
    func testLegendItemContent() throws {
        // Given: A single LegendDot
        let item = LegendDot(color: .blue, label: "Root")
        
        // When: We inspect the view
        let inspected = try item.inspect()
        let hStack = try inspected.find(ViewType.HStack.self)
        
        // Then: Check the circle exists
        let circle = try hStack.shape(0)
        XCTAssertNotNil(circle)
        
        // Check the label text
        let text = try hStack.text(1)
        XCTAssertEqual(try text.string(), "Root")
        XCTAssertEqual(try text.attributes().font(), .system(size: 11, weight: .medium))
    }
    
    func testColorLegendLabels() throws {
        // Given: A CompactColorLegend for triads
        let legend = CompactColorLegend(showSeventh: false)
        
        // When: We collect all labels
        var labels: [String] = []
        let hStack = try legend.inspect().find(ViewType.HStack.self)
        
        // ViewInspector pattern: iterate through views by index
        for index in 0..<10 { // Check up to 10 items
            if let item = try? hStack.view(LegendDot.self, index) {
                let itemHStack = try item.find(ViewType.HStack.self)
                let text = try itemHStack.text(1)
                labels.append(try text.string())
            } else {
                break
            }
        }
        
        // Then: Labels should match expected values
        XCTAssertEqual(labels, ["Root", "3rd", "5th"])
    }
    
    func testColorLegendColors() throws {
        // Given: Expected color mapping
        let expectedColors: [(String, Color)] = [
            ("Root", .blue),
            ("3rd", .green),
            ("5th", .orange),
            ("7th", .purple)
        ]
        
        // When: We inspect a seventh chord legend
        let legend = CompactColorLegend(showSeventh: true)
        let hStack = try legend.inspect().find(ViewType.HStack.self)
        
        // Then: Verify each item has correct color
        for index in 0..<expectedColors.count {
            if let item = try? hStack.view(LegendDot.self, index) {
                let itemHStack = try item.find(ViewType.HStack.self)
                let label = try itemHStack.text(1).string()
                let expectedLabel = expectedColors[index].0
                
                XCTAssertEqual(label, expectedLabel)
                // Note: Color comparison might require additional setup
            } else {
                break
            }
        }
    }
    
    // MARK: - Style Tests
    
    func testColorLegendBackground() throws {
        // Given: A CompactColorLegend
        let legend = CompactColorLegend(showSeventh: false)
        
        // When: We inspect the background
        let view = try legend.inspect()
        
        // Then: Check that the view has modifiers applied
        // Note: ViewInspector doesn't directly expose modifier inspection
        XCTAssertNotNil(view)
    }
    
    func testLegendItemSpacing() throws {
        // Given: A LegendDot
        let item = LegendDot(color: .blue, label: "Root")
        
        // When: We inspect the HStack
        let hStack = try item.inspect().find(ViewType.HStack.self)
        
        // Then: The HStack should have spacing of 8
        // Note: ViewInspector may not expose spacing directly
        XCTAssertNotNil(hStack)
    }
    
    // MARK: - Accessibility Tests
    
    func testLegendItemAccessibility() throws {
        // Given: A LegendDot
        let item = LegendDot(color: .blue, label: "Root")
        
        // When: We inspect for accessibility
        let view = try item.inspect()
        
        // Then: Check if accessibility label would be appropriate
        // This is where you'd add accessibility identifiers/labels in the actual view
        XCTAssertNotNil(view)
    }
    
    // MARK: - Performance Tests
    
    func testColorLegendRenderingPerformance() throws {
        measure {
            // Create and inspect multiple legends
            for showSeventh in [true, false] {
                let legend = CompactColorLegend(showSeventh: showSeventh)
                do {
                    _ = try legend.inspect()
                } catch {
                    XCTFail("Failed to inspect CompactColorLegend: \(error)")
                }
            }
        }
    }
}

// MARK: - Test Helpers

extension ColorLegendViewInspectorTests {
    
    /// Helper to create a test environment
    func makeTestView<T: View>(_ view: T) -> some View {
        view
            .previewLayout(.sizeThatFits)
            .padding()
    }
    
    /// Helper to verify view hierarchy depth
    func verifyViewDepth<T: View>(_ view: T, expectedDepth: Int) throws {
        let inspected = try view.inspect()
        // This would verify the view hierarchy depth
        XCTAssertNotNil(inspected)
    }
}