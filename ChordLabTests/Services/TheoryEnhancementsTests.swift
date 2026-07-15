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
        XCTAssertEqual(theoryEngine.getRomanNumeral(for: "Bø7"), "vii°7")
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
