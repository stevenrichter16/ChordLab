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
        var planted: Date
        // Cosmetic only — dew never affects growth. Optional so saves from
        // before watering existed still decode.
        var watered: Date?
    }

    private static let storageKey = "arcade.moss.garden"
    private static let maxPlants = 6
    /// Watering is a small ritual, not a mechanic: the dew fades over ~10 minutes.
    private static let dewDuration: TimeInterval = 600
    /// Age at which drawPlant graduates from the static seed bump to a
    /// swaying stem: stage 1.05, inverted from stage = 1 + log2(1 + ageHours / 1.5).
    private static let swayVisibleAge: TimeInterval = 1.5 * 3600 * (pow(2, 0.05) - 1)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var plants: [MossPlant] = []
    @State private var showClearConfirm = false
    @State private var didLoad = false

    // Header and accessibility strings are mirrored off the render path on
    // a slow cadence so the smooth-frame loop never rebuilds them per frame.
    @State private var statOldest = "—"
    @State private var statA11y = "Moss garden. Empty soil, tap to plant a seed."
    /// Wind sway is the only fast-moving element, and it isn't visible until
    /// a plant outgrows the seed bump; idle at 1 Hz the rest of the time.
    @State private var wantsSmoothFrames = false
    @State private var dayClock = DayClock()

    private let statsTicker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "moss")!,
                   onRestart: { clearGarden() },
                   confirmRestart: true) {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    StatPill(label: "Plants", value: "\(plants.count)/\(Self.maxPlants)", tint: .green)
                    StatPill(label: "Oldest", value: statOldest, tint: .mint)

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
                                // 44pt hit target around the 32pt visual circle.
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("Clear garden")
                    }
                }

                // 20 fps for the wind sway once a stem is up; a calm 1 Hz
                // while nothing visibly moves (empty soil, seeds only) or
                // when Reduce Motion is on.
                TimelineView(.animation(minimumInterval: (reduceMotion || !wantsSmoothFrames) ? 1.0 : 0.05)) { timeline in
                    GeometryReader { geo in
                        Canvas { context, size in
                            drawGarden(context: context, size: size, now: timeline.date,
                                       windPhase: reduceMotion ? nil : timeline.date.timeIntervalSinceReferenceDate)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onTapGesture(coordinateSpace: .local) { location in
                            handleTap(atX: Double(location.x), width: max(1, Double(geo.size.width)))
                        }
                        .accessibilityLabel(statA11y)
                    }
                    .padding(.horizontal, 12)
                }

                Text(plants.isEmpty
                     ? "Tap the soil to plant your first seed."
                     : "Growing in real time. Tap a plant to water it.")
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
                refreshStats()
            }
            .onReceive(statsTicker) { _ in
                refreshStats()
            }
        }
    }

    // MARK: - Persistence

    private func load() {
        guard var saved = SimPersist.load([MossPlant].self, key: Self.storageKey) else {
            plants = []
            return
        }
        // Clock-ahead repair: a plant stamped while the device clock was set
        // ahead would render as a frozen seed until real time caught up,
        // and a future watered stamp would pin its dew at full freshness.
        let now = Date()
        var repaired = false
        for index in saved.indices {
            if saved[index].planted > now {
                saved[index].planted = now
                repaired = true
            }
            if let watered = saved[index].watered, watered > now {
                saved[index].watered = now
                repaired = true
            }
        }
        plants = saved
        if repaired { save() }
    }

    private func save() {
        SimPersist.save(plants, key: Self.storageKey)
        reportDays()
        refreshStats()
    }

    private func reportDays() {
        guard let oldest = plants.map(\.planted).min() else { return }
        let days = Int(Date().timeIntervalSince(oldest) / 86_400)
        // Best-ever, not current: clearing and replanting must not wipe
        // the record, and clock rollbacks must not store negatives.
        GameScores.shared.report(score: max(0, days), for: "moss")
    }

    /// Mirrors the header pill, the canvas VoiceOver summary, and the
    /// smooth-frame gate into @State once a second (and after every save),
    /// keeping array scans and string building out of the 20 fps path.
    private func refreshStats() {
        let now = Date()
        statOldest = oldestText(now: now)
        statA11y = gardenSummary(now: now)
        wantsSmoothFrames = plants.contains {
            now.timeIntervalSince($0.planted) > Self.swayVisibleAge
        }
    }

    private func oldestText(now: Date) -> String {
        guard let oldest = plants.map(\.planted).min() else { return "—" }
        let hours = max(0, now.timeIntervalSince(oldest)) / 3600
        if hours < 1 { return "\(max(1, Int(hours * 60)))m" }
        if hours < 48 { return "\(Int(hours))h" }
        return "\(Int(hours / 24))d \(Int(hours.truncatingRemainder(dividingBy: 24)))h"
    }

    /// One-line VoiceOver summary of the whole canvas.
    private func gardenSummary(now: Date) -> String {
        guard let oldest = plants.map(\.planted).min() else {
            return "Moss garden. Empty soil, tap to plant a seed."
        }
        let hours = max(0, now.timeIntervalSince(oldest)) / 3600
        let age: String
        if hours < 1 { age = "\(max(1, Int(hours * 60))) minutes" }
        else if hours < 48 { age = "\(Int(hours)) hours" }
        else { age = "\(Int(hours / 24)) days" }
        return "Moss garden. \(plants.count) plant\(plants.count == 1 ? "" : "s"), oldest \(age) old."
    }

    // MARK: - Actions

    private func handleTap(atX x: Double, width: Double) {
        guard !showClearConfirm else { return }
        // A tap close to an existing plant waters it; open soil plants a seed.
        if let index = nearestPlantIndex(toX: x, width: width) {
            GameHaptics.tap()
            plants[index].watered = Date()
            save()
        } else {
            plantSeed(atFraction: x / width)
        }
    }

    private func nearestPlantIndex(toX x: Double, width: Double) -> Int? {
        let nearest = plants.indices.min {
            abs(plants[$0].xFraction * width - x) < abs(plants[$1].xFraction * width - x)
        }
        guard let nearest, abs(plants[nearest].xFraction * width - x) <= 24 else { return nil }
        return nearest
    }

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

    private func clearGarden() {
        plants = []
        save()
        showClearConfirm = false
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
                        clearGarden()
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

    private func drawGarden(context: GraphicsContext, size: CGSize, now: Date, windPhase: Double?) {
        let hour = dayClock.hourOfDay(now)
        let daylight = Self.daylight(at: hour)
        let sky = Self.skyColors(at: hour)
        let soilTop = size.height - 46

        context.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .linearGradient(
                        Gradient(colors: [sky.top, sky.bottom]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: 0, y: size.height)))
        drawStars(context: context, size: size, soilTop: soilTop,
                  visibility: max(0, 1 - daylight * 1.8), phase: windPhase)
        drawSunMoon(context: context, size: size, soilTop: soilTop, hour: hour)

        let soilDim = 0.55 + 0.45 * daylight
        context.fill(Path(CGRect(x: 0, y: soilTop, width: size.width, height: size.height - soilTop)),
                     with: .color(Color(red: 0.29 * soilDim, green: 0.21 * soilDim, blue: 0.15 * soilDim)))

        // Plants dim gently after dark but stay readable.
        let dim = 0.65 + 0.35 * daylight
        for plant in plants {
            let baseX = CGFloat(plant.xFraction) * size.width
            let base = CGPoint(x: baseX, y: soilTop + 2)
            let ageHours = max(0, now.timeIntervalSince(plant.planted) / 3600)
            let dew = dewFreshness(for: plant, now: now)
            drawMossPatch(context: context, base: base, seed: plant.seed, ageHours: ageHours,
                          dim: dim, dew: dew)
            drawPlant(context: context, base: base, seed: plant.seed, ageHours: ageHours,
                      dim: dim, windPhase: windPhase, dew: dew)
        }
    }

    /// 1 right after watering, fading to 0 over dewDuration.
    private func dewFreshness(for plant: MossPlant, now: Date) -> Double {
        guard let watered = plant.watered else { return 0 }
        return min(1, max(0, 1 - now.timeIntervalSince(watered) / Self.dewDuration))
    }

    // MARK: - Sky

    /// Calendar lookups are too heavy for the render path, so cache the
    /// current day's bounds and derive the hour arithmetically, refreshing
    /// only when the clock crosses out of the cached day. A plain class in
    /// @State (the sims' usual trick) so the Canvas can update it freely.
    private final class DayClock {
        private var dayStart = Date.distantPast
        private var dayEnd = Date.distantPast

        func hourOfDay(_ date: Date) -> Double {
            if date < dayStart || date >= dayEnd {
                dayStart = Calendar.current.startOfDay(for: date)
                dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)
                    ?? dayStart.addingTimeInterval(86_400)
            }
            return date.timeIntervalSince(dayStart) / 3600
        }
    }

    /// 0 = deep night, 1 = full day, with slow ramps through dawn and dusk.
    private static func daylight(at hour: Double) -> Double {
        switch hour {
        case ..<5.0: return 0
        case ..<8.0: return (hour - 5.0) / 3.0
        case ..<18.0: return 1
        case ..<21.0: return 1 - (hour - 18.0) / 3.0
        default: return 0
        }
    }

    /// Keyframed soft sky colors across the real day: muted indigo night,
    /// warm dawn/dusk bands low on the horizon, the original pastels at noon.
    private static func skyColors(at hour: Double) -> (top: Color, bottom: Color) {
        let stops: [(Double, (Double, Double, Double), (Double, Double, Double))] = [
            (0.0,  (0.10, 0.12, 0.20), (0.14, 0.15, 0.22)),
            (4.5,  (0.10, 0.12, 0.20), (0.14, 0.15, 0.22)),
            (6.5,  (0.45, 0.45, 0.62), (0.93, 0.76, 0.62)),
            (9.0,  (0.75, 0.86, 0.90), (0.90, 0.94, 0.90)),
            (16.5, (0.75, 0.86, 0.90), (0.90, 0.94, 0.90)),
            (19.5, (0.42, 0.36, 0.55), (0.92, 0.68, 0.52)),
            (21.5, (0.10, 0.12, 0.20), (0.14, 0.15, 0.22)),
            (24.0, (0.10, 0.12, 0.20), (0.14, 0.15, 0.22))
        ]
        var lower = stops[0]
        var upper = stops[stops.count - 1]
        for index in 0..<(stops.count - 1) where hour >= stops[index].0 && hour <= stops[index + 1].0 {
            lower = stops[index]
            upper = stops[index + 1]
            break
        }
        let t = (hour - lower.0) / max(0.001, upper.0 - lower.0)
        func lerp(_ a: (Double, Double, Double), _ b: (Double, Double, Double)) -> Color {
            Color(red: a.0 + (b.0 - a.0) * t,
                  green: a.1 + (b.1 - a.1) * t,
                  blue: a.2 + (b.2 - a.2) * t)
        }
        return (lerp(lower.1, upper.1), lerp(lower.2, upper.2))
    }

    private func drawSunMoon(context: GraphicsContext, size: CGSize, soilTop: CGFloat, hour: Double) {
        func arcPoint(_ progress: Double) -> CGPoint {
            CGPoint(x: CGFloat(progress) * size.width,
                    y: soilTop * 0.55 - CGFloat(sin(progress * .pi)) * soilTop * 0.38)
        }
        if hour >= 6.0 && hour <= 20.0 {
            let pos = arcPoint((hour - 6.0) / 14.0)
            context.fill(Path(ellipseIn: CGRect(x: pos.x - 16, y: pos.y - 16, width: 32, height: 32)),
                         with: .color(Color(red: 1.0, green: 0.93, blue: 0.75).opacity(0.35)))
            context.fill(Path(ellipseIn: CGRect(x: pos.x - 9, y: pos.y - 9, width: 18, height: 18)),
                         with: .color(Color(red: 1.0, green: 0.92, blue: 0.66)))
        } else {
            let nightHour = hour > 20.0 ? hour - 20.0 : hour + 4.0   // 0..10 overnight
            let pos = arcPoint(nightHour / 10.0)
            context.fill(Path(ellipseIn: CGRect(x: pos.x - 12, y: pos.y - 12, width: 24, height: 24)),
                         with: .color(.white.opacity(0.12)))
            context.fill(Path(ellipseIn: CGRect(x: pos.x - 7, y: pos.y - 7, width: 14, height: 14)),
                         with: .color(Color(red: 0.88, green: 0.89, blue: 0.94)))
        }
    }

    private func drawStars(context: GraphicsContext, size: CGSize, soilTop: CGFloat,
                           visibility: Double, phase: Double?) {
        guard visibility > 0.05 else { return }
        for star in 0..<32 {
            let x = Self.hash(7, star, 61) * Double(size.width)
            let y = Self.hash(7, star, 62) * Double(soilTop) * 0.7
            // Slow out-of-sync twinkle; steady when Reduce Motion is on.
            let twinkle = phase.map { 0.55 + 0.45 * sin($0 * 0.5 + Self.hash(7, star, 63) * .pi * 2) } ?? 0.8
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)),
                         with: .color(.white.opacity(0.7 * visibility * twinkle)))
        }
    }

    // MARK: - Plants

    private func drawMossPatch(context: GraphicsContext, base: CGPoint, seed: Int,
                               ageHours: Double, dim: Double, dew: Double) {
        let radius = min(30, 3 + ageHours.squareRoot() * 2.2)
        for blob in 0..<5 {
            let offset = (Self.hash(seed, blob, 41) - 0.5) * radius * 2
            let blobRadius = radius * (0.35 + Self.hash(seed, blob, 42) * 0.4)
            let green = (0.42 + Self.hash(seed, blob, 43) * 0.25) * dim
            context.fill(
                Path(ellipseIn: CGRect(x: base.x + offset - blobRadius,
                                       y: base.y - blobRadius * 0.4,
                                       width: blobRadius * 2,
                                       height: blobRadius * 0.8)),
                with: .color(Color(red: 0.12 * dim, green: green, blue: 0.18 * dim).opacity(0.75)))
        }
        // Fresh watering leaves a couple of dew glints on the moss, so even
        // a seedling visibly received its drink.
        if dew > 0.02 {
            for drop in 0..<2 {
                let dx = (Self.hash(seed, drop, 44) - 0.5) * radius * 1.4
                context.fill(
                    Path(ellipseIn: CGRect(x: base.x + dx - 1,
                                           y: base.y - 3 - Self.hash(seed, drop, 45) * 3,
                                           width: 2, height: 2)),
                    with: .color(Color(hue: 0.55, saturation: 0.25, brightness: 1.0).opacity(0.8 * dew)))
            }
        }
    }

    private func drawPlant(context: GraphicsContext, base: CGPoint, seed: Int,
                           ageHours: Double, dim: Double, windPhase: Double?, dew: Double) {
        // Continuous growth stage: ~1 at planting +90m, ~4 after a day,
        // ~6 after four days, flowers past ~5 days.
        let stage = min(7.6, 1 + log2(1 + ageHours / 1.5))

        if stage < 1.05 {
            // Just a seed bump
            context.fill(Path(ellipseIn: CGRect(x: base.x - 3, y: base.y - 4, width: 6, height: 5)),
                         with: .color(Color(red: 0.45 * dim, green: 0.35 * dim, blue: 0.2 * dim)))
            return
        }

        let hue = 0.28 + Self.hash(seed, 0, 1) * 0.12          // green..teal family
        let flowerHue = Self.hash(seed, 0, 2)
        let baseLength = 26.0 + Self.hash(seed, 0, 3) * 14

        drawBranch(context: context, from: base,
                   angle: -.pi / 2 + (Self.hash(seed, 0, 4) - 0.5) * 0.2,
                   depth: 1, nodeId: 0,
                   stage: stage, seed: seed, hue: hue, flowerHue: flowerHue,
                   length: baseLength, dim: dim, windPhase: windPhase, dew: dew)
    }

    private func drawBranch(context: GraphicsContext, from start: CGPoint, angle: Double,
                            depth: Int, nodeId: Int, stage: Double, seed: Int,
                            hue: Double, flowerHue: Double, length: Double,
                            dim: Double, windPhase: Double?, dew: Double) {
        guard depth <= 7 else { return }

        // Every tier (including the first stem) grows in smoothly over
        // one stage unit: growth = clamp(stage - depth, 0, 1).
        let growth = min(1.0, max(0.0, stage - Double(depth)))
        guard growth > 0.05 else { return }

        let sway = sin(Self.hash(seed, nodeId, 7) * .pi * 2) * 0.06
        // Gentle breeze: tips (deeper tiers) sway more than the rooted stem.
        let breeze = windPhase.map {
            sin($0 * 0.4 + Self.hash(seed, nodeId, 13) * .pi * 2) * 0.015 * Double(depth)
        } ?? 0
        let drawnAngle = angle + sway + breeze
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
                                          brightness: (0.42 + Double(depth) * 0.04) * dim)),
                       style: StrokeStyle(lineWidth: thickness, lineCap: .round))

        // Leaves on mid-depth nodes once the plant is established.
        // Fresh watering brightens them a touch and hangs a dew drop or two.
        if depth >= 3 && stage >= 3.6 && growth == 1 {
            let leafSize = 3.0 + Self.hash(seed, nodeId, 8) * 2.5
            context.fill(
                Path(ellipseIn: CGRect(x: end.x - leafSize / 2, y: end.y - leafSize / 2,
                                       width: leafSize, height: leafSize * 1.6)),
                with: .color(Color(hue: hue + 0.03, saturation: 0.65,
                                   brightness: min(1, 0.6 * dim + 0.12 * dew)).opacity(0.9)))
            if dew > 0.02 && Self.hash(seed, nodeId, 14) < 0.3 {
                context.fill(
                    Path(ellipseIn: CGRect(x: end.x + 1.5, y: end.y - 2, width: 2, height: 2)),
                    with: .color(Color(hue: 0.55, saturation: 0.25, brightness: 1.0).opacity(0.85 * dew)))
            }
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
                    with: .color(Color(hue: flowerHue, saturation: 0.55, brightness: 0.95 * dim)))
            }
            context.fill(Path(ellipseIn: CGRect(x: end.x - 1.4, y: end.y - 1.4, width: 2.8, height: 2.8)),
                         with: .color(.yellow.opacity(0.65 + 0.35 * dim)))
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
                       length: length * 0.74, dim: dim, windPhase: windPhase, dew: dew)
        }
    }
}

#Preview {
    MossGardenGameView()
}
