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
    
    var body: some Scene {
        WindowGroup {
            ContentView() // Temporary test
                .environment(dataManager)
                .environment(theoryEngine)
                .environment(audioEngine)
                .modelContainer(dataManager.container)
        }
    }
}
