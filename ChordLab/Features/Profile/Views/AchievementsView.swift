//
//  AchievementsView.swift
//  ChordLab
//
//  Full list of achievements with unlock state and progress
//

import SwiftUI

struct AchievementsView: View {
    @Environment(DataManager.self) private var dataManager

    @State private var achievements: [Achievement] = []

    private var groupedAchievements: [(category: Achievement.AchievementCategory, items: [Achievement])] {
        Achievement.AchievementCategory.allCases.compactMap { category in
            let items = achievements.filter { $0.category == category }
            return items.isEmpty ? nil : (category, items)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(groupedAchievements, id: \.category) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(group.category.rawValue)
                            .font(.headline)

                        VStack(spacing: 10) {
                            ForEach(group.items, id: \.id) { achievement in
                                AchievementRow(achievement: achievement)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.appBackground)
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            achievements = (try? dataManager.getAllAchievements()) ?? []
        }
    }
}

struct AchievementRow: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: achievement.iconName)
                .font(.title2)
                .foregroundColor(achievement.isUnlocked ? .yellow : .secondary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(achievement.isUnlocked ? Color.yellow.opacity(0.15) : Color.appTertiaryBackground)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(achievement.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    if achievement.isUnlocked, let unlockedAt = achievement.unlockedAt {
                        Text(unlockedAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(achievement.currentValue)/\(achievement.targetValue)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Text(achievement.achievementDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !achievement.isUnlocked {
                    ProgressView(value: achievement.progressPercentage)
                        .tint(.appPrimary)
                }
            }
        }
        .padding()
        .background(Color.appSecondaryBackground)
        .cornerRadius(12)
        .opacity(achievement.isUnlocked ? 1.0 : 0.85)
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
            .environment(DataManager(inMemory: true))
    }
}
