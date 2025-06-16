//
//  AchievementTests.swift
//  ChordLabTests
//
//  Unit tests for Achievement model
//

import XCTest
@testable import ChordLab

final class AchievementTests: XCTestCase {
    
    func testAchievementInitialization() {
        let achievement = Achievement(
            identifier: "first_chord",
            name: "First Chord",
            description: "Play your first chord",
            iconName: "music.note",
            targetValue: 1,
            category: .exploration
        )
        
        XCTAssertEqual(achievement.identifier, "first_chord")
        XCTAssertEqual(achievement.name, "First Chord")
        XCTAssertEqual(achievement.achievementDescription, "Play your first chord")
        XCTAssertEqual(achievement.iconName, "music.note")
        XCTAssertEqual(achievement.targetValue, 1)
        XCTAssertEqual(achievement.category, .exploration)
        XCTAssertEqual(achievement.currentValue, 0)
        XCTAssertFalse(achievement.isUnlocked)
        XCTAssertNil(achievement.unlockedAt)
        XCTAssertEqual(achievement.progress, 0.0)
    }
    
    func testProgressPercentageCalculation() {
        let achievement = Achievement(
            identifier: "chord_master",
            name: "Chord Master",
            description: "Play 100 different chords",
            iconName: "star",
            targetValue: 100,
            category: .exploration
        )
        
        // Test various progress states
        achievement.currentValue = 0
        XCTAssertEqual(achievement.progressPercentage, 0.0)
        
        achievement.currentValue = 25
        XCTAssertEqual(achievement.progressPercentage, 0.25)
        
        achievement.currentValue = 50
        XCTAssertEqual(achievement.progressPercentage, 0.5)
        
        achievement.currentValue = 100
        XCTAssertEqual(achievement.progressPercentage, 1.0)
        
        // Test overflow protection
        achievement.currentValue = 150
        XCTAssertEqual(achievement.progressPercentage, 1.0)
    }
    
    func testUnlockAchievement() {
        let achievement = Achievement(
            identifier: "test",
            name: "Test Achievement",
            description: "Test",
            iconName: "test",
            targetValue: 10,
            category: .practice
        )
        
        XCTAssertFalse(achievement.isUnlocked)
        XCTAssertNil(achievement.unlockedAt)
        
        achievement.unlock()
        
        XCTAssertTrue(achievement.isUnlocked)
        XCTAssertNotNil(achievement.unlockedAt)
        XCTAssertEqual(achievement.progress, 1.0)
        XCTAssertEqual(achievement.currentValue, achievement.targetValue)
    }
    
    func testUpdateProgressWithoutUnlocking() {
        let achievement = Achievement(
            identifier: "practice_streak",
            name: "Practice Streak",
            description: "Practice for 7 days",
            iconName: "flame",
            targetValue: 7,
            category: .streak
        )
        
        achievement.updateProgress(newValue: 3)
        
        XCTAssertEqual(achievement.currentValue, 3)
        XCTAssertEqual(achievement.progress, 3.0 / 7.0)
        XCTAssertFalse(achievement.isUnlocked)
        XCTAssertNil(achievement.unlockedAt)
    }
    
    func testUpdateProgressWithAutoUnlock() {
        let achievement = Achievement(
            identifier: "first_progression",
            name: "First Progression",
            description: "Create your first progression",
            iconName: "music.note.list",
            targetValue: 1,
            category: .creation
        )
        
        achievement.updateProgress(newValue: 1)
        
        XCTAssertEqual(achievement.currentValue, 1)
        XCTAssertEqual(achievement.progress, 1.0)
        XCTAssertTrue(achievement.isUnlocked)
        XCTAssertNotNil(achievement.unlockedAt)
    }
    
    func testUpdateProgressDoesNotExceedTarget() {
        let achievement = Achievement(
            identifier: "chord_explorer",
            name: "Chord Explorer",
            description: "Explore 50 chords",
            iconName: "magnifyingglass",
            targetValue: 50,
            category: .exploration
        )
        
        achievement.updateProgress(newValue: 75)
        
        XCTAssertEqual(achievement.currentValue, 50) // Should be capped at target
        XCTAssertEqual(achievement.progress, 1.0)
        XCTAssertTrue(achievement.isUnlocked)
    }
    
    func testAchievementCategoryEnumeration() {
        let categories = Achievement.AchievementCategory.allCases
        
        XCTAssertEqual(categories.count, 6)
        XCTAssertTrue(categories.contains(.practice))
        XCTAssertTrue(categories.contains(.exploration))
        XCTAssertTrue(categories.contains(.creation))
        XCTAssertTrue(categories.contains(.knowledge))
        XCTAssertTrue(categories.contains(.streak))
        XCTAssertTrue(categories.contains(.mastery))
    }
    
    func testZeroTargetValueHandling() {
        let achievement = Achievement(
            identifier: "invalid",
            name: "Invalid",
            description: "Invalid achievement",
            iconName: "xmark",
            targetValue: 0,
            category: .practice
        )
        
        XCTAssertEqual(achievement.progressPercentage, 0.0)
        
        achievement.updateProgress(newValue: 10)
        XCTAssertEqual(achievement.progressPercentage, 0.0) // Should handle division by zero
    }
}