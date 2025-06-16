//
//  ProfileTabViewTests.swift
//  ChordLabTests
//
//  Tests for ProfileTabView
//

import XCTest
import SwiftUI
@testable import ChordLab

@MainActor
final class ProfileTabViewTests: XCTestCase {
    var dataManager: DataManager!
    
    override func setUp() {
        super.setUp()
        dataManager = DataManager(inMemory: true)
    }
    
    override func tearDown() {
        dataManager = nil
        super.tearDown()
    }
    
    func testProfileTabViewInitializes() {
        // Given
        let view = ProfileTabView()
            .environment(dataManager)
        
        // Then
        XCTAssertNotNil(view)
    }
    
    func testStatCardProperties() {
        // Given
        let stats = [
            ("Sessions", "42", "music.note.list"),
            ("Favorite Key", "G major", "key.fill"),
            ("Achievements", "10", "trophy.fill"),
            ("Time Practiced", "5h 30m", "clock.fill")
        ]
        
        for (title, value, icon) in stats {
            // When
            let card = StatCard(
                title: title,
                value: value,
                icon: icon
            )
            
            // Then
            XCTAssertEqual(card.title, title)
            XCTAssertEqual(card.value, value)
            XCTAssertEqual(card.icon, icon)
        }
    }
    
    func testAchievementBadgeUnlockedState() {
        // Given
        let unlockedBadge = AchievementBadge(
            icon: "star.fill",
            title: "First Steps",
            isUnlocked: true
        )
        
        // Then
        XCTAssertEqual(unlockedBadge.icon, "star.fill")
        XCTAssertEqual(unlockedBadge.title, "First Steps")
        XCTAssertTrue(unlockedBadge.isUnlocked)
    }
    
    func testAchievementBadgeLockedState() {
        // Given
        let lockedBadge = AchievementBadge(
            icon: "crown.fill",
            title: "Theory Master",
            isUnlocked: false
        )
        
        // Then
        XCTAssertEqual(lockedBadge.icon, "crown.fill")
        XCTAssertEqual(lockedBadge.title, "Theory Master")
        XCTAssertFalse(lockedBadge.isUnlocked)
    }
    
    func testMultipleAchievementBadges() {
        // Given
        let badges = [
            ("star.fill", "First Steps", true),
            ("flame.fill", "On Fire", true),
            ("crown.fill", "Theory Master", false),
            ("music.note", "Melody Maker", false)
        ]
        
        for (icon, title, isUnlocked) in badges {
            // When
            let badge = AchievementBadge(
                icon: icon,
                title: title,
                isUnlocked: isUnlocked
            )
            
            // Then
            XCTAssertEqual(badge.icon, icon)
            XCTAssertEqual(badge.title, title)
            XCTAssertEqual(badge.isUnlocked, isUnlocked)
        }
    }
}