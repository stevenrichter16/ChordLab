//
//  SimonGameView.swift
//  ChordLab
//
//  Classic Simon memory game: watch the growing color sequence,
//  then repeat it by tapping the pads.
//

import SwiftUI

struct SimonGameView: View {
    private enum Phase {
        case idle
        case watching
        case input
        case gameOver
    }

    private enum Pad: Int, CaseIterable, Identifiable {
        case green, red, yellow, blue

        var id: Int { rawValue }

        var color: Color {
            switch self {
            case .green: return .green
            case .red: return .red
            case .yellow: return .yellow
            case .blue: return .blue
            }
        }
    }

    private let game = GameCatalog.game(withId: "simon")!

    @State private var sequence: [Pad] = []
    @State private var playerIndex = 0
    @State private var phase: Phase = .idle
    @State private var litPad: Pad? = nil
    @State private var generation = 0
    @State private var showGameOver = false
    @State private var newRecord = false
    @State private var best: Int? = nil

    private var round: Int { max(sequence.count, 1) }

    var body: some View {
        GameScreen(game: game, onRestart: startGame) {
            ZStack {
                VStack(spacing: 18) {
                    Text(statusText)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(phase == .input ? game.tint : .secondary)
                        .contentTransition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: statusText)
                        .padding(.top, 8)

                    HStack(spacing: 12) {
                        StatPill(label: "Round", value: "\(round)", tint: game.tint)
                        StatPill(label: "Best", value: best.map(String.init) ?? "–")
                    }

                    Spacer(minLength: 0)

                    padGrid
                        .padding(.horizontal, 24)

                    Spacer(minLength: 0)
                }
                .padding(.bottom, 16)

                if showGameOver {
                    GameOverOverlay(
                        title: "Game Over",
                        subtitle: "You completed \(sequence.count - 1) round\(sequence.count - 1 == 1 ? "" : "s").",
                        isVictory: false,
                        newRecord: newRecord,
                        buttonTitle: "Play Again",
                        action: startGame
                    )
                }
            }
        }
        .onAppear {
            best = GameScores.shared.best(for: game.id)
            startGame()
        }
    }

    // MARK: - Subviews

    private var statusText: String {
        switch phase {
        case .idle: return "Get ready…"
        case .watching: return "Watch…"
        case .input: return "Your turn"
        case .gameOver: return "Game over"
        }
    }

    private var padGrid: some View {
        ZStack {
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    padView(.green)
                    padView(.red)
                }
                HStack(spacing: 14) {
                    padView(.yellow)
                    padView(.blue)
                }
            }

            Circle()
                .fill(Color.appSecondaryBackground)
                .frame(width: 92, height: 92)
                .overlay(
                    Circle()
                        .strokeBorder(Color.appTertiaryBackground, lineWidth: 4)
                )
                .overlay(
                    VStack(spacing: 0) {
                        Text("\(round)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .contentTransition(.numericText())
                        Text("ROUND")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                )
                .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
                .allowsHitTesting(false)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func padView(_ pad: Pad) -> some View {
        let isLit = litPad == pad
        return Button {
            padTapped(pad)
        } label: {
            padShape(for: pad)
                .fill(pad.color.opacity(isLit ? 1.0 : 0.38))
                .overlay(
                    padShape(for: pad)
                        .strokeBorder(pad.color.opacity(isLit ? 0.95 : 0.55), lineWidth: 2)
                )
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: pad.color.opacity(isLit ? 0.7 : 0), radius: isLit ? 16 : 0)
                .scaleEffect(isLit ? 1.04 : 1.0)
                .animation(.spring(response: 0.22, dampingFraction: 0.6), value: isLit)
        }
        .buttonStyle(.plain)
        .disabled(phase != .input)
    }

    private func padShape(for pad: Pad) -> UnevenRoundedRectangle {
        let big: CGFloat = 100
        let small: CGFloat = 18
        switch pad {
        case .green:
            return UnevenRoundedRectangle(topLeadingRadius: big, bottomLeadingRadius: small,
                                          bottomTrailingRadius: small, topTrailingRadius: small)
        case .red:
            return UnevenRoundedRectangle(topLeadingRadius: small, bottomLeadingRadius: small,
                                          bottomTrailingRadius: small, topTrailingRadius: big)
        case .yellow:
            return UnevenRoundedRectangle(topLeadingRadius: small, bottomLeadingRadius: big,
                                          bottomTrailingRadius: small, topTrailingRadius: small)
        case .blue:
            return UnevenRoundedRectangle(topLeadingRadius: small, bottomLeadingRadius: small,
                                          bottomTrailingRadius: big, topTrailingRadius: small)
        }
    }

    // MARK: - Game Flow

    private func startGame() {
        generation += 1
        showGameOver = false
        newRecord = false
        litPad = nil
        playerIndex = 0
        sequence = [Pad.allCases.randomElement()!]
        playSequence(after: 0.7)
    }

    private func playSequence(after delay: Double) {
        generation += 1
        let gen = generation
        phase = .watching
        playerIndex = 0
        let seq = sequence
        // Speed up slightly as the sequence grows.
        let litTime = max(0.22, 0.45 - Double(seq.count - 1) * 0.02)
        let gapTime = max(0.08, 0.15 - Double(seq.count - 1) * 0.005)

        Task {
            litPad = nil
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard generation == gen else { return }
            for pad in seq {
                litPad = pad
                GameHaptics.tap()
                try? await Task.sleep(nanoseconds: UInt64(litTime * 1_000_000_000))
                guard generation == gen else { return }
                litPad = nil
                try? await Task.sleep(nanoseconds: UInt64(gapTime * 1_000_000_000))
                guard generation == gen else { return }
            }
            phase = .input
        }
    }

    private func padTapped(_ pad: Pad) {
        guard phase == .input, playerIndex < sequence.count else { return }
        let correct = sequence[playerIndex]

        if pad == correct {
            GameHaptics.tap()
            flash(pad)
            playerIndex += 1
            if playerIndex == sequence.count {
                // Round complete: extend the sequence and replay.
                phase = .watching
                GameHaptics.success()
                sequence.append(Pad.allCases.randomElement()!)
                playSequence(after: 0.9)
            }
        } else {
            handleGameOver(correctPad: correct)
        }
    }

    /// Briefly light the tapped pad for input feedback.
    private func flash(_ pad: Pad) {
        let gen = generation
        litPad = pad
        Task {
            try? await Task.sleep(nanoseconds: 180_000_000)
            guard generation == gen, litPad == pad else { return }
            litPad = nil
        }
    }

    private func handleGameOver(correctPad: Pad) {
        GameHaptics.error()
        phase = .gameOver
        let completedRounds = sequence.count - 1
        newRecord = GameScores.shared.report(score: completedRounds,
                                             for: game.id,
                                             higherIsBetter: game.higherIsBetter)
        best = GameScores.shared.best(for: game.id)

        generation += 1
        let gen = generation
        Task {
            litPad = nil
            // Flash the pad the player should have tapped.
            for _ in 0..<3 {
                try? await Task.sleep(nanoseconds: 140_000_000)
                guard generation == gen else { return }
                litPad = correctPad
                try? await Task.sleep(nanoseconds: 220_000_000)
                guard generation == gen else { return }
                litPad = nil
            }
            withAnimation(.easeOut(duration: 0.25)) {
                showGameOver = true
            }
        }
    }
}

#Preview {
    SimonGameView()
}
