//
//  TheoryEngine.swift
//  ChordLab
//
//  Main music theory service using Tonic
//

import Foundation
import SwiftUI
import Tonic

@Observable
final class TheoryEngine {
    // Current musical context
    var currentKey: String = "C"
    var currentScaleType: String = "major"
    var selectedChord: Chord?
    var chordHistory: [Chord] = []
    
    // Progression building
    var currentProgression: [ProgressionChord] = []
    var savedProgressions: [SavedProgression] = []
    
    // Analysis settings
    var showRomanNumerals = true
    var showFunctions = true
    var showIntervals = false
    
    // MARK: - Types
    
    struct ProgressionChord: Identifiable {
        let id = UUID()
        let chord: Chord
        let duration: Double
        let velocity: Int
        
        init(chord: Chord, duration: Double = 1.0, velocity: Int = 80) {
            self.chord = chord
            self.duration = duration
            self.velocity = velocity
        }
    }
    
    struct SavedProgression: Identifiable, Codable {
        var id = UUID()
        let name: String
        let key: String
        let chordSymbols: [String]
        let createdDate: Date
        var tags: [String]
    }
    
    struct ChordCategory: Identifiable {
        let id = UUID()
        let name: String
        let chords: [Chord]
    }
    
    // MARK: - Key Management
    
    // Computed property for the current Tonic Key object
    private var currentTonicKey: Key? {
        guard let rootNote = NoteClass(currentKey) else { return nil }
        let scale = getScaleFromType(currentScaleType)
        return Key(root: rootNote, scale: scale)
    }
    
    func setKey(_ key: String, scaleType: String) {
        currentKey = key
        currentScaleType = scaleType
        selectedChord = nil
    }
    
    // Helper method to convert scale type string to Tonic Scale
    private func getScaleFromType(_ scaleType: String) -> Scale {
        switch scaleType.lowercased() {
        case "major":
            return .major
        case "minor", "naturalminor":
            return .minor
        case "harmonicminor":
            return .harmonicMinor
        case "melodicminor":
            return .melodicMinor
        case "dorian":
            return .dorian
        case "phrygian":
            return .phrygian
        case "lydian":
            return .lydian
        case "mixolydian":
            return .mixolydian
        case "locrian":
            return .locrian
        default:
            return .major // Default to major
        }
    }
    
    func getCurrentScaleNotes() -> [NoteClass] {
        guard let key = currentTonicKey else { return [] }
        
        print("in getCurrentScaleNotes - key: \(key.root) \(key.scale)")
        
        // Key.noteSet returns notes in scale order starting from root
        // We need to maintain the order for educational purposes
        let scaleNotes = key.noteSet.array.sorted { note1, note2 in
            // Sort by distance from root to maintain scale order
            let root = key.root.canonicalNote
            let dist1 = (note1.pitch.midiNoteNumber - root.pitch.midiNoteNumber + 12) % 12
            let dist2 = (note2.pitch.midiNoteNumber - root.pitch.midiNoteNumber + 12) % 12
            return dist1 < dist2
        }.map { $0.noteClass }
        print("scaleNotes: \(scaleNotes.count): \(scaleNotes)")
        return scaleNotes
    }
    
    // New method to determine if current key prefers flats
    func currentKeyPrefersFlats() -> Bool {
        guard let key = currentTonicKey else { return false }
        
        // Use Tonic's built-in logic for determining accidental preference
        // Tonic automatically knows which keys traditionally use flats vs sharps
        // based on the circle of fifths and common music theory conventions
        return key.preferredAccidental == .flat
    }
    
    // New method to get the preferred accidental for the current key
    func getPreferredAccidental() -> Accidental {
        guard let key = currentTonicKey else { return .sharp }
        
        // Tonic's Key.preferredAccidental returns the accidental type
        // that should be used for chromatic notes in this key
        return key.preferredAccidental
    }
    
    func getScaleDegrees() -> [String] {
        return ["1", "2", "3", "4", "5", "6", "7"]
    }
    
    // MARK: - Chord Generation
    
    func getDiatonicChords() -> [Chord] {
        guard let key = currentTonicKey else { return [] }
        
        // Key.primaryTriads returns the diatonic triads in order
        return key.primaryTriads
    }
    
    func getSeventhChords() -> [Chord] {
        let scaleNotes = getCurrentScaleNotes()
        guard scaleNotes.count == 7 else { return [] }
        
        var chords: [Chord] = []
        
        // For seventh chords, we'll use the basic triad types with added sevenths
        let triadChords = getDiatonicChords()
        
        for (index, triad) in triadChords.enumerated() {
            // Create seventh chord based on the triad type
            let seventhType: ChordType
            switch triad.type {
            case .major:
                seventhType = index == 4 ? .dom7 : .maj7 // V7 is dominant
            case .minor:
                seventhType = .min7
            case .dim:
                seventhType = .halfDim7  // In diatonic context, it's half-diminished
            default:
                seventhType = triad.type
            }
            
            let root = triad.root
            chords.append(Chord(root, type: seventhType))
        }
        
        return chords
    }
    
    
    // MARK: - Chord Analysis
    
