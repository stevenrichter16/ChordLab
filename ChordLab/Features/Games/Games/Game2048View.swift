//
//  Game2048View.swift
//  ChordLab
//
//  2048: swipe to slide and merge tiles, reach 2048.
//

import SwiftUI

struct Game2048View: View {
    private static let size = 4

    private enum SlideDirection {
        case up, down, left, right
    }

    @State private var grid: [[Int]] = Array(repeating: Array(repeating: 0, count: 4), count: 4)
    @State private var score = 0
    @State private var isGameOver = false
    @State private var reached2048 = false
    @State private var keepPlaying = false
    @State private var isNewRecord = false
    @State private var lastSpawn: (row: Int, col: Int)? = nil

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "game2048")!, onRestart: { newGame() }) {
            VStack(spacing: 16) {
                HStack(spacing: 10) {
                    StatPill(label: "Score", value: "\(score)", tint: .orange)
                    StatPill(label: "Best", value: "\(GameScores.shared.best(for: "game2048") ?? 0)")
                }

                boardView
                    .padding(.horizontal, 16)

                Text("Swipe to slide tiles")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.top, 8)
            .overlay {
                if isGameOver {
                    GameOverOverlay(
                        title: "Game Over",
                        subtitle: "Score: \(score)",
                        isVictory: false,
                        newRecord: isNewRecord,
                        buttonTitle: "Try Again"
                    ) {
                        newGame()
                    }
                } else if reached2048 && !keepPlaying {
                    GameOverOverlay(
                        title: "2048!",
                        subtitle: "You made the tile. Keep going?",
                        isVictory: true,
                        newRecord: isNewRecord,
                        buttonTitle: "Keep Playing"
                    ) {
                        keepPlaying = true
                    }
                }
            }
            .onAppear {
                if grid.allSatisfy({ $0.allSatisfy { $0 == 0 } }) {
                    newGame()
                }
            }
        }
    }

    private var boardView: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 8
            let side = min(geo.size.width, geo.size.height)
            let cell = (side - spacing * CGFloat(Self.size + 1)) / CGFloat(Self.size)

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.appSecondaryBackground)
                    .frame(width: side, height: side)

                VStack(spacing: spacing) {
                    ForEach(0..<Self.size, id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(0..<Self.size, id: \.self) { col in
                                tileView(value: grid[row][col],
                                         isNew: lastSpawn?.row == row && lastSpawn?.col == col,
                                         cellSize: cell)
                            }
                        }
                    }
                }
                .padding(spacing)
                .frame(width: side, height: side)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        let direction: SlideDirection
                        if abs(value.translation.width) > abs(value.translation.height) {
                            direction = value.translation.width > 0 ? .right : .left
                        } else {
                            direction = value.translation.height > 0 ? .down : .up
                        }
                        slide(direction)
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func tileView(value: Int, isNew: Bool, cellSize: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(value == 0 ? Color.appTertiaryBackground : tileColor(value))

            if value > 0 {
                Text("\(value)")
                    .font(.system(size: value >= 1024 ? cellSize * 0.3 : cellSize * 0.38,
                                  weight: .bold, design: .rounded))
                    .foregroundStyle(value <= 4 ? Color.black.opacity(0.65) : .white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .scaleEffect(isNew && value > 0 ? 1.06 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: value)
        .animation(.spring(response: 0.18, dampingFraction: 0.6), value: isNew)
    }

    private func tileColor(_ value: Int) -> Color {
        switch value {
        case 2: return Color(red: 0.93, green: 0.89, blue: 0.85)
        case 4: return Color(red: 0.93, green: 0.88, blue: 0.78)
        case 8: return Color(red: 0.95, green: 0.69, blue: 0.47)
        case 16: return Color(red: 0.96, green: 0.58, blue: 0.39)
        case 32: return Color(red: 0.96, green: 0.49, blue: 0.37)
        case 64: return Color(red: 0.96, green: 0.37, blue: 0.23)
        case 128: return Color(red: 0.93, green: 0.81, blue: 0.45)
        case 256: return Color(red: 0.93, green: 0.80, blue: 0.38)
        case 512: return Color(red: 0.93, green: 0.78, blue: 0.31)
        case 1024: return Color(red: 0.93, green: 0.77, blue: 0.25)
        case 2048: return Color(red: 0.93, green: 0.76, blue: 0.18)
        default: return Color(red: 0.24, green: 0.22, blue: 0.20)
        }
    }

    // MARK: - Game logic

    private func newGame() {
        grid = Array(repeating: Array(repeating: 0, count: Self.size), count: Self.size)
        score = 0
        isGameOver = false
        reached2048 = false
        keepPlaying = false
        isNewRecord = false
        lastSpawn = nil
        spawnTile()
        spawnTile()
    }

    private func spawnTile() {
        var empty: [(Int, Int)] = []
        for r in 0..<Self.size {
            for c in 0..<Self.size where grid[r][c] == 0 {
                empty.append((r, c))
            }
        }
        guard let (r, c) = empty.randomElement() else { return }
        grid[r][c] = Int.random(in: 0..<10) == 0 ? 4 : 2
        lastSpawn = (r, c)
    }

    /// Slides one line toward index 0, merging equal neighbors once.
    /// Returns the new line and the score gained.
    private func collapse(_ line: [Int]) -> ([Int], Int) {
        var tiles = line.filter { $0 != 0 }
        var gained = 0
        var index = 0
        while index < tiles.count - 1 {
            if tiles[index] == tiles[index + 1] {
                tiles[index] *= 2
                gained += tiles[index]
                tiles.remove(at: index + 1)
            }
            index += 1
        }
        while tiles.count < Self.size {
            tiles.append(0)
        }
        return (tiles, gained)
    }

    private func slide(_ direction: SlideDirection) {
        guard !isGameOver else { return }

        var newGrid = grid
        var gained = 0

        for i in 0..<Self.size {
            // Extract the line in slide order (toward index 0)
            var line: [Int] = []
            for j in 0..<Self.size {
                switch direction {
                case .left: line.append(grid[i][j])
                case .right: line.append(grid[i][Self.size - 1 - j])
                case .up: line.append(grid[j][i])
                case .down: line.append(grid[Self.size - 1 - j][i])
                }
            }

            let (collapsed, lineGain) = collapse(line)
            gained += lineGain

            for j in 0..<Self.size {
                switch direction {
                case .left: newGrid[i][j] = collapsed[j]
                case .right: newGrid[i][Self.size - 1 - j] = collapsed[j]
                case .up: newGrid[j][i] = collapsed[j]
                case .down: newGrid[Self.size - 1 - j][i] = collapsed[j]
                }
            }
        }

        guard newGrid != grid else { return }

        GameHaptics.tap()
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            grid = newGrid
            score += gained
        }
        spawnTile()

        if !reached2048 && grid.contains(where: { $0.contains(2048) }) {
            reached2048 = true
            GameHaptics.success()
        }

        if !hasMoves() {
            isNewRecord = GameScores.shared.report(score: score, for: "game2048")
            GameHaptics.error()
            withAnimation(.easeOut(duration: 0.25)) {
                isGameOver = true
            }
        }
    }

    private func hasMoves() -> Bool {
        for r in 0..<Self.size {
            for c in 0..<Self.size {
                if grid[r][c] == 0 { return true }
                if c + 1 < Self.size && grid[r][c] == grid[r][c + 1] { return true }
                if r + 1 < Self.size && grid[r][c] == grid[r + 1][c] { return true }
            }
        }
        return false
    }
}

#Preview {
    Game2048View()
}
