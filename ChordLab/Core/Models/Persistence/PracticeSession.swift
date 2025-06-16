//
//  PracticeSession.swift
//  ChordLab
//
//  Practice scores and session history
//

import Foundation
import SwiftData

@Model
final class PracticeSession {
    var id: UUID = UUID()
    var mode: PracticeMode
    var score: Int
    var totalQuestions: Int
    var correctAnswers: Int = 0
    var difficulty: PracticeDifficulty
    var duration: TimeInterval
    var completedAt: Date = Date()
    var streakDays: Int = 0
    
    enum PracticeMode: String, Codable, CaseIterable {
        case earTraining = "Ear Training"
        case chordRecognition = "Chord Recognition"
        case progressionChallenge = "Progression Challenge"
        case theoryQuiz = "Theory Quiz"
    }
    
    enum PracticeDifficulty: String, Codable, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"
    }
    
    var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions)
    }
    
    init(mode: PracticeMode, score: Int, totalQuestions: Int, correctAnswers: Int, difficulty: PracticeDifficulty, duration: TimeInterval) {
        self.id = UUID()
        self.mode = mode
        self.score = score
        self.totalQuestions = totalQuestions
        self.correctAnswers = correctAnswers
        self.difficulty = difficulty
        self.duration = duration
        self.completedAt = Date()
    }
}