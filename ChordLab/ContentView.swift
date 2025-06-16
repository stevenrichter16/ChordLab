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
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Learn Tab
            NavigationStack {
                LearnTabView()
            }
            .tabItem {
                Label("Learn", systemImage: "book.fill")
            }
            .tag(0)
            
            // Explore Tab
            NavigationStack {
                ExploreTabView()
            }
            .tabItem {
                Label("Explore", systemImage: "magnifyingglass")
            }
            .tag(1)
            
            // Build Tab
            NavigationStack {
                BuildTabView()
            }
            .tabItem {
                Label("Build", systemImage: "hammer.fill")
            }
            .tag(2)
            
            // Practice Tab
            NavigationStack {
                PracticeTabView()
            }
            .tabItem {
                Label("Practice", systemImage: "music.note.list")
            }
            .tag(3)
            
            // Profile Tab
            NavigationStack {
                ProfileTabView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(4)
        }
        .accentColor(.appPrimary)
    }
}

#Preview {
    ContentView()
        .environment(DataManager(inMemory: true))
        .environment(TheoryEngine())
        .environment(AudioEngine())
}
