//
//  ChordLabUITestsLaunchTests.swift
//  ChordLabUITests
//
//  Created by Steven Richter on 6/15/25.
//

import XCTest

final class ChordLabUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OPENCLAW_UI_TEST_MODE"] = "1"
        app.launchEnvironment["OPENCLAW_UI_TEST_SCENARIO"] = "smoke_launch"
        app.launchEnvironment["OPENCLAW_UI_TEST_DISABLE_AUDIO"] = "1"
        app.launch()
        XCTAssertTrue(app.otherElements["chordlab.tab.learn.root"].waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
