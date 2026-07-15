//
//  MossGardenGameView.swift
//  ChordLab
//
//  Moss Garden: plant seeds, close the app, come back tomorrow.
//  Every plant's shape is a pure function of (seed, age), so growth
//  happens in real time whether or not you're watching. State is just
//  a tiny JSON list of seeds and plant dates.
//

import SwiftUI

struct MossGardenGameView: View {
    private struct MossPlant: Codable, Identifiable {
        var id: Int { seed }
        let seed: Int
        let xFraction: Double
        let planted: Date
    }

    private static let storageKey = "arcade.moss.garden"
    private static let maxPlants = 6

    @State private var plants: [MossPlant] = []
    @State private var showClearConfirm = false
    @State private var didLoad = false

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "moss")!, onRestart: nil) {
            VStack(spacing: 10) {
                TimelineView(.animation(minimumInterval: 1.0)) { timeline in
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            StatPill(label: "Plants", value: "\(plants.count)/\(Self.maxPlants)", tint: .green)
                            StatPill(label: "Oldest", value: oldestText(now: timeline.date), tint: .mint)

                            if !plants.isEmpty {
                                Button {
                                    GameHaptics.warning()
                                    showClearConfirm = true
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 32, height: 32)
                                        .background(Color.appSecondaryBackground, in: Circle())
                                }
                            }
                        }

                        GeometryReader { geo in
                            Canvas { context, size in
                                drawGarden(context: context, size: size, now: timeline.date)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onTapGesture(coordinateSpace: .local) { location in
                                plantSeed(atFraction: Double(location.x) / max(1, Double(geo.size.width)))
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                }

                Text(plants.isEmpty
                     ? "Tap the soil to plant your first seed."
                     : "Growing in real time. Sprouts in hours, flowers in days.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 8)
            }
            .padding(.top, 4)
            .overlay {
                if showClearConfirm {
                    clearConfirmOverlay
                }
            }
            .onAppear {
                if !didLoad {
                    didLoad = true
                    load()
                }
                reportDays()
            }
        }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let saved = try? JSONDecoder().decode([MossPlant].self, from: data) else {
            plants = []
            return
        }
        plants = saved
    }

    private func save() {
        if let data = try? JSONEncoder().encode(plants) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
        reportDays()
    }

    private func reportDays() {
        guard let oldest = plants.map(\.planted).min() else { return }
        let days = Int(Date().timeIntervalSince(oldest) / 86_400)
        // Best-ever, not current: clearing and replanting must not wipe
        // the record, and clock rollbacks must not store negatives.
        GameScores.shared.report(score: max(0, days), for: "moss")
    }

    private func oldestText(now: Date) -> String {
        guard let oldest = plants.map(\.planted).min() else { return "—" }
        let hours = max(0, now.timeIntervalSince(oldest)) / 3600
        if hours < 1 { return "\(max(1, Int(hours * 60)))m" }
        if hours < 48 { return "\(Int(hours))h" }
        return "\(Int(hours / 24))d \(Int(hours.truncatingRemainder(dividingBy: 24)))h"
    }

    // MARK: - Actions

    private func plantSeed(atFraction fraction: Double) {
        guard plants.count < Self.maxPlants, !showClearConfirm else {
            if plants.count >= Self.maxPlants { GameHaptics.warning() }
            return
        }
        GameHaptics.success()
        var seed = Int.random(in: 1..<1_000_000)
        while plants.contains(where: { $0.seed == seed }) {
            seed = Int.random(in: 1..<1_000_000)
        }
        plants.append(MossPlant(seed: seed,
                                xFraction: min(0.94, max(0.06, fraction)),
                                planted: Date()))
        save()
    }

    private var clearConfirmOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("🥀")
                    .font(.system(size: 40))
                Text("Clear the garden?")
                    .font(.title3.weight(.bold))
                Text("Your plants took real days to grow. This can't be undone.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                HStack(spacing: 10) {
                    ArcadeButton(title: "Keep Growing", tint: .green) {
                        showClearConfirm = false
                    }
                    ArcadeButton(title: "Clear", tint: .red) {
                        plants = []
                        save()
                        showClearConfirm = false
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 24))
            .padding(32)
        }
    }

    // MARK: - Drawing

    private static func hash(_ a: Int, _ b: Int, _ c: Int) -> Double {
        var h: UInt64 = 0x9E37_79B9_7F4A_7C15
        for value in [a, b, c] {
            h ^= UInt64(bitPattern: Int64(value)) &* 0xBF58_476D_1CE4_E5B9
            h = (h ^ (h >> 27)) &* 0x94D0_49BB_1331_11EB
            h ^= h >> 31
        }
        return Double(h % 1_000_000) / 1_000_000
    }

    private func drawGarden(context: GraphicsContext, size: CGSize, now: Date) {
        // Soft sky + soil
        let soilTop = size.height - 46
        context.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .linearGradient(
                        Gradient(colors: [Color(red: 0.75, green: 0.86, blue: 0.90),
                                          Color(red: 0.90, green: 0.94, blue: 0.90)]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: 0, y: size.height)))
        context.fill(Path(CGRect(x: 0, y: soilTop, width: size.width, height: size.height - soilTop)),
                     with: .color(Color(red: 0.29, green: 0.21, blue: 0.15)))

        for plant in plants {
            let baseX = CGFloat(plant.xFraction) * size.width
            let base = CGPoint(x: baseX, y: soilTop + 2)
            let ageHours = max(0, now.timeIntervalSince(plant.planted) / 3600)
            drawMossPatch(context: context, base: base, seed: plant.seed, ageHours: ageHours)
            drawPlant(context: context, base: base, seed: plant.seed, ageHours: ageHours,
                      canvasHeight: size.height)
        }
    }

    private func drawMossPatch(context: GraphicsContext, base: CGPoint, seed: Int, ageHours: Double) {
        let radius = min(30, 3 + ageHours.squareRoot() * 2.2)
        for blob in 0..<5 {
            let offset = (Self.hash(seed, blob, 41) - 0.5) * radius * 2
            let blobRadius = radius * (0.35 + Self.hash(seed, blob, 42) * 0.4)
            let green = 0.42 + Self.hash(seed, blob, 43) * 0.25
            context.fill(
                Path(ellipseIn: CGRect(x: base.x + offset - blobRadius,
                                       y: base.y - blobRadius * 0.4,
                                       width: blobRadius * 2,
                                       height: blobRadius * 0.8)),
                with: .color(Color(red: 0.12, green: green, blue: 0.18).opacity(0.75)))
        }
    }

    private func drawPlant(context: GraphicsContext, base: CGPoint, seed: Int,
                           ageHours: Double, canvasHeight: CGFloat) {
        // Continuous growth stage: ~1 at planting +90m, ~4 after a day,
        // ~6 after four days, flowers past ~5 days.
        let stage = min(7.6, 1 + log2(1 + ageHours / 1.5))

        if stage < 1.05 {
            // Just a seed bump
            context.fill(Path(ellipseIn: CGRect(x: base.x - 3, y: base.y - 4, width: 6, height: 5)),
                         with: .color(Color(red: 0.45, green: 0.35, blue: 0.2)))
            return
        }

        let hue = 0.28 + Self.hash(seed, 0, 1) * 0.12          // green..teal family
        let flowerHue = Self.hash(seed, 0, 2)
        let baseLength = 26.0 + Self.hash(seed, 0, 3) * 14

        drawBranch(context: context, from: base,
                   angle: -.pi / 2 + (Self.hash(seed, 0, 4) - 0.5) * 0.2,
                   depth: 1, nodeId: 0,
                   stage: stage, seed: seed, hue: hue, flowerHue: flowerHue,
                   length: baseLength)
    }

    private func drawBranch(context: GraphicsContext, from start: CGPoint, angle: Double,
                            depth: Int, nodeId: Int, stage: Double, seed: Int,
                            hue: Double, flowerHue: Double, length: Double) {
        guard depth <= 7 else { return }

        // Every tier (including the first stem) grows in smoothly over
        // one stage unit: growth = clamp(stage - depth, 0, 1).
        let growth = min(1.0, max(0.0, stage - Double(depth)))
        guard growth > 0.05 else { return }

        let sway = sin(Self.hash(seed, nodeId, 7) * .pi * 2) * 0.06
        let drawnAngle = angle + sway
        let drawnLength = length * growth
        let end = CGPoint(x: start.x + cos(drawnAngle) * drawnLength,
                          y: start.y + sin(drawnAngle) * drawnLength)

        var path = Path()
        path.move(to: start)
        // Slight curve makes it read as a plant, not a diagram.
        let control = CGPoint(x: (start.x + end.x) / 2 + CGFloat(sway * 40),
                              y: (start.y + end.y) / 2)
        path.addQuadCurve(to: end, control: control)

        let thickness = max(0.8, 5.0 - Double(depth) * 0.7) * growth
        context.stroke(path,
                       with: .color(Color(hue: hue, saturation: 0.55,
                                          brightness: 0.42 + Double(depth) * 0.04)),
                       style: StrokeStyle(lineWidth: thickness, lineCap: .round))

        // Leaves on mid-depth nodes once the plant is established.
        if depth >= 3 && stage >= 3.6 && growth == 1 {
            let leafSize = 3.0 + Self.hash(seed, nodeId, 8) * 2.5
            context.fill(
                Path(ellipseIn: CGRect(x: end.x - leafSize / 2, y: end.y - leafSize / 2,
                                       width: leafSize, height: leafSize * 1.6)),
                with: .color(Color(hue: hue + 0.03, saturation: 0.65, brightness: 0.6).opacity(0.9)))
        }

        // Flowers on the outermost mature tips (roughly day five onward).
        if stage >= 6.9 && depth >= 5 && growth == 1 && Self.hash(seed, nodeId, 9) < 0.4 {
            let petal = 2.6
            for p in 0..<5 {
                let petalAngle = Double(p) / 5 * .pi * 2
                context.fill(
                    Path(ellipseIn: CGRect(x: end.x + cos(petalAngle) * petal - 1.6,
                                           y: end.y + sin(petalAngle) * petal - 1.6,
                                           width: 3.2, height: 3.2)),
                    with: .color(Color(hue: flowerHue, saturation: 0.55, brightness: 0.95)))
            }
            context.fill(Path(ellipseIn: CGRect(x: end.x - 1.4, y: end.y - 1.4, width: 2.8, height: 2.8)),
                         with: .color(.yellow))
        }

        guard depth < 7 else { return }

        // Two or three children, angles seeded per node.
        let childCount = Self.hash(seed, nodeId, 10) < 0.25 ? 3 : 2
        for child in 0..<childCount {
            let childId = nodeId * 3 + child + 1
            let spread = 0.3 + Self.hash(seed, childId, 11) * 0.45
            let direction = child == 0 ? -1.0 : (child == 1 ? 1.0 : (Self.hash(seed, childId, 12) - 0.5) * 0.6)
            let childAngle = drawnAngle + spread * direction
            // Gentle upward bias so plants reach for the light.
            let biased = childAngle * 0.9 + (-.pi / 2) * 0.1
            drawBranch(context: context, from: end, angle: biased,
                       depth: depth + 1, nodeId: childId,
                       stage: stage, seed: seed, hue: hue, flowerHue: flowerHue,
                       length: length * 0.74)
        }
    }
}

#Preview {
    MossGardenGameView()
}
