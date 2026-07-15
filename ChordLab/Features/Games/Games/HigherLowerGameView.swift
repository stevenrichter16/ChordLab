//
//  HigherLowerGameView.swift
//  ChordLab
//
//  Higher or Lower: guess whether the next card from the shoe beats
//  the current one. Aces are low, ties are a free pass. Build a streak.
//

import SwiftUI

struct HigherLowerGameView: View {
    // MARK: - Types

    private enum Phase {
        case playing
        case resolving
        case gameOver
    }

    private enum Outcome: Equatable {
        case correct
        case push
        case wrong
    }

    // MARK: - State

    @State private var shoe: [PlayingCard] = []
    @State private var currentCard: PlayingCard?
    @State private var nextCard: PlayingCard?
    @State private var isRevealed = false
    @State private var streak = 0
    @State private var bestStreak: Int?
    @State private var phase: Phase = .playing
    @State private var outcome: Outcome?
    @State private var isNewRecord = false
    @State private var generation = 0

    private let game = GameCatalog.game(withId: "higherlower")!
    private let cardWidth: CGFloat = 118

    // MARK: - Body

    var body: some View {
        GameScreen(game: game, onRestart: { startGame() }) {
            ZStack {
                VStack(spacing: 16) {
                    statsRow

                    Spacer(minLength: 0)

                    cardsRow

                    resultBanner
                        .padding(.top, 4)

                    Spacer(minLength: 0)

                    buttonsRow

                    Text("Aces are low · ties are a free pass")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.bottom, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)

                if phase == .gameOver {
                    GameOverOverlay(
                        title: "Busted!",
                        subtitle: "You reached a streak of \(streak).",
                        newRecord: isNewRecord,
                        buttonTitle: "Play Again",
                        action: { startGame() }
                    )
                }
            }
        }
        .onAppear {
            if currentCard == nil {
                bestStreak = GameScores.shared.best(for: "higherlower")
                startGame()
            }
        }
    }

    // MARK: - Subviews

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatPill(label: "Streak", value: "\(streak)", tint: game.tint)
            StatPill(label: "Best", value: bestStreak.map(String.init) ?? "—", tint: .yellow)
            StatPill(label: "Shoe", value: "\(shoe.count)", tint: .mint)
        }
    }

    private var cardsRow: some View {
        HStack(spacing: 22) {
            VStack(spacing: 10) {
                ZStack {
                    if let currentCard {
                        PlayingCardView(card: currentCard, faceUp: true, width: cardWidth)
                            .id(currentCard.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .opacity.combined(with: .scale(scale: 0.85))
                            ))
                    }
                }
                .frame(width: cardWidth, height: cardWidth * 1.45)

                Text("CURRENT")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "arrow.right")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 22)

            VStack(spacing: 10) {
                flipCard
                    .frame(width: cardWidth, height: cardWidth * 1.45)

                Text("NEXT")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Face-down shoe card that flips over to reveal the drawn card.
    private var flipCard: some View {
        ZStack {
            PlayingCardView(card: nextCard ?? PlayingCard(rank: 1, suit: .spades),
                            faceUp: false,
                            width: cardWidth)
                .rotation3DEffect(.degrees(isRevealed ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .opacity(isRevealed ? 0 : 1)

            if let nextCard {
                PlayingCardView(card: nextCard, faceUp: true, width: cardWidth)
                    .rotation3DEffect(.degrees(isRevealed ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                    .opacity(isRevealed ? 1 : 0)
            }
        }
    }

    private var resultBanner: some View {
        Group {
            switch outcome {
            case .correct:
                Label("Correct! +1", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .push:
                Label("TIE — free pass", systemImage: "equal.circle.fill")
                    .foregroundStyle(.yellow)
            case .wrong:
                Label("Wrong!", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
            case nil:
                Text("Higher or lower than the \(currentCard?.rankText ?? "card")?")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.system(size: 16, weight: .semibold, design: .rounded))
        .frame(height: 24)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: outcome)
    }

    private var buttonsRow: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 6) {
                ArcadeButton(title: "HIGHER",
                             systemImage: "arrow.up",
                             tint: .green,
                             isEnabled: phase == .playing) {
                    guess(higher: true)
                }
                probabilityText(higher: true)
            }

            VStack(spacing: 6) {
                ArcadeButton(title: "LOWER",
                             systemImage: "arrow.down",
                             tint: .red,
                             isEnabled: phase == .playing) {
                    guess(higher: false)
                }
                probabilityText(higher: false)
            }
        }
    }

    private func probabilityText(higher: Bool) -> some View {
        Text("\(probability(higher: higher))% of shoe")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .contentTransition(.numericText())
    }

    /// Percentage of cards remaining in the shoe that are strictly
    /// higher/lower than the current card.
    private func probability(higher: Bool) -> Int {
        guard let currentCard, !shoe.isEmpty else { return 0 }
        let matching = shoe.filter {
            higher ? $0.rank > currentCard.rank : $0.rank < currentCard.rank
        }.count
        return Int((Double(matching) / Double(shoe.count) * 100).rounded())
    }

    // MARK: - Game Logic

    private func startGame() {
        generation += 1
        var deck = PlayingCard.standardDeck().shuffled()
        let first = deck.removeFirst()

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            nextCard = nil
            isRevealed = false
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            currentCard = first
            shoe = deck
            streak = 0
            outcome = nil
            isNewRecord = false
            phase = .playing
        }
    }

    private func drawFromShoe() -> PlayingCard {
        if shoe.isEmpty {
            refillShoe()
        }
        return shoe.removeFirst()
    }

    /// Reshuffles a fresh deck into the shoe, leaving out the card
    /// currently face-up so it can't be its own exact duplicate.
    private func refillShoe() {
        var deck = PlayingCard.standardDeck().shuffled()
        if let currentCard,
           let index = deck.firstIndex(where: {
               $0.rank == currentCard.rank && $0.suit == currentCard.suit
           }) {
            deck.remove(at: index)
        }
        shoe = deck
    }

    private func guess(higher: Bool) {
        guard phase == .playing, let currentCard else { return }
        phase = .resolving

        let drawn = drawFromShoe()
        nextCard = drawn
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            isRevealed = true
        }

        let result: Outcome
        if drawn.rank == currentCard.rank {
            result = .push
        } else if (drawn.rank > currentCard.rank) == higher {
            result = .correct
        } else {
            result = .wrong
        }

        generation += 1
        let gen = generation
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard gen == generation else { return }
            resolve(result)

            try? await Task.sleep(nanoseconds: 800_000_000)
            guard gen == generation else { return }
            if result == .wrong {
                endGame()
            } else {
                advance(to: drawn)
            }
        }
    }

    private func resolve(_ result: Outcome) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            outcome = result
            if result == .correct {
                streak += 1
            }
        }
        switch result {
        case .correct: GameHaptics.success()
        case .push: GameHaptics.warning()
        case .wrong: GameHaptics.error()
        }
    }

    /// The revealed card becomes the new current card; the shoe card
    /// snaps back to face-down without animating the flip in reverse.
    private func advance(to card: PlayingCard) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            nextCard = nil
            isRevealed = false
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            currentCard = card
            outcome = nil
            phase = .playing
        }
    }

    private func endGame() {
        isNewRecord = GameScores.shared.report(score: streak,
                                               for: "higherlower",
                                               higherIsBetter: true)
        bestStreak = GameScores.shared.best(for: "higherlower")
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            phase = .gameOver
        }
    }
}

#Preview {
    HigherLowerGameView()
}
