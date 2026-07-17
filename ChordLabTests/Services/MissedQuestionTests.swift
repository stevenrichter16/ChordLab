//
//  MissedQuestionTests.swift
//  ChordLabTests
//
//  Tests for the missed-question review queue
//

import XCTest
import Tonic
@testable import ChordLab

@MainActor
final class MissedQuestionTests: XCTestCase {

    private func makeQuestion(prompt: String = "In C major, which chord is the V?") -> PracticeQuestion {
        PracticeQuestion(
            prompt: prompt,
            keyName: "C",
            chord: Chord(.G, type: .major),
            options: ["F", "G", "Am", "Em"],
            correctIndex: 1
        )
    }

    func testRecordingAMissStoresStimulusData() throws {
        let dataManager = DataManager(inMemory: true)
        try dataManager.recordMissedQuestion(from: makeQuestion(), mode: .chordRecognition)

        let missed = try dataManager.getMissedQuestions(limit: 10)
        XCTAssertEqual(missed.count, 1)
        XCTAssertEqual(missed.first?.chordSymbol, "G")
        XCTAssertEqual(missed.first?.mode, .chordRecognition)
        XCTAssertEqual(missed.first?.correctAnswer, "G")
        XCTAssertEqual(missed.first?.timesMissed, 1)
    }

    func testRepeatMissesDeduplicateAndBumpCounter() throws {
        let dataManager = DataManager(inMemory: true)
        try dataManager.recordMissedQuestion(from: makeQuestion(), mode: .chordRecognition)
        try dataManager.recordMissedQuestion(from: makeQuestion(), mode: .review)

        XCTAssertEqual(try dataManager.missedQuestionCount(), 1)
        XCTAssertEqual(try dataManager.getMissedQuestions(limit: 10).first?.timesMissed, 2)
        // Original mode is preserved for stimulus reconstruction
        XCTAssertEqual(try dataManager.getMissedQuestions(limit: 10).first?.mode, .chordRecognition)
    }

    func testResolvingRemovesFromQueue() throws {
        let dataManager = DataManager(inMemory: true)
        let question = makeQuestion()
        try dataManager.recordMissedQuestion(from: question, mode: .theoryQuiz)
        try dataManager.recordMissedQuestion(from: makeQuestion(prompt: "Another question"), mode: .theoryQuiz)

        try dataManager.resolveMissedQuestion(prompt: question.prompt, correctAnswer: question.correctAnswer)

        XCTAssertEqual(try dataManager.missedQuestionCount(), 1)
        XCTAssertEqual(try dataManager.getMissedQuestions(limit: 10).first?.prompt, "Another question")
    }

    func testQueueOrdersOldestMissFirst() throws {
        let dataManager = DataManager(inMemory: true)
        try dataManager.recordMissedQuestion(from: makeQuestion(prompt: "First"), mode: .theoryQuiz)
        try dataManager.recordMissedQuestion(from: makeQuestion(prompt: "Second"), mode: .theoryQuiz)

        // Re-missing "First" pushes it behind "Second"
        try dataManager.recordMissedQuestion(from: makeQuestion(prompt: "First"), mode: .theoryQuiz)

        let queue = try dataManager.getMissedQuestions(limit: 10)
        XCTAssertEqual(queue.map(\.prompt), ["Second", "First"])
    }

    func testProgressionQuestionRoundTripsSymbols() throws {
        let dataManager = DataManager(inMemory: true)
        let question = PracticeQuestion(
            prompt: "Which pattern did you hear?",
            keyName: "C",
            progression: [
                Chord(.C, type: .major),
                Chord(.F, type: .major),
                Chord(.G, type: .dom7),
                Chord(.C, type: .major)
            ],
            options: ["I – IV – V7 – I", "I – V – vi – IV"],
            correctIndex: 0
        )
        try dataManager.recordMissedQuestion(from: question, mode: .progressionChallenge)

        let stored = try XCTUnwrap(dataManager.getMissedQuestions(limit: 1).first)
        let rebuilt = stored.progressionSymbols.compactMap { Chord.parse($0) }
        XCTAssertEqual(rebuilt.count, 4)
        XCTAssertEqual(rebuilt.map(\.type), [.major, .major, .dom7, .major])
    }

    func testClearAllDataEmptiesQueue() throws {
        let dataManager = DataManager(inMemory: true)
        try dataManager.recordMissedQuestion(from: makeQuestion(), mode: .theoryQuiz)
        try dataManager.clearAllData()
        XCTAssertEqual(try dataManager.missedQuestionCount(), 0)
    }
}
