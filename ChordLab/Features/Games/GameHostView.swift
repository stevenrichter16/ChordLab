//
//  GameHostView.swift
//  ChordLab
//
//  Routes a GameInfo to its concrete game view.
//

import SwiftUI
import UIKit

struct GameHostView: View {
    let game: GameInfo

    var body: some View {
        gameBody
            .onAppear {
                // Watch sims are meant to be left running; keep the screen awake.
                if game.category == .watch {
                    UIApplication.shared.isIdleTimerDisabled = true
                }
            }
            .onDisappear {
                if game.category == .watch {
                    UIApplication.shared.isIdleTimerDisabled = false
                }
            }
    }

    @ViewBuilder
    private var gameBody: some View {
        switch game.id {
        case "tictactoe": TicTacToeGameView()
        case "connectfour": ConnectFourGameView()
        case "rps": RPSGameView()
        case "dotsboxes": DotsAndBoxesGameView()
        case "yahtzee": YahtzeeGameView()
        case "pong": PongGameView()
        case "snake": SnakeGameView()
        case "game2048": Game2048View()
        case "breakout": BreakoutGameView()
        case "whackamole": WhackAMoleGameView()
        case "simon": SimonGameView()
        case "reaction": ReactionGameView()
        case "flappy": FlappyGameView()
        case "blackjack": BlackjackGameView()
        case "higherlower": HigherLowerGameView()
        case "videopoker": VideoPokerGameView()
        case "solitaire": SolitaireGameView()
        case "minesweeper": MinesweeperGameView()
        case "sudoku": SudokuGameView()
        case "lightsout": LightsOutGameView()
        case "memory": MemoryMatchGameView()
        case "wordguess": WordGuessGameView()
        case "hangman": HangmanGameView()
        case "sheepdog": SheepdogGameView()
        case "traffic": TrafficGameView()
        case "lemonade": LemonadeGameView()
        case "outbreak": OutbreakGameView()
        case "athanor": AthanorGameView()
        case "particlelife": ParticleLifeGameView()
        case "wealthants": WealthAntsGameView()
        case "forestfire": ForestFireGameView()
        case "windowlights": WindowLightsGameView()
        case "moss": MossGardenGameView()
        case "smalllife": SmallLifeGameView()
        default: GameComingSoonView(game: game)
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
