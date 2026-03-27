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
                    .accessibilityIdentifier(ChordLabAutomationID.learnRoot)
                case 1:
                    NavigationStack {
                        ExploreTabView()
                    }
                    .accessibilityIdentifier(ChordLabAutomationID.exploreRoot)
                case 2:
                    NavigationStack {
                        LibraryTabView()
                    }
                    .accessibilityIdentifier(ChordLabAutomationID.libraryRoot)
                case 3:
                    NavigationStack {
                        PracticeTabView()
                    }
                    .accessibilityIdentifier(ChordLabAutomationID.practiceRoot)
                case 4:
                    NavigationStack {
                        ProfileTabView()
                    }
                    .accessibilityIdentifier(ChordLabAutomationID.profileRoot)
                default:
                    NavigationStack {
                        LearnTabView()
                    }
                    .accessibilityIdentifier(ChordLabAutomationID.learnRoot)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
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
        .accessibilityIdentifier(ChordLabAutomationID.appRoot)
    }
}

#Preview {
    ContentView()
        .environment(DataManager(inMemory: true))
        .environment(TheoryEngine())
        .environment(AudioEngine(disableAudio: true))
        .environment(AppState())
}
