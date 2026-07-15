//
//  ForestFireGameView.swift
//  ChordLab
//
//  Forest Fire Equilibrium (Drossel–Schwabl): trees sprout, lightning
//  strikes, fire eats connected forest, regrowth follows. The mosaic of
//  burn scars and old growth never settles and never dies.
//

import SwiftUI

struct ForestFireGameView: View {
    private final class ForestSimulation {
        static let empty: UInt8 = 0
        static let tree: UInt8 = 1
        static let burning: UInt8 = 2

        static let growthChance = 0.012
        static let lightningChance = 0.00006
        static let stepsPerSecond = 14.0

        var cols = 0
        var rows = 0
        var cells: [UInt8] = []
        /// Precomputed per-cell tree colors so the draw loop doesn't
        /// construct thousands of Colors every frame.
        var treeColors: [Color] = []
        var lastStep: Date?
        var coverage = 0.0
        var burningNow = 0
        var firesSurvived = 0

        func reset(cols: Int, rows: Int) {
            guard cols > 0, rows > 0 else { return }
            self.cols = cols
            self.rows = rows
            // Start half-seeded so the first minutes are already alive.
            cells = (0..<(cols * rows)).map { _ in
                Double.random(in: 0..<1) < 0.45 ? Self.tree : Self.empty
            }
            treeColors = (0..<(cols * rows)).map { _ in
                let shade = Double.random(in: 0.72...1.0)
                return Color(red: 0.10 * shade, green: 0.55 * shade, blue: 0.20 * shade)
            }
            firesSurvived = 0
            coverage = 0
            burningNow = 0
            lastStep = nil
        }

        func stepIfDue(now: Date) {
            guard !cells.isEmpty else { return }
            let interval = 1.0 / Self.stepsPerSecond
            guard let last = lastStep else {
                lastStep = now
                step()
                return
            }
            guard now.timeIntervalSince(last) >= interval else { return }
            // Advance by the interval (not to `now`) so draw-frame
            // quantization doesn't slow the simulation below its rate;
            // clamp so backgrounding doesn't cause a catch-up burst.
            let advanced = last.addingTimeInterval(interval)
            lastStep = now.timeIntervalSince(advanced) > 1.0 ? now : advanced
            step()
        }

        private func step() {
            var next = cells
            var trees = 0
            var burning = 0

            for r in 0..<rows {
                for c in 0..<cols {
                    let index = r * cols + c
                    switch cells[index] {
                    case Self.empty:
                        if Double.random(in: 0..<1) < Self.growthChance {
                            next[index] = Self.tree
                        }

                    case Self.tree:
                        var catchesFire = false
                        if r > 0 && cells[index - cols] == Self.burning { catchesFire = true }
                        else if r < rows - 1 && cells[index + cols] == Self.burning { catchesFire = true }
                        else if c > 0 && cells[index - 1] == Self.burning { catchesFire = true }
                        else if c < cols - 1 && cells[index + 1] == Self.burning { catchesFire = true }
                        else if Double.random(in: 0..<1) < Self.lightningChance {
                            catchesFire = true
                            firesSurvived += 1
                        }
                        next[index] = catchesFire ? Self.burning : Self.tree

                    default: // burning
                        next[index] = Self.empty
                    }
                }
            }

            cells = next
            for value in cells {
                if value == Self.tree { trees += 1 }
                else if value == Self.burning { burning += 1 }
            }
            coverage = Double(trees) / Double(max(1, cells.count))
            burningNow = burning
        }
    }

    @State private var sim = ForestSimulation()
    @State private var coverageText = "—"
    @State private var burningText = "0"
    @State private var firesText = "0"

    private let statsTicker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "forestfire")!, onRestart: { replant() }) {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    StatPill(label: "Forest", value: coverageText, tint: .green)
                    StatPill(label: "Burning", value: burningText, tint: .orange)
                    StatPill(label: "Strikes", value: firesText, tint: .yellow)
                }

                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    Canvas { context, size in
                        // Degenerate layout passes would make Int(height/cell) trap.
                        guard size.width > 10, size.height > 10 else { return }

                        // Build the grid once; on later size changes just
                        // stretch the existing forest instead of wiping it.
                        if sim.cells.isEmpty {
                            let targetCols = 52
                            let cellEdge = size.width / CGFloat(targetCols)
                            let targetRows = min(120, max(10, Int(size.height / cellEdge)))
                            sim.reset(cols: targetCols, rows: targetRows)
                        }
                        sim.stepIfDue(now: timeline.date)

                        let cellWidth = size.width / CGFloat(sim.cols)
                        let cellHeight = size.height / CGFloat(sim.rows)

                        context.fill(Path(CGRect(origin: .zero, size: size)),
                                     with: .color(Color(red: 0.09, green: 0.07, blue: 0.05)))

                        for r in 0..<sim.rows {
                            for c in 0..<sim.cols {
                                let index = r * sim.cols + c
                                let cell = sim.cells[index]
                                guard cell != ForestSimulation.empty else { continue }

                                let rect = CGRect(x: CGFloat(c) * cellWidth,
                                                  y: CGFloat(r) * cellHeight,
                                                  width: cellWidth + 0.5,
                                                  height: cellHeight + 0.5)
                                if cell == ForestSimulation.tree {
                                    context.fill(Path(rect), with: .color(sim.treeColors[index]))
                                } else {
                                    context.fill(Path(rect),
                                                 with: .color(Color(red: 1.0,
                                                                    green: Double.random(in: 0.25...0.55),
                                                                    blue: 0.1)))
                                }
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 12)

                Text("Sprout chance 1.2% · lightning 0.006% · fire spreads to touching trees")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 8)
            }
            .padding(.top, 4)
            .onReceive(statsTicker) { _ in
                coverageText = String(format: "%.0f%%", sim.coverage * 100)
                burningText = "\(sim.burningNow)"
                firesText = "\(sim.firesSurvived)"
            }
        }
    }

    private func replant() {
        sim.reset(cols: sim.cols, rows: sim.rows)
    }
}

#Preview {
    ForestFireGameView()
}
