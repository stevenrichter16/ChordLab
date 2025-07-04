//
//  TheoryEngine+Progressions.swift
//  ChordLab
//
//  TheoryEngine extensions for progression management
//

import Foundation
import Tonic
import SwiftData

extension TheoryEngine {
    
    // MARK: - Progression Creation
    
    /// Create a SavedProgression from current chord array
    func createProgressionData(
        from chords: [Chord],
        name: String,
        tempo: Int
    ) -> SavedProgression {
        // Convert Tonic Chords to our ProgressionChord format
        let progressionChords = chords.map { chord in
            let chordSymbol = chord.formattedSymbol
            let romanNumeral = getRomanNumeral(for: chordSymbol)
            return ProgressionChord(
                chordSymbol: chordSymbol,
                romanNumeral: romanNumeral,
                noteNames: chord.noteClasses.map { $0.description },
                function: determineFunction(romanNumeral: romanNumeral).rawValue,
                duration: 1.0 // Default duration
            )
        }
        
        // Create the SavedProgression
        let progression = SavedProgression(
            name: name,
            progressionChords: progressionChords,
            key: currentKey,
            scale: currentScaleType,
            tempo: tempo
        )
        
        return progression
    }
    
    // MARK: - Progression Loading
    
    /// Load a SavedProgression into the current context
    func loadProgression(_ progression: SavedProgression) {
        // Update current key and scale
        setKey(progression.key, scaleType: progression.scale)
        
        // Update tempo
        currentProgressionTempo = progression.tempo
        
        // Convert ProgressionChord array back to Tonic Chords
        let chords = progression.progressionChords.compactMap { progressionChord in
            Chord.parse(progressionChord.chordSymbol)
        }
        
        // Update current progression
        currentProgression = chords.map { chord in
            PlaybackChord(chord: chord, duration: 1.0, velocity: 80)
        }
    }
    
    // MARK: - Progression Analysis
    
    /// Analyze a progression for patterns and characteristics
    func analyzeProgression(_ chords: [Chord]) -> ProgressionAnalysis {
        var patterns: [ProgressionPattern] = []
        var cadenceType: CadenceType?
        
        // Check for common patterns
        if chords.count >= 3 {
            let chordSymbols = chords.map { $0.description }
            
            // Check for ii-V-I
            for i in 0..<(chords.count - 2) {
                let romanNumerals = [
                    getRomanNumeral(for: chords[i].description),
                    getRomanNumeral(for: chords[i + 1].description),
                    getRomanNumeral(for: chords[i + 2].description)
                ]
                
                if romanNumerals == ["ii", "V", "I"] || romanNumerals == ["ii7", "V7", "Imaj7"] {
                    patterns.append(.iiVI)
                }
            }
            
            // Check for I-vi-IV-V
            if chords.count >= 4 {
                let firstFour = Array(chords.prefix(4))
                let romanNumerals = firstFour.map { getRomanNumeral(for: $0.description) }
                
                if romanNumerals == ["I", "vi", "IV", "V"] {
                    patterns.append(.IviIVV)
                }
            }
        }
        
        // Check cadence (last two chords)
        if chords.count >= 2 {
            let lastTwo = chords.suffix(2)
            let lastRomanNumerals = lastTwo.map { getRomanNumeral(for: $0.description) }
            
            switch lastRomanNumerals {
            case ["V", "I"], ["V7", "I"]:
                cadenceType = .authentic
            case ["IV", "I"]:
                cadenceType = .plagal
            case ["V", "vi"]:
                cadenceType = .deceptive
            default:
                break
            }
        }
        
        // Calculate harmonic rhythm
        let harmonicRhythm = Double(chords.count) / 4.0 // Chords per measure (assuming 4/4)
        
        // Determine the primary pattern
        let primaryPattern = patterns.first ?? .other
        
        // Get roman numerals for all chords
        let romanNumerals = chords.map { getRomanNumeral(for: $0.description) }
        
        return ProgressionAnalysis(
            chords: chords,
            romanNumerals: romanNumerals,
            key: currentKey,
            pattern: primaryPattern,
            cadence: cadenceType,
            tonalCenter: currentKey,
            harmonicRhythm: harmonicRhythm > 1.0 ? "Dense" : "Regular"
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculateComplexity(_ chords: [Chord]) -> Double {
        var complexity = 0.0
        
        // Factor 1: Number of different chord types
        let uniqueChordTypes = Set(chords.map { $0.type })
        complexity += Double(uniqueChordTypes.count) * 0.2
        
        // Factor 2: Use of seventh chords
        let seventhChordCount = chords.filter { chord in
            [.maj7, .min7, .dom7, .halfDim7, .dim7].contains(chord.type)
        }.count
        complexity += Double(seventhChordCount) / Double(chords.count) * 0.3
        
        // Factor 3: Non-diatonic chords
        let diatonicChords = getDiatonicChords()
        let nonDiatonicCount = chords.filter { chord in
            !diatonicChords.contains(where: { $0.root == chord.root && $0.type == chord.type })
        }.count
        complexity += Double(nonDiatonicCount) / Double(chords.count) * 0.5
        
        return min(complexity, 1.0) // Normalize to 0-1
    }
}
