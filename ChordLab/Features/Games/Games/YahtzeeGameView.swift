//
//  YahtzeeGameView.swift
//  ChordLab
//
//  Yahtzee: roll five dice, hold the keepers, and fill all 13 categories.
//

import SwiftUI

struct YahtzeeGameView: View {
    private static let diceCount = 5
    private static let maxRolls = 3
    private static let totalTurns = 13

    // MARK: - Nested types

    private enum TurnPhase {
        case awaitingRoll   // start of a turn, must roll before anything else
        case rolling        // shuffle animation in progress
        case rolled         // at least one roll done: hold dice, reroll, or score
        case over
    }

    private enum ScoreCategory: String, CaseIterable, Identifiable {
        case ones, twos, threes, fours, fives, sixes
        case threeOfAKind, fourOfAKind, fullHouse
        case smallStraight, largeStraight, yahtzee, chance

        var id: String { rawValue }

        var isUpper: Bool { upperFace != nil }

        var upperFace: Int? {
            switch self {
            case .ones: return 1
            case .twos: return 2
            case .threes: return 3
            case .fours: return 4
            case .fives: return 5
            case .sixes: return 6
            default: return nil
            }
        }

        var displayName: String {
            switch self {
            case .ones: return "Ones"
            case .twos: return "Twos"
            case .threes: return "Threes"
            case .fours: return "Fours"
            case .fives: return "Fives"
            case .sixes: return "Sixes"
            case .threeOfAKind: return "3 of a Kind"
            case .fourOfAKind: return "4 of a Kind"
            case .fullHouse: return "Full House"
            case .smallStraight: return "Sm. Straight"
            case .largeStraight: return "Lg. Straight"
            case .yahtzee: return "Yahtzee"
            case .chance: return "Chance"
            }
        }

        static var upper: [ScoreCategory] { allCases.filter { $0.isUpper } }
        static var lower: [ScoreCategory] { allCases.filter { !$0.isUpper } }

        func score(for dice: [Int]) -> Int {
            var counts = [Int](repeating: 0, count: 7)
            for die in dice { counts[die] += 1 }
            let sum = dice.reduce(0, +)
            let faces = Set(dice)

            switch self {
            case .ones, .twos, .threes, .fours, .fives, .sixes:
                let face = upperFace ?? 0
                return counts[face] * face
            case .threeOfAKind:
                return counts.contains(where: { $0 >= 3 }) ? sum : 0
            case .fourOfAKind:
                return counts.contains(where: { $0 >= 4 }) ? sum : 0
            case .fullHouse:
                return counts.contains(3) && counts.contains(2) ? 25 : 0
            case .smallStraight:
                let runs: [Set<Int>] = [[1, 2, 3, 4], [2, 3, 4, 5], [3, 4, 5, 6]]
                return runs.contains(where: { $0.isSubset(of: faces) }) ? 30 : 0
            case .largeStraight:
                return faces == [1, 2, 3, 4, 5] || faces == [2, 3, 4, 5, 6] ? 40 : 0
            case .yahtzee:
                return counts.contains(5) ? 50 : 0
            case .chance:
                return sum
            }
        }
    }

    // MARK: - State

    private let game = GameCatalog.game(withId: "yahtzee")
        ?? GameInfo(id: "yahtzee", name: "Yahtzee", icon: "dice.fill", tint: .red,
                    category: .classics, blurb: "Roll, hold, and fill the score sheet.")

    @State private var phase: TurnPhase = .awaitingRoll
    @State private var dice: [Int] = [1, 2, 3, 4, 5]
    @State private var held: [Bool] = Array(repeating: false, count: 5)
    @State private var rollsUsed = 0
    @State private var scores: [ScoreCategory: Int] = [:]
    @State private var rollGeneration = 0
    @State private var isNewRecord = false

    // MARK: - Derived scores

    private var turnNumber: Int {
        min(scores.count + 1, Self.totalTurns)
    }

    private var upperSubtotal: Int {
        ScoreCategory.upper.compactMap { scores[$0] }.reduce(0, +)
    }

    private var upperBonus: Int {
        upperSubtotal >= 63 ? 35 : 0
    }

    private var lowerSubtotal: Int {
        ScoreCategory.lower.compactMap { scores[$0] }.reduce(0, +)
    }

    private var totalScore: Int {
        upperSubtotal + upperBonus + lowerSubtotal
    }

    private var canRoll: Bool {
        (phase == .awaitingRoll || phase == .rolled) && rollsUsed < Self.maxRolls
    }

    // MARK: - Body

