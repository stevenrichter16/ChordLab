//
//  UserData.swift
//  ChordLab
//
//  User preferences and app state
//

import Foundation
import SwiftData

@Model
final class UserData {
    var id: UUID = UUID()
    var currentKey: String = "C"
    var currentScale: String = "major"
    var preferredTempo: Int = 120
    var lastLessonViewed: String?
    var practiceRemindersEnabled: Bool = true
    var soundEnabled: Bool = true
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()
    
    init(currentKey: String = "C", currentScale: String = "major", preferredTempo: Int = 120) {
        self.id = UUID()
        self.currentKey = currentKey
        self.currentScale = currentScale
        self.preferredTempo = preferredTempo
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}