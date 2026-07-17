//
//  MissedQuestion.swift
//  ChordLab
//
//  A practice/lesson question the user answered incorrectly, queued for review
//

import Foundation
import SwiftData

@Model
final class MissedQuestion {
    var id: UUID = UUID()
    var prompt: String
    var options: [String] = []
    var correctIndex: Int
    var keyName: String = "C"

    // Stimulus reconstruction (all optional depending on source mode)
    var chordSymbol: String?
    var progressionSymbols: [String] = []
    var modeRaw: String = PracticeSession.PracticeMode.theoryQuiz.rawValue

    var timesMissed: Int = 1
    var firstMissedAt: Date = Date()
    var lastMissedAt: Date = Date()

    var mode: PracticeSession.PracticeMode {
        PracticeSession.PracticeMode(rawValue: modeRaw) ?? .theoryQuiz
    }

    var correctAnswer: String {
        options.indices.contains(correctIndex) ? options[correctIndex] : ""
    }

    init(
        prompt: String,
        options: [String],
        correctIndex: Int,
        keyName: String = "C",
        chordSymbol: String? = nil,
        progressionSymbols: [String] = [],
        mode: PracticeSession.PracticeMode = .theoryQuiz
    ) {
        self.id = UUID()
        self.prompt = prompt
        self.options = options
        self.correctIndex = correctIndex
        self.keyName = keyName
        self.chordSymbol = chordSymbol
        self.progressionSymbols = progressionSymbols
        self.modeRaw = mode.rawValue
        self.timesMissed = 1
        self.firstMissedAt = Date()
        self.lastMissedAt = Date()
    }
}
