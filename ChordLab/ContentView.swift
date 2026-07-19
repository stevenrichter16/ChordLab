//
//  ContentView.swift
//  ChordLab
//
//  Main tab navigation container
//

import SwiftUI
import SwiftData
import Tonic

struct ContentView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(TheoryEngine.self) private var theoryEngine
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        @Bindable var appState = appState

        // The tab bar is IN the layout, not overlaid: the content region
        // physically ends at the bar's top edge, so nothing can ever
        // render behind the bar. The previous overlay + measured-height
        // reservation depended on safe-area math that broke on device
        // (the Explore dock rendered underneath the bar).
        VStack(spacing: 0) {
            Group {
                switch appState.selectedTab {
                case 0:
                    NavigationStack {
                        LearnTabView()
                    }
                case 1:
                    NavigationStack {
                        ExploreTabView()
                    }
                case 2:
                    NavigationStack {
                        LibraryTabView()
                    }
                case 3:
                    NavigationStack {
                        PracticeTabView()
                    }
                case 4:
                    NavigationStack {
                        ProfileTabView()
                    }
                default:
                    NavigationStack {
                        LearnTabView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            FloatingTabBar(selectedTab: $appState.selectedTab)
        }
        .background(Color.appBackground)
        .onAppear {
            // Honor the persisted sound preference from the first frame
            if let userData = try? dataManager.getOrCreateUserData(), !userData.soundEnabled {
                audioEngine.setVolume(0)
            }

            // Bring back the unsaved progression from the last session
            if theoryEngine.currentProgression.isEmpty,
               (try? dataManager.loadDraftProgression(into: theoryEngine)) == true {
                theoryEngine.draftWasRestored = true
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Snapshot the draft whenever the app leaves the foreground
            if newPhase == .background || newPhase == .inactive {
                try? dataManager.saveDraftProgression(from: theoryEngine)
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { !hasCompletedOnboarding },
            set: { hasCompletedOnboarding = !$0 }
        )) {
            OnboardingView {
                hasCompletedOnboarding = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(DataManager(inMemory: true))
        .environment(TheoryEngine())
        .environment(AudioEngine())
        .environment(AppState())
}