    func analyzeChord(_ chordSymbol: String) -> ChordAnalysis? {
        // For now, return a simple analysis
        // In a real implementation, this would do complex harmonic analysis
        guard let chord = Chord.parse(chordSymbol) else { return nil }
        
        let romanNumeral = getRomanNumeral(for: chordSymbol)
        let function = determineFunction(romanNumeral: romanNumeral)
        
        return ChordAnalysis(
            chord: chord,
            romanNumeral: romanNumeral,
            function: function,
            scale: Scale.major,
            isInKey: isDiatonicToCurrentKey(chord),
            commonProgressions: getCommonProgressions(romanNumeral: romanNumeral),
            voiceLeading: []
        )
    }
    
    func getRomanNumeral(for chordSymbol: String) -> String {
        guard let chord = Chord.parse(chordSymbol) else { return "?" }
        let chordRoot = chord.root
        
        let scaleNotes = getCurrentScaleNotes()
        if let degree = scaleNotes.firstIndex(of: chordRoot) {
            // Diatonic chord
            let roman = ["I", "II", "III", "IV", "V", "VI", "VII"][degree]
            
            // Lowercase for minor chords
            switch chord.type {
            case .minor, .min7:
                return roman.lowercased()
            case .dim, .dim7, .halfDim7:
                return roman.lowercased() + "°"
            default:
                return roman
            }
        } else {
            // Non-diatonic chord - check for borrowed chords
            // Get the chromatic distance from the root
            let rootPitch = currentKey == "C" ? 0 : noteClassIndex(NoteClass(currentKey)!)
            let chordPitch = noteClassIndex(chordRoot)
            let interval = (chordPitch - rootPitch + 12) % 12
            
            // Determine the degree and accidental
            var roman = ""
            var accidental = ""
            
            switch interval {
            case 0: roman = "I"
            case 1: roman = "II"; accidental = "♭"
            case 2: roman = "II"
            case 3: roman = "III"; accidental = "♭"
            case 4: roman = "III"
            case 5: roman = "IV"
            case 6: roman = "V"; accidental = "♭"
            case 7: roman = "V"
            case 8: roman = "VI"; accidental = "♭"
            case 9: roman = "VI"
            case 10: roman = "VII"; accidental = "♭"
            case 11: roman = "VII"
            default: roman = "?"
            }
            
            // Apply chord quality
            switch chord.type {
            case .minor, .min7:
                roman = roman.lowercased()
            case .dim, .dim7, .halfDim7:
                roman = roman.lowercased() + "°"
            default:
                break
            }
            
            return accidental + roman
        }
    }
    
    private func determineFunction(romanNumeral: String) -> ChordFunction {
        switch romanNumeral.uppercased() {
        case "I", "IMAJ7":
            return .tonic
        case "II", "IIM7":
            return .supertonic
        case "III", "IIIM7":
            return .mediant
        case "IV", "IVMAJ7":
            return .subdominant
        case "V", "V7":
            return .dominant
        case "VI", "VIM7":
            return .submediant
        case "VII", "VII°":
            return .leadingTone
        default:
            return .chromatic
        }
    }
    
    private func isDiatonicToCurrentKey(_ chord: Chord) -> Bool {
        let diatonicChords = getDiatonicChords()
        return diatonicChords.contains { $0.root == chord.root && $0.type == chord.type }
    }
    
    private func getCommonProgressions(romanNumeral: String) -> [String] {
        switch romanNumeral.uppercased() {
        case "I": return ["I - IV - V - I", "I - vi - IV - V", "I - V - vi - IV"]
        case "II": return ["ii - V - I", "I - ii - V", "IV - ii - V - I"]
        case "IV": return ["IV - V - I", "I - IV - I", "IV - iv - I"]
        case "V": return ["V - I", "ii - V - I", "IV - V - I"]
        case "VI": return ["vi - IV - I - V", "I - V - vi - IV", "vi - ii - V - I"]
        default: return []
        }
    }
    
    func getVoiceLeadingOptions(from chordSymbol: String) -> [VoiceLeadingOption] {
        guard let fromChord = Chord.parse(chordSymbol) else { return [] }
        
        var options: [VoiceLeadingOption] = []
        let diatonicChords = getDiatonicChords()
        
        for target in diatonicChords {
            let option = VoiceLeadingOption.calculate(from: fromChord, to: target)
            options.append(option)
        }
        
        return options.sorted { $0.smoothness < $1.smoothness }
    }
    
    // MARK: - Progression Analysis
    
    func analyzeProgression(_ chordSymbols: [String]) -> ProgressionAnalysis {
        let chords = chordSymbols.compactMap { Chord.parse($0) }
        let romanNumerals = chordSymbols.map { getRomanNumeral(for: $0) }
        
        let pattern = identifyPattern(romanNumerals: romanNumerals)
        let cadence = identifyCadence(romanNumerals: romanNumerals)
        
        return ProgressionAnalysis(
            chords: chords,
            romanNumerals: romanNumerals,
            key: currentKey,
            pattern: pattern,
            cadence: cadence,
            tonalCenter: currentKey,
            harmonicRhythm: "Regular"
        )
    }
    
