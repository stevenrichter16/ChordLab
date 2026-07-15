//
//  SolitaireGameView.swift
//  ChordLab
//
//  Klondike solitaire: draw one, unlimited redeals, tap-to-move.
//  Tapping a card sends it to a foundation when possible, otherwise
//  to the first legal tableau pile. Undo included.
//

import SwiftUI

struct SolitaireGameView: View {
    private struct SolCard: Identifiable, Equatable {
        let card: PlayingCard
        var faceUp: Bool

        var id: UUID { card.id }

        var isRed: Bool {
            card.suit == .hearts || card.suit == .diamonds
        }
    }

    /// Complete game position — cheap to snapshot for undo.
    private struct SolState: Equatable {
        var stock: [SolCard] = []
        var waste: [SolCard] = []
        var foundations: [[SolCard]] = Array(repeating: [], count: 4)
        var tableau: [[SolCard]] = Array(repeating: [], count: 7)

        static func newDeal() -> SolState {
            var state = SolState()
            var deck = PlayingCard.standardDeck().shuffled().map { SolCard(card: $0, faceUp: false) }
            for pile in 0..<7 {
                for row in 0...pile {
                    var dealt = deck.removeLast()
                    dealt.faceUp = row == pile
                    state.tableau[pile].append(dealt)
                }
            }
            state.stock = deck
            return state
        }

        var isWon: Bool {
            foundations.allSatisfy { $0.count == 13 }
        }
    }

    private static let suitOrder: [CardSuit] = [.spades, .hearts, .diamonds, .clubs]

