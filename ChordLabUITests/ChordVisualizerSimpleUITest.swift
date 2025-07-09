//
//  ChordVisualizerSimpleUITest.swift
//  ChordLabUITests
//
//  Simple UI test for ChordVisualizerView key selection
//

import XCTest

final class ChordVisualizerSimpleUITest: XCTestCase {
    
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
    func testSelectDKey() throws {
        // Navigate to Explore tab using the custom tab bar
        // Try multiple possible ways to find the Explore tab
        let exploreTabById = app.buttons["tab-Explore"]
        let exploreTabByLabel = app.buttons["Explore"]
        
        if exploreTabById.exists {
            exploreTabById.tap()
        } else if exploreTabByLabel.exists {
            exploreTabByLabel.tap()
        } else {
            XCTFail("Could not find Explore tab button")
            return
        }
        
        // Wait for the Explore view to load
        XCTAssertTrue(app.staticTexts["Type"].waitForExistence(timeout: 5), "Type label should be visible in Explore tab")
        
        // Now tap the D key using its accessibility identifier
        let dKeyButton = app.buttons["key-D"]
        XCTAssertTrue(dKeyButton.waitForExistence(timeout: 5), "D key button should exist")
        
        // Tap the D key
        dKeyButton.tap()
        
        // Give UI time to update
        Thread.sleep(forTimeInterval: 0.5)
        
        // Verify that the chord grid shows D major scale chords
        // Look for D major chord button using its identifier
        let dButton = app.buttons["chord-button-D"]
        XCTAssertTrue(dButton.waitForExistence(timeout: 2), "D chord button should exist")
        
        // The button exists, which means the grid updated to show D major scale
        // We can verify this by checking if multiple D major scale chords exist
        
        // Also verify Em appears (ii chord in D major)
        let emButton = app.buttons["chord-button-Em"]
        XCTAssertTrue(emButton.exists, "Em chord button should exist in D major scale")
        
        // Verify F#m appears (iii chord in D major)
        let fSharpMinorButton = app.buttons["chord-button-F♯m"]
        XCTAssertTrue(fSharpMinorButton.exists, "F#m chord button should exist in D major scale")
        
        // Verify A appears (V chord in D major)
        let aButton = app.buttons["chord-button-A"]
        XCTAssertTrue(aButton.exists, "A chord button should exist in D major scale")
        
        // If we can find these chords, we know the key changed to D successfully
    }
    
    @MainActor
    func testSelectAKey() throws {
        // Navigate to Explore tab
        navigateToExploreTab()
        
        // Tap the A key
        let aKeyButton = app.buttons["key-A"]
        XCTAssertTrue(aKeyButton.waitForExistence(timeout: 5), "A key button should exist")
        aKeyButton.tap()
        
        Thread.sleep(forTimeInterval: 0.5)
        print("APP BUTTONS: \(app.buttons.debugDescription)")
        
        // Verify A major scale chords appear
        // A major scale: A, Bm, C#m, D, E, F#m, G#dim
        XCTAssertTrue(app.buttons["chord-button-A"].waitForExistence(timeout: 2), "A chord button should exist")
        XCTAssertTrue(app.buttons["chord-button-Bm"].exists, "Bm chord button should exist in A major scale")
        XCTAssertTrue(app.buttons["chord-button-C♯m"].exists, "C#m chord button should exist in A major scale")
        XCTAssertTrue(app.buttons["chord-button-D"].exists, "D chord button should exist in A major scale")
        XCTAssertTrue(app.buttons["chord-button-E"].exists, "E chord button should exist in A major scale")
        XCTAssertTrue(app.buttons["chord-button-F♯m"].exists, "F#m chord button should exist in A major scale")
        XCTAssertTrue(app.buttons["chord-button-G♯°"].exists, "G#dim chord button should exist in A major scale")
    }
    
    @MainActor
    func testSelectBKey() throws {
        // Navigate to Explore tab
        navigateToExploreTab()
        
        // With the new layout, the B key should no longer be obscured
        // Simply tap the B key directly
        let bKeyButton = app.buttons["key-B"]
        XCTAssertTrue(bKeyButton.waitForExistence(timeout: 5), "B key button should exist")
        bKeyButton.tap()
        
        Thread.sleep(forTimeInterval: 1.0)
        
        // Verify B major scale chords appear
        // B major scale: B, C#m, D#m, E, F#, G#m, A#dim
        XCTAssertTrue(app.buttons["chord-button-B"].waitForExistence(timeout: 2), "B chord button should exist")
        XCTAssertTrue(app.buttons["chord-button-C♯m"].exists, "C#m chord button should exist in B major scale")
        XCTAssertTrue(app.buttons["chord-button-D♯m"].exists, "D#m chord button should exist in B major scale")
        XCTAssertTrue(app.buttons["chord-button-E"].exists, "E chord button should exist in B major scale")
        XCTAssertTrue(app.buttons["chord-button-F♯"].exists, "F# chord button should exist in B major scale")
        XCTAssertTrue(app.buttons["chord-button-G♯m"].exists, "G#m chord button should exist in B major scale")
        XCTAssertTrue(app.buttons["chord-button-A♯°"].exists, "A#dim chord button should exist in B major scale")
    }
    
