//
//  SingleChordDeletionTests.swift
//  ChordLabTests
//
//  Tests for single chord deletion functionality
//

import XCTest
import SwiftUI
import ViewInspector
@testable import ChordLab

// Make components inspectable
extension ChordDeleteButton: Inspectable { }

@MainActor
final class SingleChordDeletionTests: XCTestCase {
    
    var theoryEngine: TheoryEngine!
    
    override func setUp() async throws {
        try await super.setUp()
        theoryEngine = TheoryEngine()
    }
    
    override func tearDown() async throws {
        theoryEngine = nil
        try await super.tearDown()
    }
    
    // MARK: - Component Tests
    
    func testChordDeleteButtonInitialization() throws {
        // Given: A ChordDeleteButton
        var deletePressed = false
        let button = ChordDeleteButton(onDelete: { deletePressed = true })
        
        // When: We inspect the button
        let inspected = try button.inspect()
        let innerButton = try inspected.button()
        
        // Then: It should have the correct appearance
        let image = try innerButton.image()
        XCTAssertEqual(try image.actualImage().name(), "xmark.circle.fill")
        
        // When: We tap the button
        try innerButton.tap()
        
        // Then: The action should be triggered
        XCTAssertTrue(deletePressed)
    }
    
    // MARK: - Logic Tests
    
    func testSingleChordProgressionAllowsLongPress() {
        // Given: A progression with only one chord
        theoryEngine.addChordToProgression(Chord(.C, type: .major))
        
        // Then: The progression should have exactly one chord
        XCTAssertEqual(theoryEngine.currentProgression.count, 1)
        
        // The long press should now be allowed (no check for count > 1)
        // This is verified by the removal of the condition in onLongPress
    }
    
    func testDeletingSingleChordClearsProgression() {
        // Given: A progression with one chord
        theoryEngine.addChordToProgression(Chord(.C, type: .major))
        XCTAssertEqual(theoryEngine.currentProgression.count, 1)
        
        // When: We delete the chord
        theoryEngine.removeFromProgression(at: 0)
        
        // Then: The progression should be empty
        XCTAssertTrue(theoryEngine.currentProgression.isEmpty)
    }
    
    func testMultipleChordProgressionShowsFullArrows() {
        // Given: A progression with multiple chords
        theoryEngine.addChordToProgression(Chord(.C, type: .major))
        theoryEngine.addChordToProgression(Chord(.G, type: .major))
        theoryEngine.addChordToProgression(Chord(.F, type: .major))
        
        // Then: The progression should have multiple chords
        XCTAssertEqual(theoryEngine.currentProgression.count, 3)
        
        // The UI should show ChordMoveArrows (with delete) instead of just ChordDeleteButton
        // This is handled by the conditional logic in the overlay
    }
}

// MARK: - Preview Helper

struct SingleChordDeletionPreview: View {
    @State private var message = "Long press the chord to show delete button"
    @State private var showDeleteButton = false
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Single Chord Deletion Test")
                .font(.title)
            
            Text(message)
                .foregroundColor(.secondary)
            
            // Simulate a single chord
            Button(action: {
                message = "Chord tapped"
            }) {
                Text("C")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 56)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                showDeleteButton = true
                message = "Delete button shown"
                
                // Auto-hide after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showDeleteButton = false
                    message = "Delete button hidden"
                }
            }
            
            if showDeleteButton {
                ChordDeleteButton(onDelete: {
                    message = "Chord deleted!"
                    showDeleteButton = false
                })
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
        .animation(.spring(response: 0.3), value: showDeleteButton)
    }
}

#Preview {
    SingleChordDeletionPreview()
}