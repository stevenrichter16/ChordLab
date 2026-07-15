//
//  ReactionGameView.swift
//  ChordLab
//
//  Classic reaction-time test: wait for the card to turn green,
//  tap as fast as you can. Lower milliseconds are better.
//

import SwiftUI

struct ReactionGameView: View {
    private enum Phase {
        case idle
        case waiting
        case go
        case result
        case tooSoon
    }

    private let game = GameCatalog.game(withId: "reaction")!

    @State private var phase: Phase = .idle
    /// Bumped whenever a round starts or is invalidated so stale delay tasks bail out.
    @State private var round = 0
    @State private var goDate: Date?
    @State private var lastMs: Int?
    @State private var sessionBest: Int?
    @State private var allTimeBest: Int?
    /// Last five successful reaction times, for the rolling average.
    @State private var recentTimes: [Int] = []
    @State private var isNewRecord = false

    var body: some View {
        GameScreen(game: game, onRestart: restart) {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    StatPill(label: "Best", value: msText(sessionBest), tint: game.tint)
                    StatPill(label: "All-time", value: msText(allTimeBest), tint: .yellow)
                    StatPill(label: "Avg ×5", value: msText(rollingAverage), tint: .cyan)
                }
                .padding(.top, 8)

                tapCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
        .onAppear {
            allTimeBest = GameScores.shared.best(for: game.id)
        }
    }

    // MARK: - Card

    private var tapCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(cardColor)

            cardContent
                .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(RoundedRectangle(cornerRadius: 28))
        .onTapGesture { handleTap() }
    }

    private var cardColor: Color {
        switch phase {
        case .idle, .result:
            return .appSecondaryBackground
        case .waiting:
            return .red
        case .go:
            return .green
        case .tooSoon:
            return .orange
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        switch phase {
        case .idle:
            VStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(game.tint)
                Text("Tap to start")
                    .font(.title2.weight(.bold))
                Text("The card turns red — hold on.\nThe instant it turns green, tap!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .transition(.scale(scale: 0.8).combined(with: .opacity))

        case .waiting:
            VStack(spacing: 10) {
                Image(systemName: "hourglass")
                    .font(.system(size: 44))
                Text("Wait for green…")
                    .font(.title2.weight(.bold))
            }
            .foregroundStyle(.white)
            .transition(.opacity)

        case .go:
            Text("TAP!")
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .transition(.scale(scale: 0.6).combined(with: .opacity))

        case .result:
            VStack(spacing: 10) {
                Text("\(lastMs ?? 0)")
                    .font(.system(size: 72, weight: .heavy, design: .rounded))
                    .foregroundStyle(game.tint)
                    .contentTransition(.numericText())
                Text("milliseconds")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                if isNewRecord {
                    Label("New record!", systemImage: "star.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.yellow)
                        .transition(.scale.combined(with: .opacity))
                }
                Text("Tap to go again")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }
            .transition(.scale(scale: 0.8).combined(with: .opacity))

        case .tooSoon:
            VStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 44))
                Text("Too soon!")
                    .font(.title2.weight(.bold))
                Text("Wait for green. Tap to retry.")
                    .font(.subheadline)
            }
            .foregroundStyle(.white)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
    }

    // MARK: - Stats Helpers

    private var rollingAverage: Int? {
        guard !recentTimes.isEmpty else { return nil }
        return recentTimes.reduce(0, +) / recentTimes.count
    }

    private func msText(_ value: Int?) -> String {
        value.map(String.init) ?? "—"
    }

    // MARK: - Game Logic

    private func handleTap() {
        switch phase {
        case .idle, .result, .tooSoon:
            startRound()

        case .waiting:
            // Tapped during red: invalidate the pending go-task and fail.
            round += 1
            GameHaptics.error()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                phase = .tooSoon
            }

        case .go:
            guard let goDate else { return }
            let ms = max(1, Int(Date().timeIntervalSince(goDate) * 1000))
            lastMs = ms
            recentTimes.append(ms)
            if recentTimes.count > 5 {
                recentTimes.removeFirst(recentTimes.count - 5)
            }
            if sessionBest.map({ ms < $0 }) ?? true {
                sessionBest = ms
            }
            isNewRecord = GameScores.shared.report(score: ms, for: game.id, higherIsBetter: false)
            allTimeBest = GameScores.shared.best(for: game.id)
            if isNewRecord {
                GameHaptics.success()
            } else {
                GameHaptics.medium()
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                phase = .result
            }
        }
    }

    private func startRound() {
        GameHaptics.tap()
        round += 1
        let currentRound = round
        goDate = nil
        isNewRecord = false
        withAnimation(.easeOut(duration: 0.2)) {
            phase = .waiting
        }

        let delay = Double.random(in: 1.5...4.0)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            // Ignore stale wakeups (user tapped early or restarted).
            guard round == currentRound, phase == .waiting else { return }
            goDate = Date()
            GameHaptics.heavy()
            withAnimation(.easeOut(duration: 0.1)) {
                phase = .go
            }
        }
    }

    private func restart() {
        round += 1
        goDate = nil
        lastMs = nil
        sessionBest = nil
        recentTimes = []
        isNewRecord = false
        allTimeBest = GameScores.shared.best(for: game.id)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            phase = .idle
        }
    }
}

#Preview {
    ReactionGameView()
}
