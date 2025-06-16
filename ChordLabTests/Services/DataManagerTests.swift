//
//  DataManagerTests.swift
//  ChordLabTests
//
//  Unit tests for DataManager service
//

import XCTest
import SwiftData
@testable import ChordLab

@MainActor
final class DataManagerTests: XCTestCase {
    
    var dataManager: DataManager!
    
    override func setUp() {
        super.setUp()
        dataManager = DataManager(inMemory: true)
    }
    
    override func tearDown() {
        dataManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testDataManagerInitialization() {
        XCTAssertNotNil(dataManager.container)
        XCTAssertNotNil(dataManager.context)
    }
    
    func testInMemoryConfiguration() {
        // Verify that in-memory flag creates temporary storage
        XCTAssertTrue(dataManager.isInMemory)
    }
    
    // MARK: - User Data Tests
    
    func testGetOrCreateUserData() throws {
        // First call should create
        let userData1 = try dataManager.getOrCreateUserData()
        XCTAssertNotNil(userData1)
        XCTAssertEqual(userData1.currentKey, "C")
        XCTAssertEqual(userData1.currentScale, "major")
        
        // Second call should return same instance
        let userData2 = try dataManager.getOrCreateUserData()
        XCTAssertEqual(userData1.id, userData2.id)
    }
    
    func testUpdateUserData() throws {
        let userData = try dataManager.getOrCreateUserData()
        
        try dataManager.updateUserData { data in
            data.currentKey = "G"
            data.currentScale = "minor"
            data.preferredTempo = 140
        }
        
        let updated = try dataManager.getOrCreateUserData()
        XCTAssertEqual(updated.currentKey, "G")
        XCTAssertEqual(updated.currentScale, "minor")
        XCTAssertEqual(updated.preferredTempo, 140)
    }
    
    // MARK: - Chord History Tests
    
    func testAddChordToHistory() throws {
        try dataManager.addChordToHistory(
            symbol: "Am",
            keyContext: "C",
            romanNumeral: "vi",
            function: "Submediant"
        )
        
        let history = try dataManager.getRecentChords(limit: 10)
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.chordSymbol, "Am")
    }
    
    func testGetRecentChordsLimit() throws {
        // Add 10 chords
        for i in 1...10 {
            try dataManager.addChordToHistory(
                symbol: "Chord\(i)",
                keyContext: "C",
                romanNumeral: "I",
                function: "Tonic"
            )
            Thread.sleep(forTimeInterval: 0.01) // Ensure different timestamps
        }
        
        // Test different limits
        let recent5 = try dataManager.getRecentChords(limit: 5)
        XCTAssertEqual(recent5.count, 5)
        
        let recent20 = try dataManager.getRecentChords(limit: 20)
        XCTAssertEqual(recent20.count, 10) // Should return all 10
    }
    
    func testToggleChordFavorite() throws {
        // Add chord
        try dataManager.addChordToHistory(
            symbol: "C",
            keyContext: "C",
            romanNumeral: "I",
            function: "Tonic"
        )
        
        let history = try dataManager.getRecentChords(limit: 1)
        let chord = history.first!
        
        // Toggle favorite on
        try dataManager.toggleChordFavorite(chord)
        XCTAssertTrue(chord.isFavorite)
        
        // Toggle favorite off
        try dataManager.toggleChordFavorite(chord)
        XCTAssertFalse(chord.isFavorite)
    }
    
    func testGetFavoriteChords() throws {
        // Add mix of favorite and non-favorite chords
        for i in 1...5 {
            try dataManager.addChordToHistory(
                symbol: "Chord\(i)",
                keyContext: "C",
                romanNumeral: "I",
                function: "Tonic"
            )
        }
        
        let allChords = try dataManager.getRecentChords(limit: 10)
        
        // Mark some as favorites
        try dataManager.toggleChordFavorite(allChords[0])
        try dataManager.toggleChordFavorite(allChords[2])
        
        let favorites = try dataManager.getFavoriteChords()
        XCTAssertEqual(favorites.count, 2)
    }
    
    // MARK: - Progression Tests
    
    func testSaveProgression() throws {
        let progressionId = try dataManager.saveProgression(
            name: "My Progression",
            chords: ["C", "Am", "F", "G"],
            romanNumerals: ["I", "vi", "IV", "V"],
            key: "C",
            scale: "major",
            tempo: 120
        )
        
        XCTAssertNotNil(progressionId)
        
        let progressions = try dataManager.getAllProgressions()
        XCTAssertEqual(progressions.count, 1)
        XCTAssertEqual(progressions.first?.name, "My Progression")
    }
    
    func testUpdateProgression() throws {
        // Save initial progression
        let id = try dataManager.saveProgression(
            name: "Original",
            chords: ["C"],
            romanNumerals: ["I"],
            key: "C",
            scale: "major",
            tempo: 120
        )
        
        let progressions = try dataManager.getAllProgressions()
        let progression = progressions.first!
        
        // Update it
        try dataManager.updateProgression(progression) { prog in
            prog.name = "Updated"
            prog.chords = ["C", "G"]
            prog.tempo = 140
        }
        
        let updated = try dataManager.getAllProgressions().first!
        XCTAssertEqual(updated.name, "Updated")
        XCTAssertEqual(updated.chords.count, 2)
        XCTAssertEqual(updated.tempo, 140)
    }
    
