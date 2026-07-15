//
//  ProfileTabView.swift
//  ChordLab
//
//  Main view for the Profile tab
//

import SwiftUI

struct ProfileTabView: View {
    @Environment(DataManager.self) private var dataManager

    @State private var totalPracticeSessions = 0
    @State private var totalPracticeTime: TimeInterval = 0
    @State private var averageScore: Double = 0
    @State private var currentStreak = 0
    @State private var favoriteKey = "C major"
    @State private var learningSince: Date?
    @State private var unlockedAchievements: [Achievement] = []
    @State private var totalAchievementCount = 0
    @State private var showingSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.appPrimary)

                    Text("Music Student")
                        .font(.title2)
                        .bold()

                    Text(learningSinceText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()

                // Statistics
                VStack(alignment: .leading, spacing: 16) {
                    Text("Statistics")
                        .font(.headline)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(
                            title: "Sessions",
                            value: "\(totalPracticeSessions)",
                            icon: "music.note.list"
                        )

                        StatCard(
                            title: "Favorite Key",
                            value: favoriteKey,
                            icon: "key.fill"
                        )

                        StatCard(
                            title: "Avg Score",
                            value: totalPracticeSessions > 0 ? "\(Int(averageScore.rounded()))%" : "—",
                            icon: "target"
                        )

                        StatCard(
                            title: "Time Practiced",
                            value: formattedPracticeTime,
                            icon: "clock.fill"
                        )

                        StatCard(
                            title: "Day Streak",
                            value: "\(currentStreak)",
                            icon: "flame.fill"
                        )

                        StatCard(
                            title: "Achievements",
                            value: "\(unlockedAchievements.count)/\(totalAchievementCount)",
                            icon: "trophy.fill"
                        )
                    }
                }
                .padding(.horizontal)

                // Achievements Preview
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recent Achievements")
                            .font(.headline)
                        Spacer()
                        NavigationLink("See All") {
                            AchievementsView()
                        }
                        .font(.caption)
                    }

                    if unlockedAchievements.isEmpty {
                        Text("Complete practice sessions to unlock achievements")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.appTertiaryBackground)
                            .cornerRadius(8)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(unlockedAchievements.prefix(5), id: \.id) { achievement in
                                    AchievementBadge(
                                        icon: achievement.iconName,
                                        title: achievement.name,
                                        isUnlocked: true
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Settings Button
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding()
            }
        }
        .background(Color.appBackground)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadProfileData()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }

    // MARK: - Data

    private func loadProfileData() {
        if let stats = try? dataManager.getPracticeStatistics() {
            totalPracticeSessions = stats.totalSessions
            totalPracticeTime = stats.totalPracticeTime
            averageScore = stats.averageScore
        }

        currentStreak = (try? dataManager.getCurrentPracticeStreak()) ?? 0

        if let userData = try? dataManager.getOrCreateUserData() {
            favoriteKey = "\(userData.currentKey) \(userData.currentScale)"
            learningSince = userData.createdAt
        }

        unlockedAchievements = (try? dataManager.getUnlockedAchievements()) ?? []
        totalAchievementCount = (try? dataManager.getAllAchievements().count) ?? 0
    }

    // MARK: - Formatting

    private var learningSinceText: String {
        guard let learningSince else { return "Welcome!" }

        if Calendar.current.isDateInToday(learningSince) {
            return "Learning since today"
        }
        return "Learning since \(learningSince.formatted(date: .abbreviated, time: .omitted))"
    }

    private var formattedPracticeTime: String {
        let totalMinutes = Int(totalPracticeTime) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.appPrimary)

            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.appSecondaryBackground)
        .cornerRadius(12)
    }
}

struct AchievementBadge: View {
    let icon: String
    let title: String
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(isUnlocked ? .yellow : .gray)

            Text(title)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80, height: 80)
        .background(isUnlocked ? Color.appSecondaryBackground : Color.gray.opacity(0.2))
        .cornerRadius(12)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

#Preview {
    NavigationStack {
        ProfileTabView()
            .environment(DataManager(inMemory: true))
    }
}
