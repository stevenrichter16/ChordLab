//
//  HangmanGameView.swift
//  ChordLab
//
//  Classic hangman: guess the hidden word one letter at a time
//  before the gallows doodle is completed (6 wrong guesses).
//

import SwiftUI

struct HangmanGameView: View {
    // MARK: - Types

    private enum Phase {
        case playing
        case won
        case lost
    }

    // MARK: - Word Bank

    private static let wordBank: [(category: String, icon: String, words: [String])] = [
        ("Animals", "pawprint.fill", [
            "TIGER", "ELEPHANT", "GIRAFFE", "DOLPHIN", "PENGUIN", "RABBIT",
            "MONKEY", "EAGLE", "SHARK", "WHALE", "TURTLE", "LEOPARD",
            "KANGAROO", "SQUIRREL", "HEDGEHOG", "OCTOPUS", "FALCON", "BEAVER",
            "RACCOON", "PANTHER", "GORILLA", "OSTRICH", "FLAMINGO", "LOBSTER",
            "JELLYFISH", "BUFFALO", "CHEETAH", "WALRUS", "IGUANA", "PELICAN"
        ]),
        ("Food", "fork.knife", [
            "PIZZA", "BURGER", "NOODLES", "PANCAKE", "WAFFLE", "AVOCADO",
            "BROCCOLI", "SANDWICH", "SPAGHETTI", "CHOCOLATE", "PRETZEL", "MUFFIN",
            "YOGURT", "OMELET", "LASAGNA", "BURRITO", "POPCORN", "CUCUMBER",
            "PINEAPPLE", "MUSHROOM", "DUMPLING", "BAGUETTE", "COCONUT", "KETCHUP",
            "OATMEAL", "SAUSAGE", "BISCUIT", "PUDDING", "TACO", "HONEY"
        ]),
        ("Places", "map.fill", [
            "BEACH", "CASTLE", "LIBRARY", "AIRPORT", "MUSEUM", "STADIUM",
            "HARBOR", "VILLAGE", "DESERT", "ISLAND", "MOUNTAIN", "HOSPITAL",
            "BAKERY", "THEATER", "JUNGLE", "CANYON", "VOLCANO", "GLACIER",
            "PYRAMID", "TEMPLE", "MARKET", "GARDEN", "BRIDGE", "TUNNEL",
            "SUBWAY", "FOREST", "LAGOON", "PALACE", "SCHOOL", "FARM"
        ]),
        ("Things", "cube.fill", [
            "GUITAR", "UMBRELLA", "BACKPACK", "LANTERN", "COMPASS", "TELESCOPE",
            "KEYBOARD", "BLANKET", "MIRROR", "CANDLE", "HAMMER", "LADDER",
            "PILLOW", "WALLET", "SCISSORS", "WHISTLE", "BICYCLE", "CAMERA",
            "HELMET", "MAGNET", "ENVELOPE", "SUITCASE", "TROPHY", "BUCKET",
            "PENCIL", "STAPLER", "TOASTER", "SPEAKER", "ANCHOR", "ROCKET"
        ])
    ]

    private static let keyRows: [[Character]] = [
        Array("ABCDEFGHI"),
        Array("JKLMNOPQR"),
        Array("STUVWXYZ")
    ]

    private static let maxMistakes = 6

    // MARK: - State

    @State private var word = ""
    @State private var category = ""
    @State private var categoryIcon = "tag.fill"
    @State private var guessedLetters: Set<Character> = []
    @State private var wrongGuesses = 0
    @State private var phase: Phase = .playing
    @State private var showOverlay = false
    @State private var sessionWins = 0
    @State private var sessionLosses = 0
    @State private var overlayGeneration = 0

    private let game = GameCatalog.game(withId: "hangman")!

    // MARK: - Body

