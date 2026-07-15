//
//  ConnectFourGameView.swift
//  ChordLab
//
//  Connect Four vs an alpha-beta AI, or two-player pass & play.
//

import SwiftUI

struct ConnectFourGameView: View {
    private static let cols = 7
    private static let rows = 6

    private enum C4Mode: String, CaseIterable, Identifiable {
        case vsAI = "vs AI"
        case twoPlayer = "2 Players"
        var id: String { rawValue }
    }

    /// 0 = empty, 1 = red (player 1), 2 = yellow (player 2 / AI)
    private struct C4Board {
        var grid = Array(repeating: Array(repeating: 0, count: 7), count: 6)   // [row][col], row 0 = top

        func landingRow(col: Int) -> Int? {
            for row in stride(from: 5, through: 0, by: -1) where grid[row][col] == 0 {
                return row
            }
            return nil
        }

        mutating func drop(col: Int, player: Int) -> Int? {
            guard let row = landingRow(col: col) else { return nil }
            grid[row][col] = player
            return row
        }

        var validColumns: [Int] {
            (0..<7).filter { grid[0][$0] == 0 }
        }

        var isFull: Bool {
            validColumns.isEmpty
        }

        /// Returns the winning player's cells, if any.
        func winningLine() -> (player: Int, cells: [(Int, Int)])? {
            let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
            for row in 0..<6 {
                for col in 0..<7 {
                    let player = grid[row][col]
                    guard player != 0 else { continue }
                    for (dr, dc) in directions {
                        var cells = [(row, col)]
                        var r = row + dr
                        var c = col + dc
                        while r >= 0 && r < 6 && c >= 0 && c < 7 && grid[r][c] == player {
                            cells.append((r, c))
                            if cells.count == 4 {
                                return (player, cells)
                            }
                            r += dr
                            c += dc
                        }
                    }
                }
            }
            return nil
        }

        // MARK: Evaluation for the AI (positive favors `player`)

        func evaluate(for player: Int) -> Int {
            let opponent = player == 1 ? 2 : 1
            var score = 0

            // Slight preference for the center column
            for row in 0..<6 where grid[row][3] == player {
                score += 3
            }

            func scoreWindow(_ window: [Int]) {
                let mine = window.filter { $0 == player }.count
                let theirs = window.filter { $0 == opponent }.count
                let empty = window.filter { $0 == 0 }.count
                if mine == 4 { score += 100_000 }
                else if mine == 3 && empty == 1 { score += 120 }
                else if mine == 2 && empty == 2 { score += 12 }
                if theirs == 4 { score -= 100_000 }
                else if theirs == 3 && empty == 1 { score -= 140 }
                else if theirs == 2 && empty == 2 { score -= 12 }
            }

            for row in 0..<6 {
                for col in 0..<7 {
                    if col + 3 < 7 {
                        scoreWindow([grid[row][col], grid[row][col+1], grid[row][col+2], grid[row][col+3]])
                    }
                    if row + 3 < 6 {
                        scoreWindow([grid[row][col], grid[row+1][col], grid[row+2][col], grid[row+3][col]])
                    }
                    if row + 3 < 6 && col + 3 < 7 {
                        scoreWindow([grid[row][col], grid[row+1][col+1], grid[row+2][col+2], grid[row+3][col+3]])
                    }
                    if row + 3 < 6 && col - 3 >= 0 {
                        scoreWindow([grid[row][col], grid[row+1][col-1], grid[row+2][col-2], grid[row+3][col-3]])
                    }
                }
            }
            return score
        }
    }

