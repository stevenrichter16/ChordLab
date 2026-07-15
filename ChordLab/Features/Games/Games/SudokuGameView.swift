//
//  SudokuGameView.swift
//  ChordLab
//
//  Sudoku with a real generator: every puzzle has a unique solution.
//  Notes mode, mistake tracking, and three difficulties.
//

import SwiftUI

struct SudokuGameView: View {
    private enum SudokuDifficulty: String, CaseIterable, Identifiable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"

        var id: String { rawValue }

        /// Number of given cells to keep.
        var givens: Int {
            switch self {
            case .easy: return 40
            case .medium: return 32
            case .hard: return 27
            }
        }
    }

    // MARK: - Generator / solver

    private enum SudokuEngine {
        /// Returns a fully solved random grid.
        static func generateSolution() -> [[Int]] {
            var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
            _ = fill(&grid)
            return grid
        }

        private static func fill(_ grid: inout [[Int]]) -> Bool {
            guard let (r, c) = firstEmpty(grid) else { return true }
            for value in Array(1...9).shuffled() {
                if isValid(grid, r, c, value) {
                    grid[r][c] = value
                    if fill(&grid) { return true }
                    grid[r][c] = 0
                }
            }
            return false
        }

        private static func firstEmpty(_ grid: [[Int]]) -> (Int, Int)? {
            for r in 0..<9 {
                for c in 0..<9 where grid[r][c] == 0 {
                    return (r, c)
                }
            }
            return nil
        }

        static func isValid(_ grid: [[Int]], _ row: Int, _ col: Int, _ value: Int) -> Bool {
            for i in 0..<9 {
                if grid[row][i] == value || grid[i][col] == value { return false }
            }
            let br = (row / 3) * 3
            let bc = (col / 3) * 3
            for r in br..<(br + 3) {
                for c in bc..<(bc + 3) where grid[r][c] == value {
                    return false
                }
            }
            return true
        }

        /// Counts solutions, stopping early at `limit`.
        static func countSolutions(_ grid: inout [[Int]], limit: Int = 2) -> Int {
            guard let (r, c) = firstEmpty(grid) else { return 1 }
            var count = 0
            for value in 1...9 {
                if isValid(grid, r, c, value) {
                    grid[r][c] = value
                    count += countSolutions(&grid, limit: limit - count)
                    grid[r][c] = 0
                    if count >= limit { break }
                }
            }
            return count
        }

        /// Removes cells from a solved grid while the puzzle stays unique.
        static func makePuzzle(from solution: [[Int]], givens: Int) -> [[Int]] {
            var puzzle = solution
            var cells = Array(0..<81).shuffled()
            var remaining = 81

            while remaining > givens, let index = cells.popLast() {
                let r = index / 9
                let c = index % 9
                let backup = puzzle[r][c]
                puzzle[r][c] = 0
                var probe = puzzle
                if countSolutions(&probe, limit: 2) != 1 {
                    puzzle[r][c] = backup
                } else {
                    remaining -= 1
                }
            }
            return puzzle
        }
    }

    // MARK: - State

    @State private var difficulty: SudokuDifficulty = .easy
    @State private var solution: [[Int]] = []
    @State private var puzzle: [[Int]] = []
    @State private var entries: [[Int]] = []
    @State private var notes: [[Set<Int>]] = []
    @State private var selected: (row: Int, col: Int)? = nil
    @State private var notesMode = false
    @State private var mistakes = 0
    @State private var elapsed = 0
    @State private var isGenerating = false
    @State private var isSolved = false
    @State private var generation = 0

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "sudoku")!, onRestart: { startNewPuzzle() }) {
            VStack(spacing: 12) {
                Picker("Difficulty", selection: $difficulty) {
                    ForEach(SudokuDifficulty.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .onChange(of: difficulty) { _, _ in
                    startNewPuzzle()
                }

                HStack(spacing: 10) {
                    StatPill(label: "Time", value: timeText)
                    StatPill(label: "Mistakes", value: "\(mistakes)", tint: mistakes > 0 ? .red : .appPrimary)
                    StatPill(label: "Solved", value: "\(GameScores.shared.counter("wins", for: "sudoku"))", tint: .green)
                }

                if isGenerating || puzzle.isEmpty {
                    Spacer()
                    ProgressView("Generating puzzle…")
                        .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    gridView
                        .padding(.horizontal, 14)

                    numberPad
                        .padding(.horizontal, 16)
                        .padding(.bottom, 6)
                }
            }
            .padding(.top, 4)
            .overlay {
                if isSolved {
                    GameOverOverlay(
                        title: "Solved! 🧩",
                        subtitle: "\(difficulty.rawValue) in \(timeText) with \(mistakes) mistake\(mistakes == 1 ? "" : "s")",
                        isVictory: true,
                        buttonTitle: "New Puzzle"
                    ) {
                        startNewPuzzle()
                    }
                }
            }
            .onReceive(ticker) { _ in
                if !isGenerating && !isSolved && !puzzle.isEmpty {
                    elapsed += 1
                }
            }
            .onAppear {
                if puzzle.isEmpty {
                    startNewPuzzle()
                }
            }
        }
    }

    private var timeText: String {
        String(format: "%d:%02d", elapsed / 60, elapsed % 60)
    }

    // MARK: - Grid

    private var gridView: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = side / 9

            ZStack {
                // Cells
                VStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { r in
                        HStack(spacing: 0) {
                            ForEach(0..<9, id: \.self) { c in
                                cellView(r: r, c: c, size: cell)
                            }
                        }
                    }
                }

                // Grid lines
                Path { path in
                    for i in 0...9 {
                        let offset = CGFloat(i) * cell
                        path.move(to: CGPoint(x: offset, y: 0))
                        path.addLine(to: CGPoint(x: offset, y: side))
                        path.move(to: CGPoint(x: 0, y: offset))
                        path.addLine(to: CGPoint(x: side, y: offset))
                    }
                }
                .stroke(Color.appBorder.opacity(0.6), lineWidth: 0.5)

                Path { path in
                    for i in stride(from: 0, through: 9, by: 3) {
                        let offset = CGFloat(i) * cell
                        path.move(to: CGPoint(x: offset, y: 0))
                        path.addLine(to: CGPoint(x: offset, y: side))
                        path.move(to: CGPoint(x: 0, y: offset))
                        path.addLine(to: CGPoint(x: side, y: offset))
                    }
                }
                .stroke(Color.primary.opacity(0.7), lineWidth: 1.8)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func cellView(r: Int, c: Int, size: CGFloat) -> some View {
        let given = puzzle[r][c]
        let entry = entries[r][c]
        let value = given != 0 ? given : entry
        let isSelected = selected?.row == r && selected?.col == c
        let isPeer = isPeerOfSelection(r: r, c: c)
        let sameNumber = value != 0 && selectedValue == value
        let isWrong = given == 0 && entry != 0 && entry != solution[r][c]

        return ZStack {
            Rectangle()
                .fill(cellBackground(isSelected: isSelected, isPeer: isPeer, sameNumber: sameNumber))

            if value != 0 {
                Text("\(value)")
                    .font(.system(size: size * 0.55, weight: given != 0 ? .bold : .semibold, design: .rounded))
                    .foregroundStyle(isWrong ? Color.red : (given != 0 ? Color.primary : Color.appPrimary))
            } else if !notes[r][c].isEmpty {
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { nr in
                        HStack(spacing: 0) {
                            ForEach(0..<3, id: \.self) { nc in
                                let n = nr * 3 + nc + 1
                                Text(notes[r][c].contains(n) ? "\(n)" : " ")
                                    .font(.system(size: size * 0.2, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                    }
                }
                .padding(1)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture {
            GameHaptics.tap()
            selected = (r, c)
        }
    }

    private var selectedValue: Int {
        guard let selected else { return 0 }
        let given = puzzle[selected.row][selected.col]
        return given != 0 ? given : entries[selected.row][selected.col]
    }

    private func isPeerOfSelection(r: Int, c: Int) -> Bool {
        guard let selected else { return false }
        if selected.row == r && selected.col == c { return false }
        return selected.row == r || selected.col == c ||
            (selected.row / 3 == r / 3 && selected.col / 3 == c / 3)
    }

    private func cellBackground(isSelected: Bool, isPeer: Bool, sameNumber: Bool) -> Color {
        if isSelected { return Color.appPrimary.opacity(0.3) }
        if sameNumber { return Color.appPrimary.opacity(0.18) }
        if isPeer { return Color.appPrimary.opacity(0.08) }
        return Color.appSecondaryBackground
    }

    // MARK: - Number pad

    private var numberPad: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(1...9, id: \.self) { n in
                    let remaining = 9 - placedCount(of: n)
                    Button {
                        enter(n)
                    } label: {
                        VStack(spacing: 1) {
                            Text("\(n)")
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                            Text(remaining > 0 ? "\(remaining)" : " ")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(Color.appPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 8))
                        .opacity(remaining > 0 ? 1 : 0.35)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                Button {
                    GameHaptics.tap()
                    notesMode.toggle()
                } label: {
                    Label("Notes", systemImage: notesMode ? "pencil.circle.fill" : "pencil.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(notesMode ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(notesMode ? Color.appPrimary : Color.appSecondaryBackground, in: Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    erase()
                } label: {
                    Label("Erase", systemImage: "eraser.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.appSecondaryBackground, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func placedCount(of n: Int) -> Int {
        var count = 0
        for r in 0..<9 {
            for c in 0..<9 {
                let value = puzzle[r][c] != 0 ? puzzle[r][c] : entries[r][c]
                if value == n && (puzzle[r][c] != 0 || entries[r][c] == solution[r][c]) {
                    count += 1
                }
            }
        }
        return count
    }

    // MARK: - Actions

    private func startNewPuzzle() {
        generation += 1
        let gen = generation
        let targetGivens = difficulty.givens
        isGenerating = true
        isSolved = false
        selected = nil
        mistakes = 0
        elapsed = 0
        notesMode = false

        Task.detached(priority: .userInitiated) {
            let solved = SudokuEngine.generateSolution()
            let newPuzzle = SudokuEngine.makePuzzle(from: solved, givens: targetGivens)
            await MainActor.run {
                guard generation == gen else { return }
                solution = solved
                puzzle = newPuzzle
                entries = Array(repeating: Array(repeating: 0, count: 9), count: 9)
                notes = Array(repeating: Array(repeating: Set<Int>(), count: 9), count: 9)
                isGenerating = false
            }
        }
    }

    private func enter(_ n: Int) {
        guard let selected, !isSolved else { return }
        let r = selected.row
        let c = selected.col
        guard puzzle[r][c] == 0 else { return }

        if notesMode {
            GameHaptics.tap()
            if notes[r][c].contains(n) {
                notes[r][c].remove(n)
            } else {
                notes[r][c].insert(n)
            }
            return
        }

        guard entries[r][c] != n else { return }
        entries[r][c] = n
        notes[r][c] = []

        if n != solution[r][c] {
            mistakes += 1
            GameHaptics.error()
        } else {
            GameHaptics.tap()
            clearNotes(of: n, around: r, c)
            checkSolved()
        }
    }

    private func clearNotes(of n: Int, around r: Int, _ c: Int) {
        for i in 0..<9 {
            notes[r][i].remove(n)
            notes[i][c].remove(n)
        }
        let br = (r / 3) * 3
        let bc = (c / 3) * 3
        for rr in br..<(br + 3) {
            for cc in bc..<(bc + 3) {
                notes[rr][cc].remove(n)
            }
        }
    }

    private func erase() {
        guard let selected else { return }
        let r = selected.row
        let c = selected.col
        guard puzzle[r][c] == 0 else { return }
        GameHaptics.tap()
        entries[r][c] = 0
        notes[r][c] = []
    }

    private func checkSolved() {
        for r in 0..<9 {
            for c in 0..<9 {
                let value = puzzle[r][c] != 0 ? puzzle[r][c] : entries[r][c]
                if value != solution[r][c] { return }
            }
        }
        isSolved = true
        GameHaptics.success()
        let store = GameScores.shared
        store.incrementCounter("wins", for: "sudoku")
        store.setValue(store.counter("wins", for: "sudoku"), for: "sudoku")
    }
}

#Preview {
    SudokuGameView()
}
