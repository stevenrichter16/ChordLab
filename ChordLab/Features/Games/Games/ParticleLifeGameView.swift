//
//  ParticleLifeGameView.swift
//  ChordLab
//
//  Particle Life: a few hundred particles, five species, one random
//  asymmetric attraction matrix. From nothing but that, cells crawl,
//  chase, orbit, and form membranes. Restart rolls a new chemistry.
//

import SwiftUI

struct ParticleLifeGameView: View {
    /// Plain class (deliberately NOT @Observable): the Canvas redraws on
    /// every TimelineView tick, so mutation doesn't need to invalidate views.
    private final class PLSimulation {
        static let speciesCount = 5
        static let particleCount = 260
        static let rMax: CGFloat = 64
        static let beta: CGFloat = 0.28          // inner repulsion radius fraction
        static let forceScale: CGFloat = 520
        static let frictionHalfLife: CGFloat = 0.08
        static let universeNames = ["α", "β", "γ", "δ", "ε", "ζ", "η", "θ"]
        static let saveKey = "watch.particlelife.universe"

        var px: [CGFloat] = []
        var py: [CGFloat] = []
        var vx: [CGFloat] = []
        var vy: [CGFloat] = []
        var species: [Int] = []
        /// Flattened speciesCount×speciesCount attraction matrix (hot loop).
        var matrix: [CGFloat] = []
        var worldSize: CGSize = .zero
        var lastDate: Date?

        // Spatial-grid buffers (cell size ≥ rMax), reused across frames so
        // the force pass allocates nothing after the first step.
        private var gridCols = 0
        private var gridRows = 0
        private var cellOf: [Int] = []
        private var cellStart: [Int] = []
        private var cellCount: [Int] = []
        private var gridIndices: [Int] = []

        /// The chemistry IS the universe's identity, so it persists — the
        /// same named universe returns across launches. Positions stay
        /// ephemeral; the world re-forms from the same physics.
        struct UniverseSave: Codable {
            var matrix: [CGFloat]
            var name: String
        }

        /// Restore the saved chemistry when a valid one exists, otherwise
        /// roll (and save) a fresh universe. Returns the universe name.
        func loadOrRollUniverse() -> String {
            if let saved = SimPersist.load(UniverseSave.self, key: Self.saveKey),
               saved.matrix.count == Self.speciesCount * Self.speciesCount {
                matrix = saved.matrix
                return saved.name
            }
            return rollNewUniverse()
        }

        /// Roll a fresh chemistry and name, and persist it as the current universe.
        func rollNewUniverse() -> String {
            rollChemistry()
            let name = Self.universeNames.randomElement() ?? "α"
            SimPersist.save(UniverseSave(matrix: matrix, name: name), key: Self.saveKey)
            return name
        }

        func rollChemistry() {
            matrix = (0..<(Self.speciesCount * Self.speciesCount)).map { _ in
                CGFloat.random(in: -1...1)
            }
        }

        func scatter(in size: CGSize) {
            guard size.width > 0, size.height > 0 else { return }
            worldSize = size
            px = (0..<Self.particleCount).map { _ in CGFloat.random(in: 0..<size.width) }
            py = (0..<Self.particleCount).map { _ in CGFloat.random(in: 0..<size.height) }
            vx = Array(repeating: 0, count: Self.particleCount)
            vy = Array(repeating: 0, count: Self.particleCount)
            species = (0..<Self.particleCount).map { _ in Int.random(in: 0..<Self.speciesCount) }
        }

        /// A layout change (rotation, split view, Dynamic Type reflow) must
        /// stretch the living world, not erase it: scale positions into the
        /// new bounds and keep species and velocities.
        private func rescale(to size: CGSize) {
            guard size.width > 0, size.height > 0,
                  worldSize.width > 0, worldSize.height > 0 else { return }
            let sx = size.width / worldSize.width
            let sy = size.height / worldSize.height
            for i in 0..<px.count {
                px[i] *= sx
                py[i] *= sy
            }
            worldSize = size
        }

        /// A tap pushes nearby particles gently outward — enough to stir a
        /// cluster and watch it re-form, not enough to shatter the world.
        func stir(at point: CGPoint) {
            let radius: CGFloat = 90
            let strength: CGFloat = 260
            let width = worldSize.width
            let height = worldSize.height
            guard width > 0, height > 0 else { return }
            for i in 0..<px.count {
                var dx = px[i] - point.x
                var dy = py[i] - point.y
                if dx > width / 2 { dx -= width } else if dx < -width / 2 { dx += width }
                if dy > height / 2 { dy -= height } else if dy < -height / 2 { dy += height }
                let distSq = dx * dx + dy * dy
                guard distSq > 0.0001, distSq < radius * radius else { continue }
                let dist = sqrt(distSq)
                let falloff = 1 - dist / radius
                vx[i] += dx / dist * strength * falloff
                vy[i] += dy / dist * strength * falloff
            }
        }

