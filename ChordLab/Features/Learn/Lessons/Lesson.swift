//
//  Lesson.swift
//  ChordLab
//
//  Model for structured, interactive theory lessons
//

import SwiftUI

struct Lesson: Identifiable {
    let id: String            // Stable identifier, persisted in UserData.completedLessons
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let pages: [LessonPage]
    let quiz: [PracticeQuestion]
}

struct LessonPage: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let keyName: String       // Key context for the demo piano
    let demoChords: [String]  // Chord symbols the learner can tap to hear

    init(title: String, body: String, keyName: String = "C", demoChords: [String] = []) {
        self.title = title
        self.body = body
        self.keyName = keyName
        self.demoChords = demoChords
    }
}
