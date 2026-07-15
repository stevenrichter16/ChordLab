//
//  BlackjackGameView.swift
//  ChordLab
//
//  Single-player blackjack vs the dealer: chips, betting, double down,
//  3:2 blackjack payout, dealer stands on all 17s.
//

import SwiftUI

struct BlackjackGameView: View {
    private enum BJPhase {
        case betting
        case playerTurn
        case dealerTurn
        case settled
    }

    @State private var shoe: [PlayingCard] = []
    @State private var playerHand: [PlayingCard] = []
    @State private var dealerHand: [PlayingCard] = []
    @State private var phase: BJPhase = .betting
    @State private var bankroll = 0
    @State private var bet = 0
    @State private var resultText: String?
    @State private var resultTint: Color = .primary
    @State private var roundGeneration = 0
    @State private var didLoadBankroll = false

    private let chipValues = [10, 25, 50, 100]

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "blackjack")!, onRestart: nil) {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    StatPill(label: "Bankroll", value: "$\(bankroll)", tint: .green)
                    if bet > 0 {
                        StatPill(label: "Bet", value: "$\(bet)", tint: .orange)
                    }
                }
                .padding(.bottom, 12)

                // Dealer
                VStack(spacing: 6) {
                    handHeader(title: "Dealer",
                               value: dealerHand.isEmpty ? nil : dealerVisibleValue)
                    handView(dealerHand, hideHoleCard: phase == .playerTurn)
                }
                .frame(maxHeight: .infinity)

                // Result banner
                ZStack {
                    if let resultText {
                        Text(resultText)
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(resultTint)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.appSecondaryBackground, in: Capsule())
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(height: 48)

                // Player
                VStack(spacing: 6) {
                    handView(playerHand, hideHoleCard: false)
                    handHeader(title: "You",
                               value: playerHand.isEmpty ? nil : handLabel(playerHand))
                }
                .frame(maxHeight: .infinity)

                controls
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
            .padding(.top, 4)
            .onAppear {
                if !didLoadBankroll {
                    didLoadBankroll = true
                    loadBankroll()
                }
            }
        }
    }

    // MARK: - Subviews

    private func handHeader(title: String, value: String?) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            if let value {
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.appSecondaryBackground, in: Capsule())
            }
        }
    }

    private func handView(_ hand: [PlayingCard], hideHoleCard: Bool) -> some View {
        HStack(spacing: -26) {
            ForEach(Array(hand.enumerated()), id: \.element.id) { index, card in
                PlayingCardView(card: card,
                                faceUp: !(hideHoleCard && index == 1),
                                width: 66)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity))
                    .zIndex(Double(index))
            }
        }
        .frame(minHeight: 100)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: hand.count)
    }

    @ViewBuilder
    private var controls: some View {
        switch phase {
        case .betting:
            VStack(spacing: 12) {
                Text(bankroll <= 0 ? "You're broke! Grab a fresh stack." : "Place your bet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if bankroll <= 0 && bet == 0 {
                    ArcadeButton(title: "Rebuy $500", systemImage: "dollarsign.circle.fill", tint: .green) {
                        bankroll = 500
                        saveBankroll()
                    }
                } else {
                    HStack(spacing: 10) {
                        ForEach(chipValues, id: \.self) { value in
                            chipButton(value)
                        }
                    }

                    HStack(spacing: 10) {
                        ArcadeButton(title: "Clear", tint: .gray, isEnabled: bet > 0) {
                            bankroll += bet
                            bet = 0
                        }
                        ArcadeButton(title: "Deal", systemImage: "play.fill", tint: .appPrimary, isEnabled: bet > 0) {
                            deal()
                        }
                    }
                }
            }

        case .playerTurn:
            HStack(spacing: 10) {
                ArcadeButton(title: "Hit", systemImage: "plus.circle.fill", tint: .green) {
                    hit()
                }
                ArcadeButton(title: "Stand", systemImage: "hand.raised.fill", tint: .red) {
                    stand()
                }
                ArcadeButton(title: "Double",
                             systemImage: "arrow.up.circle.fill",
                             tint: .orange,
                             isEnabled: playerHand.count == 2 && bankroll >= bet) {
                    doubleDown()
                }
            }

        case .dealerTurn:
            Text("Dealer's turn…")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(height: 50)

        case .settled:
            ArcadeButton(title: "Next Hand", systemImage: "arrow.right.circle.fill", tint: .appPrimary) {
                nextHand()
            }
        }
    }

    private func chipButton(_ value: Int) -> some View {
        Button {
            guard bankroll >= value else {
                GameHaptics.warning()
                return
            }
            GameHaptics.tap()
            bankroll -= value
            bet += value
        } label: {
            Text("$\(value)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(
                    Circle()
                        .fill(chipColor(value))
                        .overlay(
                            Circle()
                                .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [6, 5]))
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(4)
                        )
                )
                .opacity(bankroll >= value ? 1 : 0.4)
        }
        .buttonStyle(.plain)
    }

    private func chipColor(_ value: Int) -> Color {
        switch value {
        case 10: return .blue
        case 25: return .green
        case 50: return .orange
        default: return .purple
        }
    }

    // MARK: - Hand values

    /// Best blackjack total: aces upgrade from 1 to 11 when it doesn't bust.
    private func handValue(_ hand: [PlayingCard]) -> Int {
        let base = hand.reduce(0) { $0 + $1.blackjackValue }
        let hasAce = hand.contains { $0.rank == 1 }
        if hasAce && base + 10 <= 21 {
            return base + 10
        }
        return base
    }

    private func isSoft(_ hand: [PlayingCard]) -> Bool {
        let base = hand.reduce(0) { $0 + $1.blackjackValue }
        return hand.contains { $0.rank == 1 } && base + 10 <= 21
    }

    private func handLabel(_ hand: [PlayingCard]) -> String {
        let value = handValue(hand)
        if isBlackjack(hand) { return "Blackjack!" }
        if isSoft(hand) && value != 21 {
            return "\(value - 10)/\(value)"
        }
        return "\(value)"
    }

    private var dealerVisibleValue: String {
        if phase == .playerTurn {
            guard let upCard = dealerHand.first else { return "" }
            return "\(handValue([upCard]))+"
        }
        return handLabel(dealerHand)
    }

    private func isBlackjack(_ hand: [PlayingCard]) -> Bool {
        hand.count == 2 && handValue(hand) == 21
    }

    // MARK: - Round flow

    private func loadBankroll() {
        let store = GameScores.shared
        if store.counter("bankrollInitialized", for: "blackjack") == 0 {
            store.setCounter("bankrollInitialized", to: 1, for: "blackjack")
            bankroll = 500
            saveBankroll()
        } else {
            bankroll = store.counter("bankroll", for: "blackjack")
        }
    }

    private func saveBankroll() {
        let store = GameScores.shared
        store.setCounter("bankroll", to: bankroll, for: "blackjack")
        store.setValue(bankroll, for: "blackjack")
    }

    private func drawCard() -> PlayingCard {
        if shoe.count < 15 {
            shoe = PlayingCard.standardDeck(count: 4).shuffled()
        }
        return shoe.removeLast()
    }

    private func deal() {
        roundGeneration += 1
        GameHaptics.medium()
        withAnimation {
            resultText = nil
        }
        playerHand = [drawCard(), drawCard()]
        dealerHand = [drawCard(), drawCard()]
        phase = .playerTurn

        // Naturals settle immediately.
        if isBlackjack(playerHand) || isBlackjack(dealerHand) {
            settle()
        }
    }

    private func hit() {
        GameHaptics.tap()
        playerHand.append(drawCard())
        let value = handValue(playerHand)
        if value > 21 {
            settle()
        } else if value == 21 {
            stand()
        }
    }

    private func doubleDown() {
        GameHaptics.medium()
        bankroll -= bet
        bet *= 2
        playerHand.append(drawCard())
        if handValue(playerHand) > 21 {
            settle()
        } else {
            stand()
        }
    }

    private func stand() {
        phase = .dealerTurn
        let generation = roundGeneration
        Task { @MainActor in
            // Dealer draws to 17 with visible pacing.
            while true {
                try? await Task.sleep(nanoseconds: 700_000_000)
                guard roundGeneration == generation, phase == .dealerTurn else { return }
                if handValue(dealerHand) < 17 {
                    GameHaptics.tap()
                    dealerHand.append(drawCard())
                } else {
                    break
                }
            }
            guard roundGeneration == generation else { return }
            settle()
        }
    }

    private func settle() {
        let player = handValue(playerHand)
        let dealer = handValue(dealerHand)
        let playerBJ = isBlackjack(playerHand)
        let dealerBJ = isBlackjack(dealerHand)

        var payout = 0   // total returned to bankroll (stake + winnings)
        let outcome: String
        let tint: Color

        if playerBJ && dealerBJ {
            payout = bet
            outcome = "Push — two blackjacks"
            tint = .secondary
        } else if playerBJ {
            // 3:2, rounded up so odd bets aren't shortchanged.
            let winnings = (bet * 3 + 1) / 2
            payout = bet + winnings
            outcome = "Blackjack! +$\(winnings)"
            tint = .green
        } else if dealerBJ {
            outcome = "Dealer blackjack"
            tint = .red
        } else if player > 21 {
            outcome = "Bust"
            tint = .red
        } else if dealer > 21 {
            payout = bet * 2
            outcome = "Dealer busts! +$\(bet)"
            tint = .green
        } else if player > dealer {
            payout = bet * 2
            outcome = "You win! +$\(bet)"
            tint = .green
        } else if player < dealer {
            outcome = "Dealer wins"
            tint = .red
        } else {
            payout = bet
            outcome = "Push"
            tint = .secondary
        }

        bankroll += payout
        bet = 0
        saveBankroll()

        if tint == .green {
            GameHaptics.success()
        } else if tint == .red {
            GameHaptics.error()
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            resultText = outcome
            resultTint = tint
            phase = .settled
        }
    }

    private func nextHand() {
        roundGeneration += 1
        withAnimation {
            playerHand = []
            dealerHand = []
            resultText = nil
            phase = .betting
        }
    }
}

#Preview {
    BlackjackGameView()
}
