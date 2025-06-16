//
//  SwiftDataIntegrationTests.swift
//  ChordLabTests
//
//  Integration tests for SwiftData models
//

import XCTest
import SwiftData
@testable import ChordLab

@MainActor
final class SwiftDataIntegrationTests: XCTestCase {
    
    var container: ModelContainer!
    var context: ModelContext!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        
        do {
            container = try ModelContainer(
                for: UserData.self,
                     ChordHistory.self,
                     SavedProgression.self,
                     PracticeSession.self,
                     Achievement.self,
                configurations: config
            )
            context = container.mainContext
        } catch {
            XCTFail("Failed to create ModelContainer: \(error)")
        }
    }
    
    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }
    
    // MARK: - UserData Tests
    
    func testUserDataPersistence() throws {
        // Create and insert
        let userData = UserData(currentKey: "G", currentScale: "major", preferredTempo: 140)
        context.insert(userData)
        
        try context.save()
        
        // Fetch and verify
        let descriptor = FetchDescriptor<UserData>()
        let fetchedUsers = try context.fetch(descriptor)
        
        XCTAssertEqual(fetchedUsers.count, 1)
        XCTAssertEqual(fetchedUsers.first?.currentKey, "G")
        XCTAssertEqual(fetchedUsers.first?.currentScale, "major")
        XCTAssertEqual(fetchedUsers.first?.preferredTempo, 140)
    }
    
    func testUserDataUpdate() throws {
        // Create and insert
        let userData = UserData()
        context.insert(userData)
        try context.save()
        
        // Update
        userData.currentKey = "D"
        userData.currentScale = "minor"
        userData.soundEnabled = false
        try context.save()
        
        // Fetch and verify updates
        let descriptor = FetchDescriptor<UserData>()
        let fetchedUsers = try context.fetch(descriptor)
        
        XCTAssertEqual(fetchedUsers.first?.currentKey, "D")
        XCTAssertEqual(fetchedUsers.first?.currentScale, "minor")
        XCTAssertFalse(fetchedUsers.first?.soundEnabled ?? true)
    }
    
    // MARK: - ChordHistory Tests
    
    func testChordHistoryPersistence() throws {
        // Create multiple chord history entries
        let chords = [
            ChordHistory(chordSymbol: "C", keyContext: "C", romanNumeral: "I", chordFunction: "Tonic"),
            ChordHistory(chordSymbol: "Am", keyContext: "C", romanNumeral: "vi", chordFunction: "Submediant"),
            ChordHistory(chordSymbol: "F", keyContext: "C", romanNumeral: "IV", chordFunction: "Subdominant")
        ]
        
        for chord in chords {
            context.insert(chord)
        }
        try context.save()
        
        // Fetch and verify
        let descriptor = FetchDescriptor<ChordHistory>(sortBy: [SortDescriptor(\.viewedAt)])
        let fetchedChords = try context.fetch(descriptor)
        
        XCTAssertEqual(fetchedChords.count, 3)
        XCTAssertEqual(fetchedChords.map { $0.chordSymbol }, ["C", "Am", "F"])
    }
    
    func testChordHistoryFavorites() throws {
        // Create chords with some favorites
        let chord1 = ChordHistory(chordSymbol: "C", keyContext: "C")
        let chord2 = ChordHistory(chordSymbol: "G", keyContext: "C")
        chord2.isFavorite = true
        
        context.insert(chord1)
        context.insert(chord2)
        try context.save()
        
        // Fetch only favorites
        let descriptor = FetchDescriptor<ChordHistory>()
        let allChords = try context.fetch(descriptor)
        let favorites = allChords.filter { $0.isFavorite }
        
        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.chordSymbol, "G")
    }
    
    func testChordHistoryPlayCount() throws {
        let chord = ChordHistory(chordSymbol: "Dm", keyContext: "C")
        context.insert(chord)
        try context.save()
        
        // Increment play count
        chord.playCount += 1
        try context.save()
        
        // Fetch and verify
        let descriptor = FetchDescriptor<ChordHistory>()
        let fetchedChords = try context.fetch(descriptor)
        
        XCTAssertEqual(fetchedChords.first?.playCount, 1)
    }
    
    // MARK: - SavedProgression Tests
    
    func testSavedProgressionPersistence() throws {
        let progression = SavedProgression(
            name: "My First Progression",
            chords: ["C", "Am", "F", "G"],
            key: "C",
            scale: "major",
            tempo: 120
        )
        progression.romanNumerals = ["I", "vi", "IV", "V"]
        
        context.insert(progression)
        try context.save()
        
        // Fetch and verify
        let descriptor = FetchDescriptor<SavedProgression>()
        let fetchedProgressions = try context.fetch(descriptor)
        
        XCTAssertEqual(fetchedProgressions.count, 1)
        let fetched = fetchedProgressions.first!
        XCTAssertEqual(fetched.name, "My First Progression")
        XCTAssertEqual(fetched.chords, ["C", "Am", "F", "G"])
        XCTAssertEqual(fetched.romanNumerals, ["I", "vi", "IV", "V"])
    }
    
    func testSavedProgressionSorting() throws {
        // Create progressions with different dates
        let progression1 = SavedProgression(name: "First", chords: ["C"], key: "C")
        let progression2 = SavedProgression(name: "Second", chords: ["G"], key: "G")
        
        context.insert(progression1)
        Thread.sleep(forTimeInterval: 0.1) // Ensure different timestamps
        context.insert(progression2)
        try context.save()
        
        // Fetch sorted by creation date
        let descriptor = FetchDescriptor<SavedProgression>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let sorted = try context.fetch(descriptor)
        
        XCTAssertEqual(sorted.first?.name, "Second")
        XCTAssertEqual(sorted.last?.name, "First")
    }
    
    // MARK: - PracticeSession Tests
    
    func testPracticeSessionPersistence() throws {
        let session = PracticeSession(
            mode: .earTraining,
            score: 85,
            totalQuestions: 10,
            correctAnswers: 8,
            difficulty: .intermediate,
            duration: 300
        )
        
        context.insert(session)
        try context.save()
        
        // Fetch and verify
        let descriptor = FetchDescriptor<PracticeSession>()
        let sessions = try context.fetch(descriptor)
        
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.accuracy, 0.8)
    }
    
    func testPracticeSessionsByMode() throws {
        // Create sessions for different modes
        let modes: [PracticeSession.PracticeMode] = [.earTraining, .chordRecognition, .earTraining]
        
        for mode in modes {
            let session = PracticeSession(
                mode: mode,
                score: 80,
                totalQuestions: 10,
                correctAnswers: 8,
                difficulty: .beginner,
                duration: 200
            )
            context.insert(session)
        }
        try context.save()
        
        // Fetch only ear training sessions
        let descriptor = FetchDescriptor<PracticeSession>()
        let allSessions = try context.fetch(descriptor)
        let earTrainingSessions = allSessions.filter { $0.mode == .earTraining }
        
        XCTAssertEqual(earTrainingSessions.count, 2)
    }
    
    // MARK: - Achievement Tests
    
    func testAchievementPersistence() throws {
        let achievement = Achievement(
            identifier: "first_chord",
            name: "First Chord",
            description: "Play your first chord",
            iconName: "music.note",
            targetValue: 1,
            category: .exploration
        )
        
        context.insert(achievement)
        try context.save()
        
        // Fetch and verify
        let descriptor = FetchDescriptor<Achievement>()
        let achievements = try context.fetch(descriptor)
        
        XCTAssertEqual(achievements.count, 1)
        XCTAssertEqual(achievements.first?.identifier, "first_chord")
    }
    
    func testAchievementUnlocking() throws {
        let achievement = Achievement(
            identifier: "practice_master",
            name: "Practice Master",
            description: "Complete 10 practice sessions",
            iconName: "star",
            targetValue: 10,
            category: .practice
        )
        
        context.insert(achievement)
        try context.save()
        
        // Update progress
        achievement.updateProgress(newValue: 10)
        try context.save()
        
        // Fetch and verify unlock
        let descriptor = FetchDescriptor<Achievement>()
        let allAchievements = try context.fetch(descriptor)
        let unlockedAchievements = allAchievements.filter { $0.isUnlocked }
        
        XCTAssertEqual(unlockedAchievements.count, 1)
        XCTAssertNotNil(unlockedAchievements.first?.unlockedAt)
    }
    
    func testAchievementsByCategory() throws {
        // Create achievements in different categories
        let categories: [Achievement.AchievementCategory] = [.practice, .exploration, .practice]
        
        for (index, category) in categories.enumerated() {
            let achievement = Achievement(
                identifier: "test_\(index)",
                name: "Test \(index)",
                description: "Test achievement",
                iconName: "star",
                targetValue: 10,
                category: category
            )
            context.insert(achievement)
        }
        try context.save()
        
        // Fetch practice achievements
        let descriptor = FetchDescriptor<Achievement>()
        let allAchievements = try context.fetch(descriptor)
        let practiceAchievements = allAchievements.filter { $0.category == .practice }
        
        XCTAssertEqual(practiceAchievements.count, 2)
    }
    
    // MARK: - Relationship Tests
    
    func testMultipleModelInteraction() throws {
        // Create user data
        let userData = UserData(currentKey: "C", currentScale: "major")
        context.insert(userData)
        
        // Create chord history
        let chord = ChordHistory(chordSymbol: "C", keyContext: userData.currentKey)
        context.insert(chord)
        
        // Create practice session
        let session = PracticeSession(
            mode: .earTraining,
            score: 90,
            totalQuestions: 10,
            correctAnswers: 9,
            difficulty: .beginner,
            duration: 300
        )
        context.insert(session)
        
        // Create achievement
        let achievement = Achievement(
            identifier: "first_practice",
            name: "First Practice",
            description: "Complete first practice",
            iconName: "star",
            targetValue: 1,
            category: .practice
        )
        achievement.updateProgress(newValue: 1)
        context.insert(achievement)
        
        try context.save()
        
        // Verify all models saved
        XCTAssertEqual(try context.fetch(FetchDescriptor<UserData>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<ChordHistory>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<PracticeSession>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Achievement>()).count, 1)
    }
    
    // MARK: - Deletion Tests
    
    func testModelDeletion() throws {
        // Create and save multiple models
        let progression = SavedProgression(name: "Test", chords: ["C"], key: "C")
        context.insert(progression)
        try context.save()
        
        // Verify it exists
        XCTAssertEqual(try context.fetch(FetchDescriptor<SavedProgression>()).count, 1)
        
        // Delete
        context.delete(progression)
        try context.save()
        
        // Verify deletion
        XCTAssertEqual(try context.fetch(FetchDescriptor<SavedProgression>()).count, 0)
    }
}