    @State private var state = SolState.newDeal()
    @State private var history: [SolState] = []
    @State private var moves = 0
    @State private var isWon = false

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "solitaire")!, onRestart: { newGame() }) {
            GeometryReader { geo in
                let spacing: CGFloat = 6
                let cardWidth = (geo.size.width - spacing * 6 - 20) / 7
                let cardHeight = cardWidth * 1.45

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        StatPill(label: "Moves", value: "\(moves)", tint: .green)
                        StatPill(label: "Stock", value: "\(state.stock.count)")
                        StatPill(label: "Wins", value: "\(GameScores.shared.counter("wins", for: "solitaire"))", tint: .yellow)

                        Button {
                            undo()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(history.isEmpty ? Color.secondary.opacity(0.4) : Color.appPrimary)
                                .frame(width: 40, height: 34)
                                .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(history.isEmpty)
                    }

                    topRow(cardWidth: cardWidth, cardHeight: cardHeight, spacing: spacing)

                    ScrollView(showsIndicators: false) {
                        tableauRow(cardWidth: cardWidth, cardHeight: cardHeight, spacing: spacing)
                            .padding(.bottom, 24)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 4)
            }
            .overlay {
                if isWon {
                    GameOverOverlay(
                        title: "You Won! 🎉",
                        subtitle: "Solved in \(moves) moves",
                        isVictory: true,
                        buttonTitle: "Deal Again"
                    ) {
                        newGame()
                    }
                }
            }
        }
    }

    // MARK: - Top row (stock, waste, foundations)

    private func topRow(cardWidth: CGFloat, cardHeight: CGFloat, spacing: CGFloat) -> some View {
        HStack(spacing: spacing) {
            // Stock
            ZStack {
                emptySlot(width: cardWidth, icon: "arrow.2.circlepath")
                if let top = state.stock.last {
                    PlayingCardView(card: top.card, faceUp: false, width: cardWidth)
                }
            }
            .onTapGesture { tapStock() }

            // Waste
            ZStack {
                emptySlot(width: cardWidth)
                if let top = state.waste.last {
                    PlayingCardView(card: top.card, faceUp: true, width: cardWidth)
                }
            }
            .onTapGesture { tapWaste() }

            Color.clear.frame(width: cardWidth, height: cardHeight)

            // Foundations, one per suit
            ForEach(0..<4, id: \.self) { index in
                ZStack {
                    emptySlot(width: cardWidth, text: Self.suitOrder[index].rawValue)
                    if let top = state.foundations[index].last {
                        PlayingCardView(card: top.card, faceUp: true, width: cardWidth)
                    }
                }
                .onTapGesture { tapFoundation(index) }
            }
        }
    }

    private func emptySlot(width: CGFloat, icon: String? = nil, text: String? = nil) -> some View {
        RoundedRectangle(cornerRadius: width * 0.12)
            .strokeBorder(Color.appBorder.opacity(0.6), lineWidth: 1.5)
            .background(
                RoundedRectangle(cornerRadius: width * 0.12)
                    .fill(Color.appSecondaryBackground.opacity(0.5))
            )
            .frame(width: width, height: width * 1.45)
            .overlay {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: width * 0.35))
                        .foregroundStyle(.secondary)
                } else if let text {
                    Text(text)
                        .font(.system(size: width * 0.42))
                        .foregroundStyle(.secondary.opacity(0.6))
                }
            }
    }

    // MARK: - Tableau

    private func tableauRow(cardWidth: CGFloat, cardHeight: CGFloat, spacing: CGFloat) -> some View {
        let faceDownOffset: CGFloat = cardHeight * 0.14
        let faceUpOffset: CGFloat = cardHeight * 0.3

        return HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<7, id: \.self) { pileIndex in
                let pile = state.tableau[pileIndex]
                // .offset is render-only, so give the pile its real height
                // explicitly or the ScrollView can't account for tall piles.
                let pileHeight = cardHeight + pile.dropLast().reduce(CGFloat(0)) { total, card in
                    total + (card.faceUp ? faceUpOffset : faceDownOffset)
                }

                ZStack(alignment: .top) {
                    emptySlot(width: cardWidth)
                        .onTapGesture { tapEmptyTableau(pileIndex) }

                    ForEach(Array(pile.enumerated()), id: \.element.id) { cardIndex, solCard in
                        let offset = pile.prefix(cardIndex).reduce(CGFloat(0)) { total, above in
                            total + (above.faceUp ? faceUpOffset : faceDownOffset)
                        }
                        PlayingCardView(card: solCard.card, faceUp: solCard.faceUp, width: cardWidth)
                            .offset(y: offset)
                            .onTapGesture { tapTableau(pile: pileIndex, cardIndex: cardIndex) }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .frame(height: pileHeight, alignment: .top)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: state)
    }

    // MARK: - Rules

    private func foundationIndex(for suit: CardSuit) -> Int {
        Self.suitOrder.firstIndex(of: suit) ?? 0
    }

    private func canPlaceOnFoundation(_ card: PlayingCard) -> Bool {
        state.foundations[foundationIndex(for: card.suit)].count == card.rank - 1
    }

    private func canPlace(_ card: SolCard, ontoTableau pileIndex: Int) -> Bool {
        guard let top = state.tableau[pileIndex].last else {
            return card.card.rank == 13
        }
        return top.faceUp && top.isRed != card.isRed && card.card.rank == top.card.rank - 1
    }

    /// Flips the new top card of a pile after cards were removed.
    private func flipTopIfNeeded(_ pileIndex: Int) {
        if let last = state.tableau[pileIndex].indices.last,
           !state.tableau[pileIndex][last].faceUp {
            state.tableau[pileIndex][last].faceUp = true
        }
    }

    private func commit(_ before: SolState) {
        history.append(before)
        if history.count > 200 {
            history.removeFirst()
        }
        moves += 1
        checkWin()
    }

    // MARK: - Taps

    private func tapStock() {
        let before = state
        if let drawn = state.stock.popLast() {
            var card = drawn
            card.faceUp = true
            state.waste.append(card)
            GameHaptics.tap()
        } else if !state.waste.isEmpty {
            state.stock = state.waste.reversed().map { SolCard(card: $0.card, faceUp: false) }
            state.waste = []
            GameHaptics.medium()
        } else {
            return
        }
        commit(before)
    }

    private func tapWaste() {
        guard let top = state.waste.last else { return }
        let before = state

        if canPlaceOnFoundation(top.card) {
            state.waste.removeLast()
            state.foundations[foundationIndex(for: top.card.suit)].append(top)
            GameHaptics.success()
            commit(before)
            return
        }
        for pileIndex in 0..<7 where canPlace(top, ontoTableau: pileIndex) {
            state.waste.removeLast()
            state.tableau[pileIndex].append(top)
            GameHaptics.tap()
            commit(before)
            return
        }
        GameHaptics.warning()
    }

    private func tapFoundation(_ index: Int) {
        // Allow pulling a card back down to the tableau (occasionally needed).
        guard let top = state.foundations[index].last else { return }
        let before = state
        for pileIndex in 0..<7 where canPlace(top, ontoTableau: pileIndex) {
            state.foundations[index].removeLast()
            state.tableau[pileIndex].append(top)
            GameHaptics.tap()
            commit(before)
            return
        }
        GameHaptics.warning()
    }

    private func tapEmptyTableau(_ pileIndex: Int) {
        // Empty pile: pull a king from the waste if there is one.
        guard state.tableau[pileIndex].isEmpty else { return }
        guard let top = state.waste.last, top.card.rank == 13 else { return }
        let before = state
        state.waste.removeLast()
        state.tableau[pileIndex].append(top)
        GameHaptics.tap()
        commit(before)
    }

    private func tapTableau(pile pileIndex: Int, cardIndex: Int) {
        let pile = state.tableau[pileIndex]
        guard cardIndex < pile.count else { return }
        let tapped = pile[cardIndex]

        // Face-down cards: flip only if exposed (normally automatic).
        guard tapped.faceUp else {
            if cardIndex == pile.count - 1 {
                let before = state
                state.tableau[pileIndex][cardIndex].faceUp = true
                GameHaptics.tap()
                commit(before)
            }
            return
        }

        let isTopCard = cardIndex == pile.count - 1
        let before = state

        // Single exposed card: foundation first.
        if isTopCard && canPlaceOnFoundation(tapped.card) {
            state.tableau[pileIndex].removeLast()
            state.foundations[foundationIndex(for: tapped.card.suit)].append(tapped)
            flipTopIfNeeded(pileIndex)
            GameHaptics.success()
            commit(before)
            return
        }

        // Move the substack starting at the tapped card to another pile.
        for target in 0..<7 where target != pileIndex && canPlace(tapped, ontoTableau: target) {
            let substack = Array(pile[cardIndex...])
            state.tableau[pileIndex].removeSubrange(cardIndex...)
            state.tableau[target].append(contentsOf: substack)
            flipTopIfNeeded(pileIndex)
            GameHaptics.tap()
            commit(before)
            return
        }
        GameHaptics.warning()
    }

    private func undo() {
        guard let previous = history.popLast() else { return }
        GameHaptics.medium()
        state = previous
        moves += 1
    }

    // MARK: - Round flow

    private func checkWin() {
        guard state.isWon, !isWon else { return }
        isWon = true
        GameHaptics.success()
        let store = GameScores.shared
        store.incrementCounter("wins", for: "solitaire")
        store.setValue(store.counter("wins", for: "solitaire"), for: "solitaire")
    }

    private func newGame() {
        state = SolState.newDeal()
        history = []
        moves = 0
        isWon = false
    }
}

#Preview {
    SolitaireGameView()
}
