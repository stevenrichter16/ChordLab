//
//  Achievement.swift
//  ChordLab
//
//  User achievements and progress tracking
//

import Foundation
import SwiftData

@Model
final class Achievement {
    var id: UUID = UUID()
    var identifier: String
    var name: String
    var achievementDescription: String
    var iconName: String
    var unlockedAt: Date?
    var progress: Double = 0.0
    var targetValue: Int
    var currentValue: Int = 0
    var category: AchievementCategory
    var isUnlocked: Bool = false
    
    enum AchievementCategory: String, Codable, CaseIterable {
        case practice = "Practice"
        case exploration = "Exploration"
        case creation = "Creation"
        case knowledge = "Knowledge"
        case streak = "Streak"
        case mastery = "Mastery"
    }
    
    var progressPercentage: Double {
        guard targetValue > 0 else { return 0 }
        return min(Double(currentValue) / Double(targetValue), 1.0)
    }
    
    init(identifier: String, name: String, description: String, iconName: String, targetValue: Int, category: AchievementCategory) {
        self.id = UUID()
        self.identifier = identifier
        self.name = name
        self.achievementDescription = description
        self.iconName = iconName
        self.targetValue = targetValue
        self.category = category
    }
    
    func unlock() {
        self.isUnlocked = true
        self.unlockedAt = Date()
        self.progress = 1.0
        self.currentValue = targetValue
    }
    
    func updateProgress(newValue: Int) {
        self.currentValue = min(newValue, targetValue)
        self.progress = progressPercentage
        
        if currentValue >= targetValue && !isUnlocked {
            unlock()
        }
    }
}