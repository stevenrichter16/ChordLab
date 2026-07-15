//
//  MemoryMatchGameView.swift
//  ChordLab
//
//  Memory Match: flip cards to find all the emoji pairs in as few
//  moves — and as little time — as possible.
//

import SwiftUI

struct MemoryMatchGameView: View {
    private struct Card: Identifiable, Equatable {
        let id = UUID()
        let emoji: String
        var isFaceUp = false
        var isMatched = false
    }

    private enum Difficulty: String, CaseIterable, Identifiable {
        case small = "4×3"
        case medium = "4×4"
        case large = "5×4"

        var id: String { rawValue }

        var pairCount: Int {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 10
            }
        }

        var columnCount: Int {
            switch self {
            case .small, .medium: return 4
            case .large: return 5
            }
        }
    }

    private static let emojiPool = [
        "🐶", "🐱", "🦊", "🐻", "🐼", "🐸", "🐵", "🦁", "🐯", "🐨",
        "🐷", "🐮", "🦄", "🐙", "🦋", "🐢", "🐳", "🦜", "🐝", "🦖"
    ]

    private let game = GameCatalog.game(withId: "memory")!
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State private var cards: [Card] = []
    @State private var difficulty: Difficulty = .small
    @State private var firstIndex: Int? = nil
    @State private var isBusy = false
    @State private var moves = 0
    @State private var elapsed = 0
    @State private var timerRunning = false
    @State private var isWon = false
    @State private var showWin = false
    @State private var generation = 0
    @State private var bouncing: Set<UUID> = []

    private var matchedPairs: Int {
        cards.filter(\.isMatched).count / 2
    }

    var body: some View {
        GameScreen(game: game, onRestart: newGame) {
            ZStack {
                VStack(spacing: 16) {
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(Difficulty.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                    HStack(spacing: 12) {
                        StatPill(label: "Moves", value: "\(moves)", tint: game.tint)
                        StatPill(label: "Time", value: timeString(elapsed), tint: .cyan)
                        StatPill(label: "Pairs", value: "\(matchedPairs)/\(difficulty.pairCount)", tint: .green)
                    }

                    Spacer(minLength: 0)

                    cardGrid
                        .padding(.horizontal, 20)

                    Spacer(minLength: 0)
                }
                .padding(.bottom, 16)

                if showWin {
                    GameOverOverlay(
                        title: "All Pairs Found!",
                        subtitle: "\(moves) moves • \(timeString(elapsed))",
                        isVictory: true,
                        buttonTitle: "Play Again",
                        action: newGame
                    )
                }
            }
        }
        .onAppear {
            newGame()
        }
        .onChange(of: difficulty) { _, _ in
            newGame()
        }
        .onReceive(timer) { _ in
            if timerRunning && !isWon {
                elapsed += 1
            }
        }
    }

    // MARK: - Subviews

    private var cardGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10),
                                 count: difficulty.columnCount),
                  spacing: 10) {
            ForEach(cards.indices, id: \.self) { index in
                CardView(card: cards[index], isBouncing: bouncing.contains(cards[index].id))
                    .aspectRatio(0.72, contentMode: .fit)
                    .onTapGesture {
                        flipCard(at: index)
                    }
            }
        }
    }

    private struct CardView: View {
        let card: Card
        let isBouncing: Bool

        var body: some View {
            ZStack {
                // Back
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appPrimary.gradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .strokeBorder(Color.white.opacity(0.35), lineWidth: 1.5)
                            .padding(5)
                    )
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                    )
                    .opacity(card.isFaceUp ? 0 : 1)
                    .rotation3DEffect(.degrees(card.isFaceUp ? 180 : 0), axis: (x: 0, y: 1, z: 0))

                // Front
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appSecondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(card.isMatched ? Color.green.opacity(0.8) : Color.primary.opacity(0.08),
                                          lineWidth: 2)
                    )
                    .overlay(
                        Text(card.emoji)
                            .font(.system(size: 34))
                            .minimumScaleFactor(0.5)
                            .padding(4)
                    )
                    .shadow(color: card.isMatched ? .green.opacity(0.35) : .clear, radius: 8)
                    .opacity(card.isFaceUp ? 1 : 0)
                    .rotation3DEffect(.degrees(card.isFaceUp ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            }
            .scaleEffect(isBouncing ? 1.1 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: card.isFaceUp)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isBouncing)
        }
    }

    // MARK: - Game Logic

    private func flipCard(at index: Int) {
        guard !isWon, !isBusy, !cards[index].isFaceUp else { return }
        GameHaptics.tap()
        timerRunning = true
        cards[index].isFaceUp = true

        guard let first = firstIndex else {
            firstIndex = index
            return
        }
        firstIndex = nil
        moves += 1
        let gen = generation

        if cards[first].emoji == cards[index].emoji {
            // Match: keep both revealed with a little bounce.
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard generation == gen else { return }
                GameHaptics.success()
                cards[first].isMatched = true
                cards[index].isMatched = true
                bouncing.insert(cards[first].id)
                bouncing.insert(cards[index].id)
                try? await Task.sleep(nanoseconds: 320_000_000)
                guard generation == gen else { return }
                bouncing.remove(cards[first].id)
                bouncing.remove(cards[index].id)
                checkForWin()
            }
        } else {
            // No match: block input, then flip both back.
            isBusy = true
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 900_000_000)
                guard generation == gen else { return }
                cards[first].isFaceUp = false
                cards[index].isFaceUp = false
                isBusy = false
            }
        }
    }

    private func checkForWin() {
        guard !cards.isEmpty, cards.allSatisfy(\.isMatched) else { return }
        isWon = true
        timerRunning = false
        GameHaptics.success()
        let s = GameScores.shared
        s.incrementCounter("wins", for: "memory")
        s.setValue(s.counter("wins", for: "memory"), for: "memory")
        withAnimation(.easeOut(duration: 0.25)) {
            showWin = true
        }
    }

    private func newGame() {
        generation += 1
        isWon = false
        showWin = false
        isBusy = false
        firstIndex = nil
        moves = 0
        elapsed = 0
        timerRunning = false
        bouncing.removeAll()
        let faces = Array(Self.emojiPool.shuffled().prefix(difficulty.pairCount))
        cards = (faces + faces).map { Card(emoji: $0) }.shuffled()
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

#Preview {
    MemoryMatchGameView()
}
