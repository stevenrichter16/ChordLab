//
//  WhackAMoleGameView.swift
//  ChordLab
//
//  30-second whack-a-mole on a 3x3 grid. Moles stay up for a window
//  that shrinks as the clock runs down; doubles show up near the end.
//

import SwiftUI

struct WhackAMoleGameView: View {
    private enum Phase {
        case ready
        case playing
        case over
    }

    private static let gameDuration: TimeInterval = 30
    private static let holeCount = 9

    private let game = GameCatalog.game(withId: "whackamole")!
    private let ticker = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    @State private var phase: Phase = .ready
    @State private var score = 0
    @State private var timeRemaining: TimeInterval = WhackAMoleGameView.gameDuration
    @State private var endDate = Date()
    /// Per-hole despawn deadline; nil means the hole is empty.
    @State private var moleDeadlines: [Date?] = Array(repeating: nil, count: WhackAMoleGameView.holeCount)
    @State private var nextSpawn = Date()
    @State private var newRecord = false
    @State private var bestScore: Int?

    var body: some View {
        GameScreen(game: game, onRestart: resetToReady) {
            ZStack {
                if phase == .ready {
                    readyContent
                } else {
                    gameContent
                }

                if phase == .over {
                    GameOverOverlay(
                        title: "Time's Up!",
                        subtitle: "You whacked \(score) mole\(score == 1 ? "" : "s").",
                        isVictory: newRecord,
                        newRecord: newRecord,
                        buttonTitle: "Play Again",
                        action: startGame
                    )
                }
            }
            .onReceive(ticker) { now in
                tick(now)
            }
        }
        .onAppear {
            bestScore = GameScores.shared.best(for: game.id)
        }
    }

    // MARK: - Ready Screen

    private var readyContent: some View {
        VStack(spacing: 18) {
            Text("🐹")
                .font(.system(size: 72))
            Text("30 seconds on the clock")
                .font(.title3.weight(.bold))
            Text("Tap moles for +1.\nTapping an empty hole costs a point.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let bestScore {
                Text("Best: \(bestScore)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.yellow)
            }
            ArcadeButton(title: "Play", systemImage: "play.fill", tint: game.tint) {
                startGame()
            }
            .frame(maxWidth: 220)
        }
        .padding(24)
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }

    // MARK: - Game Screen

    private var gameContent: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                StatPill(label: "Score", value: "\(score)", tint: game.tint)
                StatPill(label: "Time",
                         value: String(format: "%.1f", timeRemaining),
                         tint: timeRemaining <= 5 ? .red : .primary)
                StatPill(label: "Best", value: bestScore.map(String.init) ?? "—", tint: .yellow)
            }
            .padding(.top, 8)

            timeBar
                .padding(.horizontal, 20)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                      spacing: 12) {
                ForEach(0..<Self.holeCount, id: \.self) { index in
                    holeView(index)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            Spacer()
        }
        .transition(.opacity)
    }

    private var timeBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.appSecondaryBackground)
                Capsule()
                    .fill(timeRemaining <= 5 ? Color.red : game.tint)
                    .frame(width: max(0, geo.size.width * timeRemaining / Self.gameDuration))
            }
        }
        .frame(height: 8)
    }

    private func holeView(_ index: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appSecondaryBackground)
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appTertiaryBackground)
                .padding(12)
            if moleDeadlines[index] != nil {
                Text("🐹")
                    .font(.system(size: 46))
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture { holeTapped(index) }
    }

    // MARK: - Game Loop

    private func tick(_ now: Date) {
        guard phase == .playing else { return }

        timeRemaining = max(0, endDate.timeIntervalSince(now))
        if timeRemaining <= 0 {
            endGame()
            return
        }

        // Despawn expired moles.
        for index in moleDeadlines.indices {
            if let deadline = moleDeadlines[index], deadline <= now {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    moleDeadlines[index] = nil
                }
            }
        }

        if now >= nextSpawn {
            spawnMoles(now: now)
        }
    }

    /// Visible window per mole: starts ~1.1s, shrinks linearly to a 0.55s floor.
    private var moleWindow: TimeInterval {
        let elapsed = Self.gameDuration - timeRemaining
        return max(0.55, 1.1 - elapsed * 0.02)
    }

    private func spawnMoles(now: Date) {
        let emptyHoles = moleDeadlines.indices.filter { moleDeadlines[$0] == nil }
        guard !emptyHoles.isEmpty else {
            nextSpawn = now.addingTimeInterval(0.15)
            return
        }

        // In the last 10 seconds, sometimes pop two moles at once.
        var count = 1
        if timeRemaining <= 10, emptyHoles.count > 1, Double.random(in: 0..<1) < 0.35 {
            count = 2
        }

        for hole in emptyHoles.shuffled().prefix(count) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                moleDeadlines[hole] = now.addingTimeInterval(moleWindow)
            }
        }

        nextSpawn = now.addingTimeInterval(max(0.35, moleWindow * Double.random(in: 0.5...0.85)))
    }

    private func holeTapped(_ index: Int) {
        guard phase == .playing else { return }

        if moleDeadlines[index] != nil {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                moleDeadlines[index] = nil
                score += 1
            }
            GameHaptics.medium()
        } else {
            if score > 0 {
                withAnimation(.easeOut(duration: 0.15)) {
                    score -= 1
                }
            }
            GameHaptics.error()
        }
    }

    // MARK: - Lifecycle

    private func startGame() {
        score = 0
        newRecord = false
        moleDeadlines = Array(repeating: nil, count: Self.holeCount)
        timeRemaining = Self.gameDuration
        endDate = Date().addingTimeInterval(Self.gameDuration)
        nextSpawn = Date().addingTimeInterval(0.7)
        GameHaptics.medium()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            phase = .playing
        }
    }

    private func endGame() {
        moleDeadlines = Array(repeating: nil, count: Self.holeCount)
        newRecord = GameScores.shared.report(score: score, for: game.id)
        bestScore = GameScores.shared.best(for: game.id)
        if newRecord {
            GameHaptics.success()
        } else {
            GameHaptics.warning()
        }
        withAnimation(.easeOut(duration: 0.25)) {
            phase = .over
        }
    }

    private func resetToReady() {
        score = 0
        newRecord = false
        moleDeadlines = Array(repeating: nil, count: Self.holeCount)
        timeRemaining = Self.gameDuration
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            phase = .ready
        }
    }
}

#Preview {
    WhackAMoleGameView()
}
