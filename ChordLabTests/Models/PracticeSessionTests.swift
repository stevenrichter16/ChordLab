//
//  PracticeSessionTests.swift
//  ChordLabTests
//
//  Unit tests for PracticeSession model
//

import XCTest
@testable import ChordLab

final class PracticeSessionTests: XCTestCase {
    
    func testPracticeSessionInitialization() {
        let session = PracticeSession(
            mode: .earTraining,
            score: 85,
            totalQuestions: 10,
            correctAnswers: 8,
            difficulty: .intermediate,
            duration: 300 // 5 minutes
        )
        
        XCTAssertEqual(session.mode, .earTraining)
        XCTAssertEqual(session.score, 85)
        XCTAssertEqual(session.totalQuestions, 10)
        XCTAssertEqual(session.correctAnswers, 8)
        XCTAssertEqual(session.difficulty, .intermediate)
        XCTAssertEqual(session.duration, 300)
        XCTAssertNotNil(session.completedAt)
        XCTAssertEqual(session.streakDays, 0)
    }
    
    func testAccuracyCalculation() {
        // Test normal accuracy
        let session1 = PracticeSession(
            mode: .chordRecognition,
            score: 100,
            totalQuestions: 10,
            correctAnswers: 8,
            difficulty: .beginner,
            duration: 200
        )
        XCTAssertEqual(session1.accuracy, 0.8)
        
        // Test perfect accuracy
        let session2 = PracticeSession(
            mode: .theoryQuiz,
            score: 100,
            totalQuestions: 20,
            correctAnswers: 20,
            difficulty: .advanced,
            duration: 600
        )
        XCTAssertEqual(session2.accuracy, 1.0)
        
        // Test zero accuracy
        let session3 = PracticeSession(
            mode: .progressionChallenge,
            score: 0,
            totalQuestions: 15,
            correctAnswers: 0,
            difficulty: .expert,
            duration: 450
        )
        XCTAssertEqual(session3.accuracy, 0.0)
        
        // Test division by zero handling
        let session4 = PracticeSession(
            mode: .earTraining,
            score: 0,
            totalQuestions: 0,
            correctAnswers: 0,
            difficulty: .beginner,
            duration: 0
        )
        XCTAssertEqual(session4.accuracy, 0.0)
    }
    
    func testPracticeModeEnumeration() {
        let modes = PracticeSession.PracticeMode.allCases
        
        XCTAssertEqual(modes.count, 4)
        XCTAssertTrue(modes.contains(.earTraining))
        XCTAssertTrue(modes.contains(.chordRecognition))
        XCTAssertTrue(modes.contains(.progressionChallenge))
        XCTAssertTrue(modes.contains(.theoryQuiz))
        
        // Test raw values
        XCTAssertEqual(PracticeSession.PracticeMode.earTraining.rawValue, "Ear Training")
        XCTAssertEqual(PracticeSession.PracticeMode.chordRecognition.rawValue, "Chord Recognition")
        XCTAssertEqual(PracticeSession.PracticeMode.progressionChallenge.rawValue, "Progression Challenge")
        XCTAssertEqual(PracticeSession.PracticeMode.theoryQuiz.rawValue, "Theory Quiz")
    }
    
    func testPracticeDifficultyEnumeration() {
        let difficulties = PracticeSession.PracticeDifficulty.allCases
        
        XCTAssertEqual(difficulties.count, 4)
        XCTAssertTrue(difficulties.contains(.beginner))
        XCTAssertTrue(difficulties.contains(.intermediate))
        XCTAssertTrue(difficulties.contains(.advanced))
        XCTAssertTrue(difficulties.contains(.expert))
        
        // Test raw values
        XCTAssertEqual(PracticeSession.PracticeDifficulty.beginner.rawValue, "Beginner")
        XCTAssertEqual(PracticeSession.PracticeDifficulty.intermediate.rawValue, "Intermediate")
        XCTAssertEqual(PracticeSession.PracticeDifficulty.advanced.rawValue, "Advanced")
        XCTAssertEqual(PracticeSession.PracticeDifficulty.expert.rawValue, "Expert")
    }
    
    func testAccuracyEdgeCases() {
        // Test partial accuracy
        let session = PracticeSession(
            mode: .earTraining,
            score: 75,
            totalQuestions: 12,
            correctAnswers: 9,
            difficulty: .intermediate,
            duration: 360
        )
        XCTAssertEqual(session.accuracy, 0.75)
        
        // Test with single question
        let singleQuestion = PracticeSession(
            mode: .theoryQuiz,
            score: 100,
            totalQuestions: 1,
            correctAnswers: 1,
            difficulty: .beginner,
            duration: 30
        )
        XCTAssertEqual(singleQuestion.accuracy, 1.0)
    }
}