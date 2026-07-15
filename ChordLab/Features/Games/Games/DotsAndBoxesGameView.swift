//
//  DotsAndBoxesGameView.swift
//  ChordLab
//
//  Dots & Boxes: claim edges, complete boxes for extra turns, and
//  don't hand your opponent a long chain. Chain-aware AI or pass-and-play.
//

import SwiftUI

struct DotsAndBoxesGameView: View {

    // MARK: - Nested Types

    private enum Mode: String, CaseIterable {
        case vsAI = "vs AI"
        case twoPlayers = "2 Players"
    }

    /// Pure-value board model so the AI can simulate cheaply on copies.
    /// Horizontal edges: (size+1) rows x size cols.
    /// Vertical edges:   size rows x (size+1) cols.
    /// Box (r, c) is complete when h[r][c], h[r+1][c], v[r][c], v[r][c+1]
    /// are all claimed.
    private struct BoardModel {
        struct Edge: Hashable {
            let isHorizontal: Bool
            let r: Int
            let c: Int
        }

        let size: Int
        var hEdges: [[Int]]     // 0 = unclaimed, 1 / 2 = owning player
        var vEdges: [[Int]]
        var boxes: [[Int]]      // 0 = unclaimed, 1 / 2 = owning player
        var scores: [Int] = [0, 0]

        init(size: Int) {
            self.size = size
            hEdges = Array(repeating: Array(repeating: 0, count: size), count: size + 1)
            vEdges = Array(repeating: Array(repeating: 0, count: size + 1), count: size)
            boxes = Array(repeating: Array(repeating: 0, count: size), count: size)
        }

        func owner(of edge: Edge) -> Int {
            edge.isHorizontal ? hEdges[edge.r][edge.c] : vEdges[edge.r][edge.c]
        }

        var allEdges: [Edge] {
            var edges: [Edge] = []
            for r in 0...size {
                for c in 0..<size { edges.append(Edge(isHorizontal: true, r: r, c: c)) }
            }
            for r in 0..<size {
                for c in 0...size { edges.append(Edge(isHorizontal: false, r: r, c: c)) }
            }
            return edges
        }

        var unclaimedEdges: [Edge] {
            allEdges.filter { owner(of: $0) == 0 }
        }

        var isFinished: Bool {
            scores[0] + scores[1] == size * size
        }

        func sideCount(_ r: Int, _ c: Int) -> Int {
            var count = 0
            if hEdges[r][c] != 0 { count += 1 }
            if hEdges[r + 1][c] != 0 { count += 1 }
            if vEdges[r][c] != 0 { count += 1 }
            if vEdges[r][c + 1] != 0 { count += 1 }
            return count
        }

        func adjacentBoxes(of edge: Edge) -> [(r: Int, c: Int)] {
            var result: [(r: Int, c: Int)] = []
            if edge.isHorizontal {
                if edge.r > 0 { result.append((edge.r - 1, edge.c)) }
                if edge.r < size { result.append((edge.r, edge.c)) }
            } else {
                if edge.c > 0 { result.append((edge.r, edge.c - 1)) }
                if edge.c < size { result.append((edge.r, edge.c)) }
            }
            return result
        }

        /// Claims an edge for `player` (1 or 2); returns boxes completed.
        @discardableResult
        mutating func claim(_ edge: Edge, player: Int) -> Int {
            guard owner(of: edge) == 0 else { return 0 }
            if edge.isHorizontal {
                hEdges[edge.r][edge.c] = player
            } else {
                vEdges[edge.r][edge.c] = player
            }
            var completed = 0
            for box in adjacentBoxes(of: edge) where boxes[box.r][box.c] == 0 && sideCount(box.r, box.c) == 4 {
                boxes[box.r][box.c] = player
                scores[player - 1] += 1
                completed += 1
            }
            return completed
        }

        /// Would claiming this edge complete at least one box right now?
        func completesBox(_ edge: Edge) -> Bool {
            adjacentBoxes(of: edge).contains {
                boxes[$0.r][$0.c] == 0 && sideCount($0.r, $0.c) == 3
            }
        }

        /// Would claiming this edge leave a 3-sided box for the opponent?
        func createsThreeSidedBox(_ edge: Edge) -> Bool {
            adjacentBoxes(of: edge).contains {
                boxes[$0.r][$0.c] == 0 && sideCount($0.r, $0.c) == 2
            }
        }

        func missingEdge(of r: Int, _ c: Int) -> Edge? {
            if hEdges[r][c] == 0 { return Edge(isHorizontal: true, r: r, c: c) }
            if hEdges[r + 1][c] == 0 { return Edge(isHorizontal: true, r: r + 1, c: c) }
            if vEdges[r][c] == 0 { return Edge(isHorizontal: false, r: r, c: c) }
            if vEdges[r][c + 1] == 0 { return Edge(isHorizontal: false, r: r, c: c + 1) }
            return nil
        }

