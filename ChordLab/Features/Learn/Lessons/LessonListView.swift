//
//  LessonListView.swift
//  ChordLab
//
//  Full curriculum list with completion state
//

import SwiftUI

struct LessonListView: View {
    @Environment(DataManager.self) private var dataManager

    @State private var completedIDs: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Progress card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(completedIDs.count) of \(LessonLibrary.all.count) lessons complete")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()

                        if completedIDs.count == LessonLibrary.all.count {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.yellow)
                        }
                    }

                    ProgressView(
                        value: Double(completedIDs.count),
                        total: Double(LessonLibrary.all.count)
                    )
                    .tint(.appPrimary)
                }
                .padding()
                .background(Color.appSecondaryBackground)
                .cornerRadius(12)

                ForEach(Array(LessonLibrary.all.enumerated()), id: \.element.id) { index, lesson in
                    NavigationLink {
                        LessonDetailView(lesson: lesson)
                    } label: {
                        LessonRow(
                            lesson: lesson,
                            number: index + 1,
                            isCompleted: completedIDs.contains(lesson.id)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color.appBackground)
        .navigationTitle("Lessons")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            completedIDs = (try? dataManager.getCompletedLessonIDs()) ?? []
            try? dataManager.syncAchievementTarget(
                identifier: "theory_expert",
                target: LessonLibrary.all.count
            )
        }
    }
}

struct LessonRow: View {
    let lesson: Lesson
    let number: Int
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: lesson.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(lesson.color)
                .frame(width: 44, height: 44)
                .background(Circle().fill(lesson.color.opacity(0.12)))

            VStack(alignment: .leading, spacing: 3) {
                Text("\(number). \(lesson.title)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(lesson.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.appSecondaryBackground)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Lesson \(number), \(lesson.title), \(isCompleted ? "completed" : "not completed")"
        )
    }
}

#Preview {
    NavigationStack {
        LessonListView()
            .environment(DataManager(inMemory: true))
            .environment(TheoryEngine())
            .environment(AudioEngine())
    }
}