    func testDeleteProgression() throws {
        // Save progression
        _ = try dataManager.saveProgression(
            name: "To Delete",
            chords: ["C"],
            romanNumerals: ["I"],
            key: "C",
            scale: "major",
            tempo: 120
        )
        
        let progressions = try dataManager.getAllProgressions()
        XCTAssertEqual(progressions.count, 1)
        
        // Delete it
        try dataManager.deleteProgression(progressions.first!)
        
        let remaining = try dataManager.getAllProgressions()
        XCTAssertEqual(remaining.count, 0)
    }
    
    // MARK: - Practice Session Tests
    
    func testSavePracticeSession() throws {
        try dataManager.savePracticeSession(
            mode: .earTraining,
            score: 85,
            totalQuestions: 10,
            correctAnswers: 8,
            difficulty: .intermediate,
            duration: 300
        )
        
        let sessions = try dataManager.getRecentPracticeSessions(limit: 10)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.score, 85)
    }
    
    func testGetPracticeSessionsByMode() throws {
        // Save different types of sessions
        try dataManager.savePracticeSession(
            mode: .earTraining,
            score: 80,
            totalQuestions: 10,
            correctAnswers: 8,
            difficulty: .beginner,
            duration: 200
        )
        
        try dataManager.savePracticeSession(
            mode: .chordRecognition,
            score: 90,
            totalQuestions: 10,
            correctAnswers: 9,
            difficulty: .intermediate,
            duration: 250
        )
        
        try dataManager.savePracticeSession(
            mode: .earTraining,
            score: 85,
            totalQuestions: 10,
            correctAnswers: 8,
            difficulty: .beginner,
            duration: 220
        )
        
        let earTrainingSessions = try dataManager.getPracticeSessions(
            for: .earTraining,
            limit: 10
        )
        XCTAssertEqual(earTrainingSessions.count, 2)
    }
    
    func testCalculatePracticeStreak() throws {
        // TODO: Implement streak calculation based on consecutive days
        // For now, test that method exists and returns reasonable value
        let streak = try dataManager.getCurrentPracticeStreak()
        XCTAssertGreaterThanOrEqual(streak, 0)
    }
    
    // MARK: - Achievement Tests
    
    func testGetAllAchievements() throws {
        // Should initialize with default achievements
        let achievements = try dataManager.getAllAchievements()
        XCTAssertGreaterThan(achievements.count, 0)
    }
    
    func testUpdateAchievementProgress() throws {
        let achievements = try dataManager.getAllAchievements()
        guard let firstChordAchievement = achievements.first(where: { $0.identifier == "first_chord" }) else {
            XCTFail("First chord achievement should exist")
            return
        }
        
        try dataManager.updateAchievementProgress(
            identifier: "first_chord",
            newValue: 1
        )
        
        let updated = try dataManager.getAllAchievements()
        let updatedAchievement = updated.first(where: { $0.identifier == "first_chord" })!
        
        XCTAssertTrue(updatedAchievement.isUnlocked)
        XCTAssertEqual(updatedAchievement.currentValue, 1)
    }
    
    func testGetUnlockedAchievements() throws {
        // Update some achievements
        try dataManager.updateAchievementProgress(identifier: "first_chord", newValue: 1)
        
        let unlocked = try dataManager.getUnlockedAchievements()
        XCTAssertGreaterThan(unlocked.count, 0)
        XCTAssertTrue(unlocked.allSatisfy { $0.isUnlocked })
    }
    
    // MARK: - Statistics Tests
    
    func testGetPracticeStatistics() throws {
        // Add some practice sessions
        for i in 1...5 {
            try dataManager.savePracticeSession(
                mode: .earTraining,
                score: 70 + i * 5,
                totalQuestions: 10,
                correctAnswers: 7 + i / 2,
                difficulty: .beginner,
                duration: 300
            )
        }
        
        let stats = try dataManager.getPracticeStatistics()
        
        XCTAssertEqual(stats.totalSessions, 5)
        XCTAssertGreaterThan(stats.averageScore, 0)
        XCTAssertGreaterThan(stats.totalPracticeTime, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testHandleInvalidData() {
        // Test that invalid operations don't crash
        do {
            // Try to update non-existent achievement
            try dataManager.updateAchievementProgress(
                identifier: "non_existent",
                newValue: 1
            )
            // Should handle gracefully, either by creating or ignoring
        } catch {
            // Error is acceptable too
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Cleanup Tests
    
    func testClearAllData() throws {
        // Add some data
        try dataManager.addChordToHistory(
            symbol: "C",
            keyContext: "C",
            romanNumeral: "I",
            function: "Tonic"
        )
        
        try dataManager.saveProgression(
            name: "Test",
            chords: ["C"],
            romanNumerals: ["I"],
            key: "C",
            scale: "major",
            tempo: 120
        )
        
        // Clear all data
        try dataManager.clearAllData()
        
        // Verify everything is cleared
        let chords = try dataManager.getRecentChords(limit: 10)
        let progressions = try dataManager.getAllProgressions()
        
        XCTAssertEqual(chords.count, 0)
        XCTAssertEqual(progressions.count, 0)
    }
}