    private func identifyPattern(romanNumerals: [String]) -> ProgressionPattern {
        let pattern = romanNumerals.joined(separator: "-")
        
        switch pattern {
        case "I-vi-IV-V":
            return .popRock
        case "I-V-vi-IV":
            return .popRock
        case "ii-V-I":
            return .iiVI
        case "I-IV-V":
            return .blues
        default:
            return .other
        }
    }
    
    private func identifyCadence(romanNumerals: [String]) -> CadenceType? {
        guard romanNumerals.count >= 2 else { return nil }
        
        let lastTwo = romanNumerals.suffix(2)
        let penultimate = lastTwo.first!
        let final = lastTwo.last!
        
        switch (penultimate, final) {
        case ("V", "I"), ("V7", "I"):
            return .authentic
        case ("IV", "I"):
            return .plagal
        case ("V", "vi"):
            return .deceptive
        case (_, "V"):
            return .half
        default:
            return nil
        }
    }
    
    // MARK: - Suggestions
    
    func getChordSuggestions(after progression: [String], limit: Int = 6) -> [Chord] {
        if progression.isEmpty {
            return Array(getDiatonicChords().prefix(limit))
        }
        
        // Simple suggestion based on common progressions
        guard let lastChord = progression.last else {
            return Array(getDiatonicChords().prefix(limit))
        }
        
        let romanNumeral = getRomanNumeral(for: lastChord)
        var suggestions: [Chord] = []
        
        // Add common next chords based on current chord
        switch romanNumeral.uppercased() {
        case "I":
            suggestions = getDiatonicChords().filter { chord in
                ["IV", "V", "vi", "ii"].contains(getRomanNumeral(for: chord.description).uppercased())
            }
        case "V":
            suggestions = getDiatonicChords().filter { chord in
                ["I", "vi"].contains(getRomanNumeral(for: chord.description).uppercased())
            }
        default:
            suggestions = getDiatonicChords()
        }
        
        return Array(suggestions.prefix(limit))
    }
    
    // MARK: - Helper Methods
    
    private func noteClassIndex(_ noteClass: NoteClass) -> Int {
        // Use the canonical note's pitch class
        return Int(noteClass.canonicalNote.pitch.pitchClass)
    }
    
    private func noteClassFromIndex(_ index: Int) -> NoteClass {
        // This is not ideal for enharmonic spelling
        // For now, prefer sharps for ascending chromatic notes
        let sharpNoteClasses: [NoteClass] = [
            NoteClass(.C),
            NoteClass(.C, accidental: .sharp),
            NoteClass(.D),
            NoteClass(.D, accidental: .sharp),
            NoteClass(.E),
            NoteClass(.F),
            NoteClass(.F, accidental: .sharp),
            NoteClass(.G),
            NoteClass(.G, accidental: .sharp),
            NoteClass(.A),
            NoteClass(.A, accidental: .sharp),
            NoteClass(.B)
        ]
        return sharpNoteClasses[index % 12]
    }
    
    // MARK: - Progression Building
    
    func addChordToProgression(_ chord: Chord, duration: Double = 1.0) {
        let progressionChord = ProgressionChord(chord: chord, duration: duration)
        currentProgression.append(progressionChord)
        addToHistory(chord)
    }
    
    func removeFromProgression(at index: Int) {
        guard index < currentProgression.count else { return }
        currentProgression.remove(at: index)
    }
    
    func clearProgression() {
        currentProgression.removeAll()
    }
    
    // MARK: - History
    
    private func addToHistory(_ chord: Chord) {
        chordHistory.append(chord)
        if chordHistory.count > 20 {
            chordHistory.removeFirst()
        }
    }
}

// MARK: - Extensions for missing Tonic functionality

extension Chord {
    /// Parse a chord from a string symbol
    static func parse(_ symbol: String) -> Chord? {
        // Simple chord parsing - in real app would be more sophisticated
        let symbol = symbol.trimmingCharacters(in: .whitespaces)
        
        // Extract root note
        var rootString = ""
        var typeString = ""
        
        for (index, char) in symbol.enumerated() {
            if index == 0 || (index == 1 && (char == "#" || char == "♯" || char == "b" || char == "♭")) {
                rootString.append(char)
            } else {
                typeString = String(symbol.suffix(from: symbol.index(symbol.startIndex, offsetBy: index)))
                break
            }
        }
        
        if rootString.isEmpty {
            return nil
        }
        
        guard let root = NoteClass(rootString) else { return nil }
        
        // Determine chord type from suffix
        let chordType: ChordType
        switch typeString.lowercased() {
        case "", "maj":
            chordType = .major
        case "m", "min":
            chordType = .minor
        case "dim":
            chordType = .dim
        case "°":
            chordType = .dim
        case "°7", "dim7":
            chordType = .dim7
        case "aug", "+":
            chordType = .aug
        case "7", "dom7":
            chordType = .dom7
        case "maj7", "M7":
            chordType = .maj7
        case "m7", "min7":
            chordType = .min7
        case "dim7", "°7":
            chordType = .dim7
        default:
            chordType = .major
        }
        
        return Chord(root, type: chordType)
    }
}
