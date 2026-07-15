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

        var px: [CGFloat] = []
        var py: [CGFloat] = []
        var vx: [CGFloat] = []
        var vy: [CGFloat] = []
        var species: [Int] = []
        /// Flattened speciesCount×speciesCount attraction matrix (hot loop).
        var matrix: [CGFloat] = []
        var worldSize: CGSize = .zero
        var lastDate: Date?

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

        func reset(in size: CGSize) {
            rollChemistry()
            scatter(in: size)
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

        func step(to date: Date, size: CGSize) {
            if size != worldSize || px.isEmpty {
                if matrix.isEmpty { rollChemistry() }
                scatter(in: size)
            }
            guard size.width > 0, size.height > 0 else { return }

            let dt: CGFloat
            if let lastDate {
                dt = CGFloat(min(date.timeIntervalSince(lastDate), 1.0 / 30.0))
            } else {
                dt = 1.0 / 60.0
            }
            lastDate = date

            let width = size.width
            let height = size.height
            let count = Self.particleCount
            let friction = pow(0.5, dt / Self.frictionHalfLife)

            let maxSpeed: CGFloat = 600
            for i in 0..<count {
                var fx: CGFloat = 0
                var fy: CGFloat = 0
                let rowBase = species[i] * Self.speciesCount

                for j in 0..<count where j != i {
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

    private static let universeNames = ["α", "β", "γ", "δ", "ε", "ζ", "η", "θ"]

    @State private var sim = PLSimulation()
    @State private var isPaused = false
    @State private var universeName = ParticleLifeGameView.universeNames.randomElement() ?? "α"

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "particlelife")!, onRestart: { newUniverse() }) {
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
                        for i in 0..<PLSimulation.particleCount where i < sim.px.count {
                            let rect = CGRect(x: sim.px[i] - 2.6, y: sim.py[i] - 2.6,
                                              width: 5.2, height: 5.2)
                            context.fill(Path(ellipseIn: rect),
                                         with: .color(Self.speciesColors[sim.species[i]]))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 12)

                Text("Same particles, new physics every restart. Some universes are boring — roll again.")
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
        sim.rollChemistry()
        sim.scatter(in: sim.worldSize)   // no-op before the first frame; step() scatters then
        sim.lastDate = nil
        universeName = Self.universeNames.randomElement() ?? "α"
        isPaused = false
    }
}

#Preview {
    ParticleLifeGameView()
}
