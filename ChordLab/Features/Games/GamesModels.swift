//
//  GamesModels.swift
//  ChordLab
//
//  Core models for the Arcade (games) section.
//  This section is intentionally self-contained: no dependency on
//  TheoryEngine, AudioEngine, or the SwiftData schema.
//

import SwiftUI

// MARK: - Game Category

enum GameCategory: String, CaseIterable, Identifiable {
    case classics = "Classics"
    case arcade = "Arcade"
    case cards = "Cards"
    case puzzle = "Puzzle"
    case word = "Word"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .classics: return "circle.grid.3x3.fill"
        case .arcade: return "gamecontroller.fill"
        case .cards: return "suit.spade.fill"
        case .puzzle: return "puzzlepiece.fill"
        case .word: return "textformat.abc"
        }
    }
}

// MARK: - Game Info

struct GameInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let tint: Color
    let category: GameCategory
    let blurb: String
    /// How the "best" value should be labeled on the card (nil = no score tracking)
    let scoreLabel: String?
    /// Whether a higher stored value is better (false for e.g. reaction time)
    let higherIsBetter: Bool

    init(id: String,
         name: String,
         icon: String,
         tint: Color,
         category: GameCategory,
         blurb: String,
         scoreLabel: String? = "Best",
         higherIsBetter: Bool = true) {
        self.id = id
        self.name = name
        self.icon = icon
        self.tint = tint
        self.category = category
        self.blurb = blurb
        self.scoreLabel = scoreLabel
        self.higherIsBetter = higherIsBetter
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: GameInfo, rhs: GameInfo) -> Bool { lhs.id == rhs.id }
}

// MARK: - Game Catalog

enum GameCatalog {
    static let all: [GameInfo] = [
        // Classics
        GameInfo(id: "tictactoe", name: "Tic-Tac-Toe", icon: "number", tint: .blue,
                 category: .classics, blurb: "Beat an unbeatable AI, or pass & play.",
                 scoreLabel: "Wins"),
        GameInfo(id: "connectfour", name: "Connect Four", icon: "circle.grid.3x3.fill", tint: .red,
                 category: .classics, blurb: "Drop discs, make four in a row.",
                 scoreLabel: "Wins"),
        GameInfo(id: "rps", name: "Rock Paper Scissors", icon: "hand.raised.fill", tint: .orange,
                 category: .classics, blurb: "Best-of series against the machine.",
                 scoreLabel: "Streak"),
        GameInfo(id: "dotsboxes", name: "Dots & Boxes", icon: "square.grid.3x3.topleft.filled", tint: .teal,
                 category: .classics, blurb: "Claim boxes, don't give away chains.",
                 scoreLabel: "Wins"),

        // Arcade
        GameInfo(id: "snake", name: "Snake", icon: "point.topleft.down.curvedto.point.bottomright.up", tint: .green,
                 category: .arcade, blurb: "Eat, grow, don't bite yourself."),
        GameInfo(id: "game2048", name: "2048", icon: "square.grid.2x2.fill", tint: .yellow,
                 category: .arcade, blurb: "Swipe and merge to 2048."),
        GameInfo(id: "breakout", name: "Breakout", icon: "rectangle.grid.3x2.fill", tint: .purple,
                 category: .arcade, blurb: "Smash every brick with the ball."),
        GameInfo(id: "whackamole", name: "Whack-a-Mole", icon: "hammer.fill", tint: .brown,
                 category: .arcade, blurb: "30 seconds of pure reflexes."),
        GameInfo(id: "simon", name: "Simon", icon: "waveform.path", tint: .pink,
                 category: .arcade, blurb: "Repeat the growing color sequence."),
        GameInfo(id: "reaction", name: "Reaction Timer", icon: "bolt.fill", tint: .mint,
                 category: .arcade, blurb: "Tap the instant it turns green.",
                 scoreLabel: "Best ms", higherIsBetter: false),

        // Cards
        GameInfo(id: "blackjack", name: "Blackjack", icon: "suit.club.fill", tint: .indigo,
                 category: .cards, blurb: "Beat the dealer to 21. Chips included.",
                 scoreLabel: "Bankroll"),
        GameInfo(id: "higherlower", name: "Higher or Lower", icon: "arrow.up.arrow.down", tint: .cyan,
                 category: .cards, blurb: "Guess the next card, build a streak.",
                 scoreLabel: "Streak"),
        GameInfo(id: "videopoker", name: "Video Poker", icon: "suit.diamond.fill", tint: .red,
                 category: .cards, blurb: "Jacks or Better. Hold and draw.",
                 scoreLabel: "Credits"),

        // Puzzle
        GameInfo(id: "minesweeper", name: "Minesweeper", icon: "flag.fill", tint: .gray,
                 category: .puzzle, blurb: "Clear the field, flag the mines.",
                 scoreLabel: "Wins"),
        GameInfo(id: "sudoku", name: "Sudoku", icon: "square.grid.3x3.fill", tint: .blue,
                 category: .puzzle, blurb: "Freshly generated, always solvable.",
                 scoreLabel: "Solved"),
        GameInfo(id: "lightsout", name: "Lights Out", icon: "lightbulb.fill", tint: .yellow,
                 category: .puzzle, blurb: "Turn every light off. Fewest taps wins.",
                 scoreLabel: "Wins"),
        GameInfo(id: "memory", name: "Memory Match", icon: "rectangle.on.rectangle", tint: .purple,
                 category: .puzzle, blurb: "Find all the pairs. Fewest flips wins.",
                 scoreLabel: "Wins"),

        // Word
        GameInfo(id: "wordguess", name: "Word Guess", icon: "textformat.abc", tint: .green,
                 category: .word, blurb: "Six tries to find the five-letter word.",
                 scoreLabel: "Streak"),
        GameInfo(id: "hangman", name: "Hangman", icon: "figure.stand", tint: .orange,
                 category: .word, blurb: "Guess letters before the doodle is done.",
                 scoreLabel: "Wins")
    ]

