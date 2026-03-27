import XCTest

enum ChordLabUITestScenario: String {
    case smokeLaunch = "smoke_launch"
    case tabNavigation = "tab_navigation"
    case librarySeeded = "library_seeded"
}

enum ChordLabUITestIDs {
    static let tabBar = "chordlab.tabbar"
    static let learnRoot = "chordlab.tab.learn.root"
    static let exploreRoot = "chordlab.tab.explore.root"
    static let libraryRoot = "chordlab.tab.library.root"
    static let practiceRoot = "chordlab.tab.practice.root"
    static let profileRoot = "chordlab.tab.profile.root"
    static let libraryCard = "chordlab.library.card"
    static let learnTabButton = "chordlab.tab.button.learn"
    static let exploreTabButton = "chordlab.tab.button.explore"
    static let libraryTabButton = "chordlab.tab.button.library"
    static let practiceTabButton = "chordlab.tab.button.practice"
    static let profileTabButton = "chordlab.tab.button.profile"
}

extension XCUIApplication {
    func launchForOpenClaw(scenario: ChordLabUITestScenario) {
        launchEnvironment["OPENCLAW_UI_TEST_MODE"] = "1"
        launchEnvironment["OPENCLAW_UI_TEST_SCENARIO"] = scenario.rawValue
        launchEnvironment["OPENCLAW_UI_TEST_DISABLE_AUDIO"] = "1"
        launch()
    }

    func firstMatchingElement(identifier: String) -> XCUIElement {
        let predicate = NSPredicate(format: "identifier == %@", identifier)
        return descendants(matching: .any).matching(predicate).firstMatch
    }
}
