//
//  PracticeTabView.swift
//  ChordLab
//
//  Main view for the Practice tab
//

import SwiftUI

struct PracticeTabView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(TheoryEngine.self) private var theoryEngine

    @State private var currentStreak = 0
    @State private var recentSessions: [PracticeSession] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Daily Streak Banner
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.largeTitle)
                        .foregroundColor(currentStreak > 0 ? .orange : .secondary)

                    VStack(alignment: .leading) {
                        Text("\(currentStreak) Day Streak")
                            .font(.headline)
                        Text(currentStreak > 0 ? "Keep it going!" : "Complete a session to start a streak")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(Color.appSecondaryBackground)
                .cornerRadius(12)

                // Practice Modes
                VStack(alignment: .leading, spacing: 12) {
                    Text("Practice Modes")
                        .font(.headline)

                    VStack(spacing: 12) {
                        PracticeModeCard(
                            title: "Ear Training",
                            subtitle: "Identify chord qualities by ear",
                            icon: "ear.fill",
                            color: .blue
                        ) {
                            EarTrainingView()
                        }

                        PracticeModeCard(
                            title: "Chord Recognition",
                            subtitle: "Name the chord shown on the piano",
                            icon: "pianokeys.inverse",
                            color: .green
                        ) {
                            ChordRecognitionView()
                        }

                        PracticeModeCard(
                            title: "Progression Challenge",
                            subtitle: "Identify progressions by ear",
                            icon: "square.stack.3d.up.fill",
                            color: .purple
                        ) {
                            ProgressionChallengeView()
                        }

                        PracticeModeCard(
                            title: "Theory Quiz",
                            subtitle: "Test your knowledge",
                            icon: "questionmark.circle.fill",
                            color: .orange
                        ) {
                            TheoryQuizView()
                        }
                    }
                }

                // Recent Scores
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Scores")
                        .font(.headline)

                    if recentSessions.isEmpty {
                        Text("Complete a practice session to see your scores")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.appTertiaryBackground)
                            .cornerRadius(8)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(recentSessions, id: \.id) { session in
                                ScoreRow(
                                    mode: session.mode.rawValue,
                                    score: session.score,
                                    date: session.completedAt
                                )
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.appBackground)
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadPracticeData()
        }
    }

    private func loadPracticeData() {
        currentStreak = (try? dataManager.getCurrentPracticeStreak()) ?? 0
        recentSessions = (try? dataManager.getRecentPracticeSessions(limit: 5)) ?? []
    }
}

struct PracticeModeCard<Destination: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 50, height: 50)
                    .background(color.opacity(0.2))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.appSecondaryBackground)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct ScoreRow: View {
    let mode: String
    let score: Int
    let date: Date

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(mode)
                    .font(.subheadline)
                Text(date, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(score)%")
                .font(.headline)
                .foregroundColor(scoreColor)
        }
        .padding()
        .background(Color.appTertiaryBackground)
        .cornerRadius(8)
    }

    private var scoreColor: Color {
        if score >= 90 {
            return .green
        } else if score >= 70 {
            return .orange
        } else {
            return .red
        }
    }
}

#Preview {
    NavigationStack {
        PracticeTabView()
            .environment(DataManager(inMemory: true))
            .environment(TheoryEngine())
            .environment(AudioEngine())
    }
}
