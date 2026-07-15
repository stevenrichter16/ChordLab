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
    /// Live-switchable economic rules. Wealth is whole dollars, so both
    /// interventions are built to move only whole dollars (no cents).
    private enum EconomicPolicy: CaseIterable {
        case freeMarket, flatTax, ubi

        var label: String {
            switch self {
            case .freeMarket: return "Market"
            case .flatTax: return "Tax"
            case .ubi: return "UBI"
            }
        }
    }

    private final class AntSimulation {
        static let antCount = 110
        static let startingWealth = 10
        static let speed: CGFloat = 46
        static let meetDistance: CGFloat = 9
        static let tradeCooldown: CGFloat = 0.6
        static let windfallTotal = 24
        static let windfallShares = 3
        static let pulseDuration: CGFloat = 0.6
        /// Flat tax: chance a traded dollar is skimmed into the communal pot
        /// (a 25% skim in expectation — whole dollars, never fractions).
        static let taxSkimChance = 0.25
        static let ubiInterval: CGFloat = 6

        var px: [CGFloat] = []
        var py: [CGFloat] = []
        var heading: [CGFloat] = []
        var wealth: [Int] = []
        var cooldown: [CGFloat] = []
        var worldSize: CGSize = .zero
        var lastDate: Date?
        var trades = 0

        var policy: EconomicPolicy = .freeMarket
        /// Whole dollars skimmed from trades, waiting to be handed back out.
        var taxPot = 0
        var ubiClock: CGFloat = 0

        /// Set from the tap gesture, consumed at the top of step() so the
        /// grant happens on the sim path, not the render path.
        var pendingWindfall: CGPoint?
        var pulseCenter: CGPoint?
        var pulseAge: CGFloat = 0

        func reset(in size: CGSize) {
            guard size.width > 40, size.height > 40 else { return }
            worldSize = size
            px = (0..<Self.antCount).map { _ in CGFloat.random(in: 10..<(size.width - 10)) }
            py = (0..<Self.antCount).map { _ in CGFloat.random(in: 10..<(size.height - 10)) }
            heading = (0..<Self.antCount).map { _ in CGFloat.random(in: 0..<(2 * .pi)) }
            wealth = Array(repeating: Self.startingWealth, count: Self.antCount)
            cooldown = Array(repeating: 0, count: Self.antCount)
            trades = 0
            taxPot = 0
            ubiClock = 0
            pendingWindfall = nil
            pulseCenter = nil
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
            if lastDate == nil {
                dt = 1.0 / 60.0
            } else {
                dt = CGFloat(SimClock.dt(since: lastDate, to: date, cap: 1.0 / 30.0))
            }
            lastDate = date

            let count = Self.antCount

            // Tap windfall: the nearest ants split a bonus, then the market
            // gets to work redistributing it.
            if let tap = pendingWindfall {
                pendingWindfall = nil
                grantWindfall(at: tap)
            }
            if pulseCenter != nil {
                pulseAge += dt
                if pulseAge >= Self.pulseDuration { pulseCenter = nil }
            }

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
                        if policy == .flatTax, Double.random(in: 0..<1) < Self.taxSkimChance {
                            taxPot += 1
                        } else {
                            wealth[taker] += 1
                        }
                        trades += 1
                    }
                    cooldown[i] = Self.tradeCooldown
                    cooldown[j] = Self.tradeCooldown
                    break
                }
            }

            // The pot pays out $1 a head as soon as it can afford to
            // (even after a policy switch, so no dollars stay stranded).
            if taxPot >= count {
                taxPot -= count
                for i in 0..<count { wealth[i] += 1 }
            }

            if policy == .ubi {
                ubiClock += dt
                if ubiClock >= Self.ubiInterval {
                    ubiClock = 0
                    applyUBI()
                }
            } else {
                ubiClock = 0
            }
        }

        private func grantWindfall(at point: CGPoint) {
            let nearest = (0..<Self.antCount).sorted { a, b in
                let da = (px[a] - point.x) * (px[a] - point.x) + (py[a] - point.y) * (py[a] - point.y)
                let db = (px[b] - point.x) * (px[b] - point.x) + (py[b] - point.y) * (py[b] - point.y)
                return da < db
            }.prefix(Self.windfallShares)
            let share = Self.windfallTotal / Self.windfallShares
            for i in nearest { wealth[i] += share }
            pulseCenter = point
            pulseAge = 0
        }

        /// UBI: everyone gets $1, funded by a levy proportional to wealth.
        /// Integer division under-collects, so the shortfall comes from the
        /// richest ants — money is conserved exactly.
        private func applyUBI() {
            let need = Self.antCount
            let total = wealth.reduce(0, +)
            guard total >= need else { return }
            var collected = 0
            for i in 0..<Self.antCount {
                let levy = wealth[i] * need / total
                wealth[i] -= levy
                collected += levy
            }
            while collected < need {
                guard let i = wealth.indices.max(by: { wealth[$0] < wealth[$1] }),
                      wealth[i] > 0 else { break }
                wealth[i] -= 1
                collected += 1
            }
            for i in 0..<Self.antCount { wealth[i] += 1 }
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

    private static let giniSampleCap = 240   // ~2 minutes at the 0.5s ticker

    @State private var sim = AntSimulation()
    @State private var giniText = "0.00"
    @State private var richest = 10
    @State private var brokeCount = 0
    @State private var tradeCount = 0
    @State private var histogramBins: [Int] = Array(repeating: 0, count: 12)
    @State private var giniHistory: [Double] = []
    @State private var policy: EconomicPolicy = .freeMarket
    @State private var isPaused = false

    private let statsTicker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "wealthants")!,
                   onRestart: { resetColony() },
                   confirmRestart: true) {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    StatPill(label: "Gini", value: giniText, tint: .orange)
                    StatPill(label: "Richest", value: "$\(richest)", tint: .yellow)
                    StatPill(label: "Broke", value: "\(brokeCount)", tint: .red)
                    StatPill(label: "Trades", value: "\(tradeCount)", tint: .brown)
                }

                giniSparkline
                    .frame(height: 16)
                    .padding(.horizontal, 16)
                    .accessibilityHidden(true)

                TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: isPaused)) { timeline in
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
                        if let pulse = sim.pulseCenter {
                            let progress = min(1, sim.pulseAge / AntSimulation.pulseDuration)
                            let radius = 6 + progress * 26
                            let rect = CGRect(x: pulse.x - radius, y: pulse.y - radius,
                                              width: radius * 2, height: radius * 2)
                            context.stroke(Path(ellipseIn: rect),
                                           with: .color(Color(hue: 0.13, saturation: 0.85, brightness: 1.0)
                                               .opacity(Double(1 - progress) * 0.8)),
                                           lineWidth: 2)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onTapGesture { location in
                    guard !isPaused else { return }
                    GameHaptics.tap()
                    sim.pendingWindfall = location
                }
                .accessibilityElement()
                .accessibilityLabel("Ant colony: \(AntSimulation.antCount) ants trading, Gini \(giniText)")
                .padding(.horizontal, 12)

                HStack(spacing: 10) {
                    Picker("Policy", selection: $policy) {
                        ForEach(EconomicPolicy.allCases, id: \.self) { rule in
                            Text(rule.label).tag(rule)
                        }
                    }
                    .pickerStyle(.segmented)

                    Button {
                        GameHaptics.tap()
                        isPaused.toggle()
                    } label: {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color.appSecondaryBackground, in: Circle())
                    }
                    .accessibilityLabel(isPaused ? "Resume" : "Pause")
                }
                .padding(.horizontal, 16)

                histogramView
                    .frame(height: 64)
                    .padding(.horizontal, 16)

                Text("Every trade is a fair coin flip for $1. Inequality shows up anyway — tap to drop a windfall.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }
            .padding(.top, 4)
            .onReceive(statsTicker) { _ in
                refreshStats()
            }
            .onChange(of: policy) { _, newValue in
                sim.policy = newValue
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

    /// Two minutes of Gini samples: is inequality still climbing, or settled?
    private var giniSparkline: some View {
        Canvas { context, size in
            guard giniHistory.count >= 2 else { return }
            let stepX = size.width / CGFloat(Self.giniSampleCap - 1)
            let maxGini = 0.8
            var path = Path()
            for (index, value) in giniHistory.enumerated() {
                let x = CGFloat(index) * stepX
                let y = size.height - CGFloat(min(value, maxGini) / maxGini) * size.height
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.stroke(path, with: .color(.orange.opacity(0.7)), lineWidth: 1.5)
        }
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
                Text("broke").font(.caption2).foregroundStyle(.tertiary)
                Spacer()
                Text("wealth →").font(.caption2).foregroundStyle(.tertiary)
                Spacer()
                Text("rich").font(.caption2).foregroundStyle(.tertiary)
            }
        }
    }

    private func refreshStats() {
        let gini = sim.gini()
        giniText = String(format: "%.2f", gini)
        richest = sim.wealth.max() ?? 0
        brokeCount = sim.wealth.filter { $0 == 0 }.count
        tradeCount = sim.trades
        histogramBins = sim.histogram(bins: 12)
        if !isPaused {
            giniHistory.append(gini)
            if giniHistory.count > Self.giniSampleCap {
                giniHistory.removeFirst(giniHistory.count - Self.giniSampleCap)
            }
        }
    }

    private func resetColony() {
        sim.reset(in: sim.worldSize)
        sim.lastDate = nil
        sim.policy = policy
        giniHistory.removeAll()
        isPaused = false
        refreshStats()
    }
}

#Preview {
    WealthAntsGameView()
}
