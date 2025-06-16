//
//  ChordHistory.swift
//  ChordLab
//
//  Track recently viewed and favorite chords
//

import Foundation
import SwiftData

@Model
final class ChordHistory {
    var id: UUID = UUID()
    var chordSymbol: String
    var keyContext: String
    var romanNumeral: String?
    var chordFunction: String?
    var viewedAt: Date = Date()
    var isFavorite: Bool = false
    var playCount: Int = 0
    
    init(chordSymbol: String, keyContext: String, romanNumeral: String? = nil, chordFunction: String? = nil) {
        self.id = UUID()
        self.chordSymbol = chordSymbol
        self.keyContext = keyContext
        self.romanNumeral = romanNumeral
        self.chordFunction = chordFunction
        self.viewedAt = Date()
    }
}