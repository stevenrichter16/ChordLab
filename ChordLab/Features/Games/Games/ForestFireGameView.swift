//
//  ForestFireGameView.swift
//  ChordLab
//
//  Forest Fire Equilibrium (Drossel–Schwabl): trees sprout, lightning
//  strikes, fire eats connected forest, regrowth follows. A slowly
//  drifting wind steers the fire fronts, and the mosaic of burn scars
//  and old growth never settles and never dies.
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

        /// Quantized green shades: a per-cell bucket index keeps the
        /// mottled canopy look while letting the draw loop batch one
        /// fill per shade instead of one fill per tree.
        static let treeShades: [Color] = (0..<6).map { bucket in
            let shade = 0.72 + 0.28 * Double(bucket) / 5.0
            return Color(red: 0.10 * shade, green: 0.55 * shade, blue: 0.20 * shade)
        }
        static let flameShades: [Color] = [
            Color(red: 1.0, green: 0.30, blue: 0.1),
            Color(red: 1.0, green: 0.42, blue: 0.1),
            Color(red: 1.0, green: 0.54, blue: 0.1)
        ]

        var cols = 0
        var rows = 0
        var cells: [UInt8] = []
        /// Shade bucket per cell, fixed at reset so regrowth keeps the
        /// same mottling.
        var shadeIndex: [UInt8] = []
        var lastStep: Date?
        /// Unconsumed sim time carried between frames.
        var pendingTime: TimeInterval = 0
        /// Direction the wind blows toward, in screen coordinates.
        /// Random-walks each step so fire fronts wander over minutes.
        var windAngle = Double.random(in: 0..<(2 * .pi))
        /// Last drawn canvas size, for mapping gesture points to cells.
        var lastSize: CGSize = .zero
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
            shadeIndex = (0..<(cols * rows)).map { _ in
                UInt8.random(in: 0..<UInt8(Self.treeShades.count))
            }
            windAngle = Double.random(in: 0..<(2 * .pi))
            firesSurvived = 0
            coverage = 0
            burningNow = 0
            lastStep = nil
            pendingTime = 0
        }

        func stepIfDue(now: Date) {
            guard !cells.isEmpty else { return }
            let interval = 1.0 / Self.stepsPerSecond
            // SimClock.dt never goes negative (a backward wall-clock set
            // would otherwise freeze the sim) and caps long suspends.
            pendingTime += SimClock.dt(since: lastStep, to: now, cap: 0.5)
            lastStep = now
            var due = Int(pendingTime / interval)
            if due > 2 {
                // A frame hitch owes several steps; drop the backlog
                // rather than replaying it at fast-forward speed.
                due = 2
                pendingTime = 0
            } else {
                pendingTime -= Double(due) * interval
            }
            for _ in 0..<due { step() }
        }

        /// Tap: a lightning strike at the touched point — ignites a tree.
        func strike(at point: CGPoint) {
            guard let (c, r) = cellIndex(at: point) else { return }
            let index = r * cols + c
            if cells[index] == Self.tree {
                cells[index] = Self.burning
                firesSurvived += 1
            }
        }

        /// Long press: plant a small grove — a disc of trees on bare soil.
        func plantGrove(at point: CGPoint) {
            guard let (c0, r0) = cellIndex(at: point) else { return }
            let radius = 3
            for r in max(0, r0 - radius)...min(rows - 1, r0 + radius) {
                for c in max(0, c0 - radius)...min(cols - 1, c0 + radius) {
                    let dr = r - r0
                    let dc = c - c0
                    guard dr * dr + dc * dc <= radius * radius else { continue }
                    let index = r * cols + c
                    if cells[index] == Self.empty { cells[index] = Self.tree }
                }
            }
        }

        private func cellIndex(at point: CGPoint) -> (col: Int, row: Int)? {
            guard !cells.isEmpty, lastSize.width > 0, lastSize.height > 0 else { return nil }
            let c = Int(point.x / lastSize.width * CGFloat(cols))
            let r = Int(point.y / lastSize.height * CGFloat(rows))
            guard (0..<cols).contains(c), (0..<rows).contains(r) else { return nil }
            return (c, r)
        }

        private func step() {
            // Slow random walk so the wind wanders over minutes.
            windAngle += Double.random(in: -0.02...0.02)

            // Directional spread weights, fixed for this step: a tree
            // downwind of a fire almost always catches, one upwind rarely
            // does, so fire fronts stretch into streaks along the wind.
            let windX = cos(windAngle)
            let windY = sin(windAngle)
            let fromAbove = 0.675 + 0.325 * windY
            let fromBelow = 0.675 - 0.325 * windY
            let fromLeft = 0.675 + 0.325 * windX
            let fromRight = 0.675 - 0.325 * windX

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
                        if r > 0 && cells[index - cols] == Self.burning
                            && Double.random(in: 0..<1) < fromAbove { catchesFire = true }
                        else if r < rows - 1 && cells[index + cols] == Self.burning
                            && Double.random(in: 0..<1) < fromBelow { catchesFire = true }
                        else if c > 0 && cells[index - 1] == Self.burning
                            && Double.random(in: 0..<1) < fromLeft { catchesFire = true }
                        else if c < cols - 1 && cells[index + 1] == Self.burning
                            && Double.random(in: 0..<1) < fromRight { catchesFire = true }
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

    /// Autoscaled trace of recent coverage samples — the Drossel–Schwabl
    /// equilibrium never settles, and this makes the sawtooth glanceable.
    private struct CoverageSparkline: View {
        let samples: [Double]
        let capacity: Int

        var body: some View {
            Canvas { context, size in
                guard samples.count > 1 else { return }
                let lo = samples.min() ?? 0
                let hi = samples.max() ?? 1
                let range = max(hi - lo, 0.02)   // flatline guard
                let stepX = size.width / CGFloat(max(1, capacity - 1))
                var path = Path()
                for (i, sample) in samples.enumerated() {
                    let y = 2 + (size.height - 4) * (1 - CGFloat((sample - lo) / range))
                    let point = CGPoint(x: CGFloat(i) * stepX, y: y)
                    if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
                context.stroke(path, with: .color(.green.opacity(0.5)), lineWidth: 1.5)
            }
        }
    }

    private static let historyCapacity = 120   // ~60s at the 0.5s ticker

    @State private var sim = ForestSimulation()
    @State private var isPaused = false
    @State private var coverageText = "—"
    @State private var burningText = "0"
    @State private var firesText = "0"
    @State private var windDisplay = 0.0
    @State private var coverageHistory: [Double] = []

    private let statsTicker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "forestfire")!,
                   onRestart: { replant() },
                   confirmRestart: true) {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    StatPill(label: "Forest", value: coverageText, tint: .green)
                    StatPill(label: "Burning", value: burningText, tint: .orange)
                    StatPill(label: "Strikes", value: firesText, tint: .yellow)

                    Spacer(minLength: 0)

                    // Wind vane: points where the wind blows; mirrored on
                    // the slow ticker, not per frame.
                    Image(systemName: "location.north.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.teal)
                        .rotationEffect(.radians(windDisplay + .pi / 2))
                        .animation(.easeInOut(duration: 0.5), value: windDisplay)
                        .frame(width: 32, height: 32)
                        .background(Color.appSecondaryBackground, in: Circle())
                        .accessibilityLabel("Wind direction")

                    Button {
                        GameHaptics.tap()
                        isPaused.toggle()
                    } label: {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color.appSecondaryBackground, in: Circle())
                    }
                }
                .padding(.horizontal, 16)

                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: isPaused)) { timeline in
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
                        sim.lastSize = size
                        sim.stepIfDue(now: timeline.date)

                        let cellWidth = size.width / CGFloat(sim.cols)
                        let cellHeight = size.height / CGFloat(sim.rows)

                        context.fill(Path(CGRect(origin: .zero, size: size)),
                                     with: .color(Color(red: 0.09, green: 0.07, blue: 0.05)))

                        // Batch cells into one Path per color bucket — a
                        // handful of fills per frame instead of one per tree.
                        var shadePaths = [Path](repeating: Path(),
                                                count: ForestSimulation.treeShades.count)
                        var flamePaths = [Path](repeating: Path(),
                                                count: ForestSimulation.flameShades.count)

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
                                    shadePaths[Int(sim.shadeIndex[index])].addRect(rect)
                                } else {
                                    // Random bucket per frame keeps the flicker.
                                    flamePaths[Int.random(in: 0..<flamePaths.count)].addRect(rect)
                                }
                            }
                        }
                        for (bucket, path) in shadePaths.enumerated() where !path.isEmpty {
                            context.fill(path, with: .color(ForestSimulation.treeShades[bucket]))
                        }
                        for (bucket, path) in flamePaths.enumerated() where !path.isEmpty {
                            context.fill(path, with: .color(ForestSimulation.flameShades[bucket]))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onTapGesture(coordinateSpace: .local) { location in
                    guard !isPaused else { return }
                    GameHaptics.tap()
                    sim.strike(at: location)
                }
                .gesture(
                    // No location-carrying long press in SwiftUI: sequence
                    // a zero-distance drag so the release point is known.
                    LongPressGesture(minimumDuration: 0.4)
                        .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
                        .onEnded { value in
                            guard !isPaused,
                                  case .second(true, let drag) = value,
                                  let location = drag?.location else { return }
                            GameHaptics.tap()
                            sim.plantGrove(at: location)
                        }
                )
                .accessibilityLabel("Forest fire: \(coverageText) tree cover, \(burningText) cells burning")
                .padding(.horizontal, 12)

                CoverageSparkline(samples: coverageHistory, capacity: Self.historyCapacity)
                    .frame(height: 22)
                    .padding(.horizontal, 14)
                    .accessibilityHidden(true)

                Text("Tap for lightning · hold to plant a grove · fire runs with the wind")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 8)
            }
            .padding(.top, 4)
            .onReceive(statsTicker) { _ in
                coverageText = String(format: "%.0f%%", sim.coverage * 100)
                burningText = "\(sim.burningNow)"
                firesText = "\(sim.firesSurvived)"
                windDisplay = sim.windAngle
                if !isPaused && !sim.cells.isEmpty {
                    coverageHistory.append(sim.coverage)
                    if coverageHistory.count > Self.historyCapacity {
                        coverageHistory.removeFirst()
                    }
                }
            }
        }
    }

    private func replant() {
        sim.reset(cols: sim.cols, rows: sim.rows)
        coverageHistory.removeAll()
        isPaused = false
    }
}

#Preview {
    ForestFireGameView()
}