    var body: some View {
        GameScreen(game: game, onRestart: { newGame() }) {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    StatPill(label: "Turn", value: "\(turnNumber)/\(Self.totalTurns)")
                    StatPill(label: "Rolls Left", value: "\(Self.maxRolls - rollsUsed)", tint: .orange)
                    StatPill(label: "Total", value: "\(totalScore)", tint: game.tint)
                }

                diceRow

                ArcadeButton(
                    title: rollsUsed == 0 ? "Roll Dice" : "Roll Again",
                    systemImage: "dice.fill",
                    tint: game.tint,
                    isEnabled: canRoll
                ) {
                    rollDice()
                }
                .padding(.horizontal, 16)

                scoreSheet
            }
            .padding(.top, 4)
            .overlay {
                if phase == .over {
                    GameOverOverlay(
                        title: "Game Over",
                        subtitle: "Total score: \(totalScore)"
                            + (upperBonus > 0 ? " (incl. +35 bonus)" : ""),
                        isVictory: totalScore >= 250,
                        newRecord: isNewRecord,
                        buttonTitle: "Play Again"
                    ) {
                        newGame()
                    }
                }
            }
        }
    }

    // MARK: - Dice row

    private var diceRow: some View {
        HStack(spacing: 10) {
            ForEach(0..<Self.diceCount, id: \.self) { index in
                dieButton(index)
            }
        }
        .padding(.horizontal, 16)
    }

    private func dieButton(_ index: Int) -> some View {
        Button {
            toggleHold(index)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: held[index] ? "die.face.\(dice[index]).fill" : "die.face.\(dice[index])")
                    .font(.system(size: 42))
                    .foregroundStyle(held[index] ? game.tint : Color.primary)
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(held[index] ? game.tint.opacity(0.15) : Color.appSecondaryBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(held[index] ? game.tint : Color.clear, lineWidth: 2)
                    )
                    .scaleEffect(held[index] ? 0.94 : 1)

                Text(held[index] ? "HELD" : " ")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(game.tint)
            }
        }
        .buttonStyle(.plain)
        .disabled(rollsUsed == 0 || phase == .rolling || phase == .over)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: held[index])
    }

    private func toggleHold(_ index: Int) {
        guard rollsUsed > 0, phase == .rolled else { return }
        GameHaptics.tap()
        held[index].toggle()
    }

    // MARK: - Score sheet

    private var scoreSheet: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 10) {
                VStack(spacing: 4) {
                    columnHeader("Upper")
                    ForEach(ScoreCategory.upper) { category in
                        scoreRow(category)
                    }
                    summaryRow(label: "Subtotal", value: "\(upperSubtotal)/63", highlighted: false)
                    summaryRow(label: "Bonus", value: "+\(upperBonus)", highlighted: upperBonus > 0)
                }

                VStack(spacing: 4) {
                    columnHeader("Lower")
                    ForEach(ScoreCategory.lower) { category in
                        scoreRow(category)
                    }
                    summaryRow(label: "Total", value: "\(totalScore)", highlighted: true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    private func columnHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
    }

    private func scoreRow(_ category: ScoreCategory) -> some View {
        let recorded = scores[category]
        let canScore = phase == .rolled && recorded == nil

        return Button {
            score(category)
        } label: {
            HStack(spacing: 4) {
                Text(category.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(recorded != nil ? Color.secondary : Color.primary)

                Spacer(minLength: 2)

                if let recorded {
                    Text("\(recorded)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(game.tint)
                } else if canScore {
                    Text("\(category.score(for: dice))")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                } else {
                    Text("–")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 32)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(canScore ? game.tint.opacity(0.10) : Color.appSecondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(canScore ? game.tint.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canScore)
    }

    private func summaryRow(label: String, value: String, highlighted: Bool) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 2)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(highlighted ? game.tint : Color.secondary)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 8)
        .frame(height: 32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.appTertiaryBackground)
        )
    }

    // MARK: - Game flow

    private func newGame() {
        rollGeneration += 1
        phase = .awaitingRoll
        dice = [1, 2, 3, 4, 5]
        held = Array(repeating: false, count: Self.diceCount)
        rollsUsed = 0
        scores = [:]
        isNewRecord = false
    }

    private func rollDice() {
        guard canRoll else { return }
        phase = .rolling
        rollsUsed += 1
        rollGeneration += 1
        let generation = rollGeneration

        Task { @MainActor in
            // Quick shuffle steps before the dice settle.
            for step in 0..<6 {
                try? await Task.sleep(nanoseconds: 55_000_000)
                guard generation == rollGeneration else { return }
                shuffleFreeDice()
                if step % 2 == 0 { GameHaptics.tap() }
            }
            try? await Task.sleep(nanoseconds: 70_000_000)
            guard generation == rollGeneration else { return }
            shuffleFreeDice()
            GameHaptics.medium()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                phase = .rolled
            }
        }
    }

    private func shuffleFreeDice() {
        for index in 0..<Self.diceCount where !held[index] {
            dice[index] = Int.random(in: 1...6)
        }
    }

    private func score(_ category: ScoreCategory) {
        guard phase == .rolled, scores[category] == nil else { return }
        let value = category.score(for: dice)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            scores[category] = value
        }

        if scores.count == Self.totalTurns {
            GameHaptics.success()
            isNewRecord = GameScores.shared.report(score: totalScore, for: "yahtzee")
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                phase = .over
            }
        } else {
            if value > 0 {
                GameHaptics.medium()
            } else {
                GameHaptics.warning()
            }
            rollGeneration += 1
            held = Array(repeating: false, count: Self.diceCount)
            rollsUsed = 0
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                phase = .awaitingRoll
            }
        }
    }
}

#Preview {
    YahtzeeGameView()
}
