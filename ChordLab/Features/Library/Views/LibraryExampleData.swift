//
//  LibraryExampleData.swift
//  ChordLab
//
//  Example progressions for testing
//

import Foundation
import SwiftData

extension SavedProgression {
    static var exampleProgressions: [SavedProgression] {
        [
            SavedProgression(
                name: "Classic ii-V-I",
                progressionChords: [
                    ProgressionChord(chordSymbol: "Dm7", romanNumeral: "ii7", noteNames: ["D", "F", "A", "C"], function: "Supertonic"),
                    ProgressionChord(chordSymbol: "G7", romanNumeral: "V7", noteNames: ["G", "B", "D", "F"], function: "Dominant"),
                    ProgressionChord(chordSymbol: "Cmaj7", romanNumeral: "Imaj7", noteNames: ["C", "E", "G", "B"], function: "Tonic")
                ],
                key: "C",
                tempo: 120
            ),
            
            SavedProgression(
                name: "Pop Progression",
                progressionChords: [
                    ProgressionChord(chordSymbol: "C", romanNumeral: "I", noteNames: ["C", "E", "G"], function: "Tonic"),
                    ProgressionChord(chordSymbol: "Am", romanNumeral: "vi", noteNames: ["A", "C", "E"], function: "Submediant"),
                    ProgressionChord(chordSymbol: "F", romanNumeral: "IV", noteNames: ["F", "A", "C"], function: "Subdominant"),
                    ProgressionChord(chordSymbol: "G", romanNumeral: "V", noteNames: ["G", "B", "D"], function: "Dominant")
                ],
                key: "C",
                tempo: 90
            ),
            
            SavedProgression(
                name: "Blues in A",
                progressionChords: [
                    ProgressionChord(chordSymbol: "A7", romanNumeral: "I7", noteNames: ["A", "C#", "E", "G"], function: "Tonic", duration: 4.0),
                    ProgressionChord(chordSymbol: "D7", romanNumeral: "IV7", noteNames: ["D", "F#", "A", "C"], function: "Subdominant", duration: 2.0),
                    ProgressionChord(chordSymbol: "A7", romanNumeral: "I7", noteNames: ["A", "C#", "E", "G"], function: "Tonic", duration: 2.0),
                    ProgressionChord(chordSymbol: "E7", romanNumeral: "V7", noteNames: ["E", "G#", "B", "D"], function: "Dominant", duration: 2.0),
                    ProgressionChord(chordSymbol: "D7", romanNumeral: "IV7", noteNames: ["D", "F#", "A", "C"], function: "Subdominant", duration: 1.0),
                    ProgressionChord(chordSymbol: "A7", romanNumeral: "I7", noteNames: ["A", "C#", "E", "G"], function: "Tonic", duration: 1.0)
                ],
                key: "A",
                tempo: 100
            )
        ]
    }
    
    static func createExampleData(in context: ModelContext) {
        for progression in exampleProgressions {
            progression.tags = ["Example", "Tutorial"]
            progression.isFavorite = Bool.random()
            progression.playCount = Int.random(in: 0...20)
            context.insert(progression)
        }
        
        try? context.save()
    }
}