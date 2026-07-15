//
//  LightsOutGameView.swift
//  ChordLab
//
//  Lights Out puzzle: tapping a cell toggles it and its four orthogonal
//  neighbors. Turn every light off in as few moves as possible.
//

import SwiftUI

struct LightsOutGameView: View {
    private enum Difficulty: String, CaseIterable, Identifiable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"

        var id: String { rawValue }

        var scrambleTaps: Int {
            switch self {
            case .easy: return 5
            case .medium: return 10
            case .hard: return 15
            }
        }
    }

    private static let gridSize = 5
    private static let cellCount = gridSize * gridSize

    private let game = GameCatalog.game(withId: "lightsout")!

    @State private var lights = Array(repeating: false, count: cellCount)
    @State private var difficulty: Difficulty = .easy
    @State private var moves = 0
    @State private var par = Difficulty.easy.scrambleTaps
    @State private var wins = 0
    @State private var isWon = false
    @State private var showWin = false

    var body: some View {
        GameScreen(game: game, onRestart: newPuzzle) {
            ZStack {
                VStack(spacing: 18) {
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(Difficulty.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                    HStack(spacing: 12) {
                        StatPill(label: "Moves", value: "\(moves)", tint: game.tint)
                        StatPill(label: "Par", value: "\(par)")
                        StatPill(label: "Wins", value: "\(wins)", tint: .green)
                    }

                    Spacer(minLength: 0)

                    boardGrid
                        .padding(.horizontal, 24)

                    Text("Tap a light to toggle it and its neighbors.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 0)

                    ArcadeButton(title: "New Puzzle", systemImage: "shuffle", tint: game.tint) {
                        newPuzzle()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                }

                if showWin {
                    GameOverOverlay(
                        title: "Lights Out!",
                        subtitle: "Solved in \(moves) move\(moves == 1 ? "" : "s") — Par \(par)",
                        isVictory: true,
                        buttonTitle: "New Puzzle",
                        action: newPuzzle
                    )
                }
            }
        }
        .onAppear {
            wins = GameScores.shared.counter("wins", for: game.id)
            newPuzzle()
        }
        .onChange(of: difficulty) { _, _ in
            newPuzzle()
        }
    }

    // MARK: - Subviews

    private var boardGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: Self.gridSize),
                  spacing: 10) {
            ForEach(0..<Self.cellCount, id: \.self) { index in
                cellView(at: index)
            }
        }
        .padding(14)
        .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 20))
    }

    private func cellView(at index: Int) -> some View {
        let isOn = lights[index]
        return Button {
            tapCell(index)
        } label: {
            RoundedRectangle(cornerRadius: 11)
                .fill(isOn ? AnyShapeStyle(Color.yellow.gradient) : AnyShapeStyle(Color.appTertiaryBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .strokeBorder(isOn ? Color.yellow.opacity(0.9) : Color.primary.opacity(0.06),
                                      lineWidth: 1.5)
                )
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: isOn ? .yellow.opacity(0.55) : .clear, radius: isOn ? 9 : 0)
                .scaleEffect(isOn ? 1.0 : 0.93)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
        }
        .buttonStyle(.plain)
        .disabled(isWon)
    }

    // MARK: - Game Logic

    private static func applyTap(_ index: Int, to grid: inout [Bool]) {
        let row = index / gridSize
        let col = index % gridSize
        grid[index].toggle()
        if row > 0 { grid[index - gridSize].toggle() }
        if row < gridSize - 1 { grid[index + gridSize].toggle() }
        if col > 0 { grid[index - 1].toggle() }
        if col < gridSize - 1 { grid[index + 1].toggle() }
    }

    private func tapCell(_ index: Int) {
        guard !isWon else { return }
        GameHaptics.tap()
        Self.applyTap(index, to: &lights)
        moves += 1
        if !lights.contains(true) {
            handleWin()
        }
    }

    private func handleWin() {
        isWon = true
        GameHaptics.success()
        let s = GameScores.shared
        s.incrementCounter("wins", for: "lightsout")
        s.setValue(s.counter("wins", for: "lightsout"), for: "lightsout")
        wins = s.counter("wins", for: "lightsout")

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard isWon else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                showWin = true
            }
        }
    }

    /// Builds a guaranteed-solvable board by simulating random taps
    /// on an all-off grid. The tap count doubles as "par".
    private func newPuzzle() {
        isWon = false
        showWin = false
        moves = 0
        par = difficulty.scrambleTaps

        var grid = Array(repeating: false, count: Self.cellCount)
        repeat {
            grid = Array(repeating: false, count: Self.cellCount)
            for index in Array(0..<Self.cellCount).shuffled().prefix(par) {
                Self.applyTap(index, to: &grid)
            }
        } while !grid.contains(true)

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            lights = grid
        }
    }
}

#Preview {
    LightsOutGameView()
}
