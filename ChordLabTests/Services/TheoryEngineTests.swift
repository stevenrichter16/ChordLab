//
//  TheoryEngineTests.swift
//  ChordLabTests
//
//  Unit tests for TheoryEngine music theory calculations
//

import XCTest
import Tonic
@testable import ChordLab

final class TheoryEngineTests: XCTestCase {
    
    var theoryEngine: TheoryEngine!
    
    override func setUp() {
        super.setUp()
        theoryEngine = TheoryEngine()
    }
    
    override func tearDown() {
        theoryEngine = nil
        super.tearDown()
    }
    
    // MARK: - Scale and Key Tests
    
    func testGetScaleForAllMajorKeys() {
        // Test all 12 major keys with their expected scale notes
        let majorScales: [String: [String]] = [
            "C": ["C", "D", "E", "F", "G", "A", "B"],
            "G": ["G", "A", "B", "C", "D", "E", "F♯"],
            "D": ["D", "E", "F♯", "G", "A", "B", "C♯"],
            "A": ["A", "B", "C♯", "D", "E", "F♯", "G♯"],
            "E": ["E", "F♯", "G♯", "A", "B", "C♯", "D♯"],
            "B": ["B", "C♯", "D♯", "E", "F♯", "G♯", "A♯"],
            "F": ["F", "G", "A", "B♭", "C", "D", "E"],
            "B♭": ["B♭", "C", "D", "E♭", "F", "G", "A"],
            "E♭": ["E♭", "F", "G", "A♭", "B♭", "C", "D"],
            "A♭": ["A♭", "B♭", "C", "D♭", "E♭", "F", "G"],
            "D♭": ["D♭", "E♭", "F", "G♭", "A♭", "B♭", "C"],
            "G♭": ["G♭", "A♭", "B♭", "C♭", "D♭", "E♭", "F"]
        ]
        
        for (key, expectedNotes) in majorScales {
            theoryEngine.setKey(key, scaleType: "major")
            let scaleNotes = theoryEngine.getCurrentScaleNotes()
            
            XCTAssertEqual(scaleNotes.count, 7, "Scale for \(key) major should have 7 notes")
            
            for (index, note) in scaleNotes.enumerated() {
                XCTAssertEqual(note.description, expectedNotes[index],
                              "\(key) major scale: Note at position \(index + 1) should be \(expectedNotes[index]) but was \(note.description)")
            }
        }
    }
    
    func testGetScaleForAllMinorKeys() {
        // Test natural minor scales
        let minorScales: [String: [String]] = [
            "A": ["A", "B", "C", "D", "E", "F", "G"],
            "E": ["E", "F♯", "G", "A", "B", "C", "D"],
            "B": ["B", "C♯", "D", "E", "F♯", "G", "A"],
            "F♯": ["F♯", "G♯", "A", "B", "C♯", "D", "E"],
            "C♯": ["C♯", "D♯", "E", "F♯", "G♯", "A", "B"],
            "D": ["D", "E", "F", "G", "A", "B♭", "C"],
            "G": ["G", "A", "B♭", "C", "D", "E♭", "F"],
            "C": ["C", "D", "E♭", "F", "G", "A♭", "B♭"],
            "F": ["F", "G", "A♭", "B♭", "C", "D♭", "E♭"]
        ]
        
        for (key, expectedNotes) in minorScales {
            theoryEngine.setKey(key, scaleType: "minor")
            let scaleNotes = theoryEngine.getCurrentScaleNotes()
            
            XCTAssertEqual(scaleNotes.count, 7, "Scale for \(key) minor should have 7 notes")
            
            for (index, note) in scaleNotes.enumerated() {
                XCTAssertEqual(note.description, expectedNotes[index],
                              "\(key) minor scale: Note at position \(index + 1) should be \(expectedNotes[index]) but was \(note.description)")
            }
        }
    }
    
