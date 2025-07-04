//
//  TestProgressionView.swift
//  ChordLab
//
//  Test view for the chord progression builder
//

import SwiftUI

struct TestProgressionView: View {
    var body: some View {
        ChordVisualizerView()
            .environment(TheoryEngine())
            .environment(AudioEngine())
            .environment(DataManager(inMemory: true))
    }
}

#Preview {
    TestProgressionView()
}