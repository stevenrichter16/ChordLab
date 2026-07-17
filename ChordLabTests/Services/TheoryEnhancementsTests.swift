//
//  TheoryEnhancementsTests.swift
//  ChordLabTests
//
//  Tests for seventh-chord Roman numeral analysis, robust function
//  detection, chord voicing, and the practice question generators
//

import XCTest
import Tonic
@testable import ChordLab

final class TheoryEnhancementsTests: XCTestCase {
    var theoryEngine: TheoryEngine!

    override func setUp() {
        super.setUp()
        theoryEngine = TheoryEngine()
        theoryEngine.setKey("C", scaleType: "major")
    }

    override func tearDown() {
        theoryEngine = nil
        super.tearDown()
    }

    // MARK: - getRomanNumeral seventh-chord suffixes

    func testRomanNumeralsForSeventhChordsInCMajor() {
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "Cmaj7"), "Imaj7")
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "Dm7"), "ii7")
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "Em7"), "iii7")
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "Fmaj7"), "IVmaj7")
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "G7"), "V7")
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "Am7"), "vi7")
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "Bø7"), "viiø7")
    }

    func testTriadRomanNumeralsUnchanged() {
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "C"), "I")
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "Dm"), "ii")
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "B°"), "vii°")
    }

    // MARK: - determineFunction with quality suffixes

    func testDetermineFunctionHandlesSeventhSuffixes() {
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "Imaj7"), .tonic)
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "ii7"), .supertonic)
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "iii7"), .mediant)
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "IVmaj7"), .subdominant)
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "V7"), .dominant)
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "vi7"), .submediant)
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "vii°7"), .leadingTone)
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "viiø7"), .leadingTone)
    }

    func testDetermineFunctionKeepsChromaticCases() {
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "♭III"), .chromatic)
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "♭VI"), .chromatic)
        XCTAssertEqual(theoryEngine.determineFunction(romanNumeral: "V/V"), .chromatic)
    }

    // MARK: - Chord.parse unicode accidentals

    func testParseUnicodeAccidentalRoots() {
        XCTAssertEqual(Chord.parse("B♭")?.root, NoteClass(.B, accidental: .flat))
        XCTAssertEqual(Chord.parse("B♭")?.type, .major)
        XCTAssertEqual(Chord.parse("F♯m")?.root, NoteClass(.F, accidental: .sharp))
        XCTAssertEqual(Chord.parse("F♯m")?.type, .minor)
        XCTAssertEqual(Chord.parse("E♭maj7")?.type, .maj7)
    }

    func testParseEdgeEnharmonicSpellings() {
        // F# major's vii chord is rooted on E# — these spellings must parse
        // or saved progressions in sharp keys silently drop chords
        XCTAssertEqual(Chord.parse("E♯ø7")?.root, NoteClass(.E, accidental: .sharp))
        XCTAssertEqual(Chord.parse("E♯ø7")?.type, .halfDim7)
        XCTAssertEqual(Chord.parse("E#°")?.type, .dim)
        XCTAssertEqual(Chord.parse("B♯m")?.root, NoteClass(.B, accidental: .sharp))
        XCTAssertEqual(Chord.parse("Cb")?.root, NoteClass(.C, accidental: .flat))
        XCTAssertEqual(Chord.parse("Fb")?.root, NoteClass(.F, accidental: .flat))
    }

    func testAllDiatonicSymbolsRoundTripInEveryKey() {
        let allKeys = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]

        for key in allKeys {
            let engine = TheoryEngine()
            engine.setKey(key, scaleType: "major")

            let entries = engine.getDiatonicChordsWithAnalysis() + engine.getSeventhChordsWithAnalysis()
            for entry in entries {
                let symbol = entry.chord.formattedSymbol
                let parsed = Chord.parse(symbol)
                XCTAssertNotNil(parsed, "\(symbol) (in \(key) major) should parse")
                XCTAssertEqual(parsed?.root, entry.chord.root, "Root of \(symbol) should round-trip")
                XCTAssertEqual(parsed?.type, entry.chord.type, "Type of \(symbol) should round-trip")
            }
        }
    }

    func testFormattedSymbolRoundTrip() {
        let chords = [
            Chord(NoteClass(.B, accidental: .flat), type: .major),
            Chord(NoteClass(.F, accidental: .sharp), type: .min7),
            Chord(NoteClass(.E, accidental: .flat), type: .maj7),
            Chord(.G, type: .dom7)
        ]

        for chord in chords {
            let parsed = Chord.parse(chord.formattedSymbol)
            XCTAssertNotNil(parsed, "Should round-trip \(chord.formattedSymbol)")
            XCTAssertEqual(parsed?.root, chord.root, "Root should round-trip for \(chord.formattedSymbol)")
            XCTAssertEqual(parsed?.type, chord.type, "Type should round-trip for \(chord.formattedSymbol)")
        }
    }

    // MARK: - AudioEngine voicing

    func testVoicedNotesAscendStrictly() {
        let audioEngine = AudioEngine()
        let chords = [
            Chord(.C, type: .major),
            Chord(.G, type: .dom7),        // wraps: G-B-D-F
            Chord(.B, type: .halfDim7),    // wraps early: B-D-F-A
            Chord(.F, type: .maj7),
            Chord(.A, type: .min7)
        ]

        for chord in chords {
            let notes = audioEngine.voicedNotes(for: chord)
            XCTAssertEqual(notes.count, chord.noteClasses.count)

            let midiNumbers = notes.map { $0.pitch.midiNoteNumber }
            for index in 1..<midiNumbers.count {
                XCTAssertLessThan(
                    midiNumbers[index - 1],
                    midiNumbers[index],
                    "\(chord.formattedSymbol) voicing should ascend, got \(midiNumbers)"
                )
            }
        }
    }

    func testChordSlotDurationPolicy() {
        let audioEngine = AudioEngine()

        // Interior chords stop just short of their slot
        XCTAssertEqual(audioEngine.chordSlotDuration(interval: 1.0, isLast: false), 0.9, accuracy: 0.0001)
        XCTAssertEqual(audioEngine.chordSlotDuration(interval: 0.3, isLast: false), 0.27, accuracy: 0.0001)

        // The final chord always gets room to ring, even at fast tempos
        XCTAssertEqual(audioEngine.chordSlotDuration(interval: 0.3, isLast: true), 1.2, accuracy: 0.0001)
        XCTAssertEqual(audioEngine.chordSlotDuration(interval: 4.0, isLast: true), 3.6, accuracy: 0.0001)
    }

    // MARK: - Practice question generators

    func testEarTrainingQuestionGeneration() {
        for difficulty in PracticeSession.PracticeDifficulty.allCases {
            let questions = PracticeQuestionGenerator.earTrainingQuestions(count: 10, difficulty: difficulty)
            XCTAssertEqual(questions.count, 10)

            let pool = PracticeQuestionGenerator.qualityPool(for: difficulty)
            for question in questions {
                XCTAssertNotNil(question.chord)
                XCTAssertEqual(question.options.count, pool.count)
                XCTAssertTrue(question.correctIndex < question.options.count)
                XCTAssertEqual(question.chord?.type, pool[question.correctIndex].type)
            }
        }
    }

    func testChordRecognitionQuestionGeneration() {
        for difficulty in PracticeSession.PracticeDifficulty.allCases {
            let questions = PracticeQuestionGenerator.chordRecognitionQuestions(count: 10, difficulty: difficulty)
            XCTAssertEqual(questions.count, 10)

            for question in questions {
                XCTAssertNotNil(question.chord)
                XCTAssertEqual(question.options.count, 4, "Should offer 4 options at \(difficulty.rawValue)")
                XCTAssertEqual(Set(question.options).count, question.options.count, "Options must be unique")
                XCTAssertTrue(question.correctIndex < question.options.count)
                XCTAssertEqual(question.options[question.correctIndex], question.chord?.formattedSymbol)
            }
        }
    }

    func testProgressionQuestionGeneration() {
        for difficulty in PracticeSession.PracticeDifficulty.allCases {
            let questions = PracticeQuestionGenerator.progressionQuestions(count: 6, difficulty: difficulty)
            XCTAssertEqual(questions.count, 6)

            for question in questions {
                XCTAssertEqual(question.progression.count, 4, "Progressions should have 4 chords")
                XCTAssertEqual(question.options.count, 4)
                XCTAssertEqual(Set(question.options).count, question.options.count)
                XCTAssertTrue(question.correctIndex < question.options.count)
            }
        }
    }

    func testTheoryQuizQuestionGeneration() {
        for difficulty in PracticeSession.PracticeDifficulty.allCases {
            let questions = PracticeQuestionGenerator.theoryQuizQuestions(count: 9, difficulty: difficulty)
            XCTAssertEqual(questions.count, 9)

            for question in questions {
                XCTAssertFalse(question.prompt.isEmpty)
                XCTAssertEqual(question.options.count, 4)
                XCTAssertEqual(Set(question.options).count, question.options.count)
                XCTAssertTrue(question.correctIndex < question.options.count)
            }
        }
    }

    // MARK: - Base numerals & progression analysis

    func testBaseNumeralStripsQualitySuffixes() {
        XCTAssertEqual(theoryEngine.baseNumeral("ii7"), "ii")
        XCTAssertEqual(theoryEngine.baseNumeral("V7"), "V")
        XCTAssertEqual(theoryEngine.baseNumeral("Imaj7"), "I")
        XCTAssertEqual(theoryEngine.baseNumeral("IVmaj7"), "IV")
        XCTAssertEqual(theoryEngine.baseNumeral("viiø7"), "vii°")
        XCTAssertEqual(theoryEngine.baseNumeral("vii°7"), "vii°")
        XCTAssertEqual(theoryEngine.baseNumeral("vii°"), "vii°")
        XCTAssertEqual(theoryEngine.baseNumeral("♭VII7"), "♭VII")
        XCTAssertEqual(theoryEngine.baseNumeral("I+"), "I")
        XCTAssertEqual(theoryEngine.baseNumeral("ii"), "ii")
        XCTAssertEqual(theoryEngine.baseNumeral("I"), "I")
    }

    func testSeventhChordProgressionAnalysisBySymbols() {
        let analysis = theoryEngine.analyzeProgression(["Dm7", "G7", "Cmaj7"])
        XCTAssertEqual(analysis.pattern, .iiVI)
        XCTAssertEqual(analysis.cadence, .authentic)
    }

    func testSeventhChordProgressionAnalysisByChords() {
        let chords = [
            Chord(.D, type: .min7),
            Chord(.G, type: .dom7),
            Chord(.C, type: .maj7)
        ]
        let analysis = theoryEngine.analyzeProgression(chords)
        XCTAssertEqual(analysis.pattern, .iiVI)
        XCTAssertEqual(analysis.cadence, .authentic)
    }

    func testTriadProgressionAnalysisUnchanged() {
        let analysis = theoryEngine.analyzeProgression(["Dm", "G", "C"])
        XCTAssertEqual(analysis.pattern, .iiVI)
        XCTAssertEqual(analysis.cadence, .authentic)
    }

    func testChordOverloadDetectsGlossaryPatterns() {
        // I-V-vi-IV (Axis of Awesome) badges as its own pattern
        let axis = theoryEngine.analyzeProgression([
            Chord(.C, type: .major), Chord(.G, type: .major),
            Chord(.A, type: .minor), Chord(.F, type: .major)
        ])
        XCTAssertEqual(axis.pattern, .IVivIV)

        // Ending on V is a half cadence
        let hang = theoryEngine.analyzeProgression([
            Chord(.C, type: .major), Chord(.F, type: .major), Chord(.G, type: .major)
        ])
        XCTAssertEqual(hang.cadence, .half)

        // Pachelbel's eight-chord loop
        let canon = theoryEngine.analyzeProgression([
            Chord(.C, type: .major), Chord(.G, type: .major),
            Chord(.A, type: .minor), Chord(.E, type: .minor),
            Chord(.F, type: .major), Chord(.C, type: .major),
            Chord(.F, type: .major), Chord(.G, type: .major)
        ])
        XCTAssertEqual(canon.pattern, .pachelbel)
        XCTAssertEqual(canon.cadence, .half)

        // The 12-bar form (all-triad rendering)
        let blues = [0, 0, 0, 0, 3, 3, 0, 0, 4, 3, 0, 4].map { degree in
            theoryEngine.getDiatonicChordsWithAnalysis()[degree].chord
        }
        XCTAssertEqual(theoryEngine.analyzeProgression(blues).pattern, .blues)
    }

    func testChordSuggestionsAfterDominantSeventh() {
        let suggestions = theoryEngine.getChordSuggestions(after: ["G7"])
        XCTAssertEqual(suggestions.map { $0.formattedSymbol }, ["C", "Am"])
    }

    func testChordSuggestionsAfterTonic() {
        let suggestions = theoryEngine.getChordSuggestions(after: ["C"])
        XCTAssertEqual(suggestions.map { $0.formattedSymbol }, ["Dm", "F", "G", "Am"])
    }

    func testAnalyzeChordSeventhHasCommonProgressions() {
        XCTAssertFalse(theoryEngine.analyzeChord("G7")?.commonProgressions.isEmpty ?? true)
        XCTAssertFalse(theoryEngine.analyzeChord("Cmaj7")?.commonProgressions.isEmpty ?? true)
    }

    // MARK: - Chord durations

    func testCycleChordDuration() {
        theoryEngine.addChordToProgression(Chord(.C, type: .major))
        XCTAssertEqual(theoryEngine.currentProgression[0].duration, 1.0)

        theoryEngine.cycleChordDuration(at: 0)
        XCTAssertEqual(theoryEngine.currentProgression[0].duration, 2.0)

        theoryEngine.cycleChordDuration(at: 0)
        XCTAssertEqual(theoryEngine.currentProgression[0].duration, 4.0)

        theoryEngine.cycleChordDuration(at: 0)
        XCTAssertEqual(theoryEngine.currentProgression[0].duration, 1.0)

        // Off-grid legacy values snap to the next step up
        theoryEngine.currentProgression[0].duration = 3.0
        theoryEngine.cycleChordDuration(at: 0)
        XCTAssertEqual(theoryEngine.currentProgression[0].duration, 4.0)

        // Out-of-bounds index is a no-op
        theoryEngine.cycleChordDuration(at: 99)
    }

    // MARK: - Cadence resolution

    func testAppendAuthenticResolution() {
        theoryEngine.setKey("C", scaleType: "major")
        theoryEngine.addChordToProgression(Chord(.C, type: .major))

        theoryEngine.appendResolution(.authentic)

        XCTAssertEqual(
            theoryEngine.currentProgression.map { $0.chord.formattedSymbol },
            ["C", "G7", "C"]
        )
        XCTAssertEqual(theoryEngine.currentProgression.map(\.duration), [1.0, 2.0, 4.0])

        // The appended ending should analyze as an authentic cadence
        let analysis = theoryEngine.analyzeProgression(theoryEngine.currentProgression.map { $0.chord })
        XCTAssertEqual(analysis.cadence, .authentic)
    }

    func testAppendPlagalResolution() {
        theoryEngine.setKey("C", scaleType: "major")

        theoryEngine.appendResolution(.plagal)

        XCTAssertEqual(
            theoryEngine.currentProgression.map { $0.chord.formattedSymbol },
            ["F", "C"]
        )
        XCTAssertEqual(theoryEngine.currentProgression.map(\.duration), [2.0, 4.0])

        let analysis = theoryEngine.analyzeProgression(theoryEngine.currentProgression.map { $0.chord })
        XCTAssertEqual(analysis.cadence, .plagal)
    }

    func testDurationsRoundTripThroughSaveAndLoad() {
        theoryEngine.addChordToProgression(Chord(.C, type: .major), duration: 2.0)
        theoryEngine.addChordToProgression(Chord(.G, type: .dom7), duration: 4.0)

        let saved = theoryEngine.createProgressionData(
            from: theoryEngine.currentProgression,
            name: "Duration test",
            tempo: 90
        )
        XCTAssertEqual(saved.progressionChords.map(\.duration), [2.0, 4.0])

        let fresh = TheoryEngine()
        fresh.loadProgression(saved)
        XCTAssertEqual(fresh.currentProgression.map(\.duration), [2.0, 4.0])
        XCTAssertEqual(fresh.currentProgressionTempo, 90)
    }

    // MARK: - Draft persistence

    @MainActor
    func testDraftProgressionRoundTrip() throws {
        let dataManager = DataManager(inMemory: true)

        let engine = TheoryEngine()
        engine.setKey("F", scaleType: "major")
        engine.currentProgressionTempo = 100
        engine.addChordToProgression(Chord(.F, type: .major), duration: 2.0)
        engine.addChordToProgression(Chord(NoteClass(.B, accidental: .flat), type: .major))
        try dataManager.saveDraftProgression(from: engine)

        let restored = TheoryEngine()
        XCTAssertTrue(try dataManager.loadDraftProgression(into: restored))
        XCTAssertEqual(restored.currentKey, "F")
        XCTAssertEqual(restored.currentProgressionTempo, 100)
        XCTAssertEqual(restored.currentProgression.map(\.duration), [2.0, 1.0])
        XCTAssertEqual(restored.currentProgression.map { $0.chord.formattedSymbol }, ["F", "B♭"])
    }

    @MainActor
    func testEmptyProgressionClearsDraft() throws {
        let dataManager = DataManager(inMemory: true)

        let engine = TheoryEngine()
        engine.addChordToProgression(Chord(.C, type: .major))
        try dataManager.saveDraftProgression(from: engine)

        engine.clearProgression()
        try dataManager.saveDraftProgression(from: engine)

        let restored = TheoryEngine()
        XCTAssertFalse(try dataManager.loadDraftProgression(into: restored))
        XCTAssertTrue(restored.currentProgression.isEmpty)
    }

    // MARK: - Streak counting

    @MainActor
    func testPracticeStreakCountsMultipleSessionsPerDay() throws {
        let dataManager = DataManager(inMemory: true)
        let calendar = Calendar.current

        // Three sessions today and three yesterday: a count-limited fetch
        // used to undercount this as fewer distinct days
        for dayOffset in 0...1 {
            for _ in 0..<3 {
                let session = PracticeSession(
                    mode: .earTraining,
                    score: 80,
                    totalQuestions: 10,
                    correctAnswers: 8,
                    difficulty: .beginner,
                    duration: 60
                )
                session.completedAt = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
                dataManager.context.insert(session)
            }
        }
        try dataManager.context.save()

        XCTAssertEqual(try dataManager.getCurrentPracticeStreak(), 2)
    }

    // MARK: - Duplicate naming

    func testCopyNameUniquing() {
        XCTAssertEqual(SavedProgression.copyName(basedOn: "Jam", existingNames: ["Jam"]), "Jam Copy")
        XCTAssertEqual(SavedProgression.copyName(basedOn: "Jam", existingNames: ["Jam", "Jam Copy"]), "Jam Copy 2")
        XCTAssertEqual(
            SavedProgression.copyName(basedOn: "Jam", existingNames: ["Jam", "Jam Copy", "Jam Copy 2"]),
            "Jam Copy 3"
        )
    }

    // MARK: - Diatonic data available for all 12 keys

    func testDiatonicAnalysisAvailableForAllTwelveKeys() {
        let allKeys = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]

        for key in allKeys {
            let engine = TheoryEngine()
            engine.setKey(key, scaleType: "major")

            let triads = engine.getDiatonicChordsWithAnalysis()
            XCTAssertEqual(triads.count, 7, "\(key) major should have 7 diatonic triads")

            let sevenths = engine.getSeventhChordsWithAnalysis()
            XCTAssertEqual(sevenths.count, 7, "\(key) major should have 7 diatonic seventh chords")

            // The I chord should be rooted on the key's tonic
            XCTAssertEqual(
                triads[0].chord.root.canonicalNote.pitch.pitchClass,
                NoteClass(key)?.canonicalNote.pitch.pitchClass,
                "I chord of \(key) major should be rooted on \(key)"
            )
        }
    }
}
