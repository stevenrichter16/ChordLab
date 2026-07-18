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

    // Measured height of whichever custom tab bar style is active, so the
    // content reservation below matches the bar exactly on every device
    @State private var tabBarHeight: CGFloat = 72

    var body: some View {
        @Bindable var appState = appState

        GeometryReader { proxy in
            ZStack {
                // Main content
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
                // The custom tab bar is overlaid on the content, pinned to the
                // PHYSICAL bottom (it ignores the safe area), so the safe-area
                // reservation must be the bar's real height minus the device
                // bottom inset — a fixed value gaps on Face ID phones and
                // overlaps on inset-less ones, which matters now that the
                // Explore dock sits directly on this boundary
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Color.clear
                        .frame(height: max(tabBarHeight - proxy.safeAreaInsets.bottom, 0))
                }

                // Custom tab bar overlay
                VStack {
                    Spacer()

                    FloatingTabBar(selectedTab: $appState.selectedTab)
                        .background(
                            GeometryReader { barGeometry in
                                Color.clear.preference(
                                    key: TabBarHeightPreferenceKey.self,
                                    value: barGeometry.size.height
                                )
                            }
                        )
                }
                .ignoresSafeArea(.keyboard)
                .ignoresSafeArea(edges: .bottom)
            }
            .onPreferenceChange(TabBarHeightPreferenceKey.self) { height in
                if height > 0 {
                    tabBarHeight = height
                }
            }
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

private struct TabBarHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    ContentView()
        .environment(DataManager(inMemory: true))
        .environment(TheoryEngine())
        .environment(AudioEngine())
        .environment(AppState())
}