    // TODO: Re-enable when modal scale generation is properly implemented
    // This requires proper enharmonic spelling for each mode
    func DISABLED_testModalScales() {
        // Test all modal scales
        theoryEngine.setKey("C", scaleType: "dorian")
        let dorianNotes = theoryEngine.getCurrentScaleNotes().map { $0.description }
        XCTAssertEqual(dorianNotes, ["C", "D", "E♭", "F", "G", "A", "B♭"])
        
        theoryEngine.setKey("C", scaleType: "phrygian")
        let phrygianNotes = theoryEngine.getCurrentScaleNotes().map { $0.description }
        XCTAssertEqual(phrygianNotes, ["C", "D♭", "E♭", "F", "G", "A♭", "B♭"])
        
        theoryEngine.setKey("C", scaleType: "lydian")
        let lydianNotes = theoryEngine.getCurrentScaleNotes().map { $0.description }
        XCTAssertEqual(lydianNotes, ["C", "D", "E", "F♯", "G", "A", "B"])
        
        theoryEngine.setKey("C", scaleType: "mixolydian")
        let mixolydianNotes = theoryEngine.getCurrentScaleNotes().map { $0.description }
        XCTAssertEqual(mixolydianNotes, ["C", "D", "E", "F", "G", "A", "B♭"])
        
        theoryEngine.setKey("C", scaleType: "locrian")
        let locrianNotes = theoryEngine.getCurrentScaleNotes().map { $0.description }
        XCTAssertEqual(locrianNotes, ["C", "D♭", "E♭", "F", "G♭", "A♭", "B♭"])
    }
    
    // MARK: - Chord Generation Tests
    
    func testGenerateDiatonicChordsAllQualities() {
        // Test C major diatonic chords
        theoryEngine.setKey("C", scaleType: "major")
        let diatonicChords = theoryEngine.getDiatonicChords()
        
        let expectedChords = ["C", "Dm", "Em", "F", "G", "Am", "B°"]
        XCTAssertEqual(diatonicChords.count, 7)
        
        for (index, chord) in diatonicChords.enumerated() {
            XCTAssertEqual(chord.description, expectedChords[index],
                          "Diatonic chord at position \(index + 1) should be \(expectedChords[index]) but was \(chord.description)")
        }
        
        // Test A minor diatonic chords
        theoryEngine.setKey("A", scaleType: "minor")
        let minorDiatonicChords = theoryEngine.getDiatonicChords()
        
        let expectedMinorChords = ["Am", "B°", "C", "Dm", "Em", "F", "G"]
        for (index, chord) in minorDiatonicChords.enumerated() {
            XCTAssertEqual(chord.description, expectedMinorChords[index],
                          "A minor diatonic chord at position \(index + 1) should be \(expectedMinorChords[index]) but was \(chord.description)")
        }
    }
    
    func testGenerateSeventhChordsAllQualities() {
        theoryEngine.setKey("C", scaleType: "major")
        let seventhChords = theoryEngine.getSeventhChords()
        
        let expectedSevenths = ["Cmaj7", "Dm7", "Em7", "Fmaj7", "G7", "Am7", "Bø7"]
        XCTAssertEqual(seventhChords.count, 7)
        
        for (index, chord) in seventhChords.enumerated() {
            XCTAssertEqual(chord.description, expectedSevenths[index],
                          "Seventh chord at position \(index + 1) should be \(expectedSevenths[index]) but was \(chord.description)")
        }
    }
    
    // MARK: - Chord Analysis Tests
    
    func testAnalyzeAllDiatonicChords() {
        theoryEngine.setKey("C", scaleType: "major")
        
        let chordTests: [(symbol: String, roman: String, function: ChordFunction)] = [
            ("C", "I", .tonic),
            ("Dm", "ii", .supertonic),
            ("Em", "iii", .mediant),
            ("F", "IV", .subdominant),
            ("G", "V", .dominant),
            ("Am", "vi", .submediant),
            ("Bdim", "vii°", .leadingTone)
        ]
        
        for test in chordTests {
            let analysis = theoryEngine.analyzeChord(test.symbol)
            XCTAssertNotNil(analysis, "Analysis for \(test.symbol) should not be nil")
            XCTAssertEqual(analysis?.romanNumeral, test.roman,
                          "\(test.symbol) should be \(test.roman) but was \(analysis?.romanNumeral ?? "nil")")
            XCTAssertEqual(analysis?.function, test.function,
                          "\(test.symbol) should have function \(test.function) but was \(String(describing: analysis?.function))")
            XCTAssertTrue(analysis?.isInKey ?? false,
                         "\(test.symbol) should be in key of C major")
        }
    }
    
    // TODO: Re-enable when secondary dominant analysis is implemented
    // This requires detecting V/V, V/ii, etc. relationships
    func DISABLED_testAnalyzeSecondaryDominants() {
        theoryEngine.setKey("C", scaleType: "major")
        
        let secondaryDominants: [(symbol: String, roman: String)] = [
            ("D", "V/V"),    // V of G
            ("A", "V/vi"),   // V of Am
            ("E", "V/vi"),   // Also V of Am (should handle both major and dominant 7)
            ("B", "V/iii"),  // V of Em
            ("C7", "V/IV")   // V of F
        ]
        
        for test in secondaryDominants {
            let analysis = theoryEngine.analyzeChord(test.symbol)
            XCTAssertNotNil(analysis, "Analysis for \(test.symbol) should not be nil")
            XCTAssertEqual(analysis?.romanNumeral, test.roman,
                          "\(test.symbol) should be analyzed as \(test.roman) but was \(analysis?.romanNumeral ?? "nil")")
            XCTAssertEqual(analysis?.function, .secondaryDominant)
        }
    }
    
