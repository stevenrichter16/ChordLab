//
//  ChordMoveArrowsTests.swift
//  ChordLabTests
//
//  Tests for ChordMoveArrows component with delete functionality
//

import XCTest
import SwiftUI
import ViewInspector
import Tonic
@testable import ChordLab

// Make ChordMoveArrows inspectable
extension ChordMoveArrows: Inspectable { }

@MainActor
final class ChordMoveArrowsTests: XCTestCase {
    
    // MARK: - Component Tests
    
    func testChordMoveArrowsInitialization() throws {
        // Given: ChordMoveArrows with all actions
        var leftPressed = false
        var rightPressed = false
        var deletePressed = false
        
        let arrows = ChordMoveArrows(
            canMoveLeft: true,
            canMoveRight: true,
            onMoveLeft: { leftPressed = true },
            onMoveRight: { rightPressed = true },
            onDelete: { deletePressed = true }
        )
        
        // When: We inspect the view
        let inspected = try arrows.inspect()
        
        // Then: All three buttons should exist
        let hStack = try inspected.hStack()
        
        // Verify we have 3 buttons
        let leftButton = try hStack.button(0)
        let rightButton = try hStack.button(1)
        let deleteButton = try hStack.button(2)
        
        XCTAssertNotNil(leftButton)
        XCTAssertNotNil(rightButton)
        XCTAssertNotNil(deleteButton)
    }
    
    func testArrowButtonStates() throws {
        // Given: ChordMoveArrows with specific states
        let arrows = ChordMoveArrows(
            canMoveLeft: false,
            canMoveRight: true,
            onMoveLeft: { },
            onMoveRight: { },
            onDelete: { }
        )
        
        // When: We inspect the buttons
        let inspected = try arrows.inspect()
        let hStack = try inspected.hStack()
        
        let leftButton = try hStack.button(0)
        let rightButton = try hStack.button(1)
        
        // Then: Left button should be disabled
        XCTAssertTrue(try leftButton.isDisabled())
        XCTAssertFalse(try rightButton.isDisabled())
    }
    
    func testDeleteButtonAppearance() throws {
        // Given: ChordMoveArrows
        let arrows = ChordMoveArrows(
            canMoveLeft: true,
            canMoveRight: true,
            onMoveLeft: { },
            onMoveRight: { },
            onDelete: { }
        )
        
        // When: We inspect the delete button
        let inspected = try arrows.inspect()
        let hStack = try inspected.hStack()
        let deleteButton = try hStack.button(2)
        let deleteImage = try deleteButton.image()
        
        // Then: It should have the correct icon
        XCTAssertEqual(try deleteImage.actualImage().name(), "xmark.circle.fill")
    }
    
    func testButtonActions() throws {
        // Given: ChordMoveArrows with action tracking
        var leftCount = 0
        var rightCount = 0
        var deleteCount = 0
        
        let arrows = ChordMoveArrows(
            canMoveLeft: true,
            canMoveRight: true,
            onMoveLeft: { leftCount += 1 },
            onMoveRight: { rightCount += 1 },
            onDelete: { deleteCount += 1 }
        )
        
        // When: We tap each button
        let inspected = try arrows.inspect()
        let hStack = try inspected.hStack()
        
        try hStack.button(0).tap() // Left
        try hStack.button(1).tap() // Right
        try hStack.button(2).tap() // Delete
        
        // Then: Actions should be triggered
        XCTAssertEqual(leftCount, 1)
        XCTAssertEqual(rightCount, 1)
        XCTAssertEqual(deleteCount, 1)
    }
    
    func testVisualStyling() throws {
        // Given: ChordMoveArrows
        let arrows = ChordMoveArrows(
            canMoveLeft: true,
            canMoveRight: false,
            onMoveLeft: { },
            onMoveRight: { },
            onDelete: { }
        )
        
        // When: We inspect the container
        let inspected = try arrows.inspect()
        
        // Then: It should have proper styling
        // Note: ViewInspector limitations prevent checking all modifiers
        XCTAssertNotNil(try inspected.hStack())
        
        // Check that the HStack has 3 buttons
        let hStack = try inspected.hStack()
        var buttonCount = 0
        for i in 0..<10 {
            if let _ = try? hStack.button(i) {
                buttonCount += 1
            } else {
                break
            }
        }
        XCTAssertEqual(buttonCount, 3, "Should have exactly 3 buttons: left, right, and delete")
    }
    
    // MARK: - Integration Tests
    
    func testChordDeletionIntegration() {
        // Given: A TheoryEngine with chords in progression
        let engine = TheoryEngine()
        engine.addChordToProgression(Chord(.C, type: .major))
        engine.addChordToProgression(Chord(.G, type: .major))
        engine.addChordToProgression(Chord(.F, type: .major))
        
        XCTAssertEqual(engine.currentProgression.count, 3)
        
        // When: We simulate deletion of the middle chord
        engine.removeFromProgression(at: 1)
        
        // Then: The progression should be updated
        XCTAssertEqual(engine.currentProgression.count, 2)
        XCTAssertEqual(engine.currentProgression[0].chord.root.name, "C")
        XCTAssertEqual(engine.currentProgression[1].chord.root.name, "F")
    }
}

// MARK: - Preview Helpers

struct ChordMoveArrowsPreview: View {
    @State private var message = "No action"
    
    var body: some View {
        VStack(spacing: 40) {
            Text("ChordMoveArrows Test")
                .font(.title)
            
            Text(message)
                .foregroundColor(.secondary)
            
            ChordMoveArrows(
                canMoveLeft: true,
                canMoveRight: true,
                onMoveLeft: { message = "Moved left" },
                onMoveRight: { message = "Moved right" },
                onDelete: { message = "Deleted" }
            )
            
            ChordMoveArrows(
                canMoveLeft: false,
                canMoveRight: true,
                onMoveLeft: { },
                onMoveRight: { message = "Moved right (left disabled)" },
                onDelete: { message = "Deleted" }
            )
            
            ChordMoveArrows(
                canMoveLeft: true,
                canMoveRight: false,
                onMoveLeft: { message = "Moved left (right disabled)" },
                onMoveRight: { },
                onDelete: { message = "Deleted" }
            )
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
    }
}

#Preview {
    ChordMoveArrowsPreview()
}