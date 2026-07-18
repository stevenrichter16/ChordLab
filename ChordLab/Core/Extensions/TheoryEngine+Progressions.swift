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
    
    // MARK: - Transposition

    /// Re-renders a saved progression into a new key by mapping each chord's
    /// roman-numeral degree through the target key's diatonic sets, so the
    /// spelling always follows the destination key (F# major gets E#°, flat
    /// keys keep their flats) and durations are preserved. Returns nil when
    /// any chord has no diatonic degree in the source key (borrowed or
    /// chromatic chords can't be re-rendered this way yet).
    static func transposedProgressionChords(
        _ storedChords: [ProgressionChord],
        fromKey sourceKey: String,
        toKey targetKey: String,
        scaleType: String = "major"
    ) -> [ProgressionChord]? {
        // Throwaway engines so transposing never touches app-wide key state
        let source = TheoryEngine()
        source.setKey(sourceKey, scaleType: scaleType)
        let target = TheoryEngine()
        target.setKey(targetKey, scaleType: scaleType)

        let sourceTriads = source.getDiatonicChordsWithAnalysis()
        let targetTriads = target.getDiatonicChordsWithAnalysis()
        let targetSevenths = target.getSeventhChordsWithAnalysis()
        guard sourceTriads.count == 7, targetTriads.count == 7, targetSevenths.count == 7 else {
            return nil
        }

        let sourceBases = sourceTriads.map { source.baseNumeral($0.romanNumeral) }

        var result: [ProgressionChord] = []
        for stored in storedChords {
            // Legacy rows may lack a numeral; derive it from the symbol
            let numeral = stored.romanNumeral.isEmpty
                ? source.getRomanNumeral(for: stored.chordSymbol)
                : stored.romanNumeral

            guard let degree = sourceBases.firstIndex(of: source.baseNumeral(numeral)) else {
                return nil
            }

            let entry = numeral.contains("7") ? targetSevenths[degree] : targetTriads[degree]
            result.append(ProgressionChord(
                chordSymbol: entry.chord.formattedSymbol,
                romanNumeral: entry.romanNumeral,
                noteNames: entry.chord.noteClasses.map { $0.description },
                function: entry.function.rawValue,
                duration: stored.duration
            ))
        }
        return result
    }

    // MARK: - Progression Analysis
    
    /// Analyze a progression for patterns and characteristics
    func analyzeProgression(_ chords: [Chord]) -> ProgressionAnalysis {
        var patterns: [ProgressionPattern] = []
        var cadenceType: CadenceType?

        // Compare bare degrees so seventh-chord numerals ("ii7", "V7",
        // "Imaj7") match the same patterns as their triad forms
        let romanNumerals = chords.map { getRomanNumeral(for: $0.description) }
        let base = romanNumerals.map(baseNumeral)

        // Whole-form shapes first so they win the primary-pattern slot
        if base == ["I", "I", "I", "I", "IV", "IV", "I", "I", "V", "IV", "I", "V"] {
            patterns.append(.blues)
        }

        if base.count >= 8,
           Array(base.prefix(8)) == ["I", "V", "vi", "iii", "IV", "I", "IV", "V"] {
            patterns.append(.pachelbel)
        }

        if base.count >= 4 {
            let firstFour = Array(base.prefix(4))
            if firstFour == ["I", "vi", "IV", "V"] {
                patterns.append(.IviIVV)
            } else if firstFour == ["I", "V", "vi", "IV"] {
                patterns.append(.IVivIV)
            }
        }

        // ii-V-I anywhere in the progression
        if base.count >= 3 {
            for i in 0..<(base.count - 2) {
                if base[i] == "ii" && base[i + 1] == "V" && base[i + 2] == "I" {
                    patterns.append(.iiVI)
                }
            }
        }

        // Cadence from the last two chords; any stop on V is a half cadence
        if base.count >= 2 {
            switch (base[base.count - 2], base[base.count - 1]) {
            case ("V", "I"):
                cadenceType = .authentic
            case ("IV", "I"):
                cadenceType = .plagal
            case ("V", "vi"):
                cadenceType = .deceptive
            case (_, "V"):
                cadenceType = .half
            default:
                break
            }
        }

        // Calculate harmonic rhythm
        let harmonicRhythm = Double(chords.count) / 4.0 // Chords per measure (assuming 4/4)

        // Determine the primary pattern
        let primaryPattern = patterns.first ?? .other

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
