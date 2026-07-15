//
//  PracticeQuestion.swift
//  ChordLab
//
//  Question model and generators for the practice modes
//

import Foundation
import Tonic

struct PracticeQuestion: Identifiable {
    let id = UUID()
    let prompt: String
    let keyName: String
    let chord: Chord?          // Single chord stimulus (ear training / recognition)
    let progression: [Chord]   // Multi-chord stimulus (progression challenge)
    let options: [String]
    let correctIndex: Int

    init(
        prompt: String,
        keyName: String = "C",
        chord: Chord? = nil,
        progression: [Chord] = [],
        options: [String],
        correctIndex: Int
    ) {
        self.prompt = prompt
        self.keyName = keyName
        self.chord = chord
        self.progression = progression
        self.options = options
        self.correctIndex = correctIndex
    }

    var correctAnswer: String {
        options[correctIndex]
    }
}

/// Generates practice questions from TheoryEngine data.
/// Uses throwaway TheoryEngine instances so the global app state
/// (current key, selected chord) is never disturbed mid-practice.
enum PracticeQuestionGenerator {

    // MARK: - Shared pools

    private static let chromaticRoots: [NoteClass] = [
        .C, .Cs, .D, .Ds, .E, .F, .Fs, .G, .Gs, .A, .As, .B
    ]

