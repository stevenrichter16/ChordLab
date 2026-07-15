//
//  TicTacToeGameView.swift
//  ChordLab
//
//  Tic-Tac-Toe: pass-and-play or take on an easy / unbeatable minimax AI.
//

import SwiftUI

struct TicTacToeGameView: View {

    // MARK: - Nested Types

    private enum Mark: Equatable {
        case x
        case o

        var symbol: String { self == .x ? "xmark" : "circle" }
        var tint: Color { self == .x ? .blue : .red }
        var label: String { self == .x ? "X" : "O" }
        var opponent: Mark { self == .x ? .o : .x }
    }

    private enum Mode: String, CaseIterable {
        case vsAI = "vs AI"
        case twoPlayers = "2 Players"
    }

    private enum Difficulty: String, CaseIterable {
        case easy = "Easy"
        case unbeatable = "Unbeatable"
    }

    /// Animatable strike-through line drawn over the three winning cells.
    private struct StrikeLine: Shape {
        var start: CGPoint
        var end: CGPoint
        var progress: CGFloat

        var animatableData: CGFloat {
            get { progress }
            set { progress = newValue }
        }

        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: start)
            path.addLine(to: CGPoint(x: start.x + (end.x - start.x) * progress,
                                     y: start.y + (end.y - start.y) * progress))
            return path
        }
    }

    // MARK: - State

    @State private var board: [Mark?] = Array(repeating: nil, count: 9)
    @State private var currentPlayer: Mark = .x
    @State private var winner: Mark?
    @State private var winLine: [Int]?
    @State private var isDraw = false
    @State private var showOverlay = false
    @State private var strikeProgress: CGFloat = 0
    @State private var mode: Mode = .vsAI
    @State private var difficulty: Difficulty = .unbeatable
    @State private var roundID = 0
    @State private var xWins = 0
    @State private var oWins = 0
    @State private var draws = 0
    @State private var twoPlayerStarter: Mark = .x

    private static let winPatterns: [[Int]] = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6]
    ]

    private var roundOver: Bool { winner != nil || isDraw }

    // MARK: - Body

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "tictactoe")!, onRestart: restartEverything) {
            ZStack {
                VStack(spacing: 14) {
                    pickers
                    scoreboard
                    statusText
                    boardView
                    Spacer(minLength: 0)
                }
                .padding(.top, 6)
                .onChange(of: mode) { _, _ in
                    xWins = 0
                    oWins = 0
                    draws = 0
                    twoPlayerStarter = .x
                    resetRound(startingWith: .x)
                }
                .onChange(of: difficulty) { _, _ in
                    resetRound(startingWith: .x)
                }

                if showOverlay {
                    GameOverOverlay(
                        title: overlayTitle,
                        subtitle: overlaySubtitle,
                        isVictory: overlayIsVictory,
                        buttonTitle: "Play Again",
                        action: startNextRound
                    )
                }
            }
        }
    }

    // MARK: - Subviews

    private var pickers: some View {
        VStack(spacing: 10) {
            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if mode == .vsAI {
                Picker("Difficulty", selection: $difficulty) {
                    ForEach(Difficulty.allCases, id: \.self) { difficulty in
                        Text(difficulty.rawValue).tag(difficulty)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(.horizontal, 20)
    }

    private var scoreboard: some View {
        HStack(spacing: 10) {
            StatPill(label: mode == .vsAI ? "You (X)" : "X Wins", value: "\(xWins)", tint: .blue)
            StatPill(label: "Draws", value: "\(draws)", tint: .gray)
            StatPill(label: mode == .vsAI ? "AI (O)" : "O Wins", value: "\(oWins)", tint: .red)
        }
    }

    private var statusText: some View {
        HStack(spacing: 7) {
            if !roundOver {
                Image(systemName: currentPlayer.symbol)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(currentPlayer.tint)
            }
            Text(statusMessage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(height: 22)
        .animation(.easeInOut(duration: 0.2), value: statusMessage)
    }

    private var statusMessage: String {
        if let winner {
            if mode == .vsAI { return winner == .x ? "You win!" : "AI wins!" }
            return "\(winner.label) wins!"
        }
        if isDraw { return "It's a draw" }
        if mode == .vsAI {
            return currentPlayer == .x ? "Your turn" : "AI is thinking…"
        }
        return "\(currentPlayer.label)'s turn"
    }

    private var boardView: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let spacing: CGFloat = 10
            let cell = (side - spacing * 2) / 3

            ZStack(alignment: .topLeading) {
                VStack(spacing: spacing) {
                    ForEach(0..<3, id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(0..<3, id: \.self) { col in
                                cellView(row * 3 + col, size: cell)
                            }
                        }
                    }
                }

                if let line = winLine, let winner {
                    StrikeLine(start: cellCenter(line[0], cell: cell, spacing: spacing),
                               end: cellCenter(line[2], cell: cell, spacing: spacing),
                               progress: strikeProgress)
                        .stroke(winner.tint, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .shadow(color: winner.tint.opacity(0.5), radius: 4)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 340)
        .padding(.horizontal, 24)
        .padding(.top, 4)
    }

    private func cellView(_ index: Int, size: CGFloat) -> some View {
        let mark = board[index]
        let isWinningCell = winLine?.contains(index) ?? false

        return Button {
            handleTap(index)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isWinningCell
                          ? (winner?.tint ?? Color.appPrimary).opacity(0.25)
                          : Color.appSecondaryBackground)

                if let mark {
                    Image(systemName: mark.symbol)
                        .font(.system(size: size * 0.42, weight: .bold))
                        .foregroundStyle(mark.tint)
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                }
            }
            .frame(width: size, height: size)
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func cellCenter(_ index: Int, cell: CGFloat, spacing: CGFloat) -> CGPoint {
        let row = CGFloat(index / 3)
        let col = CGFloat(index % 3)
        return CGPoint(x: col * (cell + spacing) + cell / 2,
                       y: row * (cell + spacing) + cell / 2)
    }

    // MARK: - Overlay content

    private var overlayTitle: String {
        if let winner {
            if mode == .vsAI { return winner == .x ? "You Win!" : "AI Wins" }
            return "\(winner.label) Wins!"
        }
        return "It's a Draw"
    }

    private var overlaySubtitle: String {
        if mode == .vsAI {
            return "You \(xWins) · Draws \(draws) · AI \(oWins)"
        }
        return "X \(xWins) · Draws \(draws) · O \(oWins)"
    }

    private var overlayIsVictory: Bool {
        guard let winner else { return false }
        return mode == .vsAI ? winner == .x : true
    }

    // MARK: - Game Flow

    private func handleTap(_ index: Int) {
        guard board[index] == nil, !roundOver else { return }
        if mode == .vsAI && currentPlayer == .o { return }
        GameHaptics.tap()
        place(currentPlayer, at: index)
    }

    private func place(_ mark: Mark, at index: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
            board[index] = mark
        }

        if let (winMark, line) = Self.winningLine(in: board) {
            finishRound(winner: winMark, line: line)
        } else if !board.contains(nil) {
            finishRound(winner: nil, line: nil)
        } else {
            currentPlayer = mark.opponent
            if mode == .vsAI && currentPlayer == .o {
                scheduleAIMove()
            }
        }
    }

    private func finishRound(winner winMark: Mark?, line: [Int]?) {
        winner = winMark
        isDraw = winMark == nil

        if let winMark {
            winLine = line
            withAnimation(.easeOut(duration: 0.45).delay(0.1)) {
                strikeProgress = 1
            }
            if winMark == .x { xWins += 1 } else { oWins += 1 }

            if mode == .vsAI {
                if winMark == .x {
                    GameHaptics.success()
                    let scores = GameScores.shared
                    scores.incrementCounter("wins", for: "tictactoe")
                    scores.setValue(scores.counter("wins", for: "tictactoe"), for: "tictactoe")
                } else {
                    GameHaptics.error()
                }
            } else {
                GameHaptics.success()
            }
        } else {
            draws += 1
            GameHaptics.warning()
        }

        let generation = roundID
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard generation == roundID else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                showOverlay = true
            }
        }
    }

    private func startNextRound() {
        let starter: Mark
        if mode == .twoPlayers {
            twoPlayerStarter = twoPlayerStarter.opponent
            starter = twoPlayerStarter
        } else {
            starter = .x
        }
        resetRound(startingWith: starter)
    }

    private func restartEverything() {
        xWins = 0
        oWins = 0
        draws = 0
        twoPlayerStarter = .x
        resetRound(startingWith: .x)
    }

    private func resetRound(startingWith starter: Mark) {
        roundID += 1
        strikeProgress = 0
        winner = nil
        winLine = nil
        isDraw = false
        currentPlayer = starter
        withAnimation(.easeOut(duration: 0.2)) {
            showOverlay = false
            board = Array(repeating: nil, count: 9)
        }
    }

    // MARK: - AI

    private func scheduleAIMove() {
        let generation = roundID
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard generation == roundID,
                  mode == .vsAI,
                  currentPlayer == .o,
                  !roundOver else { return }

            let index = difficulty == .unbeatable
                ? Self.minimaxMove(for: .o, in: board)
                : Self.easyMove(for: .o, in: board)

            guard let index, board[index] == nil else { return }
            place(.o, at: index)
        }
    }

    /// Easy: random empty cell, with a 30% chance of spotting the
    /// winning / blocking move first.
    private static func easyMove(for ai: Mark, in board: [Mark?]) -> Int? {
        let empty = board.indices.filter { board[$0] == nil }
        guard !empty.isEmpty else { return nil }

        if Double.random(in: 0..<1) < 0.3 {
            if let winning = immediateWin(for: ai, in: board) { return winning }
            if let block = immediateWin(for: ai.opponent, in: board) { return block }
        }
        return empty.randomElement()
    }

    private static func immediateWin(for mark: Mark, in board: [Mark?]) -> Int? {
        for index in board.indices where board[index] == nil {
            var next = board
            next[index] = mark
            if let (winMark, _) = winningLine(in: next), winMark == mark {
                return index
            }
        }
        return nil
    }

    /// Unbeatable: full minimax, preferring faster wins / slower losses
    /// via a depth adjustment on the score.
    private static func minimaxMove(for ai: Mark, in board: [Mark?]) -> Int? {
        var bestScore = Int.min
        var bestIndex: Int?
        for index in board.indices where board[index] == nil {
            var next = board
            next[index] = ai
            let score = minimax(next, ai: ai, current: ai.opponent, depth: 1)
            if score > bestScore {
                bestScore = score
                bestIndex = index
            }
        }
        return bestIndex
    }

    private static func minimax(_ board: [Mark?], ai: Mark, current: Mark, depth: Int) -> Int {
        if let (winMark, _) = winningLine(in: board) {
            return winMark == ai ? 10 - depth : depth - 10
        }
        if !board.contains(nil) { return 0 }

        var best = current == ai ? Int.min : Int.max
        for index in board.indices where board[index] == nil {
            var next = board
            next[index] = current
            let score = minimax(next, ai: ai, current: current.opponent, depth: depth + 1)
            best = current == ai ? max(best, score) : min(best, score)
        }
        return best
    }

    private static func winningLine(in board: [Mark?]) -> (Mark, [Int])? {
        for pattern in winPatterns {
            if let mark = board[pattern[0]],
               board[pattern[1]] == mark,
               board[pattern[2]] == mark {
                return (mark, pattern)
            }
        }
        return nil
    }
}

#Preview {
    TicTacToeGameView()
}
