//
//  ProgressionDetailView.swift
//  ChordLab
//
//  Detailed view of a saved chord progression
//

import SwiftUI
import Tonic

struct ProgressionDetailView: View {
    let progression: SavedProgression
    @Environment(\.dismiss) private var dismiss
    @Environment(TheoryEngine.self) private var theoryEngine
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(AppState.self) private var appState
    @State private var isPlaying = false
    @State private var currentPlayIndex: Int? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header info
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("\(progression.key) \(progression.scale.capitalized)", systemImage: "key")
                            Spacer()
                            Label("\(progression.tempo) BPM", systemImage: "metronome")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        
                        if !progression.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(progression.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.appPrimary.opacity(0.2))
                                            .foregroundColor(.appPrimary)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Playback controls
                    HStack(spacing: 16) {
                        Button(action: togglePlayback) {
                            Label(
                                isPlaying ? "Stop" : "Play",
                                systemImage: isPlaying ? "stop.fill" : "play.fill"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Spacer()
                        
                        Button(action: loadInVisualizer) {
                            Label("Load in Visualizer", systemImage: "pianokeys")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                    
                    // Chord list
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Chords")
                            .font(.headline)
                        
                        ForEach(Array(progression.progressionChords.enumerated()), id: \.offset) { index, chord in
                            ChordDetailRow(
                                chord: chord,
                                index: index,
                                isPlaying: currentPlayIndex == index
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Stats
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Statistics")
                            .font(.headline)
                        
                        HStack {
                            StatItem(label: "Chords", value: "\(progression.chordCount)")
                            Spacer()
                            StatItem(label: "Duration", value: formatDuration(progression.duration))
                            Spacer()
                            StatItem(label: "Plays", value: "\(progression.playCount)")
                        }
                    }
                    .padding()
                    .background(Color.appSecondaryBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Notes
                    if let notes = progression.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            
                            Text(notes)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(progression.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Edit", systemImage: "pencil") {
                            // TODO: Edit functionality
                        }
                        
                        Button("Duplicate", systemImage: "doc.on.doc") {
                            // TODO: Duplicate functionality
                        }
                        
                        Divider()
                        
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            // TODO: Delete functionality
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func togglePlayback() {
        if isPlaying {
            // Stop playback by setting flag - the Task will check this
            isPlaying = false
            currentPlayIndex = nil
        } else {
            // Start playback
            playProgression()
        }
    }
    
    private func playProgression() {
        isPlaying = true
        progression.playCount += 1
        progression.lastPlayedAt = Date()
        
        // Convert ProgressionChords to Tonic Chords
        let chords = progression.progressionChords.compactMap { progressionChord in
            Chord.parse(progressionChord.chordSymbol)
        }
        
        // Calculate the delay between chords based on tempo
        let beatsPerSecond = Double(progression.tempo) / 60.0
        
        // Play each chord in sequence
        Task {
            for (index, chord) in chords.enumerated() {
                guard isPlaying else { break }
                
                // Update UI to show which chord is playing
                await MainActor.run {
                    currentPlayIndex = index
                }
                
                // Play the chord
                audioEngine.playChord(chord)
                
                // Wait for the duration of this chord
                let duration = progression.progressionChords[index].duration
                let delaySeconds = duration / beatsPerSecond
                
                try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
            }
            
            // Reset when done
            await MainActor.run {
                isPlaying = false
                currentPlayIndex = nil
            }
        }
    }
    
    private func loadInVisualizer() {
        // Load the progression into TheoryEngine
        theoryEngine.loadProgression(progression)
        
        // Switch to Explore tab
        appState.switchToExplore()
        
        // Dismiss the detail view
        dismiss()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Chord Detail Row

struct ChordDetailRow: View {
    let chord: ProgressionChord
    let index: Int
    let isPlaying: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Index
            Text("\(index + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            // Chord info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(chord.chordSymbol)
                        .font(.headline)
                    
                    Text(chord.romanNumeral)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if !chord.function.isEmpty {
                        Text("• \(chord.function)")
                            .font(.caption)
                            .foregroundColor(.appPrimary)
                    }
                }
                
                if !chord.noteNames.isEmpty {
                    Text(chord.noteNames.joined(separator: " - "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Duration
            Text("\(Int(chord.duration)) beat\(chord.duration == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(isPlaying ? Color.appPrimary.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    ProgressionDetailView(
        progression: SavedProgression(
            name: "Jazz ii-V-I",
            progressionChords: [
                ProgressionChord(chordSymbol: "Dm7", romanNumeral: "ii7", noteNames: ["D", "F", "A", "C"], function: "Supertonic"),
                ProgressionChord(chordSymbol: "G7", romanNumeral: "V7", noteNames: ["G", "B", "D", "F"], function: "Dominant"),
                ProgressionChord(chordSymbol: "Cmaj7", romanNumeral: "Imaj7", noteNames: ["C", "E", "G", "B"], function: "Tonic")
            ],
            key: "C",
            tempo: 120
        )
    )
    .environment(TheoryEngine())
    .environment(AudioEngine())
    .environment(AppState())
}