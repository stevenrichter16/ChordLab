//
//  GameHostView.swift
//  ChordLab
//
//  Routes a GameInfo to its concrete game view.
//

import SwiftUI

struct GameHostView: View {
    let game: GameInfo

    var body: some View {
        switch game.id {
        default:
            GameComingSoonView(game: game)
        }
    }
}

// MARK: - Placeholder for games not yet implemented

struct GameComingSoonView: View {
    let game: GameInfo

    var body: some View {
        GameScreen(game: game) {
            VStack(spacing: 16) {
                Image(systemName: game.icon)
                    .font(.system(size: 56))
                    .foregroundStyle(game.tint)
                Text("Coming soon")
                    .font(.title2.weight(.bold))
                Text(game.blurb)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
        }
    }
}