    var body: some View {
        GameScreen(game: game, onRestart: { restart() }) {
            ZStack {
                VStack(spacing: 10) {
                    statsRow

                    categoryChip
                        .padding(.top, 2)

                    GallowsView(mistakes: wrongGuesses, tint: game.tint)
                        .frame(width: 190, height: 200)

                    Spacer(minLength: 4)

                    wordSlots

                    Spacer(minLength: 8)

                    keyboard
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                if showOverlay {
                    GameOverOverlay(
                        title: phase == .won ? "You got it!" : "Out of guesses",
                        subtitle: phase == .won
                            ? "\(word) — solved with \(Self.maxMistakes - wrongGuesses) to spare."
                            : "The word was \(word).",
                        isVictory: phase == .won,
                        buttonTitle: "Next Word",
                        action: { newRound() }
                    )
                }
            }
        }
        .onAppear {
            if word.isEmpty {
                newRound()
            }
        }
    }

    // MARK: - Subviews

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatPill(label: "Wins", value: "\(sessionWins)", tint: .green)
            StatPill(label: "Losses", value: "\(sessionLosses)", tint: .red)
            StatPill(label: "Left", value: "\(Self.maxMistakes - wrongGuesses)", tint: game.tint)
        }
    }

    private var categoryChip: some View {
        HStack(spacing: 6) {
            Image(systemName: categoryIcon)
                .font(.system(size: 11, weight: .semibold))
            Text(category)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(game.tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(game.tint.opacity(0.15), in: Capsule())
    }

    private var wordSlots: some View {
        HStack(spacing: 6) {
            ForEach(Array(word.enumerated()), id: \.offset) { _, letter in
                letterSlot(letter)
            }
        }
        .padding(.horizontal, 8)
    }

    private func letterSlot(_ letter: Character) -> some View {
        let isGuessed = guessedLetters.contains(letter)
        let isRevealed = isGuessed || phase != .playing
        let missed = phase == .lost && !isGuessed

        return VStack(spacing: 4) {
            Text(isRevealed ? String(letter) : " ")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(missed ? Color.red : Color.primary)
                .frame(width: 27, height: 30)
                .scaleEffect(isRevealed ? 1 : 0.5)
                .opacity(isRevealed ? 1 : 0)
                .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isRevealed)
            Capsule()
                .fill(isGuessed ? game.tint : Color.secondary.opacity(0.4))
                .frame(width: 27, height: 3)
        }
    }

    private var keyboard: some View {
        VStack(spacing: 7) {
            ForEach(Self.keyRows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { letter in
                        keyButton(letter)
                    }
                }
            }
        }
    }

    private func keyButton(_ letter: Character) -> some View {
        let isGuessed = guessedLetters.contains(letter)
        let inWord = word.contains(letter)

        return Button {
            guess(letter)
        } label: {
            Text(String(letter))
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(isGuessed ? Color.white : Color.primary)
                .frame(width: 33, height: 44)
                .background(
                    isGuessed ? (inWord ? Color.green : Color.red) : Color.appTertiaryBackground,
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .opacity(isGuessed ? 0.85 : 1)
        }
        .disabled(isGuessed || phase != .playing)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isGuessed)
    }

    // MARK: - Game Logic

    private func guess(_ letter: Character) {
        guard phase == .playing, !guessedLetters.contains(letter) else { return }
        guessedLetters.insert(letter)

        if word.contains(letter) {
            GameHaptics.tap()
            if Set(word).isSubset(of: guessedLetters) {
                finishRound(won: true)
            }
        } else {
            GameHaptics.error()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                wrongGuesses += 1
            }
            if wrongGuesses >= Self.maxMistakes {
                finishRound(won: false)
            }
        }
    }

    private func finishRound(won: Bool) {
        phase = won ? .won : .lost
        if won {
            sessionWins += 1
            GameHaptics.success()
            let s = GameScores.shared
            s.incrementCounter("wins", for: "hangman")
            s.setValue(s.counter("wins", for: "hangman"), for: "hangman")
        } else {
            sessionLosses += 1
            GameHaptics.heavy()
        }

        overlayGeneration += 1
        let gen = overlayGeneration
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard gen == overlayGeneration else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                showOverlay = true
            }
        }
    }

    private func newRound() {
        overlayGeneration += 1
        let group = Self.wordBank.randomElement()!
        var next = group.words.randomElement()!
        while next == word && group.words.count > 1 {
            next = group.words.randomElement()!
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            category = group.category
            categoryIcon = group.icon
            word = next
            guessedLetters = []
            wrongGuesses = 0
            phase = .playing
            showOverlay = false
        }
    }

    private func restart() {
        sessionWins = 0
        sessionLosses = 0
        newRound()
    }

    // MARK: - Gallows Drawing

    private struct GallowsView: View {
        let mistakes: Int
        let tint: Color

        private struct Line: Shape {
            let start: CGPoint
            let end: CGPoint

            func path(in rect: CGRect) -> Path {
                var path = Path()
                path.move(to: start)
                path.addLine(to: end)
                return path
            }
        }

        var body: some View {
            ZStack {
                // Static gallows structure.
                frameLine(CGPoint(x: 25, y: 195), CGPoint(x: 165, y: 195))   // base
                frameLine(CGPoint(x: 50, y: 195), CGPoint(x: 50, y: 15))     // pole
                frameLine(CGPoint(x: 50, y: 15), CGPoint(x: 135, y: 15))     // beam
                frameLine(CGPoint(x: 50, y: 42), CGPoint(x: 77, y: 15))      // brace
                frameLine(CGPoint(x: 135, y: 15), CGPoint(x: 135, y: 36))    // rope

                // Body parts, revealed one per mistake with a draw-on animation.
                Circle()                                                     // 1. head
                    .trim(from: 0, to: mistakes >= 1 ? 1 : 0)
                    .stroke(tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 30, height: 30)
                    .position(x: 135, y: 51)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: mistakes)

                bodyLine(CGPoint(x: 135, y: 66), CGPoint(x: 135, y: 120), part: 2)   // body
                bodyLine(CGPoint(x: 135, y: 80), CGPoint(x: 112, y: 104), part: 3)   // left arm
                bodyLine(CGPoint(x: 135, y: 80), CGPoint(x: 158, y: 104), part: 4)   // right arm
                bodyLine(CGPoint(x: 135, y: 120), CGPoint(x: 114, y: 152), part: 5)  // left leg
                bodyLine(CGPoint(x: 135, y: 120), CGPoint(x: 156, y: 152), part: 6)  // right leg

                // A tiny sad face once the doodle is complete.
                Text("× ×")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(tint)
                    .position(x: 135, y: 49)
                    .opacity(mistakes >= 6 ? 1 : 0)
                    .animation(.easeIn(duration: 0.3).delay(0.4), value: mistakes)
            }
        }

        private func frameLine(_ start: CGPoint, _ end: CGPoint) -> some View {
            Line(start: start, end: end)
                .stroke(Color.secondary.opacity(0.55),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }

        private func bodyLine(_ start: CGPoint, _ end: CGPoint, part: Int) -> some View {
            Line(start: start, end: end)
                .trim(from: 0, to: mistakes >= part ? 1 : 0)
                .stroke(tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: mistakes)
        }
    }
}

#Preview {
    HangmanGameView()
}
