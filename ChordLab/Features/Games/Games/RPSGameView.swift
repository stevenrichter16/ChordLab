//
//  RPSGameView.swift
//  ChordLab
//
//  Rock Paper Scissors against a random AI, with a 3-2-1 shootout
//  animation and win-streak tracking.
//

import SwiftUI

struct RPSGameView: View {
    private enum Phase {
        case idle
        case countdown
        case reveal
    }

    private enum Move: String, CaseIterable {
        case rock = "✊"
        case paper = "✋"
        case scissors = "✌️"

        var title: String {
            switch self {
            case .rock: return "Rock"
            case .paper: return "Paper"
            case .scissors: return "Scissors"
            }
        }

        func beats(_ other: Move) -> Bool {
            switch (self, other) {
            case (.rock, .scissors), (.paper, .rock), (.scissors, .paper):
                return true
            default:
                return false
            }
        }
    }

    private enum Outcome {
        case win
        case lose
        case draw

        var title: String {
            switch self {
            case .win: return "YOU WIN"
            case .lose: return "YOU LOSE"
            case .draw: return "DRAW"
            }
        }

        var tint: Color {
            switch self {
            case .win: return .green
            case .lose: return .red
            case .draw: return .orange
            }
        }
    }

    private let game = GameCatalog.game(withId: "rps")!

    @State private var phase: Phase = .idle
    @State private var playerMove: Move?
    @State private var aiMove: Move?
    @State private var outcome: Outcome?
    @State private var countdown: Int?
    @State private var bounce: CGFloat = 0
    @State private var playerScore = 0
    @State private var aiScore = 0
    @State private var streak = 0
    @State private var isNewRecord = false
    /// Bumped on every new round / restart so stale countdown tasks bail out.
    @State private var round = 0

    var body: some View {
        GameScreen(game: game, onRestart: restart) {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    StatPill(label: "You", value: "\(playerScore)", tint: .green)
                    StatPill(label: "Streak", value: "\(streak)", tint: game.tint)
                    StatPill(label: "AI", value: "\(aiScore)", tint: .red)
                }
                .padding(.top, 8)

                Spacer()

                arena

                Spacer()

                moveButtons
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Arena

    private var arena: some View {
        VStack(spacing: 16) {
            // AI hand (upside down, at the top)
            Text(aiHandEmoji)
                .font(.system(size: 84))
                .rotationEffect(.degrees(180))
                .offset(y: bounce)
                .scaleEffect(phase == .reveal && outcome == .lose ? 1.18 : 1)
                .opacity(phase == .idle ? 0.35 : 1)

            centerBanner
                .frame(height: 76)

            // Player hand
            Text(playerHandEmoji)
                .font(.system(size: 84))
                .offset(y: -bounce)
                .scaleEffect(phase == .reveal && outcome == .win ? 1.18 : 1)
                .opacity(phase == .idle ? 0.35 : 1)
        }
    }

    @ViewBuilder
    private var centerBanner: some View {
        if let countdown {
            Text("\(countdown)")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(.secondary)
                .contentTransition(.numericText(countsDown: true))
        } else if let outcome {
            VStack(spacing: 6) {
                Text(outcome.title)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 8)
                    .background(outcome.tint, in: Capsule())

                if isNewRecord {
                    Label("New record!", systemImage: "star.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.yellow)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .transition(.scale(scale: 0.6).combined(with: .opacity))
        } else {
            Text("Pick your move")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private var aiHandEmoji: String {
        if phase == .reveal, let aiMove { return aiMove.rawValue }
        return Move.rock.rawValue
    }

    private var playerHandEmoji: String {
        if phase == .reveal, let playerMove { return playerMove.rawValue }
        return Move.rock.rawValue
    }

    // MARK: - Move Buttons

    private var moveButtons: some View {
        HStack(spacing: 14) {
            ForEach(Move.allCases, id: \.self) { move in
                Button {
                    play(move)
                } label: {
                    VStack(spacing: 6) {
                        Text(move.rawValue)
                            .font(.system(size: 42))
                        Text(move.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(
                                phase == .reveal && playerMove == move
                                    ? (outcome?.tint ?? Color.appPrimary)
                                    : Color.clear,
                                lineWidth: 2
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(phase == .countdown)
                .opacity(phase == .countdown ? 0.5 : 1)
            }
        }
    }

    // MARK: - Game Logic

    private func play(_ move: Move) {
        guard phase != .countdown else { return }
        GameHaptics.tap()

        round += 1
        let currentRound = round
        playerMove = move
        aiMove = Move.allCases.randomElement()

        withAnimation(.easeOut(duration: 0.15)) {
            outcome = nil
            isNewRecord = false
            phase = .countdown
        }

        Task { @MainActor in
            for count in stride(from: 3, through: 1, by: -1) {
                guard round == currentRound else { return }
                withAnimation(.easeOut(duration: 0.15)) { countdown = count }
                withAnimation(.easeIn(duration: 0.13)) { bounce = 14 }
                GameHaptics.tap()
                try? await Task.sleep(nanoseconds: 150_000_000)

                guard round == currentRound else { return }
                withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) { bounce = 0 }
                try? await Task.sleep(nanoseconds: 260_000_000)
            }
            guard round == currentRound else { return }
            countdown = nil
            reveal()
        }
    }

    private func reveal() {
        guard let playerMove, let aiMove else { return }

        let result: Outcome
        if playerMove == aiMove {
            result = .draw
        } else if playerMove.beats(aiMove) {
            result = .win
        } else {
            result = .lose
        }

        switch result {
        case .win:
            playerScore += 1
            streak += 1
            isNewRecord = GameScores.shared.report(score: streak, for: game.id)
            GameHaptics.success()
        case .lose:
            aiScore += 1
            streak = 0
            GameHaptics.error()
        case .draw:
            GameHaptics.warning()
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            outcome = result
            phase = .reveal
        }
    }

    private func restart() {
        round += 1
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            phase = .idle
            playerMove = nil
            aiMove = nil
            outcome = nil
            countdown = nil
            bounce = 0
            playerScore = 0
            aiScore = 0
            streak = 0
            isNewRecord = false
        }
    }
}

#Preview {
    RPSGameView()
}