    static func games(in category: GameCategory) -> [GameInfo] {
        all.filter { $0.category == category }
    }

    static func game(withId id: String) -> GameInfo? {
        all.first { $0.id == id }
    }
}

// MARK: - High Score Store

/// UserDefaults-backed score store for the Arcade section.
/// Deliberately kept out of SwiftData so games can't affect ChordLab's schema.
@Observable
final class GameScores {
    static let shared = GameScores()

    /// Bumped whenever any score changes so views re-read values.
    private(set) var revision: Int = 0

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private func key(_ gameId: String, _ field: String) -> String {
        "arcade.\(gameId).\(field)"
    }

    // MARK: Best score

    func best(for gameId: String) -> Int? {
        let k = key(gameId, "best")
        guard defaults.object(forKey: k) != nil else { return nil }
        return defaults.integer(forKey: k)
    }

    /// Reports a finished-game score. Stores it if it beats the current best.
    /// Returns true when a new record was set.
    @discardableResult
    func report(score: Int, for gameId: String, higherIsBetter: Bool = true) -> Bool {
        let current = best(for: gameId)
        let isRecord: Bool
        if let current {
            isRecord = higherIsBetter ? score > current : score < current
        } else {
            isRecord = true
        }
        if isRecord {
            defaults.set(score, forKey: key(gameId, "best"))
            revision += 1
        }
        return isRecord
    }

    /// Unconditionally stores a value (for running counters like bankroll).
    func setValue(_ value: Int, for gameId: String) {
        defaults.set(value, forKey: key(gameId, "best"))
        revision += 1
    }

    // MARK: Simple per-game counters (wins, games played, ...)

    func counter(_ name: String, for gameId: String) -> Int {
        defaults.integer(forKey: key(gameId, name))
    }

    func incrementCounter(_ name: String, for gameId: String, by amount: Int = 1) {
        let k = key(gameId, name)
        defaults.set(defaults.integer(forKey: k) + amount, forKey: k)
        revision += 1
    }

    func setCounter(_ name: String, to value: Int, for gameId: String) {
        defaults.set(value, forKey: key(gameId, name))
        revision += 1
    }
}
