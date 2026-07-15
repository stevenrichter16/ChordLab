//
//  OutbreakGameView.swift
//  ChordLab
//
//  Outbreak: a turn-based epidemic on a grid. Spend three action points
//  a turn on vaccines, walls, and cures, then watch the infection spread.
//  Save as many people as you can.
//

import SwiftUI

struct OutbreakGameView: View {
    private enum Cell: Equatable {
        case healthy
        case infected(turnsLeft: Int)
        case immune
        case dead
        case wall

        var isInfected: Bool {
            if case .infected = self { return true }
            return false
        }
    }

    private enum Tool: String, CaseIterable, Identifiable {
        case vaccinate = "Vaccine"
        case wall = "Wall"
        case cure = "Cure"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .vaccinate: return "syringe.fill"
            case .wall: return "square.stack.3d.up.fill"
            case .cure: return "cross.vial.fill"
            }
        }

        var cost: Int {
            self == .cure ? 2 : 1
        }

        var tint: Color {
            switch self {
            case .vaccinate: return .blue
            case .wall: return .brown
            case .cure: return .green
            }
        }
    }

    private enum OutbreakPhase {
        case playing
        case finished
    }

    private static let gridSize = 14
    private static let apPerTurn = 3
    private static let maxTurns = 20
    private static let infectionChance = 0.45
    private static let infectionDuration = 3

    @State private var grid: [[Cell]] = []
    @State private var tool: Tool = .vaccinate
    @State private var actionPoints = OutbreakGameView.apPerTurn
    @State private var turn = 1
    @State private var phase: OutbreakPhase = .playing
    @State private var isNewRecord = false

    private var population: Int {
        Self.gridSize * Self.gridSize
    }

    private var infectedCount: Int {
        grid.joined().filter(\.isInfected).count
    }

    private var deadCount: Int {
        grid.joined().filter { $0 == .dead }.count
    }

    private var survivorCount: Int {
        grid.joined().filter { $0 == .healthy || $0 == .immune }.count
    }

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "outbreak")!, onRestart: { newGame() }) {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    StatPill(label: "Turn", value: "\(turn)/\(Self.maxTurns)")
                    StatPill(label: "Infected", value: "\(infectedCount)", tint: .red)
                    StatPill(label: "Lost", value: "\(deadCount)", tint: .gray)
                    StatPill(label: "AP", value: "\(actionPoints)", tint: .green)
                }

                gridView
                    .padding(.horizontal, 12)

                toolPicker
                    .padding(.horizontal, 16)

                ArcadeButton(title: "End Turn",
                             systemImage: "forward.fill",
                             tint: .teal,
                             isEnabled: phase == .playing) {
                    endTurn()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .padding(.top, 4)
            .overlay {
                if phase == .finished {
                    GameOverOverlay(
                        title: infectedCount == 0 ? "Outbreak Contained!" : "The Season Ends",
                        subtitle: "\(survivorCount) of \(population) saved • \(deadCount) lost",
                        isVictory: infectedCount == 0,
                        newRecord: isNewRecord,
                        buttonTitle: "New Outbreak"
                    ) {
                        newGame()
                    }
                }
            }
            .onAppear {
                if grid.isEmpty {
                    newGame()
                }
            }
        }
    }

    // MARK: - Grid

    private var gridView: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 2
            let cellSize = min(
                (geo.size.width - spacing * CGFloat(Self.gridSize - 1)) / CGFloat(Self.gridSize),
                (geo.size.height - spacing * CGFloat(Self.gridSize - 1)) / CGFloat(Self.gridSize)
            )

            // Iterate the actual array so the first body evaluation
            // (before onAppear seeds the grid) can't index out of range.
            VStack(spacing: spacing) {
                ForEach(0..<grid.count, id: \.self) { r in
                    HStack(spacing: spacing) {
                        ForEach(0..<grid[r].count, id: \.self) { c in
                            cellView(r: r, c: c, size: cellSize)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func cellView(r: Int, c: Int, size: CGFloat) -> some View {
        let cell = grid[r][c]
        return RoundedRectangle(cornerRadius: 3)
            .fill(cellColor(cell))
            .overlay {
                if case .wall = cell {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: size * 0.42))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            .frame(width: size, height: size)
            .contentShape(Rectangle())
            .onTapGesture {
                applyTool(r: r, c: c)
            }
            .animation(.easeInOut(duration: 0.2), value: cell)
    }

    private func cellColor(_ cell: Cell) -> Color {
        switch cell {
        case .healthy: return Color.green.opacity(0.45)
        case .infected(let turnsLeft):
            return Color.red.opacity(turnsLeft == 1 ? 0.95 : 0.7)
        case .immune: return Color.blue.opacity(0.65)
        case .dead: return Color.black.opacity(0.55)
        case .wall: return Color.brown.opacity(0.8)
        }
    }

    private var toolPicker: some View {
        HStack(spacing: 8) {
            ForEach(Tool.allCases) { candidate in
                Button {
                    GameHaptics.tap()
                    tool = candidate
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: candidate.icon)
                            .font(.system(size: 16, weight: .semibold))
                        Text("\(candidate.rawValue) · \(candidate.cost) AP")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(tool == candidate ? .white : candidate.tint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        tool == candidate ? candidate.tint : candidate.tint.opacity(0.14),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Actions

    private func applyTool(r: Int, c: Int) {
        guard phase == .playing, actionPoints >= tool.cost else {
            GameHaptics.warning()
            return
        }

        switch tool {
        case .vaccinate:
            guard grid[r][c] == .healthy else { GameHaptics.warning(); return }
            grid[r][c] = .immune
        case .wall:
            guard grid[r][c] == .healthy else { GameHaptics.warning(); return }
            grid[r][c] = .wall
        case .cure:
            guard grid[r][c].isInfected else { GameHaptics.warning(); return }
            grid[r][c] = .immune
        }

        GameHaptics.tap()
        actionPoints -= tool.cost
    }

    private func endTurn() {
        guard phase == .playing else { return }
        GameHaptics.medium()

        // Spread from a snapshot so brand-new infections don't chain this turn.
        let snapshot = grid
        for r in 0..<Self.gridSize {
            for c in 0..<Self.gridSize where snapshot[r][c].isInfected {
                for (nr, nc) in [(r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)] {
                    guard nr >= 0, nr < Self.gridSize, nc >= 0, nc < Self.gridSize else { continue }
                    if grid[nr][nc] == .healthy && Double.random(in: 0..<1) < Self.infectionChance {
                        grid[nr][nc] = .infected(turnsLeft: Self.infectionDuration)
                    }
                }
            }
        }

        // Progress the disease using the same snapshot's timers.
        for r in 0..<Self.gridSize {
            for c in 0..<Self.gridSize {
                if case .infected(let turnsLeft) = snapshot[r][c] {
                    grid[r][c] = turnsLeft <= 1 ? .dead : .infected(turnsLeft: turnsLeft - 1)
                }
            }
        }

        turn += 1
        actionPoints = Self.apPerTurn

        if infectedCount == 0 || turn > Self.maxTurns {
            finishGame()
        }
    }

    private func finishGame() {
        phase = .finished
        isNewRecord = GameScores.shared.report(score: survivorCount, for: "outbreak")
        if infectedCount == 0 {
            GameHaptics.success()
        } else {
            GameHaptics.warning()
        }
    }

    private func newGame() {
        var fresh: [[Cell]] = Array(repeating: Array(repeating: Cell.healthy, count: Self.gridSize),
                                    count: Self.gridSize)
        // Three separate index positions become patient zero clusters.
        var seeds = Set<Int>()
        while seeds.count < 3 {
            seeds.insert(Int.random(in: 0..<(Self.gridSize * Self.gridSize)))
        }
        for seed in seeds {
            fresh[seed / Self.gridSize][seed % Self.gridSize] = .infected(turnsLeft: Self.infectionDuration)
        }
        grid = fresh
        tool = .vaccinate
        actionPoints = Self.apPerTurn
        turn = 1
        isNewRecord = false
        phase = .playing
    }
}

#Preview {
    OutbreakGameView()
}
