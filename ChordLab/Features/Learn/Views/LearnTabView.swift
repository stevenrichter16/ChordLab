//
//  LearnTabView.swift
//  ChordLab
//
//  Main view for the Learn tab
//

import SwiftUI

struct LearnTabView: View {
    @Environment(TheoryEngine.self) private var theoryEngine
    @Environment(DataManager.self) private var dataManager
    @Environment(AppState.self) private var appState
    @State private var useScrollablePiano = false

    private static let theoryTips = [
        "The V7 chord creates tension that naturally resolves to the I chord due to the tritone between its 3rd and 7th degrees.",
        "The ii–V–I progression is the backbone of jazz harmony — practice it in every key.",
        "Relative major and minor keys share the same key signature: A minor has the same notes as C major.",
        "A half-diminished 7th chord (ø7) has a minor 3rd, diminished 5th, and minor 7th — it's the natural vii chord in major keys.",
        "Voice leading is smoothest when adjacent chords share common tones and other voices move by step.",
        "The IV–I motion is called a plagal cadence — you know it as the 'Amen' ending in hymns.",
        "Borrowed chords like ♭VII and iv come from the parallel minor and add color to major-key progressions.",
        "In any major key, the I, IV, and V chords are major; ii, iii, and vi are minor; vii° is diminished.",
        "A deceptive cadence (V–vi) sets up an expected resolution and lands somewhere surprising instead.",
        "Seventh chords add the 7th scale degree above the root — they make triads sound richer and more directional."
    ]

    private var dailyTip: String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return Self.theoryTips[day % Self.theoryTips.count]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Key and Scale Selector
                KeyScaleSelector()
                    .padding(.vertical, 8)
                
                // Scale Piano View
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Scale Visualization")
                            .font(.headline)
                        
                        Spacer()

                    }
                    .padding(.horizontal)
                    
                        ScrollablePianoView()
                            .padding(.horizontal)

                }
                
                // Today's Focus
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Focus")
                        .font(.headline)

                    Text("Practice identifying progressions in \(theoryEngine.currentKey) major")
                        .font(.body)
                        .foregroundColor(.secondary)

                    NavigationLink {
                        ProgressionChallengeView()
                    } label: {
                        Text("Start Practice")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .cornerRadius(12)

                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        QuickActionLink(
                            title: "Ear Training",
                            icon: "ear",
                            color: .orange
                        ) {
                            EarTrainingView()
                        }

                        QuickActionButton(
                            title: "Chord Explorer",
                            icon: "pianokeys",
                            color: .green
                        ) {
                            appState.switchToExplore()
                        }

                        QuickActionLink(
                            title: "Progressions",
                            icon: "square.stack.3d.up",
                            color: .blue
                        ) {
                            ProgressionChallengeView()
                        }

                        QuickActionLink(
                            title: "Theory Quiz",
                            icon: "questionmark.circle",
                            color: .purple
                        ) {
                            TheoryQuizView()
                        }
                    }
                }
                .padding()

                // Theory Tip
                VStack(alignment: .leading, spacing: 8) {
                    Label("Theory Tip", systemImage: "lightbulb.fill")
                        .font(.headline)
                        .foregroundColor(.yellow)

                    Text(dailyTip)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.appTertiaryBackground)
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Learn")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            QuickActionLabel(title: title, icon: icon, color: color)
        }
        .buttonStyle(.plain)
    }
}

struct QuickActionLink<Destination: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            QuickActionLabel(title: title, icon: icon, color: color)
        }
        .buttonStyle(.plain)
    }
}

private struct QuickActionLabel: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.appSecondaryBackground)
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        LearnTabView()
            .environment(TheoryEngine())
            .environment(AudioEngine())
            .environment(DataManager(inMemory: true))
            .environment(AppState())
    }
}
