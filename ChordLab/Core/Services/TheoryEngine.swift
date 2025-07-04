//
//  TheoryEngine.swift
//  ChordLab
//
//  Main music theory service using Tonic
//

import Foundation
import SwiftUI
import Tonic
import SwiftData

@Observable
final class TheoryEngine {
    // Current musical context
    var currentKey: String = "C"
    var currentScaleType: String = "major"
    var selectedChord: Chord?
    var chordHistory: [Chord] = []
    
    // Chord visualization state
    var visualizedChord: Chord? = nil  // Chord to highlight on piano
    
    // Progression building
    var currentProgression: [PlaybackChord] = []
    var savedProgressions: [LegacyProgression] = []
    var currentProgressionTempo: Int = 120  // BPM for current progression
    
    // Analysis settings
    var showRomanNumerals = true
    var showFunctions = true
    var showIntervals = false
    
    // MARK: - Types
    
    struct PlaybackChord: Identifiable {
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
    
    struct LegacyProgression: Identifiable, Codable {
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
    
//    func currentKeyPrefersFlats() -> Bool {
//        // Keys that typically use flats: F, Bb, Eb, Ab, Db, Gb
//        let flatKeys = ["F", "Bb", "B♭", "Eb", "E♭", "Ab", "A♭", "Db", "D♭", "Gb", "G♭"]
//        return flatKeys.contains(currentKey)
//    }
    
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
        
        // Key.noteSet returns notes in scale order starting from root
        // We need to maintain the order for educational purposes
        let scaleNotes = key.noteSet.array.sorted { note1, note2 in
            // Sort by distance from root to maintain scale order
            let root = key.root.canonicalNote
            let dist1 = (note1.pitch.midiNoteNumber - root.pitch.midiNoteNumber + 12) % 12
            let dist2 = (note2.pitch.midiNoteNumber - root.pitch.midiNoteNumber + 12) % 12
            return dist1 < dist2
        }.map { $0.noteClass }
        //print("Scale notes: \(scaleNotes)")
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
    
