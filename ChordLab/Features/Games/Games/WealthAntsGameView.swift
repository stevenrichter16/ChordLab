//
//  WealthAntsGameView.swift
//  ChordLab
//
//  The Wealth of Ants: every ant starts with $10. When two ants meet,
//  one gives the other $1 — direction chosen by coin flip. Perfectly
//  fair rules, and yet: watch the histogram. A few ants get rich,
//  most go broke. (The Boltzmann wealth model.)
//

import SwiftUI

struct WealthAntsGameView: View {
    private final class AntSimulation {
        static let antCount = 110
        static let startingWealth = 10
        static let speed: CGFloat = 46
        static let meetDistance: CGFloat = 9
        static let tradeCooldown: CGFloat = 0.6

        var px: [CGFloat] = []
        var py: [CGFloat] = []
        var heading: [CGFloat] = []
        var wealth: [Int] = []
        var cooldown: [CGFloat] = []
        var worldSize: CGSize = .zero
        var lastDate: Date?
        var trades = 0

        func reset(in size: CGSize) {
            guard size.width > 40, size.height > 40 else { return }
            worldSize = size
            px = (0..<Self.antCount).map { _ in CGFloat.random(in: 10..<(size.width - 10)) }
            py = (0..<Self.antCount).map { _ in CGFloat.random(in: 10..<(size.height - 10)) }
            heading = (0..<Self.antCount).map { _ in CGFloat.random(in: 0..<(2 * .pi)) }
            wealth = Array(repeating: Self.startingWealth, count: Self.antCount)
            cooldown = Array(repeating: 0, count: Self.antCount)
            trades = 0
        }

        func step(to date: Date, size: CGSize) {
            if px.isEmpty {
                reset(in: size)
            } else if size != worldSize {
                // Keep the colony (and its inequality) across rotations —
                // just clamp everyone into the new bounds.
                worldSize = size
                for i in 0..<px.count {
                    px[i] = min(max(px[i], 6), max(7, size.width - 6))
                    py[i] = min(max(py[i], 6), max(7, size.height - 6))
                }
            }
            guard !px.isEmpty else { return }

            let dt: CGFloat
            if let lastDate {
                dt = CGFloat(min(date.timeIntervalSince(lastDate), 1.0 / 30.0))
            } else {
                dt = 1.0 / 60.0
            }
            lastDate = date

            let count = Self.antCount

            // Wander
            for i in 0..<count {
                heading[i] += CGFloat.random(in: -2.2...2.2) * dt
                px[i] += cos(heading[i]) * Self.speed * dt
                py[i] += sin(heading[i]) * Self.speed * dt

                // Bounce off the walls
                if px[i] < 6 { px[i] = 6; heading[i] = .pi - heading[i] }
                if px[i] > size.width - 6 { px[i] = size.width - 6; heading[i] = .pi - heading[i] }
                if py[i] < 6 { py[i] = 6; heading[i] = -heading[i] }
                if py[i] > size.height - 6 { py[i] = size.height - 6; heading[i] = -heading[i] }

                cooldown[i] = max(0, cooldown[i] - dt)
            }

            // Meetings: one random $1 transfer per encounter
            let meetSq = Self.meetDistance * Self.meetDistance
            for i in 0..<count where cooldown[i] <= 0 {
                for j in (i + 1)..<count where cooldown[j] <= 0 {
                    let dx = px[j] - px[i]
                    let dy = py[j] - py[i]
                    guard dx * dx + dy * dy < meetSq else { continue }

                    let giver = Bool.random() ? i : j
                    let taker = giver == i ? j : i
                    if wealth[giver] > 0 {
                        wealth[giver] -= 1
                        wealth[taker] += 1
                        trades += 1
                    }
                    cooldown[i] = Self.tradeCooldown
                    cooldown[j] = Self.tradeCooldown
                    break
                }
            }
        }