        /// Piecewise particle-life force: always repel when too close,
        /// attract/repel by the matrix in the mid band, nothing beyond rMax.
        private func force(_ normalizedDist: CGFloat, attraction: CGFloat) -> CGFloat {
            if normalizedDist < Self.beta {
                return normalizedDist / Self.beta - 1
            }
            if normalizedDist < 1 {
                return attraction * (1 - abs(2 * normalizedDist - 1 - Self.beta) / (1 - Self.beta))
            }
            return 0
        }

        /// Counting-sort the particles into a uniform grid whose cells are
        /// at least rMax wide/tall, so every in-range pair sits within one
        /// cell ring. Flat buffers only — zero heap churn per frame.
        private func rebuildGrid(width: CGFloat, height: CGFloat) {
            let cols = max(1, Int(width / Self.rMax))
            let rows = max(1, Int(height / Self.rMax))
            let cellTotal = cols * rows
            if cols != gridCols || rows != gridRows {
                gridCols = cols
                gridRows = rows
                cellStart = Array(repeating: 0, count: cellTotal + 1)
                cellCount = Array(repeating: 0, count: cellTotal)
            }
            if cellOf.count != Self.particleCount {
                cellOf = Array(repeating: 0, count: Self.particleCount)
                gridIndices = cellOf
            }

            let cellW = width / CGFloat(cols)
            let cellH = height / CGFloat(rows)
            for c in 0..<cellTotal { cellCount[c] = 0 }
            for i in 0..<Self.particleCount {
                let cx = min(cols - 1, max(0, Int(px[i] / cellW)))
                let cy = min(rows - 1, max(0, Int(py[i] / cellH)))
                let cell = cy * cols + cx
                cellOf[i] = cell
                cellCount[cell] += 1
            }
            cellStart[0] = 0
            for c in 0..<cellTotal { cellStart[c + 1] = cellStart[c] + cellCount[c] }
            // Second pass reuses cellCount as per-cell write cursors.
            for c in 0..<cellTotal { cellCount[c] = 0 }
            for i in 0..<Self.particleCount {
                let cell = cellOf[i]
                gridIndices[cellStart[cell] + cellCount[cell]] = i
                cellCount[cell] += 1
            }
        }

        func step(to date: Date, size: CGSize) {
            if px.isEmpty {
                if matrix.isEmpty { rollChemistry() }
                scatter(in: size)
            } else if size != worldSize {
                rescale(to: size)
            }
            guard size.width > 0, size.height > 0 else { return }

            // SimClock clamps backward wall-clock jumps to 0: a negative dt
            // would make friction pow(0.5, negative) > 1 and compound
            // velocities into NaN.
            let dt = CGFloat(SimClock.dt(since: lastDate, to: date, cap: 1.0 / 30.0))
            lastDate = date

            let width = size.width
            let height = size.height
            let count = Self.particleCount
            let friction = pow(0.5, dt / Self.frictionHalfLife)

            rebuildGrid(width: width, height: height)
            let cols = gridCols
            let rows = gridRows
            // When the grid is narrower than three cells the ±1 ring would
            // visit a cell twice and double-count forces, so dedupe the
            // offsets to one full sweep instead.
            let xOffsets = cols >= 3 ? -1...1 : 0...(cols - 1)
            let yOffsets = rows >= 3 ? -1...1 : 0...(rows - 1)

            let maxSpeed: CGFloat = 600
            for i in 0..<count {
                var fx: CGFloat = 0
                var fy: CGFloat = 0
                let rowBase = species[i] * Self.speciesCount
                let cix = cellOf[i] % cols
                let ciy = cellOf[i] / cols

                for oy in yOffsets {
                    let ncy = (ciy + oy + rows) % rows
                    for ox in xOffsets {
                        let cell = ncy * cols + (cix + ox + cols) % cols
                        for k in cellStart[cell]..<cellStart[cell + 1] {
                            let j = gridIndices[k]
                            if j == i { continue }

                            // Toroidal wrap: interact across the nearest edge.
                            var dx = px[j] - px[i]
                            var dy = py[j] - py[i]
                            if dx > width / 2 { dx -= width } else if dx < -width / 2 { dx += width }
                            if dy > height / 2 { dy -= height } else if dy < -height / 2 { dy += height }

                            let distSq = dx * dx + dy * dy
                            guard distSq > 0.0001, distSq < Self.rMax * Self.rMax else { continue }

                            let dist = sqrt(distSq)
                            let f = force(dist / Self.rMax, attraction: matrix[rowBase + species[j]])
                            fx += dx / dist * f
                            fy += dy / dist * f
                        }
                    }
                }

                vx[i] = vx[i] * friction + fx * Self.forceScale * dt
                vy[i] = vy[i] * friction + fy * Self.forceScale * dt

                // Cap speed so a force pile-up can't fling a particle
                // more than one world-width in a single step.
                let speedSq = vx[i] * vx[i] + vy[i] * vy[i]
                if speedSq > maxSpeed * maxSpeed {
                    let scale = maxSpeed / sqrt(speedSq)
                    vx[i] *= scale
                    vy[i] *= scale
                }
            }

            for i in 0..<count {
                px[i] += vx[i] * dt
                py[i] += vy[i] * dt
                if px[i] < 0 { px[i] += width } else if px[i] >= width { px[i] -= width }
                if py[i] < 0 { py[i] += height } else if py[i] >= height { py[i] -= height }
            }
        }
    }

