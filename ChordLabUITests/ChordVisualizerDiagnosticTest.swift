//
//  ChordVisualizerDiagnosticTest.swift
//  ChordLabUITests
//
//  Diagnostic test to understand the B key selection issue
//

import XCTest

final class ChordVisualizerDiagnosticTest: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    @MainActor
    func testKeySelectionDiagnostic() throws {
        // Navigate to Explore tab
        let exploreTab = app.buttons["tab-Explore"]
        if exploreTab.exists {
            exploreTab.tap()
        }
        
        // Wait for view to load
        XCTAssertTrue(app.staticTexts["Type"].waitForExistence(timeout: 5))
        
        // Test each key to see which ones work
        let keys = ["C", "D", "E", "F", "G", "B", "A"]
        
        for key in keys {
            print("\n=== Testing \(key) Key ===")
            
            // Tap the key
            let keyButton = app.buttons["key-\(key)"]
            if keyButton.exists {
                keyButton.tap()
                Thread.sleep(forTimeInterval: 1.0)
                
                // Check what chords appear
                print("Chord buttons after tapping \(key):")
                let chordButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "chord-button-"))
                var foundChords: [String] = []
                
                for i in 0..<min(chordButtons.count, 7) {
                    let button = chordButtons.element(boundBy: i)
                    if button.exists {
                        foundChords.append(button.identifier.replacingOccurrences(of: "chord-button-", with: ""))
                    }
                }
                
                print("  Found chords: \(foundChords.joined(separator: ", "))")
                
                // Check if the tonic chord exists
                let tonicButton = app.buttons["chord-button-\(key)"]
                print("  Tonic chord (\(key)) exists: \(tonicButton.exists)")
            }
        }
        
        // This test always passes - it's just for diagnostics
        XCTAssertTrue(true, "Diagnostic test completed")
    }
}