    @MainActor
    func testSelectCKey() throws {
        // Navigate to Explore tab
        navigateToExploreTab()
        
        // Tap the C key
        let cKeyButton = app.buttons["key-C"]
        XCTAssertTrue(cKeyButton.waitForExistence(timeout: 5), "C key button should exist")
        cKeyButton.tap()
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Verify C major scale chords appear
        // C major scale: C, Dm, Em, F, G, Am, Bdim
        XCTAssertTrue(app.buttons["chord-button-C"].waitForExistence(timeout: 2), "C chord button should exist")
        XCTAssertTrue(app.buttons["chord-button-Dm"].exists, "Dm chord button should exist in C major scale")
        XCTAssertTrue(app.buttons["chord-button-Em"].exists, "Em chord button should exist in C major scale")
        XCTAssertTrue(app.buttons["chord-button-F"].exists, "F chord button should exist in C major scale")
        XCTAssertTrue(app.buttons["chord-button-G"].exists, "G chord button should exist in C major scale")
        XCTAssertTrue(app.buttons["chord-button-Am"].exists, "Am chord button should exist in C major scale")
        XCTAssertTrue(app.buttons["chord-button-B°"].exists, "Bdim chord button should exist in C major scale")
    }
    
    @MainActor
    func testSelectEKey() throws {
        // Navigate to Explore tab
        navigateToExploreTab()
        
        // Tap the E key
        let eKeyButton = app.buttons["key-E"]
        XCTAssertTrue(eKeyButton.waitForExistence(timeout: 5), "E key button should exist")
        eKeyButton.tap()
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Verify E major scale chords appear
        // E major scale: E, F#m, G#m, A, B, C#m, D#dim
        XCTAssertTrue(app.buttons["chord-button-E"].waitForExistence(timeout: 2), "E chord button should exist")
        XCTAssertTrue(app.buttons["chord-button-F♯m"].exists, "F#m chord button should exist in E major scale")
        XCTAssertTrue(app.buttons["chord-button-G♯m"].exists, "G#m chord button should exist in E major scale")
        XCTAssertTrue(app.buttons["chord-button-A"].exists, "A chord button should exist in E major scale")
        XCTAssertTrue(app.buttons["chord-button-B"].exists, "B chord button should exist in E major scale")
        XCTAssertTrue(app.buttons["chord-button-C♯m"].exists, "C#m chord button should exist in E major scale")
        XCTAssertTrue(app.buttons["chord-button-D♯°"].exists, "D#dim chord button should exist in E major scale")
    }
    
    @MainActor
    func testSelectFKey() throws {
        // Navigate to Explore tab
        navigateToExploreTab()
        
        // Tap the F key
        let fKeyButton = app.buttons["key-F"]
        XCTAssertTrue(fKeyButton.waitForExistence(timeout: 5), "F key button should exist")
        fKeyButton.tap()
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Verify F major scale chords appear
        // F major scale: F, Gm, Am, Bb, C, Dm, Edim
        XCTAssertTrue(app.buttons["chord-button-F"].waitForExistence(timeout: 2), "F chord button should exist")
        XCTAssertTrue(app.buttons["chord-button-Gm"].exists, "Gm chord button should exist in F major scale")
        XCTAssertTrue(app.buttons["chord-button-Am"].exists, "Am chord button should exist in F major scale")
        XCTAssertTrue(app.buttons["chord-button-B♭"].exists, "Bb chord button should exist in F major scale")
        XCTAssertTrue(app.buttons["chord-button-C"].exists, "C chord button should exist in F major scale")
        XCTAssertTrue(app.buttons["chord-button-Dm"].exists, "Dm chord button should exist in F major scale")
        XCTAssertTrue(app.buttons["chord-button-E°"].exists, "Edim chord button should exist in F major scale")
    }
    
    @MainActor
    func testSelectGKey() throws {
        // Navigate to Explore tab
        navigateToExploreTab()
        
        // Tap the G key
        let gKeyButton = app.buttons["key-G"]
        XCTAssertTrue(gKeyButton.waitForExistence(timeout: 5), "G key button should exist")
        gKeyButton.tap()
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Verify G major scale chords appear
        // G major scale: G, Am, Bm, C, D, Em, F#dim
        XCTAssertTrue(app.buttons["chord-button-G"].waitForExistence(timeout: 2), "G chord button should exist")
        XCTAssertTrue(app.buttons["chord-button-Am"].exists, "Am chord button should exist in G major scale")
        XCTAssertTrue(app.buttons["chord-button-Bm"].exists, "Bm chord button should exist in G major scale")
        XCTAssertTrue(app.buttons["chord-button-C"].exists, "C chord button should exist in G major scale")
        XCTAssertTrue(app.buttons["chord-button-D"].exists, "D chord button should exist in G major scale")
        XCTAssertTrue(app.buttons["chord-button-Em"].exists, "Em chord button should exist in G major scale")
        XCTAssertTrue(app.buttons["chord-button-F♯°"].exists, "F#dim chord button should exist in G major scale")
    }
    
    // MARK: - Helper Methods
    
    private func navigateToExploreTab() {
        let exploreTabById = app.buttons["tab-Explore"]
        let exploreTabByLabel = app.buttons["Explore"]
        
        if exploreTabById.exists {
            exploreTabById.tap()
        } else if exploreTabByLabel.exists {
            exploreTabByLabel.tap()
        } else {
            XCTFail("Could not find Explore tab button")
            return
        }
        
        // Wait for the Explore view to load
        XCTAssertTrue(app.staticTexts["Type"].waitForExistence(timeout: 5), "Type label should be visible in Explore tab")
    }
}
