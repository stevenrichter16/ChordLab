//
//  TestLibraryView.swift
//  ChordLab
//
//  Test view for the Library functionality
//

import SwiftUI

struct TestLibraryView: View {
    var body: some View {
        ContentView()
            .environment(TheoryEngine())
            .environment(AudioEngine())
            .environment(DataManager(inMemory: false)) // Use persistent storage for testing
    }
}

#Preview {
    TestLibraryView()
}