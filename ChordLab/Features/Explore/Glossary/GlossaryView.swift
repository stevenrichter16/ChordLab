//
//  GlossaryView.swift
//  ChordLab
//
//  Browsable glossary of famous chord progressions. Every entry renders
//  in the user's current key; tap a chip to hear one chord, play the
//  whole entry, or append it to the working progression.
//

import SwiftUI
import Tonic
import UIKit

struct GlossaryView: View {
    @Environment(TheoryEngine.self) private var theoryEngine
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(\.dismiss) private var dismiss

    // Entries rendered once per appearance for the current key
    @State private var renderedEntries: [RenderedGlossaryEntry] = []

    // One entry plays at a time; the index drives per-chip highlighting
    @State private var playingID: String? = nil
    @State private var playingChordIndex: Int? = nil
    @State private var playbackTask: Task<Void, Never>? = nil
    @State private var recentlyAddedID: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Playing in \(theoryEngine.currentKey) \(theoryEngine.currentScaleType)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    ForEach(GlossaryCategory.allCases) { category in
                        let entries = renderedEntries.filter { $0.entry.category == category }

                        if !entries.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Label(category.rawValue, systemImage: category.icon)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(category.tint)
                                    .padding(.horizontal)

                                ForEach(entries) { rendered in
                                    GlossaryCard(
                                        rendered: rendered,
                                        isPlaying: playingID == rendered.id,
                                        playingChordIndex: playingID == rendered.id ? playingChordIndex : nil,
                                        wasJustAdded: recentlyAddedID == rendered.id,
                                        onTogglePlay: { togglePlay(rendered) },
                                        onChipTap: { index in playSingleChord(rendered, at: index) },
                                        onAdd: { add(rendered) }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color.appBackground)
            .navigationTitle("Progression Glossary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            // Take over audio: halt the floating player's loop (a sheet
            // never fires the covered view's onDisappear) and silence
            // anything still ringing
            theoryEngine.requestPlaybackHalt()
            audioEngine.stopPlayback()

            renderedEntries = GlossaryLibrary.all.map { entry in
                RenderedGlossaryEntry(
                    entry: entry,
                    chords: entry.playbackChords(in: theoryEngine),
                    chips: entry.chipData(in: theoryEngine)
                )
            }
        }
        .onDisappear {
            stopEntryPlayback()
        }
    }

    // MARK: - Playback

    private func togglePlay(_ rendered: RenderedGlossaryEntry) {
        if playingID == rendered.id {
            stopEntryPlayback()
            return
        }

        stopEntryPlayback()
        guard !rendered.chords.isEmpty else { return }

        let tempo = rendered.entry.suggestedTempo ?? theoryEngine.currentProgressionTempo
        let beatInterval = 60.0 / Double(max(tempo, 1))

        playingID = rendered.id
        playbackTask = Task {
            for (index, playback) in rendered.chords.enumerated() {
                guard !Task.isCancelled else { return }

                playingChordIndex = index

                let interval = beatInterval * playback.duration
                let isLast = index == rendered.chords.count - 1
                audioEngine.playChord(
                    playback.chord,
                    velocity: UInt8(clamping: playback.velocity),
                    duration: audioEngine.chordSlotDuration(interval: interval, isLast: isLast),
                    includeBass: audioEngine.bassDoublingEnabled
                )

                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }

            guard !Task.isCancelled else { return }
            playingID = nil
            playingChordIndex = nil
        }
    }

    private func playSingleChord(_ rendered: RenderedGlossaryEntry, at index: Int) {
        guard rendered.chords.indices.contains(index) else { return }

        stopEntryPlayback()
        audioEngine.playChord(rendered.chords[index].chord, velocity: 70, duration: 1.0)
    }

    private func stopEntryPlayback() {
        playbackTask?.cancel()
        playbackTask = nil
        playingID = nil
        playingChordIndex = nil
        audioEngine.stopAllNotes()
    }

    // MARK: - Add to progression

    private func add(_ rendered: RenderedGlossaryEntry) {
        guard !rendered.chords.isEmpty else { return }

        let wasEmpty = theoryEngine.currentProgression.isEmpty
        for playback in rendered.chords {
            theoryEngine.addChordToProgression(playback.chord, duration: playback.duration)
        }

        // A fresh progression adopts the entry's feel; an in-progress one
        // keeps the user's tempo
        if wasEmpty, let tempo = rendered.entry.suggestedTempo {
            theoryEngine.currentProgressionTempo = tempo
        }

        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)

        recentlyAddedID = rendered.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if recentlyAddedID == rendered.id {
                recentlyAddedID = nil
            }
        }
    }
}

// MARK: - Rendered entry

/// A glossary entry resolved into the current key once per appearance,
/// so cards don't re-run diatonic analysis on every body evaluation
struct RenderedGlossaryEntry: Identifiable {
    let entry: GlossaryProgression
    let chords: [TheoryEngine.PlaybackChord]
    let chips: [(symbol: String, numeral: String)]

    var id: String { entry.id }
}

// MARK: - Card

struct GlossaryCard: View {
    let rendered: RenderedGlossaryEntry
    let isPlaying: Bool
    let playingChordIndex: Int?
    let wasJustAdded: Bool
    let onTogglePlay: () -> Void
    let onChipTap: (Int) -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(rendered.entry.name)
                        .font(.headline)

                    Text(rendered.entry.numerals)
                        .font(.subheadline.monospaced())
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onTogglePlay) {
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(isPlaying ? Color.red : rendered.entry.category.tint)
                        .clipShape(Circle())
                }
                .accessibilityLabel(isPlaying ? "Stop \(rendered.entry.name)" : "Play \(rendered.entry.name)")
            }

            Text(rendered.entry.details)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // One chip per chord — tap to hear it on its own
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(rendered.chips.enumerated()), id: \.offset) { index, chip in
                        let isSounding = playingChordIndex == index

                        Button(action: { onChipTap(index) }) {
                            VStack(spacing: 2) {
                                Text(chip.symbol)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(isSounding ? .white : .primary)

                                Text(chip.numeral)
                                    .font(.caption2)
                                    .foregroundColor(isSounding ? .white.opacity(0.85) : .secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSounding ? rendered.entry.category.tint : Color.appTertiaryBackground)
                            )
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.15), value: isSounding)
                        .accessibilityLabel("Play \(chip.symbol), \(chip.numeral)")
                    }
                }
            }

            Button(action: onAdd) {
                HStack(spacing: 6) {
                    Image(systemName: wasJustAdded ? "checkmark" : "plus")
                        .font(.system(size: 13, weight: .semibold))
                    Text(wasJustAdded ? "Added ✓" : "Add to progression")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(wasJustAdded ? .green : .appPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill((wasJustAdded ? Color.green : Color.appPrimary).opacity(0.12))
                )
            }
            .disabled(wasJustAdded)
            .animation(.easeInOut(duration: 0.2), value: wasJustAdded)
            .accessibilityLabel("Add \(rendered.entry.name) to progression")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appSecondaryBackground)
        )
    }
}

// MARK: - Preview

#Preview {
    GlossaryView()
        .environment(TheoryEngine())
        .environment(AudioEngine())
}
