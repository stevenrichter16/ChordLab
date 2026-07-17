//
//  DataManager.swift
//  ChordLab
//
//  SwiftData persistence manager
//

import Foundation
import SwiftData
import Tonic

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
                Achievement.self,
                MissedQuestion.self
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
    
    // MARK: - Progression Draft

    /// Snapshots the current in-memory progression so it survives restarts.
    /// An empty progression clears the stored draft.
    func saveDraftProgression(from engine: TheoryEngine) throws {
        let userData = try getOrCreateUserData()

        if engine.currentProgression.isEmpty {
            userData.draftProgressionData = nil
        } else {
            let draft = ProgressionDraft(
                chordSymbols: engine.currentProgression.map { $0.chord.formattedSymbol },
                durations: engine.currentProgression.map { $0.duration },
                key: engine.currentKey,
                scale: engine.currentScaleType,
                tempo: engine.currentProgressionTempo,
                savedAt: Date()
            )
            userData.draftProgressionData = try? JSONEncoder().encode(draft)
        }

        userData.modifiedAt = Date()
        try context.save()
    }

    /// Restores a saved draft into the engine; returns true when something
    /// was restored. Drafts older than 7 days are discarded so a weeks-old
    /// experiment doesn't ambush the user.
    @discardableResult
    func loadDraftProgression(into engine: TheoryEngine) throws -> Bool {
        let userData = try getOrCreateUserData()

        guard let data = userData.draftProgressionData,
              let draft = try? JSONDecoder().decode(ProgressionDraft.self, from: data),
              !draft.chordSymbols.isEmpty else { return false }

        guard Date().timeIntervalSince(draft.savedAt) < 7 * 24 * 3600 else {
            userData.draftProgressionData = nil
            try context.save()
            return false
        }

        engine.setKey(draft.key, scaleType: draft.scale)
        engine.currentProgressionTempo = draft.tempo
        engine.currentProgression = draft.chordSymbols.enumerated().compactMap { index, symbol in
            Chord.parse(symbol).map { chord in
                TheoryEngine.PlaybackChord(
                    chord: chord,
                    duration: index < draft.durations.count ? max(draft.durations[index], 0.25) : 1.0
                )
            }
        }

        return !engine.currentProgression.isEmpty
    }

    // MARK: - Lessons

    func getCompletedLessonIDs() throws -> Set<String> {
        Set(try getOrCreateUserData().completedLessons)
    }

    func recordLessonViewed(_ lessonID: String) throws {
        try updateUserData { userData in
            userData.lastLessonViewed = lessonID
        }
    }

    /// Marks a lesson complete (idempotent) and advances the theory_expert achievement
    func markLessonCompleted(_ lessonID: String) throws {
        let userData = try getOrCreateUserData()
        guard !userData.completedLessons.contains(lessonID) else { return }

        userData.completedLessons.append(lessonID)
        userData.modifiedAt = Date()
        try context.save()

        try updateAchievementProgress(identifier: "theory_expert", newValue: userData.completedLessons.count)
    }

    /// Keeps an achievement's target in sync with the actual content count
    /// (e.g. theory_expert was seeded before the lesson curriculum existed)
    func syncAchievementTarget(identifier: String, target: Int) throws {
        let allAchievements = try context.fetch(FetchDescriptor<Achievement>())
        guard let achievement = allAchievements.first(where: { $0.identifier == identifier }),
              achievement.targetValue != target else { return }

        achievement.targetValue = target
        achievement.updateProgress(newValue: achievement.currentValue)
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
    
    /// Saves a completed practice session and updates every achievement
    /// that practice activity can advance (session counts, streaks, mastery).
    func recordPracticeSession(mode: PracticeSession.PracticeMode, score: Int, totalQuestions: Int, correctAnswers: Int, difficulty: PracticeSession.PracticeDifficulty, duration: TimeInterval) throws {
        try savePracticeSession(
            mode: mode,
            score: score,
            totalQuestions: totalQuestions,
            correctAnswers: correctAnswers,
            difficulty: difficulty,
            duration: duration
        )

        let totalSessions = try context.fetchCount(FetchDescriptor<PracticeSession>())
        try updateAchievementProgress(identifier: "first_practice", newValue: totalSessions)

        let streak = try getCurrentPracticeStreak()
        try updateAchievementProgress(identifier: "practice_streak_7", newValue: streak)
        try updateAchievementProgress(identifier: "practice_streak_30", newValue: streak)

        if mode == .earTraining {
            let allSessions = try context.fetch(FetchDescriptor<PracticeSession>())
            let highScoringEarSessions = allSessions
                .filter { $0.mode == .earTraining && $0.score >= 90 }
                .count
            try updateAchievementProgress(identifier: "ear_training_pro", newValue: highScoringEarSessions)
        }
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
        // Counts consecutive days with at least one practice session.
        // Fetch by date window, not session count — a count-limited fetch
        // undercounts streaks as soon as users play multiple sessions per day.
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let cutoff = calendar.date(byAdding: .day, value: -366, to: today) else { return 0 }

        let descriptor = FetchDescriptor<PracticeSession>(
            predicate: #Predicate { $0.completedAt >= cutoff }
        )
        let sessions = try context.fetch(descriptor)
        let practiceDays = Set(sessions.map { calendar.startOfDay(for: $0.completedAt) })

        guard !practiceDays.isEmpty else { return 0 }

        var day = today
        // No practice yet today doesn't break a streak still alive from yesterday
        if !practiceDays.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }

        var streak = 0
        while practiceDays.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }

        return streak
    }
    
    // MARK: - Missed Questions (review queue)

    /// Queues a wrongly-answered question for later review.
    /// Deduplicates on (prompt, correct answer, stimulus chord): repeat misses
    /// bump the counter. The chord is part of the key because ear-training
    /// questions share one prompt across many different chords.
    func recordMissedQuestion(from question: PracticeQuestion, mode: PracticeSession.PracticeMode) throws {
        let all = try context.fetch(FetchDescriptor<MissedQuestion>())
        let chordSymbol = question.chord?.formattedSymbol

        if let existing = all.first(where: {
            $0.prompt == question.prompt
                && $0.correctAnswer == question.correctAnswer
                && $0.chordSymbol == chordSymbol
        }) {
            existing.timesMissed += 1
            existing.lastMissedAt = Date()
        } else {
            let missed = MissedQuestion(
                prompt: question.prompt,
                options: question.options,
                correctIndex: question.correctIndex,
                keyName: question.keyName,
                chordSymbol: question.chord?.formattedSymbol,
                progressionSymbols: question.progression.map { $0.formattedSymbol },
                mode: mode
            )
            context.insert(missed)
        }

        try context.save()
    }

    /// Oldest-missed first, so review naturally spaces out repeats
    func getMissedQuestions(limit: Int) throws -> [MissedQuestion] {
        var descriptor = FetchDescriptor<MissedQuestion>(
            sortBy: [SortDescriptor(\.lastMissedAt, order: .forward)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    func missedQuestionCount() throws -> Int {
        try context.fetchCount(FetchDescriptor<MissedQuestion>())
    }

    /// Removes a question from the review queue after a correct review answer
    func resolveMissedQuestion(prompt: String, correctAnswer: String, chordSymbol: String?) throws {
        let all = try context.fetch(FetchDescriptor<MissedQuestion>())
        for item in all
        where item.prompt == prompt
            && item.correctAnswer == correctAnswer
            && item.chordSymbol == chordSymbol {
            context.delete(item)
        }
        try context.save()
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
        try context.delete(model: MissedQuestion.self)
        
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
