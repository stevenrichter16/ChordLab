//
//  VideoPokerGameView.swift
//  ChordLab
//
//  Jacks or Better video poker: bet, deal, hold, draw.
//

import SwiftUI

struct VideoPokerGameView: View {
    private enum VPPhase {
        case betting     // before deal
        case holding     // first five dealt, choosing holds
        case settled     // after draw, hand paid
    }

    private enum VPHand: String, CaseIterable {
        case royalFlush = "Royal Flush"
        case straightFlush = "Straight Flush"
        case fourOfAKind = "Four of a Kind"
        case fullHouse = "Full House"
        case flush = "Flush"
        case straight = "Straight"
        case threeOfAKind = "Three of a Kind"
        case twoPair = "Two Pair"
        case jacksOrBetter = "Jacks or Better"
        case nothing = "Nothing"

        /// Payout per credit bet.
        var payout: Int {
            switch self {
            case .royalFlush: return 250
            case .straightFlush: return 50
            case .fourOfAKind: return 25
            case .fullHouse: return 9
            case .flush: return 6
            case .straight: return 4
            case .threeOfAKind: return 3
            case .twoPair: return 2
            case .jacksOrBetter: return 1
            case .nothing: return 0
            }
        }
    }

    @State private var credits = 0
    @State private var bet = 1
    @State private var deck: [PlayingCard] = []
    @State private var hand: [PlayingCard] = []
    @State private var held: Set<UUID> = []
    @State private var phase: VPPhase = .betting
    @State private var lastResult: VPHand? = nil
    @State private var lastWin = 0
    @State private var didLoadCredits = false

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "videopoker")!, onRestart: nil) {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    StatPill(label: "Credits", value: "\(credits)", tint: .green)
                    StatPill(label: "Bet", value: "\(bet)", tint: .orange)
                }

                payTable
                    .padding(.horizontal, 16)

                Spacer(minLength: 0)

                resultBanner

                cardRow
                    .padding(.horizontal, 8)

                Spacer(minLength: 0)

                controls
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
            .padding(.top, 4)
            .onAppear {
                if !didLoadCredits {
                    didLoadCredits = true
                    loadCredits()
                }
            }
        }
    }

    // MARK: - Subviews

    private var payTable: some View {
        VStack(spacing: 3) {
            ForEach(VPHand.allCases.filter { $0 != .nothing }, id: \.rawValue) { handType in
                HStack {
                    Text(handType.rawValue)
                    Spacer()
                    Text("\(handType == .royalFlush && bet == 5 ? 4000 : handType.payout * bet)")
                        .fontWeight(.semibold)
                }
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(lastResult == handType ? Color.yellow : .secondary)
            }
        }
        .padding(12)
        .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private var resultBanner: some View {
        ZStack {
            if let lastResult {
                Text(lastResult == .nothing ? "No win" : "\(lastResult.rawValue)! +\(lastWin)")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(lastResult == .nothing ? Color.secondary : Color.green)
                    .transition(.scale.combined(with: .opacity))
            } else if phase == .holding {
                Text("Tap cards to HOLD, then draw")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 30)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: lastResult)
    }

    private var cardRow: some View {
        HStack(spacing: 6) {
            if hand.isEmpty {
                ForEach(0..<5, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appSecondaryBackground)
                        .aspectRatio(0.69, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                }
            } else {
                ForEach(hand) { card in
                    VStack(spacing: 6) {
                        PlayingCardView(card: card, faceUp: true, width: 62)
                            .overlay(alignment: .top) {
                                if held.contains(card.id) {
                                    Text("HELD")
                                        .font(.system(size: 10, weight: .heavy))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.red, in: Capsule())
                                        .offset(y: -10)
                                }
                            }
                    }
                    .onTapGesture {
                        toggleHold(card)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch phase {
        case .betting, .settled:
            VStack(spacing: 10) {
                if credits <= 0 {
                    ArcadeButton(title: "Rebuy 200 credits", systemImage: "dollarsign.circle.fill", tint: .green) {
                        credits = 200
                        saveCredits()
                    }
                } else {
                    HStack(spacing: 10) {
                        ArcadeButton(title: "Bet \(bet)",
                                     systemImage: "plusminus.circle.fill",
                                     tint: .orange) {
                            bet = bet >= 5 ? 1 : bet + 1
                        }
                        ArcadeButton(title: "Max Bet",
                                     tint: .red,
                                     isEnabled: bet != 5) {
                            bet = 5
                        }
                    }
                    ArcadeButton(title: "Deal",
                                 systemImage: "play.fill",
                                 tint: .appPrimary,
                                 isEnabled: credits >= bet) {
                        deal()
                    }
                }
            }

        case .holding:
            ArcadeButton(title: "Draw", systemImage: "arrow.triangle.2.circlepath", tint: .appPrimary) {
                draw()
            }
        }
    }

    // MARK: - Persistence

    private func loadCredits() {
        let store = GameScores.shared
        if store.counter("creditsInitialized", for: "videopoker") == 0 {
            store.setCounter("creditsInitialized", to: 1, for: "videopoker")
            credits = 200
            saveCredits()
        } else {
            credits = store.counter("credits", for: "videopoker")
        }
    }

    private func saveCredits() {
        let store = GameScores.shared
        store.setCounter("credits", to: credits, for: "videopoker")
        store.setValue(credits, for: "videopoker")
    }

    // MARK: - Round flow

    private func deal() {
        GameHaptics.medium()
        credits -= bet
        saveCredits()
        deck = PlayingCard.standardDeck().shuffled()
        hand = (0..<5).map { _ in deck.removeLast() }
        held = []
        lastResult = nil
        lastWin = 0
        phase = .holding
    }

    private func toggleHold(_ card: PlayingCard) {
        guard phase == .holding else { return }
        GameHaptics.tap()
        if held.contains(card.id) {
            held.remove(card.id)
        } else {
            held.insert(card.id)
        }
    }

    private func draw() {
        GameHaptics.medium()
        hand = hand.map { card in
            held.contains(card.id) ? card : deck.removeLast()
        }
        held = []

        let result = Self.evaluate(hand)
        lastResult = result
        if result == .royalFlush && bet == 5 {
            lastWin = 4000
        } else {
            lastWin = result.payout * bet
        }
        credits += lastWin
        saveCredits()

        if lastWin > 0 {
            GameHaptics.success()
        } else {
            GameHaptics.warning()
        }
        phase = .settled
    }

    // MARK: - Hand evaluation

    private static func evaluate(_ hand: [PlayingCard]) -> VPHand {
        let ranks = hand.map { $0.rank }
        let suits = hand.map { $0.suit }
        var counts: [Int: Int] = [:]
        for rank in ranks {
            counts[rank, default: 0] += 1
        }
        let countValues = counts.values.sorted(by: >)
        let isFlush = Set(suits).count == 1

        // Straight detection (ace low or high)
        let unique = Set(ranks)
        var isStraight = false
        var isAceHighStraight = false
        if unique.count == 5 {
            let sorted = unique.sorted()
            if sorted.last! - sorted.first! == 4 {
                isStraight = true
            } else if sorted == [1, 10, 11, 12, 13] {
                isStraight = true
                isAceHighStraight = true
            }
        }

        if isStraight && isFlush {
            return isAceHighStraight ? .royalFlush : .straightFlush
        }
        if countValues == [4, 1] { return .fourOfAKind }
        if countValues == [3, 2] { return .fullHouse }
        if isFlush { return .flush }
        if isStraight { return .straight }
        if countValues == [3, 1, 1] { return .threeOfAKind }
        if countValues == [2, 2, 1] { return .twoPair }
        if countValues == [2, 1, 1, 1] {
            let pairRank = counts.first { $0.value == 2 }!.key
            if pairRank == 1 || pairRank >= 11 {
                return .jacksOrBetter
            }
        }
        return .nothing
    }
}

#Preview {
    VideoPokerGameView()
}
