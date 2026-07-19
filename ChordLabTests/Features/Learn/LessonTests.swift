//
//  LessonTests.swift
//  ChordLabTests
//
//  Validates the lesson curriculum content and completion persistence
//

import XCTest
import Tonic
@testable import ChordLab

final class LessonTests: XCTestCase {

    // MARK: - Content integrity

    func testCurriculumHasFifteenLessonsWithUniqueIDs() {
        let lessons = LessonLibrary.all
        XCTAssertGreaterThanOrEqual(lessons.count, 15)
        XCTAssertEqual(Set(lessons.map(\.id)).count, lessons.count, "Lesson IDs must be unique")
    }

    func testProgressionWorkshopTrackExists() {
        // The applied progression-building track appended to the curriculum
        let workshopIDs = [
            "progression-foundations",
            "harmonic-rhythm",
            "loops-vs-journeys",
            "bass-motion",
            "finishing-progressions"
        ]

        for id in workshopIDs {
            XCTAssertNotNil(LessonLibrary.lesson(withID: id), "Missing workshop lesson \(id)")
        }

        // Every lesson now teaches with at least three pages
        for lesson in LessonLibrary.all {
            XCTAssertGreaterThanOrEqual(lesson.pages.count, 3,
                                        "\(lesson.id) should have at least 3 pages")
        }
    }

    func testEveryLessonHasPagesAndAValidQuiz() {
        for lesson in LessonLibrary.all {
            XCTAssertFalse(lesson.pages.isEmpty, "\(lesson.id) needs at least one page")
            XCTAssertGreaterThanOrEqual(lesson.quiz.count, 3, "\(lesson.id) needs at least 3 quiz questions")

            for question in lesson.quiz {
                XCTAssertFalse(question.prompt.isEmpty)
                XCTAssertGreaterThanOrEqual(question.options.count, 2)
                XCTAssertLessThan(question.correctIndex, question.options.count,
                                  "\(lesson.id): correctIndex out of bounds for '\(question.prompt)'")
                XCTAssertEqual(Set(question.options).count, question.options.count,
                               "\(lesson.id): duplicate options in '\(question.prompt)'")
            }
        }
    }

    func testEveryDemoChordSymbolParses() {
        for lesson in LessonLibrary.all {
            for page in lesson.pages {
                XCTAssertNotNil(NoteClass(page.keyName),
                                "\(lesson.id): page key '\(page.keyName)' must parse")

                for symbol in page.demoChords {
                    let chord = Chord.parse(symbol)
                    XCTAssertNotNil(chord, "\(lesson.id): demo chord '\(symbol)' must parse")
                }
            }
        }
    }

    func testLessonLookupByID() {
        XCTAssertEqual(LessonLibrary.lesson(withID: "major-triads")?.title, "Major Triads")
        XCTAssertNil(LessonLibrary.lesson(withID: "does-not-exist"))
    }

    // MARK: - Completion persistence

    @MainActor
    func testLessonCompletionIsIdempotentAndAdvancesAchievement() throws {
        let dataManager = DataManager(inMemory: true)
        try dataManager.syncAchievementTarget(identifier: "theory_expert", target: LessonLibrary.all.count)

        try dataManager.markLessonCompleted("notes-intervals")
        try dataManager.markLessonCompleted("notes-intervals") // second call is a no-op
        try dataManager.markLessonCompleted("major-triads")

        XCTAssertEqual(try dataManager.getCompletedLessonIDs(), ["notes-intervals", "major-triads"])

        let achievement = try dataManager.getAllAchievements().first { $0.identifier == "theory_expert" }
        XCTAssertEqual(achievement?.currentValue, 2)
        XCTAssertEqual(achievement?.targetValue, LessonLibrary.all.count)
        XCTAssertEqual(achievement?.isUnlocked, false)
    }

    @MainActor
    func testCompletingAllLessonsUnlocksTheoryExpert() throws {
        let dataManager = DataManager(inMemory: true)
        try dataManager.syncAchievementTarget(identifier: "theory_expert", target: LessonLibrary.all.count)

        for lesson in LessonLibrary.all {
            try dataManager.markLessonCompleted(lesson.id)
        }

        let achievement = try dataManager.getAllAchievements().first { $0.identifier == "theory_expert" }
        XCTAssertEqual(achievement?.isUnlocked, true)
    }

    @MainActor
    func testRecordLessonViewedUpdatesUserData() throws {
        let dataManager = DataManager(inMemory: true)
        try dataManager.recordLessonViewed("cadences")
        XCTAssertEqual(try dataManager.getOrCreateUserData().lastLessonViewed, "cadences")
    }
}