    func testAnalyzeBorrowedChords() {
        theoryEngine.setKey("C", scaleType: "major")
        
        let borrowedChords: [(symbol: String, roman: String)] = [
            ("Fm", "iv"),      // Borrowed from C minor
            ("B♭", "♭VII"),    // Borrowed from C minor
            ("A♭", "♭VI"),     // Borrowed from C minor
            ("E♭", "♭III"),    // Borrowed from C minor
            ("Gm", "v"),       // Borrowed from C minor
            ("D°", "ii°")    // Borrowed from C minor
        ]
        
        for test in borrowedChords {
            let analysis = theoryEngine.analyzeChord(test.symbol)
            XCTAssertNotNil(analysis, "Analysis for \(test.symbol) should not be nil")
            XCTAssertEqual(analysis?.romanNumeral, test.roman,
                          "\(test.symbol) should be analyzed as \(test.roman) but was \(analysis?.romanNumeral ?? "nil")")
            XCTAssertFalse(analysis?.isInKey ?? true,
                          "\(test.symbol) should NOT be in key of C major")
        }
    }
    
    // MARK: - Voice Leading Tests
    
    // TODO: Re-enable when voice leading calculation is refined
    // Current implementation needs more sophisticated smoothness scoring
    func DISABLED_testVoiceLeadingSmoothness() {
        // Test that voice leading correctly calculates smoothness
        let testCases: [(from: String, to: String, maxSmoothness: Int)] = [
            ("C", "G", 2),    // Common tone: G, smooth movement
            ("C", "Am", 1),   // Two common tones: C and E
            ("C", "F", 2),    // One common tone: C
            ("C", "Dm", 2),   // No common tones but close movement
            ("C", "F♯", 6)    // Tritone relationship, less smooth
        ]
        
        for test in testCases {
            let voiceLeadingOptions = theoryEngine.getVoiceLeadingOptions(from: test.from)
            let option = voiceLeadingOptions.first { $0.toChord.description == test.to }
            
            XCTAssertNotNil(option, "Should have voice leading from \(test.from) to \(test.to)")
            XCTAssertLessThanOrEqual(option?.smoothness ?? 999, test.maxSmoothness,
                                    "Voice leading from \(test.from) to \(test.to) should have smoothness ≤ \(test.maxSmoothness)")
        }
    }
    
    func testVoiceLeadingCommonTones() {
        let voiceLeadingOptions = theoryEngine.getVoiceLeadingOptions(from: "C")
        
        // Find specific transitions
        let toAm = voiceLeadingOptions.first { $0.toChord.description == "Am" }
        XCTAssertNotNil(toAm)
        XCTAssertEqual(toAm?.commonTones.count, 2, "C to Am should have 2 common tones (C and E)")
        
        let toG = voiceLeadingOptions.first { $0.toChord.description == "G" }
        XCTAssertNotNil(toG)
        XCTAssertEqual(toG?.commonTones.count, 1, "C to G should have 1 common tone (G)")
        
        let toF = voiceLeadingOptions.first { $0.toChord.description == "F" }
        XCTAssertNotNil(toF)
        XCTAssertEqual(toF?.commonTones.count, 1, "C to F should have 1 common tone (C)")
    }
    
    // MARK: - Progression Analysis Tests
    
    // TODO: Re-enable when progression pattern recognition is enhanced
    // Needs more sophisticated pattern matching beyond simple string comparison
    func DISABLED_testAnalyzeCommonProgressionPatterns() {
        theoryEngine.setKey("C", scaleType: "major")
        
        let progressionTests: [(chords: [String], pattern: ProgressionPattern, cadence: CadenceType?)] = [
            (["C", "Am", "F", "G"], .popRock, .authentic),
            (["C", "F", "G"], .blues, nil),
            (["Dm", "G", "C"], .iiVI, .authentic),
            (["C", "G", "Am", "F"], .popRock, .plagal),
            (["Am", "F", "C", "G"], .popRock, .half),
            (["C", "Dm", "Em", "F", "G", "Am", "Bdim", "C"], .other, .authentic)
        ]
        
        for test in progressionTests {
            let analysis = theoryEngine.analyzeProgression(test.chords)
            
            XCTAssertEqual(analysis.pattern, test.pattern,
                          "Progression \(test.chords) should be pattern \(test.pattern) but was \(analysis.pattern)")
            
            if let expectedCadence = test.cadence {
                XCTAssertEqual(analysis.cadence, expectedCadence,
                              "Progression \(test.chords) should have cadence \(expectedCadence) but was \(String(describing: analysis.cadence))")
            }
        }
    }
    