    private static let naturalKeys = ["C", "D", "E", "F", "G", "A", "B"]
    private static let allKeys = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]

    private static func keys(for difficulty: PracticeSession.PracticeDifficulty) -> [String] {
        switch difficulty {
        case .beginner:
            return ["C"]
        case .intermediate:
            return ["C", "G", "D", "F", "A", "E"]
        case .advanced:
            return naturalKeys
        case .expert:
            return allKeys
        }
    }

    private static func usesSevenths(_ difficulty: PracticeSession.PracticeDifficulty) -> Bool {
        difficulty == .advanced || difficulty == .expert
    }

    private static func diatonicData(
        key: String,
        sevenths: Bool
    ) -> [(chord: Chord, romanNumeral: String, function: ChordFunction, degreeName: String)] {
        let engine = TheoryEngine()
        engine.setKey(key, scaleType: "major")
        return sevenths ? engine.getSeventhChordsWithAnalysis() : engine.getDiatonicChordsWithAnalysis()
    }

    // MARK: - Ear Training (chord quality identification)

    static func qualityPool(for difficulty: PracticeSession.PracticeDifficulty) -> [(name: String, type: ChordType)] {
        switch difficulty {
        case .beginner:
            return [("Major", .major), ("Minor", .minor)]
        case .intermediate:
            return [("Major", .major), ("Minor", .minor), ("Diminished", .dim), ("Augmented", .aug)]
        case .advanced:
            return [
                ("Major", .major), ("Minor", .minor),
                ("Major 7th", .maj7), ("Minor 7th", .min7), ("Dominant 7th", .dom7)
            ]
        case .expert:
            return [
                ("Major 7th", .maj7), ("Minor 7th", .min7), ("Dominant 7th", .dom7),
                ("Half-dim 7th", .halfDim7), ("Diminished 7th", .dim7), ("Augmented", .aug)
            ]
        }
    }

    static func earTrainingQuestions(
        count: Int,
        difficulty: PracticeSession.PracticeDifficulty
    ) -> [PracticeQuestion] {
        let pool = qualityPool(for: difficulty)
        let options = pool.map { $0.name }

        return (0..<count).map { _ in
            let correctIndex = Int.random(in: 0..<pool.count)
            let root = chromaticRoots.randomElement() ?? .C
            let chord = Chord(root, type: pool[correctIndex].type)

            return PracticeQuestion(
                prompt: "Listen to the chord. What quality is it?",
                chord: chord,
                options: options,
                correctIndex: correctIndex
            )
        }
    }

    // MARK: - Chord Recognition (name the chord shown on the piano)

    static func chordRecognitionQuestions(
        count: Int,
        difficulty: PracticeSession.PracticeDifficulty
    ) -> [PracticeQuestion] {
        let keyPool = keys(for: difficulty)
        let sevenths = usesSevenths(difficulty)

        return (0..<count).map { _ in
            let key = keyPool.randomElement() ?? "C"
            let data = diatonicData(key: key, sevenths: sevenths)
            guard data.count == 7 else {
                // Defensive fallback; diatonic data should always have 7 entries
                return PracticeQuestion(
                    prompt: "Which chord is shown on the piano?",
                    chord: Chord(.C, type: .major),
                    options: ["C", "Cm", "C°", "C+"],
                    correctIndex: 0
                )
            }

            let correctEntry = data.randomElement()!
            let correct = correctEntry.chord
            var optionSet: [String] = [correct.formattedSymbol]

            // Same root, different quality — the classic confusion
            let altQualities: [ChordType] = sevenths
                ? [.maj7, .min7, .dom7, .halfDim7]
                : [.major, .minor, .dim, .aug]
            for quality in altQualities.shuffled() where quality != correct.type {
                let symbol = Chord(correct.root, type: quality).formattedSymbol
                if !optionSet.contains(symbol) {
                    optionSet.append(symbol)
                    break
                }
            }

            // Fill remaining slots with other chords from the key
            for entry in data.shuffled() {
                guard optionSet.count < 4 else { break }
                let symbol = entry.chord.formattedSymbol
                if !optionSet.contains(symbol) {
                    optionSet.append(symbol)
                }
            }

            let shuffled = optionSet.shuffled()
            let correctIndex = shuffled.firstIndex(of: correct.formattedSymbol) ?? 0

            return PracticeQuestion(
                prompt: "Which chord is shown on the piano?",
                keyName: key,
                chord: correct,
                options: shuffled,
                correctIndex: correctIndex
            )
        }
    }

    // MARK: - Progression Challenge (identify the progression by ear)

    /// Common progressions expressed as scale-degree indices (0 = I)
    private static let progressionPatterns: [[Int]] = [
        [0, 3, 4, 0],  // I - IV - V - I
        [0, 5, 3, 4],  // I - vi - IV - V
        [0, 4, 5, 3],  // I - V - vi - IV
        [1, 4, 0, 0],  // ii - V - I - I
        [0, 3, 0, 4],  // I - IV - I - V
        [5, 3, 0, 4],  // vi - IV - I - V
        [0, 2, 3, 4]   // I - iii - IV - V
    ]

    static func progressionQuestions(
        count: Int,
        difficulty: PracticeSession.PracticeDifficulty
    ) -> [PracticeQuestion] {
        let keyPool = keys(for: difficulty)
        let sevenths = usesSevenths(difficulty)

        return (0..<count).map { _ in
            let key = keyPool.randomElement() ?? "C"
            let data = diatonicData(key: key, sevenths: sevenths)
            guard data.count == 7 else {
                return PracticeQuestion(
                    prompt: "Listen to the progression. Which pattern is it?",
                    progression: [Chord(.C, type: .major)],
                    options: ["I", "IV", "V", "vi"],
                    correctIndex: 0
                )
            }

            func label(_ pattern: [Int]) -> String {
                pattern.map { data[$0].romanNumeral }.joined(separator: " – ")
            }

            let patterns = progressionPatterns.shuffled()
            let correctPattern = patterns[0]
            let chords = correctPattern.map { data[$0].chord }

            var options = [label(correctPattern)]
            for pattern in patterns.dropFirst() {
                guard options.count < 4 else { break }
                let text = label(pattern)
                if !options.contains(text) {
                    options.append(text)
                }
            }

            let shuffled = options.shuffled()
            let correctIndex = shuffled.firstIndex(of: label(correctPattern)) ?? 0

            return PracticeQuestion(
                prompt: "Listen to the progression in \(key) major. Which pattern is it?",
                keyName: key,
                progression: chords,
                options: shuffled,
                correctIndex: correctIndex
            )
        }
    }

    // MARK: - Theory Quiz (mixed knowledge questions)

    static func theoryQuizQuestions(
        count: Int,
        difficulty: PracticeSession.PracticeDifficulty
    ) -> [PracticeQuestion] {
        let keyPool = keys(for: difficulty)
        let sevenths = usesSevenths(difficulty)

        return (0..<count).map { index in
            let key = keyPool.randomElement() ?? "C"
            let data = diatonicData(key: key, sevenths: sevenths)
            guard data.count == 7 else {
                return PracticeQuestion(
                    prompt: "Which chord is the I of C major?",
                    options: ["C", "F", "G", "Am"],
                    correctIndex: 0
                )
            }

            switch index % 3 {
            case 0:
                return romanNumeralQuestion(key: key, data: data)
            case 1:
                return functionQuestion(key: key, data: data)
            default:
                return chordTonesQuestion(key: key, data: data)
            }
        }
    }

    private static func romanNumeralQuestion(
        key: String,
        data: [(chord: Chord, romanNumeral: String, function: ChordFunction, degreeName: String)]
    ) -> PracticeQuestion {
        let correctEntry = data.randomElement()!

        var options = [correctEntry.chord.formattedSymbol]
        for entry in data.shuffled() {
            guard options.count < 4 else { break }
            let symbol = entry.chord.formattedSymbol
            if !options.contains(symbol) {
                options.append(symbol)
            }
        }

        let shuffled = options.shuffled()
        let correctIndex = shuffled.firstIndex(of: correctEntry.chord.formattedSymbol) ?? 0

        return PracticeQuestion(
            prompt: "In \(key) major, which chord is the \(correctEntry.romanNumeral)?",
            keyName: key,
            options: shuffled,
            correctIndex: correctIndex
        )
    }

    private static func functionQuestion(
        key: String,
        data: [(chord: Chord, romanNumeral: String, function: ChordFunction, degreeName: String)]
    ) -> PracticeQuestion {
        let correctEntry = data.randomElement()!

        var options = [correctEntry.degreeName]
        for entry in data.shuffled() {
            guard options.count < 4 else { break }
            if !options.contains(entry.degreeName) {
                options.append(entry.degreeName)
            }
        }

        let shuffled = options.shuffled()
        let correctIndex = shuffled.firstIndex(of: correctEntry.degreeName) ?? 0

        return PracticeQuestion(
            prompt: "What role does \(correctEntry.chord.formattedSymbol) play in \(key) major?",
            keyName: key,
            options: shuffled,
            correctIndex: correctIndex
        )
    }

    private static func chordTonesQuestion(
        key: String,
        data: [(chord: Chord, romanNumeral: String, function: ChordFunction, degreeName: String)]
    ) -> PracticeQuestion {
        let correctEntry = data.randomElement()!

        func noteList(_ chord: Chord) -> String {
            chord.noteClasses.map { $0.description }.joined(separator: " – ")
        }

        var options = [noteList(correctEntry.chord)]
        for entry in data.shuffled() {
            guard options.count < 4 else { break }
            let text = noteList(entry.chord)
            if !options.contains(text) {
                options.append(text)
            }
        }

        let shuffled = options.shuffled()
        let correctIndex = shuffled.firstIndex(of: noteList(correctEntry.chord)) ?? 0

        return PracticeQuestion(
            prompt: "Which notes make up \(correctEntry.chord.formattedSymbol)?",
            keyName: key,
            options: shuffled,
            correctIndex: correctIndex
        )
    }
}