    private static let speciesColors: [Color] = [
        Color(hue: 0.00, saturation: 0.75, brightness: 0.95),
        Color(hue: 0.33, saturation: 0.70, brightness: 0.90),
        Color(hue: 0.58, saturation: 0.75, brightness: 0.95),
        Color(hue: 0.13, saturation: 0.80, brightness: 0.95),
        Color(hue: 0.80, saturation: 0.65, brightness: 0.95)
    ]

    @State private var sim: PLSimulation
    @State private var isPaused = false
    @State private var universeName: String

    init() {
        let sim = PLSimulation()
        let name = sim.loadOrRollUniverse()
        _sim = State(initialValue: sim)
        _universeName = State(initialValue: name)
    }

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "particlelife")!,
                   onRestart: { newUniverse() },
                   confirmRestart: true) {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    HStack(spacing: 5) {
                        ForEach(0..<Self.speciesColors.count, id: \.self) { index in
                            Circle()
                                .fill(Self.speciesColors[index])
                                .frame(width: 9, height: 9)
                        }
                    }
                    Text("Universe \(universeName)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

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

                TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: isPaused)) { timeline in
                    Canvas { context, size in
                        sim.step(to: timeline.date, size: size)
                        context.fill(Path(CGRect(origin: .zero, size: size)),
                                     with: .color(Color(white: 0.06)))

                        // One glow + one core path per species: 10 fills
                        // per frame instead of one per particle.
                        var glowPaths = Array(repeating: Path(), count: PLSimulation.speciesCount)
                        var corePaths = Array(repeating: Path(), count: PLSimulation.speciesCount)
                        for i in 0..<sim.px.count {
                            let s = sim.species[i]
                            let x = sim.px[i]
                            let y = sim.py[i]
                            glowPaths[s].addEllipse(in: CGRect(x: x - 6, y: y - 6,
                                                               width: 12, height: 12))
                            corePaths[s].addEllipse(in: CGRect(x: x - 2.6, y: y - 2.6,
                                                               width: 5.2, height: 5.2))
                        }
                        for s in 0..<PLSimulation.speciesCount {
                            context.fill(glowPaths[s],
                                         with: .color(Self.speciesColors[s].opacity(0.16)))
                        }
                        for s in 0..<PLSimulation.speciesCount {
                            context.fill(corePaths[s], with: .color(Self.speciesColors[s]))
                        }
                    }
                    // On the Canvas only, so it can never fight the pause button.
                    .onTapGesture(coordinateSpace: .local) { location in
                        guard !isPaused else { return }
                        GameHaptics.tap()
                        sim.stir(at: location)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel("Particle Life, universe \(universeName), \(isPaused ? "paused" : "running")")
                .padding(.horizontal, 12)

                Text("Tap to stir. Same particles, new physics every restart. Some universes are boring — roll again.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }
            .padding(.top, 4)
        }
    }

    private func newUniverse() {
        universeName = sim.rollNewUniverse()
        sim.scatter(in: sim.worldSize)   // no-op before the first frame; step() scatters then
        sim.lastDate = nil
        isPaused = false
    }
}

#Preview {
    ParticleLifeGameView()
}
