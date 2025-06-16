//
//  BuildTabView.swift
//  ChordLab
//
//  Main view for the Build tab
//

import SwiftUI
import Tonic

struct BuildTabView: View {
    @Environment(TheoryEngine.self) private var theoryEngine
    @Environment(AudioEngine.self) private var audioEngine
    
    @State private var isPlaying = false
    @State private var tempo: Double = 120
    
    var body: some View {
        VStack(spacing: 0) {
            // Progression Timeline
            VStack(alignment: .leading, spacing: 12) {
                Text("Progression")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        if theoryEngine.currentProgression.isEmpty {
                            // Empty state
                            VStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.appPrimary)
                                Text("Add chords")
                                    .font(.caption)
                            }
                            .frame(width: 100, height: 100)
                            .background(Color.appSecondaryBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .foregroundColor(.appPrimary)
                            )
                        } else {
                            ForEach(Array(theoryEngine.currentProgression.enumerated()), id: \.element.id) { index, progressionChord in
                                TimelineChordView(
                                    chord: progressionChord.chord,
                                    index: index
                                )
                            }
                        }
                    }
                }
                .frame(height: 120)
            }
            .padding()
            .background(Color.appBackground)
            
            // Controls
            HStack(spacing: 20) {
                // Play/Stop button
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                        .font(.title)
                        .frame(width: 60, height: 60)
                        .background(Color.appPrimary)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                
                // Tempo control
                VStack(alignment: .leading) {
                    Text("Tempo: \(Int(tempo)) BPM")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(value: $tempo, in: 60...200, step: 5)
                        .onChange(of: tempo) { _, newValue in
                            audioEngine.setTempo(Int(newValue))
                        }
                }
            }
            .padding()
            
            // Suggestions
            VStack(alignment: .leading, spacing: 12) {
                Text("Suggestions")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(theoryEngine.getChordSuggestions(
                            after: theoryEngine.currentProgression.map { $0.chord.description }
                        ), id: \.description) { chord in
                            SuggestionChordView(chord: chord) {
                                theoryEngine.addChordToProgression(chord)
                                audioEngine.playChord(chord)
                            }
                        }
                    }
                }
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("Build")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Clear") {
                    theoryEngine.clearProgression()
                }
                .disabled(theoryEngine.currentProgression.isEmpty)
            }
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            // TODO: Stop playback
            isPlaying = false
        } else {
            // TODO: Start playback
            isPlaying = true
        }
    }
}

struct TimelineChordView: View {
    let chord: Chord
    let index: Int
    
    var body: some View {
        VStack {
            Text(chord.description)
                .font(.headline)
            Text("Bar \(index + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 80, height: 100)
        .background(Color.appSecondaryBackground)
        .cornerRadius(12)
    }
}

struct SuggestionChordView: View {
    let chord: Chord
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text(chord.description)
                    .font(.subheadline)
                Image(systemName: "plus.circle")
                    .font(.caption)
            }
            .padding()
            .background(Color.appTertiaryBackground)
            .cornerRadius(8)
        }
    }
}

#Preview {
    NavigationStack {
        BuildTabView()
            .environment(TheoryEngine())
            .environment(AudioEngine())
    }
}