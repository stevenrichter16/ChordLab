//
//  ExploreTabView.swift
//  ChordLab
//
//  Main view for the Explore tab - Piano Chord Visualizer
//

import SwiftUI
import Tonic

struct ExploreTabView: View {
    var body: some View {
        ChordVisualizerView()
            //.navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ExploreTabView()
            .environment(TheoryEngine())
            .environment(AudioEngine())
    }
}
