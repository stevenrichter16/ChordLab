//
//  ChordLabApp.swift
//  ChordLab
//
//  Created by Steven Richter on 6/15/25.
//

import SwiftUI
import SwiftData

@main
struct ChordLabApp: App {
    let dataManager = DataManager()
    let theoryEngine = TheoryEngine()
    let audioEngine = AudioEngine()
    let appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dataManager)
                .environment(theoryEngine)
                .environment(audioEngine)
                .environment(appState)
                .modelContainer(dataManager.container)
        }
    }
}
