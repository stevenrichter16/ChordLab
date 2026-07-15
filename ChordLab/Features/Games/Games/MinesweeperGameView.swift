//
//  MinesweeperGameView.swift
//  ChordLab
//
//  Minesweeper: tap to reveal, long-press (or flag mode) to flag.
//  First tap is always safe.
//

import SwiftUI

struct MinesweeperGameView: View {
    private struct MSCell {
        var isMine = false
        var isRevealed = false
        var isFlagged = false
        var adjacent = 0
    }

    private enum MSPhase {
        case fresh       // board built, mines not placed yet (first tap pending)
        case playing
        case won
        case lost
    }

    private enum MSDifficulty: String, CaseIterable, Identifiable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"

        var id: String { rawValue }

        var columns: Int { 9 }

        var rows: Int {
            switch self {
            case .easy: return 9
            case .medium: return 12
            case .hard: return 14
            }
        }

        var mines: Int {
            switch self {
            case .easy: return 10
            case .medium: return 22
            case .hard: return 32
            }
        }
    }

    @State private var difficulty: MSDifficulty = .easy
    @State private var board: [[MSCell]] = []
    @State private var phase: MSPhase = .fresh
    @State private var flagMode = false
    @State private var flagsPlaced = 0
    @State private var elapsed = 0
    @State private var tickCount = 0

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var rows: Int { board.count }
    private var cols: Int { board.first?.count ?? 0 }

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "minesweeper")!, onRestart: { newGame() }) {
            VStack(spacing: 12) {
                Picker("Difficulty", selection: $difficulty) {
                    ForEach(MSDifficulty.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .onChange(of: difficulty) { _, _ in
                    newGame()
                }

                HStack(spacing: 10) {
                    StatPill(label: "Mines", value: "\(difficulty.mines - flagsPlaced)", tint: .red)
                    StatPill(label: "Time", value: "\(elapsed)s")
                    StatPill(label: "Wins", value: "\(GameScores.shared.counter("wins", for: "minesweeper"))", tint: .green)
                }

                boardView
                    .padding(.horizontal, 12)

                flagToggle
                    .padding(.bottom, 8)
            }
            .padding(.top, 4)
            .overlay {
                if phase == .won || phase == .lost {
                    GameOverOverlay(
                        title: phase == .won ? "Field Cleared!" : "Boom! 💥",
                        subtitle: phase == .won ? "Solved in \(elapsed)s" : "You hit a mine.",
                        isVictory: phase == .won,
                        buttonTitle: "New Game"
                    ) {
                        newGame()
                    }
                }
            }
            .onReceive(ticker) { _ in
                if phase == .playing {
                    elapsed += 1
                }
            }
            .onAppear {
                if board.isEmpty {
                    newGame()
                }
            }
        }
    }

    // MARK: - Board rendering

    private var boardView: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 2
            let cellSize = min(
                (geo.size.width - spacing * CGFloat(cols - 1)) / CGFloat(max(cols, 1)),
                (geo.size.height - spacing * CGFloat(rows - 1)) / CGFloat(max(rows, 1))
            )

            VStack(spacing: spacing) {
                ForEach(0..<rows, id: \.self) { r in
                    HStack(spacing: spacing) {
                        ForEach(0..<cols, id: \.self) { c in
                            cellView(r: r, c: c, size: cellSize)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func cellView(r: Int, c: Int, size: CGFloat) -> some View {
        let cell = board[r][c]
        return ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(cellColor(cell))

            if cell.isRevealed {
                if cell.isMine {
                    Text("💣").font(.system(size: size * 0.55))
                } else if cell.adjacent > 0 {
                    Text("\(cell.adjacent)")
                        .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
                        .foregroundStyle(numberColor(cell.adjacent))
                }
            } else if cell.isFlagged {
                Text("🚩").font(.system(size: size * 0.5))
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap(r: r, c: c)
        }
        .onLongPressGesture(minimumDuration: 0.3) {
            toggleFlag(r: r, c: c)
        }
    }

    private func cellColor(_ cell: MSCell) -> Color {
        if cell.isRevealed {
            return cell.isMine ? Color.red.opacity(0.55) : Color.appTertiaryBackground
        }
        return Color.appPrimary.opacity(0.35)
    }

    private func numberColor(_ n: Int) -> Color {
        switch n {
        case 1: return .blue
        case 2: return .green
        case 3: return .red
        case 4: return .purple
        case 5: return .orange
        default: return .pink
        }
    }

    private var flagToggle: some View {
        Button {
            GameHaptics.tap()
            flagMode.toggle()
        } label: {
            Label(flagMode ? "Flag mode: ON" : "Flag mode: OFF", systemImage: "flag.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(flagMode ? .white : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(flagMode ? Color.red : Color.appSecondaryBackground, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Game logic

    private func newGame() {
        board = Array(repeating: Array(repeating: MSCell(), count: difficulty.columns),
                      count: difficulty.rows)
        phase = .fresh
        flagsPlaced = 0
        elapsed = 0
        flagMode = false
    }

    private func neighbors(r: Int, c: Int) -> [(Int, Int)] {
        var result: [(Int, Int)] = []
        for dr in -1...1 {
            for dc in -1...1 where !(dr == 0 && dc == 0) {
                let nr = r + dr
                let nc = c + dc
                if nr >= 0 && nr < rows && nc >= 0 && nc < cols {
                    result.append((nr, nc))
                }
            }
        }
        return result
    }

    /// Places mines everywhere except the first-tapped cell and its neighbors.
    private func placeMines(avoiding r: Int, _ c: Int) {
        var forbidden = Set(neighbors(r: r, c: c).map { $0.0 * cols + $0.1 })
        forbidden.insert(r * cols + c)

        var candidates = Array(0..<(rows * cols)).filter { !forbidden.contains($0) }
        candidates.shuffle()

        for index in candidates.prefix(difficulty.mines) {
            board[index / cols][index % cols].isMine = true
        }

        for rr in 0..<rows {
            for cc in 0..<cols {
                board[rr][cc].adjacent = neighbors(r: rr, c: cc)
                    .filter { board[$0.0][$0.1].isMine }
                    .count
            }
        }
    }

    private func handleTap(r: Int, c: Int) {
        guard phase == .fresh || phase == .playing else { return }

        if flagMode && phase == .playing {
            toggleFlag(r: r, c: c)
            return
        }

        let cell = board[r][c]
        if cell.isFlagged { return }

        if phase == .fresh {
            placeMines(avoiding: r, c)
            phase = .playing
        }

        if cell.isRevealed {
            chord(r: r, c: c)
            return
        }

        GameHaptics.tap()
        reveal(r: r, c: c)
        checkEnd()
    }

    private func toggleFlag(r: Int, c: Int) {
        guard phase == .playing, !board[r][c].isRevealed else { return }
        GameHaptics.medium()
        board[r][c].isFlagged.toggle()
        flagsPlaced += board[r][c].isFlagged ? 1 : -1
    }

    /// Reveals a cell; flood-fills zero regions iteratively.
    private func reveal(r: Int, c: Int) {
        guard !board[r][c].isRevealed, !board[r][c].isFlagged else { return }

        if board[r][c].isMine {
            board[r][c].isRevealed = true
            lose()
            return
        }

        var queue = [(r, c)]
        while let (qr, qc) = queue.popLast() {
            guard !board[qr][qc].isRevealed, !board[qr][qc].isFlagged, !board[qr][qc].isMine else { continue }
            board[qr][qc].isRevealed = true
            if board[qr][qc].adjacent == 0 {
                queue.append(contentsOf: neighbors(r: qr, c: qc))
            }
        }
    }

    /// Tap a satisfied number to reveal its remaining neighbors.
    private func chord(r: Int, c: Int) {
        let cell = board[r][c]
        guard cell.adjacent > 0 else { return }
        let around = neighbors(r: r, c: c)
        let flagged = around.filter { board[$0.0][$0.1].isFlagged }.count
        guard flagged == cell.adjacent else { return }

        GameHaptics.tap()
        for (nr, nc) in around where !board[nr][nc].isFlagged && !board[nr][nc].isRevealed {
            if board[nr][nc].isMine {
                board[nr][nc].isRevealed = true
                lose()
                return
            }
            reveal(r: nr, c: nc)
        }
        checkEnd()
    }

    private func checkEnd() {
        guard phase == .playing else { return }
        let unrevealedSafe = board.joined().contains { !$0.isMine && !$0.isRevealed }
        if !unrevealedSafe {
            phase = .won
            GameHaptics.success()
            let store = GameScores.shared
            store.incrementCounter("wins", for: "minesweeper")
            store.setValue(store.counter("wins", for: "minesweeper"), for: "minesweeper")
        }
    }

    private func lose() {
        guard phase == .playing else { return }
        phase = .lost
        GameHaptics.error()
        for r in 0..<rows {
            for c in 0..<cols where board[r][c].isMine {
                board[r][c].isRevealed = true
            }
        }
    }
}

#Preview {
    MinesweeperGameView()
}
