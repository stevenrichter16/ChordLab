//
//  GamesHomeView.swift
//  ChordLab
//
//  Hub for the Arcade section: browse games by category and launch them.
//  Games are presented full-screen so the tab bar never overlaps controls.
//

import SwiftUI

struct GamesHomeView: View {
    @State private var scores = GameScores.shared
    @State private var activeGame: GameInfo?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                ForEach(GameCategory.allCases) { category in
                    let games = GameCatalog.games(in: category)
                    if !games.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label(category.rawValue, systemImage: category.icon)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(games) { game in
                                    GameCardView(game: game, scores: scores) {
                                        GameHaptics.tap()
                                        activeGame = game
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 110)   // clearance for the floating tab bar
        }
        .background(Color.appBackground)
        .navigationTitle("Arcade")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $activeGame) { game in
            GameHostView(game: game)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Arcade")
                .font(.system(size: 32, weight: .bold, design: .rounded))
            Text("\(GameCatalog.all.count) games. Zero ads. Take a break from the theory.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Game Card

struct GameCardView: View {
    let game: GameInfo
    let scores: GameScores
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: game.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(game.tint)
                    .frame(width: 46, height: 46)
                    .background(game.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text(game.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(game.blurb)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2, reservesSpace: true)
                        .multilineTextAlignment(.leading)
                }

                bestScoreLine
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var bestScoreLine: some View {
        // Read revision so the card refreshes when scores change.
        let _ = scores.revision
        if let label = game.scoreLabel {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.yellow)
                if let best = scores.best(for: game.id) {
                    Text("\(label): \(best)")
                } else {
                    Text("Not played yet")
                }
            }
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
        } else {
            Color.clear.frame(height: 12)
        }
    }
}

#Preview {
    NavigationStack {
        GamesHomeView()
    }
}
