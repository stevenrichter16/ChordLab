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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        @Bindable var appState = appState
        
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
            // The custom tab bar is overlaid on the content, so reserve its
            // height as a safe-area inset: scroll views gain bottom content
            // inset automatically and the last items can scroll clear of it
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: 64)
            }

            // Custom tab bar overlay
            VStack {
                Spacer()
                
                switch appState.tabBarStyle {
                case .compact:
                    CompactTabBar(selectedTab: $appState.selectedTab)
                case .ultraCompact:
                    UltraCompactTabBar(selectedTab: $appState.selectedTab)
                case .floating:
                    FloatingTabBar(selectedTab: $appState.selectedTab)
                }
            }
            .ignoresSafeArea(.keyboard)
            .ignoresSafeArea(edges: .bottom)
        }
        .background(Color.appBackground)
        .onAppear {
            // Honor the persisted sound preference from the first frame
            if let userData = try? dataManager.getOrCreateUserData(), !userData.soundEnabled {
                audioEngine.setVolume(0)
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
