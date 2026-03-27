import Foundation
import SwiftData

enum OpenClawUITestKeys {
    static let mode = "OPENCLAW_UI_TEST_MODE"
    static let scenario = "OPENCLAW_UI_TEST_SCENARIO"
    static let disableAudio = "OPENCLAW_UI_TEST_DISABLE_AUDIO"
}

struct OpenClawUITestConfiguration {
    let isEnabled: Bool
    let scenario: String
    let disableAudio: Bool

    static var current: OpenClawUITestConfiguration {
        OpenClawUITestConfiguration(
            isEnabled: boolValue(for: OpenClawUITestKeys.mode),
            scenario: stringValue(for: OpenClawUITestKeys.scenario) ?? ChordLabUITestScenario.smokeLaunch.rawValue,
            disableAudio: boolValue(for: OpenClawUITestKeys.disableAudio)
        )
    }

    private static func boolValue(for key: String) -> Bool {
        guard let rawValue = rawValue(for: key) else {
            return ProcessInfo.processInfo.arguments.contains(key)
        }

        switch rawValue.lowercased() {
        case "1", "true", "yes", "on":
            return true
        default:
            return false
        }
    }

    private static func stringValue(for key: String) -> String? {
        guard let rawValue = rawValue(for: key) else { return nil }
        return rawValue.isEmpty ? nil : rawValue
    }

    private static func rawValue(for key: String) -> String? {
        let processInfo = ProcessInfo.processInfo

        if let value = processInfo.environment[key], !value.isEmpty {
            return value
        }

        if let argument = processInfo.arguments.first(where: { $0.hasPrefix("\(key)=") }) {
            return String(argument.dropFirst(key.count + 1))
        }

        let userDefaultsValue = UserDefaults.standard.object(forKey: key)
        switch userDefaultsValue {
        case let value as String:
            return value
        case let value as NSNumber:
            return value.stringValue
        default:
            return nil
        }
    }
}

enum ChordLabUITestScenario: String {
    case smokeLaunch = "smoke_launch"
    case tabNavigation = "tab_navigation"
    case librarySeeded = "library_seeded"

    init(rawScenario: String) {
        self = ChordLabUITestScenario(rawValue: rawScenario) ?? .smokeLaunch
    }
}

enum ChordLabAutomationID {
    static let appRoot = "chordlab.app.root"
    static let tabBar = "chordlab.tabbar"
    static let learnRoot = "chordlab.tab.learn.root"
    static let exploreRoot = "chordlab.tab.explore.root"
    static let libraryRoot = "chordlab.tab.library.root"
    static let practiceRoot = "chordlab.tab.practice.root"
    static let profileRoot = "chordlab.tab.profile.root"
    static let libraryEmpty = "chordlab.library.empty"
    static let libraryCard = "chordlab.library.card"
    static let libraryCardTitle = "chordlab.library.card.title"
    static let libraryFilterButton = "chordlab.library.filter"

    static func tabButtonID(label: String) -> String {
        let slug = label
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        return "chordlab.tab.button.\(slug)"
    }
}

@MainActor
enum ChordLabUITestBootstrap {
    static func makeDataManager() -> DataManager {
        let configuration = OpenClawUITestConfiguration.current
        let dataManager = DataManager(inMemory: configuration.isEnabled)

        if configuration.isEnabled {
            seed(dataManager: dataManager, scenario: ChordLabUITestScenario(rawScenario: configuration.scenario))
        }

        return dataManager
    }

    static func makeAudioEngine() -> AudioEngine {
        AudioEngine(disableAudio: OpenClawUITestConfiguration.current.disableAudio)
    }

    static func makeAppState() -> AppState {
        let configuration = OpenClawUITestConfiguration.current
        let scenario = ChordLabUITestScenario(rawScenario: configuration.scenario)
        let appState = AppState()

        guard configuration.isEnabled else {
            return appState
        }

        appState.tabBarStyle = .compact
        if scenario == .librarySeeded {
            appState.selectedTab = 2
        }

        return appState
    }

    private static func seed(dataManager: DataManager, scenario: ChordLabUITestScenario) {
        clearSavedProgressions(in: dataManager.context)

        switch scenario {
        case .librarySeeded:
            dataManager.context.insert(makeSeededProgression())
        case .smokeLaunch, .tabNavigation:
            break
        }

        try? dataManager.context.save()
    }

    private static func clearSavedProgressions(in context: ModelContext) {
        let descriptor = FetchDescriptor<SavedProgression>()
        let existingProgressions = (try? context.fetch(descriptor)) ?? []
        for progression in existingProgressions {
            context.delete(progression)
        }
    }

    private static func makeSeededProgression() -> SavedProgression {
        let progression = SavedProgression(
            name: "OpenClaw Turnaround",
            progressionChords: [
                ProgressionChord(chordSymbol: "Dm7", romanNumeral: "ii", duration: 1.0),
                ProgressionChord(chordSymbol: "G7", romanNumeral: "V", duration: 1.0),
                ProgressionChord(chordSymbol: "Cmaj7", romanNumeral: "I", duration: 2.0),
            ],
            key: "C",
            scale: "major",
            tempo: 92
        )
        progression.tags = ["smoke", "seeded"]
        progression.isFavorite = true
        progression.playCount = 7
        progression.notes = "Seeded for OpenClaw UI smoke coverage."
        return progression
    }
}
