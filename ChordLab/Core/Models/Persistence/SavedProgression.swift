//
//  SavedProgression.swift
//  ChordLab
//
//  User-created chord progressions
//

import Foundation
import SwiftData

@Model
final class SavedProgression {
    var id: UUID = UUID()
    var name: String
    var chords: [String] = []
    var romanNumerals: [String] = []
    var key: String
    var scale: String = "major"
    var tempo: Int = 120
    var timeSignature: String = "4/4"
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()
    var isFavorite: Bool = false
    var playCount: Int = 0
    var notes: String?
    
    init(name: String, chords: [String], key: String, scale: String = "major", tempo: Int = 120) {
        self.id = UUID()
        self.name = name
        self.chords = chords
        self.key = key
        self.scale = scale
        self.tempo = tempo
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}