        /// Gini coefficient: 0 = perfect equality, 1 = one ant owns it all.
        func gini() -> Double {
            guard !wealth.isEmpty else { return 0 }
            let sorted = wealth.sorted().map(Double.init)
            let total = sorted.reduce(0, +)
            guard total > 0 else { return 0 }
            let n = Double(sorted.count)
            var weightedSum = 0.0
            for (index, value) in sorted.enumerated() {
                weightedSum += Double(index + 1) * value
            }
            return (2 * weightedSum) / (n * total) - (n + 1) / n
        }

        func histogram(bins: Int) -> [Int] {
            guard !wealth.isEmpty else { return Array(repeating: 0, count: bins) }
            let top = max(Self.startingWealth * 3, wealth.max() ?? 1)
            var counts = Array(repeating: 0, count: bins)
            for value in wealth {
                let bin = min(bins - 1, value * bins / max(top, 1))
                counts[bin] += 1
            }
            return counts
        }
    }

    @State private var sim = AntSimulation()
    @State private var giniText = "0.00"
    @State private var richest = 10
    @State private var brokeCount = 0
    @State private var tradeCount = 0
    @State private var histogramBins: [Int] = Array(repeating: 0, count: 12)

    private let statsTicker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "wealthants")!, onRestart: { resetColony() }) {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    StatPill(label: "Gini", value: giniText, tint: .orange)
                    StatPill(label: "Richest", value: "$\(richest)", tint: .yellow)
                    StatPill(label: "Broke", value: "\(brokeCount)", tint: .red)
                    StatPill(label: "Trades", value: "\(tradeCount)", tint: .brown)
                }

                TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                    Canvas { context, size in
                        sim.step(to: timeline.date, size: size)
                        context.fill(Path(CGRect(origin: .zero, size: size)),
                                     with: .color(Color(red: 0.13, green: 0.10, blue: 0.07)))
                        for i in 0..<sim.px.count {
                            let money = sim.wealth[i]
                            let radius = 2.0 + min(4.0, CGFloat(money) * 0.09)
                            let rect = CGRect(x: sim.px[i] - radius, y: sim.py[i] - radius,
                                              width: radius * 2, height: radius * 2)
                            context.fill(Path(ellipseIn: rect), with: .color(antColor(money)))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 12)

                histogramView
                    .frame(height: 64)
                    .padding(.horizontal, 16)

                Text("Every trade is a fair coin flip for $1. Inequality shows up anyway.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 8)
            }
            .padding(.top, 4)
            .onReceive(statsTicker) { _ in
                refreshStats()
            }
        }
    }

    private func antColor(_ money: Int) -> Color {
        if money == 0 {
            return Color(white: 0.45)
        }
        let richness = min(1.0, Double(money) / 40.0)
        return Color(hue: 0.12, saturation: 0.5 + richness * 0.5, brightness: 0.55 + richness * 0.45)
    }

    private var histogramView: some View {
        VStack(spacing: 3) {
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<histogramBins.count, id: \.self) { index in
                    let peak = max(histogramBins.max() ?? 1, 1)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.brown.opacity(0.85))
                        .frame(height: max(2, CGFloat(histogramBins[index]) / CGFloat(peak) * 46))
                        .frame(maxWidth: .infinity, alignment: .bottom)
                }
            }
            .frame(height: 48, alignment: .bottom)
            .animation(.easeOut(duration: 0.3), value: histogramBins)

            HStack {
                Text("broke").font(.system(size: 9)).foregroundStyle(.tertiary)
                Spacer()
                Text("wealth →").font(.system(size: 9)).foregroundStyle(.tertiary)
                Spacer()
                Text("rich").font(.system(size: 9)).foregroundStyle(.tertiary)
            }
        }
    }

    private func refreshStats() {
        giniText = String(format: "%.2f", sim.gini())
        richest = sim.wealth.max() ?? 0
        brokeCount = sim.wealth.filter { $0 == 0 }.count
        tradeCount = sim.trades
        histogramBins = sim.histogram(bins: 12)
    }

    private func resetColony() {
        sim.reset(in: sim.worldSize)
        sim.lastDate = nil
        refreshStats()
    }
}

#Preview {
    WealthAntsGameView()
}