    public func determineFunction(romanNumeral: String) -> ChordFunction {
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
    
    // MARK: - Piano Chord Visualizer Support
    
    /// Returns the scale degree name for a given index (0-6)
    func getScaleDegreeName(for index: Int) -> String {
        let names = ["Tonic", "Supertonic", "Mediant", "Subdominant", "Dominant", "Submediant", "Leading Tone"]
        guard index >= 0 && index < names.count else { return "Unknown" }
        return names[index]
    }
    
    // MARK: - Precalculated Chord Data
    
    /// Precalculated diatonic triads for all major keys
    /// Structure: [key: [(chordType, notes)]] where notes are NoteClass values
    private let precalculatedTriads: [String: [(type: ChordType, notes: [NoteClass])]] = [
        "C": [
            (.major, [.C, .E, .G]),        // I - C Major
            (.minor, [.D, .F, .A]),        // ii - D minor
            (.minor, [.E, .G, .B]),        // iii - E minor
            (.major, [.F, .A, .C]),        // IV - F Major
            (.major, [.G, .B, .D]),        // V - G Major
            (.minor, [.A, .C, .E]),        // vi - A minor
            (.dim, [.B, .D, .F])           // vii° - B diminished
        ],
        "D": [
            (.major, [.D, .Fs, .A]),       // I - D Major
            (.minor, [.E, .G, .B]),        // ii - E minor
            (.minor, [.Fs, .A, .Cs]),      // iii - F# minor
            (.major, [.G, .B, .D]),        // IV - G Major
            (.major, [.A, .Cs, .E]),       // V - A Major
            (.minor, [.B, .D, .Fs]),       // vi - B minor
            (.dim, [.Cs, .E, .G])          // vii° - C# diminished
        ],
        "E": [
            (.major, [.E, .Gs, .B]),       // I - E Major
            (.minor, [.Fs, .A, .Cs]),      // ii - F# minor
            (.minor, [.Gs, .B, .Ds]),      // iii - G# minor
            (.major, [.A, .Cs, .E]),       // IV - A Major
            (.major, [.B, .Ds, .Fs]),      // V - B Major
            (.minor, [.Cs, .E, .Gs]),      // vi - C# minor
            (.dim, [.Ds, .Fs, .A])         // vii° - D# diminished
        ],
        "F": [
            (.major, [.F, .A, .C]),        // I - F Major
            (.minor, [.G, .Bb, .D]),       // ii - G minor
            (.minor, [.A, .C, .E]),        // iii - A minor
            (.major, [.Bb, .D, .F]),       // IV - Bb Major
            (.major, [.C, .E, .G]),        // V - C Major
            (.minor, [.D, .F, .A]),        // vi - D minor
            (.dim, [.E, .G, .Bb])          // vii° - E diminished
        ],
        "G": [
            (.major, [.G, .B, .D]),        // I - G Major
            (.minor, [.A, .C, .E]),        // ii - A minor
            (.minor, [.B, .D, .Fs]),       // iii - B minor
            (.major, [.C, .E, .G]),        // IV - C Major
            (.major, [.D, .Fs, .A]),       // V - D Major
            (.minor, [.E, .G, .B]),        // vi - E minor
            (.dim, [.Fs, .A, .C])          // vii° - F# diminished
        ],
        "A": [
            (.major, [.A, .Cs, .E]),       // I - A Major
            (.minor, [.B, .D, .Fs]),       // ii - B minor
            (.minor, [.Cs, .E, .Gs]),      // iii - C# minor
            (.major, [.D, .Fs, .A]),       // IV - D Major
            (.major, [.E, .Gs, .B]),       // V - E Major
            (.minor, [.Fs, .A, .Cs]),      // vi - F# minor
            (.dim, [.Gs, .B, .D])          // vii° - G# diminished
        ],
        "B": [
            (.major, [.B, .Ds, .Fs]),      // I - B Major
            (.minor, [.Cs, .E, .Gs]),      // ii - C# minor
            (.minor, [.Ds, .Fs, .As]),     // iii - D# minor
            (.major, [.E, .Gs, .B]),       // IV - E Major
            (.major, [.Fs, .As, .Cs]),     // V - F# Major
            (.minor, [.Gs, .B, .Ds]),      // vi - G# minor
            (.dim, [.As, .Cs, .E])         // vii° - A# diminished
        ]
    ]
    
    /// Precalculated diatonic seventh chords for all major keys
    private let precalculatedSevenths: [String: [(type: ChordType, notes: [NoteClass])]] = [
        "C": [
            (.maj7, [.C, .E, .G, .B]),     // Imaj7 - C Major 7
            (.min7, [.D, .F, .A, .C]),     // ii7 - D minor 7
            (.min7, [.E, .G, .B, .D]),     // iii7 - E minor 7
            (.maj7, [.F, .A, .C, .E]),     // IVmaj7 - F Major 7
            (.dom7, [.G, .B, .D, .F]),     // V7 - G7
            (.min7, [.A, .C, .E, .G]),     // vi7 - A minor 7
            (.halfDim7, [.B, .D, .F, .A])  // vii°7 - B half-dim 7
        ],
        "D": [
            (.maj7, [.D, .Fs, .A, .Cs]),   // Imaj7 - D Major 7
            (.min7, [.E, .G, .B, .D]),     // ii7 - E minor 7
            (.min7, [.Fs, .A, .Cs, .E]),   // iii7 - F# minor 7
            (.maj7, [.G, .B, .D, .Fs]),    // IVmaj7 - G Major 7
            (.dom7, [.A, .Cs, .E, .G]),    // V7 - A7
            (.min7, [.B, .D, .Fs, .A]),    // vi7 - B minor 7
            (.halfDim7, [.Cs, .E, .G, .B]) // vii°7 - C# half-dim 7
        ],
        "E": [
            (.maj7, [.E, .Gs, .B, .Ds]),   // Imaj7 - E Major 7
            (.min7, [.Fs, .A, .Cs, .E]),   // ii7 - F# minor 7
            (.min7, [.Gs, .B, .Ds, .Fs]),  // iii7 - G# minor 7
            (.maj7, [.A, .Cs, .E, .Gs]),   // IVmaj7 - A Major 7
            (.dom7, [.B, .Ds, .Fs, .A]),   // V7 - B7
            (.min7, [.Cs, .E, .Gs, .B]),   // vi7 - C# minor 7
            (.halfDim7, [.Ds, .Fs, .A, .Cs]) // vii°7 - D# half-dim 7
        ],
        "F": [
            (.maj7, [.F, .A, .C, .E]),     // Imaj7 - F Major 7
            (.min7, [.G, .Bb, .D, .F]),    // ii7 - G minor 7
            (.min7, [.A, .C, .E, .G]),     // iii7 - A minor 7
            (.maj7, [.Bb, .D, .F, .A]),    // IVmaj7 - Bb Major 7
            (.dom7, [.C, .E, .G, .Bb]),    // V7 - C7
            (.min7, [.D, .F, .A, .C]),     // vi7 - D minor 7
            (.halfDim7, [.E, .G, .Bb, .D]) // vii°7 - E half-dim 7
        ],
        "G": [
            (.maj7, [.G, .B, .D, .Fs]),    // Imaj7 - G Major 7
            (.min7, [.A, .C, .E, .G]),     // ii7 - A minor 7
            (.min7, [.B, .D, .Fs, .A]),    // iii7 - B minor 7
            (.maj7, [.C, .E, .G, .B]),     // IVmaj7 - C Major 7
            (.dom7, [.D, .Fs, .A, .C]),    // V7 - D7
            (.min7, [.E, .G, .B, .D]),     // vi7 - E minor 7
            (.halfDim7, [.Fs, .A, .C, .E]) // vii°7 - F# half-dim 7
        ],
        "A": [
            (.maj7, [.A, .Cs, .E, .Gs]),   // Imaj7 - A Major 7
            (.min7, [.B, .D, .Fs, .A]),    // ii7 - B minor 7
            (.min7, [.Cs, .E, .Gs, .B]),   // iii7 - C# minor 7
            (.maj7, [.D, .Fs, .A, .Cs]),   // IVmaj7 - D Major 7
            (.dom7, [.E, .Gs, .B, .D]),    // V7 - E7
            (.min7, [.Fs, .A, .Cs, .E]),   // vi7 - F# minor 7
            (.halfDim7, [.Gs, .B, .D, .Fs]) // vii°7 - G# half-dim 7
        ],
        "B": [
            (.maj7, [.B, .Ds, .Fs, .As]),  // Imaj7 - B Major 7
            (.min7, [.Cs, .E, .Gs, .B]),   // ii7 - C# minor 7
            (.min7, [.Ds, .Fs, .As, .Cs]), // iii7 - D# minor 7
            (.maj7, [.E, .Gs, .B, .Ds]),   // IVmaj7 - E Major 7
            (.dom7, [.Fs, .As, .Cs, .E]),  // V7 - F#7
            (.min7, [.Gs, .B, .Ds, .Fs]),  // vi7 - G# minor 7
            (.halfDim7, [.As, .Cs, .E, .Gs]) // vii°7 - A# half-dim 7
        ]
    ]
    
    /// Returns chord tone roles for visualization (root, third, fifth, and seventh if present)
    func getChordToneRoles(for chord: Chord) -> [(note: NoteClass, role: String)] {
        let notes = chord.noteClasses
        guard notes.count >= 3 else { return [] }
        
        var roles = [
            (notes[0], "Root"),
            (notes[1], "Third"),
            (notes[2], "Fifth")
        ]
        
        // Add seventh if present
        if notes.count >= 4 {
            roles.append((notes[3], "Seventh"))
        }
        
        return roles
    }
    
    /// Returns all diatonic triads with complete visualization data - FAST version using precalculated data
    func getDiatonicChordsWithAnalysis() -> [(chord: Chord, romanNumeral: String, function: ChordFunction, degreeName: String)] {
        // Use precalculated chords if available
        if let precalcData = precalculatedTriads[currentKey] {
            let romanNumerals = ["I", "ii", "iii", "IV", "V", "vi", "vii°"]
            let functions: [ChordFunction] = [.tonic, .supertonic, .mediant, .subdominant, .dominant, .submediant, .leadingTone]
            let degreeNames = ["Tonic", "Supertonic", "Mediant", "Subdominant", "Dominant", "Submediant", "Leading Tone"]
            
            return precalcData.enumerated().map { index, chordData in
                // Create chord directly from precalculated notes
                let root = chordData.notes[0]
                let chord = Chord(root, type: chordData.type)
                return (chord, romanNumerals[index], functions[index], degreeNames[index])
            }
        }
        
        // Fallback to calculation if key not in precalculated data
        let chords = getDiatonicChords()
        let romanNumerals = ["I", "ii", "iii", "IV", "V", "vi", "vii°"]
        let functions: [ChordFunction] = [.tonic, .supertonic, .mediant, .subdominant, .dominant, .submediant, .leadingTone]
        let degreeNames = ["Tonic", "Supertonic", "Mediant", "Subdominant", "Dominant", "Submediant", "Leading Tone"]
        
        return chords.enumerated().map { index, chord in
            (chord, romanNumerals[index], functions[index], degreeNames[index])
        }
    }
    
    /// Returns all diatonic seventh chords with complete visualization data - FAST version using precalculated data
    func getSeventhChordsWithAnalysis() -> [(chord: Chord, romanNumeral: String, function: ChordFunction, degreeName: String)] {
        // Use precalculated chords if available
        if let precalcData = precalculatedSevenths[currentKey] {
            let romanNumerals = ["Imaj7", "ii7", "iii7", "IVmaj7", "V7", "vi7", "vii°7"]
            let functions: [ChordFunction] = [.tonic, .supertonic, .mediant, .subdominant, .dominant, .submediant, .leadingTone]
            let degreeNames = ["Tonic", "Supertonic", "Mediant", "Subdominant", "Dominant", "Submediant", "Leading Tone"]
            
            return precalcData.enumerated().map { index, chordData in
                // Create chord directly from precalculated notes
                let root = chordData.notes[0]
                let chord = Chord(root, type: chordData.type)
                return (chord, romanNumerals[index], functions[index], degreeNames[index])
            }
        }
        
        // Fallback to calculation if key not in precalculated data
        let chords = getSeventhChords()
        let romanNumerals = ["Imaj7", "ii7", "iii7", "IVmaj7", "V7", "vi7", "vii°7"]
        let functions: [ChordFunction] = [.tonic, .supertonic, .mediant, .subdominant, .dominant, .submediant, .leadingTone]
        let degreeNames = ["Tonic", "Supertonic", "Mediant", "Subdominant", "Dominant", "Submediant", "Leading Tone"]
        
        return chords.enumerated().map { index, chord in
            (chord, romanNumerals[index], functions[index], degreeNames[index])
        }
    }
    
    /// Helper method for proper Roman numeral formatting with 7th chord symbols
    private func getRomanNumeralForSeventhChord(chord: Chord, index: Int) -> String {
        let baseRomanNumerals = ["I", "ii", "iii", "IV", "V", "vi", "vii°"]
        guard index < baseRomanNumerals.count else { return "" }
        
        let base = baseRomanNumerals[index]
        
        // Add appropriate 7th chord suffix
        switch chord.type {
        case .maj7:
            return index == 0 || index == 3 ? base + "maj7" : base + "7"
        case .min7:
            return base + "7"
        case .dom7:
            return base + "7"
        case .halfDim7:
            return base + "7"  // vii°7 or viiø7
        default:
            return base
        }
    }
    
    // MARK: - Progression Building
    
    func addChordToProgression(_ chord: Chord, duration: Double = 1.0) {
        let progressionChord = PlaybackChord(chord: chord, duration: duration)
        currentProgression.append(progressionChord)
        addToHistory(chord)
    }
    
    func removeFromProgression(at index: Int) {
        guard index < currentProgression.count else { return }
        currentProgression.remove(at: index)
    }
    
    func clearProgression() {
        currentProgression.removeAll()
        currentProgressionTempo = 120  // Reset to default
    }
    
    func reorderProgression(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex < currentProgression.count,
              destinationIndex <= currentProgression.count,
              sourceIndex != destinationIndex else { return }
        
        let chord = currentProgression.remove(at: sourceIndex)
        let adjustedDestination = destinationIndex > sourceIndex ? destinationIndex - 1 : destinationIndex
        currentProgression.insert(chord, at: adjustedDestination)
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
    /// Generate a properly formatted chord symbol
    var formattedSymbol: String {
        let rootName = root.description
        
        switch type {
        case .major:
            return rootName
        case .minor:
            return rootName + "m"
        case .dim:
            return rootName + "°"
        case .dim7:
            return rootName + "°7"
        case .halfDim7:
            return rootName + "ø7"
        case .aug:
            return rootName + "+"
        case .dom7:
            return rootName + "7"
        case .maj7:
            return rootName + "maj7"
        case .min7:
            return rootName + "m7"
        default:
            return description // Fallback to Tonic's description
        }
    }
    
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
        
        // Check exact matches first (for symbols that don't change with case)
        switch typeString {
        case "°7":
            chordType = .dim7
        case "°":
            chordType = .dim
        case "ø7", "ø":
            chordType = .halfDim7
        default:
            // Now check case-insensitive matches
            switch typeString.lowercased() {
            case "", "maj":
                chordType = .major
            case "m", "min":
                chordType = .minor
            case "dim":
                chordType = .dim
            case "dim7":
                chordType = .dim7
            case "aug", "+":
                chordType = .aug
            case "7", "dom7":
                chordType = .dom7
            case "maj7":
                chordType = .maj7
            case "m7", "min7":
                chordType = .min7
            case "hdim7", "m7b5":
                chordType = .halfDim7
            default:
                chordType = .major
            }
        }
        
        return Chord(root, type: chordType)
    }
}