        /// Approximate length of the chain opened by claiming `edge`:
        /// greedily flood-take every 3-sided box that appears and count them.
        func chainCount(afterClaiming edge: Edge) -> Int {
            var sim = self
            sim.claim(edge, player: 2)
            var count = 0
            var tookBox = true
            while tookBox {
                tookBox = false
                search: for r in 0..<size {
                    for c in 0..<size where sim.boxes[r][c] == 0 && sim.sideCount(r, c) == 3 {
                        if let missing = sim.missingEdge(of: r, c) {
                            count += sim.claim(missing, player: 1)
                            tookBox = true
                            break search
                        }
                    }
                }
            }
            return count
        }
    }

    // MARK: - State

    @State private var mode: Mode = .vsAI
    @State private var gridSize = 4
    @State private var board = BoardModel(size: 4)
    @State private var currentPlayer = 1
    @State private var gameOver = false
    @State private var showOverlay = false
    @State private var roundID = 0

    // MARK: - Body

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "dotsboxes")!, onRestart: startNewGame) {
            ZStack {
                VStack(spacing: 14) {
                    pickers
                    scoreboard
                    statusText
                    boardView
                    Spacer(minLength: 0)
                }
                .padding(.top, 6)
                .onChange(of: mode) { _, _ in startNewGame() }
                .onChange(of: gridSize) { _, _ in startNewGame() }

                if showOverlay {
                    GameOverOverlay(
                        title: overlayTitle,
                        subtitle: overlaySubtitle,
                        isVictory: overlayIsVictory,
                        buttonTitle: "Play Again",
                        action: startNewGame
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

            Picker("Grid", selection: $gridSize) {
                Text("3×3").tag(3)
                Text("4×4").tag(4)
                Text("5×5").tag(5)
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 20)
    }

    private var scoreboard: some View {
        HStack(spacing: 10) {
            StatPill(label: playerName(1), value: "\(board.scores[0])", tint: .blue)
            StatPill(label: "Left",
                     value: "\(gridSize * gridSize - board.scores[0] - board.scores[1])",
                     tint: .gray)
            StatPill(label: playerName(2), value: "\(board.scores[1])", tint: .red)
        }
    }

    private var statusText: some View {
        HStack(spacing: 7) {
            if !gameOver {
                Circle()
                    .fill(playerColor(currentPlayer))
                    .frame(width: 10, height: 10)
            }
            Text(statusMessage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(height: 22)
        .animation(.easeInOut(duration: 0.2), value: statusMessage)
    }

    private var statusMessage: String {
        if gameOver { return "Game over" }
        if mode == .vsAI {
            return currentPlayer == 1 ? "Your turn — tap an edge" : "AI is thinking…"
        }
        return "\(playerName(currentPlayer))'s turn"
    }

    private var boardView: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = side / CGFloat(gridSize)

            ZStack(alignment: .topLeading) {
                boxLayer(cell: cell)
                edgeLayer(cell: cell)
                dotLayer(cell: cell)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 330)
        .padding(.horizontal, 28)
        .padding(.vertical, 8)
    }

    private func boxLayer(cell: CGFloat) -> some View {
        ForEach(0..<gridSize, id: \.self) { r in
            ForEach(0..<gridSize, id: \.self) { c in
                let owner = board.boxes[r][c]
                if owner != 0 {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(playerColor(owner).opacity(0.32))
                        .overlay(
                            Text(playerInitial(owner))
                                .font(.system(size: cell * 0.34, weight: .bold, design: .rounded))
                                .foregroundStyle(playerColor(owner))
                        )
                        .frame(width: cell - 16, height: cell - 16)
                        .position(x: (CGFloat(c) + 0.5) * cell,
                                  y: (CGFloat(r) + 0.5) * cell)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                }
            }
        }
    }

    @ViewBuilder
    private func edgeLayer(cell: CGFloat) -> some View {
        ForEach(0...gridSize, id: \.self) { r in
            ForEach(0..<gridSize, id: \.self) { c in
                edgeView(BoardModel.Edge(isHorizontal: true, r: r, c: c), cell: cell)
            }
        }
        ForEach(0..<gridSize, id: \.self) { r in
            ForEach(0...gridSize, id: \.self) { c in
                edgeView(BoardModel.Edge(isHorizontal: false, r: r, c: c), cell: cell)
            }
        }
    }

    private func edgeView(_ edge: BoardModel.Edge, cell: CGFloat) -> some View {
        let owner = board.owner(of: edge)
        let claimed = owner != 0
        let length = cell - 14
        let thickness: CGFloat = claimed ? 6 : 2.5
        let center: CGPoint = edge.isHorizontal
            ? CGPoint(x: (CGFloat(edge.c) + 0.5) * cell, y: CGFloat(edge.r) * cell)
            : CGPoint(x: CGFloat(edge.c) * cell, y: (CGFloat(edge.r) + 0.5) * cell)

        return Capsule()
            .fill(claimed ? playerColor(owner) : Color.gray.opacity(0.3))
            .frame(width: edge.isHorizontal ? length : thickness,
                   height: edge.isHorizontal ? thickness : length)
            .frame(width: edge.isHorizontal ? cell - 10 : 30,
                   height: edge.isHorizontal ? 30 : cell - 10)
            .contentShape(Rectangle())
            .onTapGesture { tapEdge(edge) }
            .position(center)
    }

    private func dotLayer(cell: CGFloat) -> some View {
        ForEach(0...gridSize, id: \.self) { r in
            ForEach(0...gridSize, id: \.self) { c in
                Circle()
                    .fill(Color.primary.opacity(0.55))
                    .frame(width: 9, height: 9)
                    .position(x: CGFloat(c) * cell, y: CGFloat(r) * cell)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Overlay content

    private var overlayTitle: String {
        let p1 = board.scores[0]
        let p2 = board.scores[1]
        if p1 == p2 { return "It's a Tie" }
        if mode == .vsAI { return p1 > p2 ? "You Win!" : "AI Wins" }
        return p1 > p2 ? "Player 1 Wins!" : "Player 2 Wins!"
    }

    private var overlaySubtitle: String {
        "\(playerName(1)) \(board.scores[0]) — \(board.scores[1]) \(playerName(2))"
    }

    private var overlayIsVictory: Bool {
        let p1 = board.scores[0]
        let p2 = board.scores[1]
        guard p1 != p2 else { return false }
        return mode == .vsAI ? p1 > p2 : true
    }

    // MARK: - Player helpers

    private func playerName(_ player: Int) -> String {
        if mode == .vsAI { return player == 1 ? "You" : "AI" }
        return player == 1 ? "Player 1" : "Player 2"
    }

    private func playerInitial(_ player: Int) -> String {
        if mode == .vsAI { return player == 1 ? "Y" : "A" }
        return player == 1 ? "1" : "2"
    }

    private func playerColor(_ player: Int) -> Color {
        player == 1 ? .blue : .red
    }

    // MARK: - Game Flow

    private func tapEdge(_ edge: BoardModel.Edge) {
        guard !gameOver, board.owner(of: edge) == 0 else { return }
        if mode == .vsAI && currentPlayer == 2 { return }
        applyEdge(edge)
    }

    private func applyEdge(_ edge: BoardModel.Edge) {
        var completed = 0
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            completed = board.claim(edge, player: currentPlayer)
        }
        if completed > 0 {
            GameHaptics.medium()
        } else {
            GameHaptics.tap()
        }

        if board.isFinished {
            finishGame()
            return
        }

        // Completing a box grants another turn; otherwise pass the turn.
        if completed == 0 {
            currentPlayer = currentPlayer == 1 ? 2 : 1
            if mode == .vsAI && currentPlayer == 2 {
                scheduleAITurn()
            }
        }
    }

    private func finishGame() {
        gameOver = true
        let p1 = board.scores[0]
        let p2 = board.scores[1]

        if mode == .vsAI {
            if p1 > p2 {
                GameHaptics.success()
                let scores = GameScores.shared
                scores.incrementCounter("wins", for: "dotsboxes")
                scores.setValue(scores.counter("wins", for: "dotsboxes"), for: "dotsboxes")
            } else if p2 > p1 {
                GameHaptics.error()
            } else {
                GameHaptics.warning()
            }
        } else {
            if p1 == p2 { GameHaptics.warning() } else { GameHaptics.success() }
        }

        let generation = roundID
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard generation == roundID else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                showOverlay = true
            }
        }
    }

    private func startNewGame() {
        roundID += 1
        gameOver = false
        currentPlayer = 1
        withAnimation(.easeOut(duration: 0.2)) {
            showOverlay = false
            board = BoardModel(size: gridSize)
        }
    }

    // MARK: - AI

    /// Loops as long as it stays the AI's turn (chains grant extra turns),
    /// pausing ~0.5s between consecutive edges so chains are visible.
    private func scheduleAITurn() {
        let generation = roundID
        Task { @MainActor in
            while true {
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard generation == roundID,
                      mode == .vsAI,
                      currentPlayer == 2,
                      !gameOver else { return }
                guard let edge = Self.aiChooseEdge(in: board) else { return }
                applyEdge(edge)
            }
        }
    }

    private static func aiChooseEdge(in board: BoardModel) -> BoardModel.Edge? {
        let free = board.unclaimedEdges
        guard !free.isEmpty else { return nil }

        // 1. Take any box that can be completed right now
        //    (chains continue naturally via the extra-turn rule).
        if let scoring = free.first(where: { board.completesBox($0) }) {
            return scoring
        }

        // 2. Prefer edges that don't hand the opponent a 3-sided box.
        let safe = free.filter { !board.createsThreeSidedBox($0) }
        if let pick = safe.randomElement() {
            return pick
        }

        // 3. Forced to give something away: open the shortest chain.
        var best = free[0]
        var bestChain = Int.max
        for edge in free.shuffled() {
            let chain = board.chainCount(afterClaiming: edge)
            if chain < bestChain {
                bestChain = chain
                best = edge
            }
        }
        return best
    }
}

#Preview {
    DotsAndBoxesGameView()
}
