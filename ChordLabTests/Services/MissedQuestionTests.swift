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

        try dataManager.resolveMissedQuestion(
            prompt: question.prompt,
            correctAnswer: question.correctAnswer,
            chordSymbol: question.chord?.formattedSymbol
        )

        XCTAssertEqual(try dataManager.missedQuestionCount(), 1)
        XCTAssertEqual(try dataManager.getMissedQuestions(limit: 10).first?.prompt, "Another question")
    }

    func testSamePromptDifferentChordsQueueSeparately() throws {
        let dataManager = DataManager(inMemory: true)

        // Ear training reuses one prompt across many chords; each chord
        // must keep its own queue entry
        let cMajor = PracticeQuestion(
            prompt: "Listen to the chord. What quality is it?",
            chord: Chord(.C, type: .major),
            options: ["Major", "Minor"],
            correctIndex: 0
        )
        let fSharpMajor = PracticeQuestion(
            prompt: "Listen to the chord. What quality is it?",
            chord: Chord(NoteClass(.F, accidental: .sharp), type: .major),
            options: ["Major", "Minor"],
            correctIndex: 0
        )

        try dataManager.recordMissedQuestion(from: cMajor, mode: .earTraining)
        try dataManager.recordMissedQuestion(from: fSharpMajor, mode: .earTraining)

        XCTAssertEqual(try dataManager.missedQuestionCount(), 2)

        try dataManager.resolveMissedQuestion(
            prompt: cMajor.prompt,
            correctAnswer: cMajor.correctAnswer,
            chordSymbol: cMajor.chord?.formattedSymbol
        )

        XCTAssertEqual(try dataManager.missedQuestionCount(), 1)
        XCTAssertEqual(try dataManager.getMissedQuestions(limit: 10).first?.chordSymbol, "F♯")
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
