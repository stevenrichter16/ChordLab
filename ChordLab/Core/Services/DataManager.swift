//
//  DataManager.swift
//  ChordLab
//
//  SwiftData persistence manager
//

import Foundation
import SwiftData

@Observable
@MainActor
final class DataManager {
    let container: ModelContainer
    let context: ModelContext
    let isInMemory: Bool
    
    init(inMemory: Bool = false) {
        self.isInMemory = inMemory
        
        do {
            let schema = Schema([
                UserData.self,
                ChordHistory.self,
                SavedProgression.self,
                PracticeSession.self,
                Achievement.self
            ])
            
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: inMemory
            )
            
            container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            
            context = container.mainContext
            
            // Initialize default data
            initializeDefaultData()
            
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    // MARK: - User Data
    
    func getOrCreateUserData() throws -> UserData {
        let descriptor = FetchDescriptor<UserData>()
        let users = try context.fetch(descriptor)
        
        if let userData = users.first {
            return userData
        } else {
            let newUserData = UserData()
            context.insert(newUserData)
            try context.save()
            return newUserData
        }
    }
    
    func updateUserData(_ update: (UserData) -> Void) throws {
        let userData = try getOrCreateUserData()
        update(userData)
        userData.modifiedAt = Date()
        try context.save()
    }
    
    // MARK: - Chord History
    
    func addChordToHistory(symbol: String, keyContext: String, romanNumeral: String? = nil, function: String? = nil) throws {
        let chord = ChordHistory(
            chordSymbol: symbol,
            keyContext: keyContext,
            romanNumeral: romanNumeral,
            chordFunction: function
        )
        context.insert(chord)
        try context.save()
    }
    
    func getRecentChords(limit: Int) throws -> [ChordHistory] {
        var descriptor = FetchDescriptor<ChordHistory>(
            sortBy: [SortDescriptor(\.viewedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }
    
    func getFavoriteChords() throws -> [ChordHistory] {
        // Fetch all chord history and filter favorites in memory
        let descriptor = FetchDescriptor<ChordHistory>(
            sortBy: [SortDescriptor(\.viewedAt, order: .reverse)]
        )
        let allChords = try context.fetch(descriptor)
        return allChords.filter { $0.isFavorite }
    }
    
    func toggleChordFavorite(_ chord: ChordHistory) throws {
        chord.isFavorite.toggle()
        try context.save()
    }
    
    // MARK: - Progressions
    
    func saveProgression(name: String, chords: [String], romanNumerals: [String], key: String, scale: String, tempo: Int) throws -> UUID {
        let progression = SavedProgression(
            name: name,
            chords: chords,
            key: key,
            scale: scale,
            tempo: tempo
        )
        progression.romanNumerals = romanNumerals
        
        context.insert(progression)
        try context.save()
        
        return progression.id
    }
    
    func getAllProgressions() throws -> [SavedProgression] {
        let descriptor = FetchDescriptor<SavedProgression>(
            sortBy: [SortDescriptor(\.dateCreated, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    func updateProgression(_ progression: SavedProgression, update: (SavedProgression) -> Void) throws {
        update(progression)
        progression.dateModified = Date()
        try context.save()
    }
    
    func deleteProgression(_ progression: SavedProgression) throws {
        context.delete(progression)
        try context.save()
    }
    
    // MARK: - Practice Sessions
    
    func savePracticeSession(mode: PracticeSession.PracticeMode, score: Int, totalQuestions: Int, correctAnswers: Int, difficulty: PracticeSession.PracticeDifficulty, duration: TimeInterval) throws {
        let session = PracticeSession(
            mode: mode,
            score: score,
            totalQuestions: totalQuestions,
            correctAnswers: correctAnswers,
            difficulty: difficulty,
            duration: duration
        )
        
        context.insert(session)
        try context.save()
    }
    
    func getRecentPracticeSessions(limit: Int) throws -> [PracticeSession] {
        var descriptor = FetchDescriptor<PracticeSession>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }
    
    func getPracticeSessions(for mode: PracticeSession.PracticeMode, limit: Int) throws -> [PracticeSession] {
        // Fetch all sessions and filter in memory due to SwiftData predicate limitations with enums
        var descriptor = FetchDescriptor<PracticeSession>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit * 2 // Fetch more to ensure we have enough after filtering
        
        let allSessions = try context.fetch(descriptor)
        return Array(allSessions.filter { $0.mode == mode }.prefix(limit))
    }
    
    func getCurrentPracticeStreak() throws -> Int {
        // Simple implementation - counts consecutive days with practice
        let sessions = try getRecentPracticeSessions(limit: 30)
        
        guard !sessions.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        for _ in 0..<30 {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let hasPractice = sessions.contains { session in
                session.completedAt >= dayStart && session.completedAt < dayEnd
            }
            
            if hasPractice {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else if calendar.isDateInToday(currentDate) {
                // Today doesn't have practice yet, check yesterday
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Achievements
    
    func getAllAchievements() throws -> [Achievement] {
        let descriptor = FetchDescriptor<Achievement>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }
    
    func getUnlockedAchievements() throws -> [Achievement] {
        // Fetch all achievements and filter unlocked ones in memory
        let descriptor = FetchDescriptor<Achievement>(
            sortBy: [SortDescriptor(\.unlockedAt, order: .reverse)]
        )
        let allAchievements = try context.fetch(descriptor)
        return allAchievements.filter { $0.isUnlocked }
    }
    
    func updateAchievementProgress(identifier: String, newValue: Int) throws {
        // Fetch all achievements and filter by identifier
        let descriptor = FetchDescriptor<Achievement>()
        let allAchievements = try context.fetch(descriptor)
        
        if let achievement = allAchievements.first(where: { $0.identifier == identifier }) {
            achievement.updateProgress(newValue: newValue)
            try context.save()
        }
    }
    
    // MARK: - Statistics
    
    struct PracticeStatistics {
        let totalSessions: Int
        let averageScore: Double
        let totalPracticeTime: TimeInterval
        let favoriteMode: PracticeSession.PracticeMode?
    }
    
    func getPracticeStatistics() throws -> PracticeStatistics {
        let sessions = try context.fetch(FetchDescriptor<PracticeSession>())
        
        let totalSessions = sessions.count
        let averageScore = sessions.isEmpty ? 0 : Double(sessions.map { $0.score }.reduce(0, +)) / Double(sessions.count)
        let totalPracticeTime = sessions.map { $0.duration }.reduce(0, +)
        
        // Find favorite mode
        let modeCounts = Dictionary(grouping: sessions, by: { $0.mode })
            .mapValues { $0.count }
        let favoriteMode = modeCounts.max(by: { $0.value < $1.value })?.key
        
        return PracticeStatistics(
            totalSessions: totalSessions,
            averageScore: averageScore,
            totalPracticeTime: totalPracticeTime,
            favoriteMode: favoriteMode
        )
    }
    
    // MARK: - Data Management
    
    func clearAllData() throws {
        // Delete all entities
        try context.delete(model: UserData.self)
        try context.delete(model: ChordHistory.self)
        try context.delete(model: SavedProgression.self)
        try context.delete(model: PracticeSession.self)
        try context.delete(model: Achievement.self)
        
        try context.save()
        
        // Reinitialize default data
        initializeDefaultData()
    }
    
    // MARK: - Private Methods
    
    private func initializeDefaultData() {
        do {
            // Check if achievements exist
            let achievementCount = try context.fetchCount(FetchDescriptor<Achievement>())
            
            if achievementCount == 0 {
                createDefaultAchievements()
            }
            
            // Ensure user data exists
            _ = try getOrCreateUserData()
            
        } catch {
            print("Failed to initialize default data: \(error)")
        }
    }
    
    private func createDefaultAchievements() {
        let defaultAchievements = [
            (id: "first_chord", name: "First Chord", desc: "Play your first chord", icon: "music.note", target: 1, category: Achievement.AchievementCategory.exploration),
            (id: "chord_explorer", name: "Chord Explorer", desc: "Explore 50 different chords", icon: "magnifyingglass", target: 50, category: .exploration),
            (id: "chord_master", name: "Chord Master", desc: "Explore 200 different chords", icon: "star.circle", target: 200, category: .exploration),
            (id: "first_progression", name: "First Progression", desc: "Create your first progression", icon: "music.note.list", target: 1, category: .creation),
            (id: "progression_builder", name: "Progression Builder", desc: "Create 10 progressions", icon: "hammer", target: 10, category: .creation),
            (id: "first_practice", name: "First Practice", desc: "Complete your first practice session", icon: "graduationcap", target: 1, category: .practice),
            (id: "practice_streak_7", name: "Week Warrior", desc: "Practice for 7 days in a row", icon: "flame", target: 7, category: .streak),
            (id: "practice_streak_30", name: "Monthly Master", desc: "Practice for 30 days in a row", icon: "flame.fill", target: 30, category: .streak),
            (id: "ear_training_pro", name: "Golden Ears", desc: "Score 90% or higher in 10 ear training sessions", icon: "ear", target: 10, category: .mastery),
            (id: "theory_expert", name: "Theory Expert", desc: "Complete all theory lessons", icon: "book.fill", target: 20, category: .knowledge)
        ]
        
        for achievement in defaultAchievements {
            let newAchievement = Achievement(
                identifier: achievement.id,
                name: achievement.name,
                description: achievement.desc,
                iconName: achievement.icon,
                targetValue: achievement.target,
                category: achievement.category
            )
            context.insert(newAchievement)
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to create default achievements: \(error)")
        }
    }
}