    func testProgressionRomanNumeralAnalysis() {
        theoryEngine.setKey("G", scaleType: "major")
        let progression = ["G", "Em", "C", "D"]
        let analysis = theoryEngine.analyzeProgression(progression)
        
        XCTAssertEqual(analysis.romanNumerals, ["I", "vi", "IV", "V"])
        XCTAssertEqual(analysis.chords.count, 4)
        XCTAssertEqual(analysis.key, "G")
    }
    
    // MARK: - Chord Suggestions Tests
    
    // TODO: Re-enable when chord suggestion algorithm is implemented
    // Requires music theory rules for chord progressions
    func DISABLED_testChordSuggestionsAfterTonic() {
        theoryEngine.setKey("C", scaleType: "major")
        let suggestions = theoryEngine.getChordSuggestions(after: ["C"])
        
        let suggestionSymbols = suggestions.map { $0.symbol }
        
        // Common progressions from I
        XCTAssertTrue(suggestionSymbols.contains("F"), "Should suggest IV after I")
        XCTAssertTrue(suggestionSymbols.contains("G"), "Should suggest V after I")
        XCTAssertTrue(suggestionSymbols.contains("Am"), "Should suggest vi after I")
        XCTAssertTrue(suggestionSymbols.contains("Dm"), "Should suggest ii after I")
        
        // Should be limited to reasonable number
        XCTAssertLessThanOrEqual(suggestions.count, 10)
    }
    
    // TODO: Re-enable when chord suggestion algorithm is implemented
    // Requires music theory rules for chord progressions
    func DISABLED_testChordSuggestionsWithLimit() {
        theoryEngine.setKey("C", scaleType: "major")
        
        let suggestions3 = theoryEngine.getChordSuggestions(after: ["C"], limit: 3)
        XCTAssertEqual(suggestions3.count, 3)
        
        let suggestions5 = theoryEngine.getChordSuggestions(after: ["C"], limit: 5)
        XCTAssertEqual(suggestions5.count, 5)
        
        let suggestionsUnlimited = theoryEngine.getChordSuggestions(after: ["C"], limit: 20)
        XCTAssertGreaterThan(suggestionsUnlimited.count, 5)
    }
    
    // MARK: - Scale Degree Tests
    
    func testGetScaleDegreesAllNotes() {
        theoryEngine.setKey("C", scaleType: "major")
        let degrees = theoryEngine.getScaleDegrees()
        
        XCTAssertEqual(degrees, ["1", "2", "3", "4", "5", "6", "7"])
        
        // Test with different key to ensure it's not hardcoded
        theoryEngine.setKey("G", scaleType: "major")
        let gDegrees = theoryEngine.getScaleDegrees()
        XCTAssertEqual(gDegrees, ["1", "2", "3", "4", "5", "6", "7"])
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testInvalidChordAnalysis() {
        theoryEngine.setKey("C", scaleType: "major")
        
        let invalidAnalysis = theoryEngine.analyzeChord("XYZ")
        XCTAssertNil(invalidAnalysis, "Invalid chord should return nil analysis")
        
        let emptyAnalysis = theoryEngine.analyzeChord("")
        XCTAssertNil(emptyAnalysis, "Empty chord should return nil analysis")
    }
    
    func testEmptyProgressionAnalysis() {
        let emptyAnalysis = theoryEngine.analyzeProgression([])
        
        XCTAssertEqual(emptyAnalysis.chords.count, 0)
        XCTAssertEqual(emptyAnalysis.romanNumerals.count, 0)
        XCTAssertEqual(emptyAnalysis.pattern, .other)
        XCTAssertNil(emptyAnalysis.cadence)
    }
    
    func testKeyChangeResetsSelectedChord() {
        theoryEngine.setKey("C", scaleType: "major")
        theoryEngine.selectedChord = Chord.C
        
        XCTAssertNotNil(theoryEngine.selectedChord)
        
        theoryEngine.setKey("G", scaleType: "major")
        XCTAssertNil(theoryEngine.selectedChord, "Changing key should clear selected chord")
    }
}