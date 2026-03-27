//
//  ChordLabUITests.swift
//  ChordLabUITests
//
//  Created by Steven Richter on 6/15/25.
//

import XCTest

final class ChordLabUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSmokeLaunchesLearnTab() throws {
        let app = XCUIApplication()
        app.launchForOpenClaw(scenario: .smokeLaunch)

        XCTAssertTrue(app.firstMatchingElement(identifier: ChordLabUITestIDs.learnRoot).waitForExistence(timeout: 5))
        XCTAssertTrue(app.firstMatchingElement(identifier: ChordLabUITestIDs.learnTabButton).exists)
        XCTAssertTrue(app.firstMatchingElement(identifier: ChordLabUITestIDs.tabBar).exists)
    }

    @MainActor
    func testTabNavigationShowsEachRootView() throws {
        let app = XCUIApplication()
        app.launchForOpenClaw(scenario: .tabNavigation)

        let navigationPlan: [(buttonID: String, rootID: String)] = [
            (ChordLabUITestIDs.exploreTabButton, ChordLabUITestIDs.exploreRoot),
            (ChordLabUITestIDs.libraryTabButton, ChordLabUITestIDs.libraryRoot),
            (ChordLabUITestIDs.practiceTabButton, ChordLabUITestIDs.practiceRoot),
            (ChordLabUITestIDs.profileTabButton, ChordLabUITestIDs.profileRoot),
            (ChordLabUITestIDs.learnTabButton, ChordLabUITestIDs.learnRoot),
        ]

        for step in navigationPlan {
            let button = app.firstMatchingElement(identifier: step.buttonID)
            XCTAssertTrue(button.waitForExistence(timeout: 5))
            button.tap()
            XCTAssertTrue(app.firstMatchingElement(identifier: step.rootID).waitForExistence(timeout: 5))
        }
    }

    @MainActor
    func testLibrarySeededProgressionAppears() throws {
        let app = XCUIApplication()
        app.launchForOpenClaw(scenario: .librarySeeded)

        XCTAssertTrue(app.firstMatchingElement(identifier: ChordLabUITestIDs.libraryRoot).waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["OpenClaw Turnaround"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.firstMatchingElement(identifier: ChordLabUITestIDs.libraryCard).exists)
    }
}