    @State private var mode: C4Mode = .vsAI
    @State private var board = C4Board()
    @State private var currentPlayer = 1
    @State private var winner: Int? = nil
    @State private var winningCells: [(Int, Int)] = []
    @State private var isDraw = false
    @State private var aiThinking = false
    @State private var generation = 0
    @State private var sessionWins = [1: 0, 2: 0]

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "connectfour")!, onRestart: { newGame() }) {
            VStack(spacing: 14) {
                Picker("Mode", selection: $mode) {
                    ForEach(C4Mode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .onChange(of: mode) { _, _ in
                    sessionWins = [1: 0, 2: 0]
                    newGame()
                }

                HStack(spacing: 10) {
                    StatPill(label: mode == .vsAI ? "You" : "Red", value: "\(sessionWins[1] ?? 0)", tint: .red)
                    StatPill(label: turnLabel, value: turnSymbol, tint: currentPlayer == 1 ? .red : .yellow)
                    StatPill(label: mode == .vsAI ? "AI" : "Yellow", value: "\(sessionWins[2] ?? 0)", tint: .yellow)
                }

                boardView
                    .padding(.horizontal, 14)

                Spacer(minLength: 0)
            }
            .padding(.top, 4)
            .overlay {
                if winner != nil || isDraw {
                    GameOverOverlay(
                        title: overlayTitle,
                        subtitle: isDraw ? "The board is full." : nil,
                        isVictory: winner == 1 || (mode == .twoPlayer && winner != nil),
                        buttonTitle: "Play Again"
                    ) {
                        newGame()
                    }
                }
            }
        }
    }

    private var turnLabel: String {
        if aiThinking { return "AI" }
        return "Turn"
    }

    private var turnSymbol: String {
        aiThinking ? "…" : "●"
    }

    private var overlayTitle: String {
        if isDraw { return "It's a Draw" }
        guard let winner else { return "" }
        if mode == .vsAI {
            return winner == 1 ? "You Win!" : "AI Wins"
        }
        return winner == 1 ? "Red Wins!" : "Yellow Wins!"
    }

    // MARK: - Board view

    private var boardView: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 6
            let cell = min(
                (geo.size.width - spacing * CGFloat(Self.cols + 1)) / CGFloat(Self.cols),
                (geo.size.height - spacing * CGFloat(Self.rows + 1)) / CGFloat(Self.rows)
            )
            let boardWidth = cell * CGFloat(Self.cols) + spacing * CGFloat(Self.cols + 1)
            let boardHeight = cell * CGFloat(Self.rows) + spacing * CGFloat(Self.rows + 1)

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.gradient)

                VStack(spacing: spacing) {
                    ForEach(0..<Self.rows, id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(0..<Self.cols, id: \.self) { col in
                                discView(row: row, col: col, size: cell)
                            }
                        }
                    }
                }
                .padding(spacing)
            }
            .frame(width: boardWidth, height: boardHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func discView(row: Int, col: Int, size: CGFloat) -> some View {
        let value = board.grid[row][col]
        let isWinning = winningCells.contains { $0.0 == row && $0.1 == col }

        return Circle()
            .fill(discColor(value))
            .overlay(
                Circle()
                    .strokeBorder(isWinning ? Color.white : Color.black.opacity(0.15),
                                  lineWidth: isWinning ? 3 : 1)
            )
            .frame(width: size, height: size)
            .scaleEffect(value == 0 ? 1 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: value)
            .contentShape(Rectangle())
            .onTapGesture {
                humanDrop(col: col)
            }
    }

    private func discColor(_ value: Int) -> Color {
        switch value {
        case 1: return .red
        case 2: return .yellow
        default: return Color.appBackground
        }
    }

    // MARK: - Game flow

    private func newGame() {
        generation += 1
        board = C4Board()
        currentPlayer = 1
        winner = nil
        winningCells = []
        isDraw = false
        aiThinking = false
    }

    private func humanDrop(col: Int) {
        guard winner == nil, !isDraw, !aiThinking else { return }
        guard mode == .twoPlayer || currentPlayer == 1 else { return }
        guard board.landingRow(col: col) != nil else { return }

        GameHaptics.tap()
        _ = board.drop(col: col, player: currentPlayer)
        afterMove()

        if mode == .vsAI && winner == nil && !isDraw {
            scheduleAIMove()
        }
    }

    private func afterMove() {
        if let result = board.winningLine() {
            winner = result.player
            winningCells = result.cells
            sessionWins[result.player, default: 0] += 1
            if mode == .vsAI && result.player == 1 {
                GameHaptics.success()
                let store = GameScores.shared
                store.incrementCounter("wins", for: "connectfour")
                store.setValue(store.counter("wins", for: "connectfour"), for: "connectfour")
            } else if mode == .vsAI {
                GameHaptics.error()
            } else {
                GameHaptics.success()
            }
        } else if board.isFull {
            isDraw = true
            GameHaptics.warning()
        } else {
            currentPlayer = currentPlayer == 1 ? 2 : 1
        }
    }

    private func scheduleAIMove() {
        aiThinking = true
        let gen = generation
        let snapshot = board
        Task { @MainActor in
            let column = Self.bestMove(board: snapshot, aiPlayer: 2, depth: 5)
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard generation == gen, winner == nil, !isDraw else { return }
            aiThinking = false
            GameHaptics.medium()
            _ = board.drop(col: column, player: 2)
            afterMove()
        }
    }

    // MARK: - AI (minimax + alpha-beta)

    private static func bestMove(board: C4Board, aiPlayer: Int, depth: Int) -> Int {
        let ordered = [3, 2, 4, 1, 5, 0, 6].filter { board.validColumns.contains($0) }
        var bestScore = Int.min
        var best = ordered.first ?? 0

        for col in ordered {
            var next = board
            _ = next.drop(col: col, player: aiPlayer)
            let score = minimax(board: next, depth: depth - 1, alpha: Int.min, beta: Int.max,
                                maximizing: false, aiPlayer: aiPlayer)
            if score > bestScore {
                bestScore = score
                best = col
            }
        }
        return best
    }

    private static func minimax(board: C4Board, depth: Int, alpha: Int, beta: Int,
                                maximizing: Bool, aiPlayer: Int) -> Int {
        let human = aiPlayer == 1 ? 2 : 1

        if let result = board.winningLine() {
            // Prefer quicker wins / later losses.
            return result.player == aiPlayer ? 1_000_000 + depth : -1_000_000 - depth
        }
        if board.isFull || depth == 0 {
            return board.evaluate(for: aiPlayer)
        }

        var alpha = alpha
        var beta = beta
        let ordered = [3, 2, 4, 1, 5, 0, 6].filter { board.validColumns.contains($0) }

        if maximizing {
            var value = Int.min
            for col in ordered {
                var next = board
                _ = next.drop(col: col, player: aiPlayer)
                value = max(value, minimax(board: next, depth: depth - 1, alpha: alpha, beta: beta,
                                           maximizing: false, aiPlayer: aiPlayer))
                alpha = max(alpha, value)
                if alpha >= beta { break }
            }
            return value
        } else {
            var value = Int.max
            for col in ordered {
                var next = board
                _ = next.drop(col: col, player: human)
                value = min(value, minimax(board: next, depth: depth - 1, alpha: alpha, beta: beta,
                                           maximizing: true, aiPlayer: aiPlayer))
                beta = min(beta, value)
                if alpha >= beta { break }
            }
            return value
        }
    }
}

#Preview {
    ConnectFourGameView()
}
