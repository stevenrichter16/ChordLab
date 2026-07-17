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
    
    /// Create a SavedProgression from the current playback chords,
    /// preserving each chord's duration in beats
    func createProgressionData(
        from playbackChords: [PlaybackChord],
        name: String,
        tempo: Int
    ) -> SavedProgression {
        // Convert to our persisted ProgressionChord format
        let progressionChords = playbackChords.map { playback in
            let chordSymbol = playback.chord.formattedSymbol
            let romanNumeral = getRomanNumeral(for: chordSymbol)
            return ProgressionChord(
                chordSymbol: chordSymbol,
                romanNumeral: romanNumeral,
                noteNames: playback.chord.noteClasses.map { $0.description },
                function: determineFunction(romanNumeral: romanNumeral).rawValue,
                duration: playback.duration
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
        // A deliberately loaded progression must not be captioned as a
        // restored draft on the next Explore visit
        draftWasRestored = false

        // Update current key and scale
        setKey(progression.key, scaleType: progression.scale)
        
        // Update tempo
        currentProgressionTempo = progression.tempo
        
        // Convert ProgressionChord array back to playback chords,
        // keeping each chord's stored duration (clamped to stay positive
        // so a corrupt value can't stall or race the sequencer)
        currentProgression = progression.progressionChords.compactMap { progressionChord in
            Chord.parse(progressionChord.chordSymbol).map { chord in
                PlaybackChord(
                    chord: chord,
                    duration: max(progressionChord.duration, 0.25),
                    velocity: 80
                )
            }
        }
    }
    
    // MARK: - Progression Analysis
    
    /// Analyze a progression for patterns and characteristics
    func analyzeProgression(_ chords: [Chord]) -> ProgressionAnalysis {
        var patterns: [ProgressionPattern] = []
        var cadenceType: CadenceType?
        
        // Compare bare degrees so seventh-chord numerals ("ii7", "V7",
        // "Imaj7") match the same patterns as their triad forms
        if chords.count >= 3 {
            // Check for ii-V-I
            for i in 0..<(chords.count - 2) {
                let baseNumerals = [
                    baseNumeral(getRomanNumeral(for: chords[i].description)),
                    baseNumeral(getRomanNumeral(for: chords[i + 1].description)),
                    baseNumeral(getRomanNumeral(for: chords[i + 2].description))
                ]

                if baseNumerals == ["ii", "V", "I"] {
                    patterns.append(.iiVI)
                }
            }

            // Check for I-vi-IV-V
            if chords.count >= 4 {
                let firstFour = Array(chords.prefix(4))
                let baseNumerals = firstFour.map { baseNumeral(getRomanNumeral(for: $0.description)) }

                if baseNumerals == ["I", "vi", "IV", "V"] {
                    patterns.append(.IviIVV)
                }
            }
        }

        // Check cadence (last two chords)
        if chords.count >= 2 {
            let lastTwo = chords.suffix(2)
            let lastBaseNumerals = lastTwo.map { baseNumeral(getRomanNumeral(for: $0.description)) }

            switch lastBaseNumerals {
            case ["V", "I"]:
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
