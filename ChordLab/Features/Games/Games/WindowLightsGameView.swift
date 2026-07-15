//
//  WindowLightsGameView.swift
//  ChordLab
//
//  Window Lights: a city block synced to the real clock. Every window
//  belongs to a simulated resident with a daily routine — lights come on
//  when they wake, go dark when they commute, and the block sleeps when
//  they do. Only the block's identity (seed + founding date) is stored;
//  everything drawn is a pure function of (seed, clock).
//

import SwiftUI

struct WindowLightsGameView: View {
    private struct WLBuilding {
        let x: CGFloat
        let width: CGFloat
        let height: CGFloat
        let windowCols: Int
        let windowRows: Int
        let facadeShade: Double
    }

    /// The block's persisted identity — the same skyline and the same
    /// residents greet you every visit. Restart founds a new block.
    private struct WLCitySave: Codable {
        var seed: Int
        var founded: Date
    }

    /// Timelapse speeds; rawValue is sim-seconds per real second.
    private enum WLSpeed: Int {
        case x1 = 1
        case x60 = 60
        case x1440 = 1440

        var next: WLSpeed {
            switch self {
            case .x1: return .x60
            case .x60: return .x1440
            case .x1440: return .x1
            }
        }

        var buttonTitle: String {
            switch self {
            case .x1: return "Timelapse"
            case .x60: return "60×"
            case .x1440: return "1440×"
            }
        }
    }

    /// A resident woken by a tap: their window glows warmly until `until`
    /// (sim time), then they drift back to sleep.
    private struct WLWake {
        let building: Int
        let window: Int
        let started: Date
        let until: Date
    }

    private final class WLCity {
        var buildings: [WLBuilding] = []
        var builtForWidth: CGFloat = 0
        var builtForHeight: CGFloat = 0
        var seed: Int
        var founded: Date
        /// A freshly rolled block that hasn't been stored yet. Saved from
        /// onAppear rather than init: SwiftUI may build throwaway @State
        /// instances during updates, and only the kept one should write.
        var needsSave = false

        /// Timelapse clock, advanced per-frame from clamped deltas so a
        /// backgrounded app resumes instead of leaping days ahead.
        var simTime = Date()
        var lastFrame: Date?
        /// Walk/twinkle phase clock: commuter strolls and star twinkle speed
        /// up proportionally with the timelapse multiplier, same as simTime.
        /// Accumulated per-frame (never divides absolute time by the
        /// multiplier), so cycling speeds changes the pace without
        /// teleporting dots or re-rolling twinkle.
        var walkPhase = Date().timeIntervalSinceReferenceDate

        var wakes: [WLWake] = []

        /// Frame-accumulated stats, mirrored to @State by a slow ticker.
        var statLit = 0
        var statTotal = 0

        init() {
            if let saved = SimPersist.load(WLCitySave.self, key: WindowLightsGameView.storageKey) {
                seed = saved.seed
                founded = saved.founded
            } else {
                seed = Int.random(in: 0..<100_000)
                founded = Date()
                needsSave = true
            }
        }

        func buildIfNeeded(width: CGFloat, height: CGFloat) {
            guard width > 60, height > 80 else { return }
            guard abs(width - builtForWidth) > 1 || abs(height - builtForHeight) > 1 else { return }
            builtForWidth = width
            builtForHeight = height
            buildings = []
            wakes = []   // window indices don't survive a relayout
            // Shrink the skyline on short canvases (landscape, large text)
            // so the tallest buildings don't clip flat against the top.
            let heightScale = min(1.0, (height - 40) / 246)
            var cursor: CGFloat = 6
            var index = 0
            while cursor < width - 50 {
                let bWidth = CGFloat(WindowLightsGameView.hash(seed, index, 1) * 34 + 42)
                let bHeight = CGFloat(WindowLightsGameView.hash(seed, index, 2) * 150 + 96) * heightScale
                let cols = 2 + Int(WindowLightsGameView.hash(seed, index, 3) * 2.99)
                let rows = max(3, Int(bHeight / 26))
                buildings.append(WLBuilding(x: cursor, width: bWidth, height: bHeight,
                                            windowCols: cols, windowRows: rows,
                                            facadeShade: 0.10 + WindowLightsGameView.hash(seed, index, 4) * 0.08))
                cursor += bWidth + CGFloat(WindowLightsGameView.hash(seed, index, 5) * 10 + 4)
                index += 1
            }
        }
    }

    private static let storageKey = "watch.windowlights.city"

    /// Real seconds a tap-wake glows at x1; sim durations scale with the
    /// multiplier so the glow lasts the same real time at every speed.
    private static let wakeDuration = 150.0

    @State private var city = WLCity()
    @State private var speed = WLSpeed.x1
    /// Bumped on restart so the new skyline appears immediately
    /// instead of at the next 1Hz timeline tick.
    @State private var blockStamp = 0

    // Stats mirrored from the plain class off the render path.
    @State private var statAwake = "—"
    @State private var statSunLabel = "Sunset"
    @State private var statSunTime = "—"
    @State private var statWeekend = false
    @State private var statA11y = "A quiet city block."
    /// Commuter dots (and freshly woken windows) are the only fast-moving
    /// elements; run smooth frames only while they're on screen and idle
    /// at 1 Hz the rest of the time.
    @State private var wantsSmoothFrames = false

    private let statsTicker = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "windowlights")!,
                   onRestart: { newBlock() },
                   confirmRestart: true) {
            VStack(spacing: 10) {
                TimelineView(.animation(minimumInterval: frameInterval)) { timeline in
                    let simDate = headerSimDate(realNow: timeline.date)

                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            StatPill(label: "City time",
                                     value: clockText(simDate),
                                     tint: .indigo)

                            Button {
                                GameHaptics.tap()
                                cycleSpeed()
                            } label: {
                                Label(speed.buttonTitle, systemImage: "forward.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(speed == .x1 ? Color.secondary : Color.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(speed == .x1 ? Color.appSecondaryBackground : Color.indigo,
                                                in: Capsule())
                            }
                        }

                        HStack(spacing: 10) {
                            StatPill(label: "Awake", value: statAwake, tint: .yellow)
                            StatPill(label: statSunLabel, value: statSunTime, tint: .orange)
                            if statWeekend {
                                StatPill(label: "Day", value: "Weekend", tint: .mint)
                            }
                        }

                        GeometryReader { geo in
                            Canvas { context, size in
                                city.buildIfNeeded(width: size.width, height: size.height)
                                drawScene(context: context, size: size,
                                          date: advanceSimClock(realNow: timeline.date))
                            }
                            .id(blockStamp)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onTapGesture(coordinateSpace: .local) { location in
                                wakeResident(at: location, canvasSize: geo.size)
                            }
                            .accessibilityLabel(statA11y)
                            .accessibilityAddTraits(.updatesFrequently)
                        }
                        .padding(.horizontal, 12)
                    }
                }

                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 8)
            }
            .padding(.top, 4)
            .onAppear {
                if city.needsSave {
                    city.needsSave = false
                    SimPersist.save(WLCitySave(seed: city.seed, founded: city.founded),
                                    key: Self.storageKey)
                }
                refreshStats()
            }
            .onReceive(statsTicker) { _ in
                refreshStats()
            }
        }
    }

    private var caption: String {
        switch speed {
        case .x1: return "This block lives on your clock. Tap a window to wake someone."
        case .x60: return "One minute here is an hour there."
        case .x1440: return "One minute here is 24 hours there."
        }
    }

    private var frameInterval: Double {
        speed != .x1 || wantsSmoothFrames ? 1.0 / 30.0 : 1.0
    }

    // MARK: - Time

    /// Read-only sim clock for the chrome; the Canvas advances the real one.
    private func headerSimDate(realNow: Date) -> Date {
        speed == .x1 ? realNow : city.simTime
    }

    /// Advance the timelapse clock by a clamped per-frame delta (never raw
    /// wall-clock deltas, which would leap days across a suspension).
    private func advanceSimClock(realNow: Date) -> Date {
        // The looser cap covers the 1 Hz idle frame gap. Both clocks
        // accumulate from the same clamped dt scaled by the multiplier, so
        // walk/twinkle pace speeds up right along with the sim clock while
        // staying continuous across speed changes (no divisor jump).
        let dt = SimClock.dt(since: city.lastFrame, to: realNow, cap: 1.5)
        city.lastFrame = realNow
        city.walkPhase += min(dt, 0.5) * Double(speed.rawValue)
        guard speed != .x1 else { return realNow }
        city.simTime.addTimeInterval(min(dt, 0.5) * Double(speed.rawValue))
        return city.simTime
    }

    private func cycleSpeed() {
        let next = speed.next
        if speed == .x1 {
            // Entering timelapse: race ahead from the present moment.
            let now = Date()
            reanchorWakes(oldNow: now, newNow: now, to: next)
            city.simTime = now
            city.lastFrame = nil
        } else if next == .x1 {
            // Back to the real clock: surviving glows finish out on a
            // wall-clock envelope so a sim-inflated `until` can't outlive
            // the timelapse.
            reanchorWakes(oldNow: city.simTime, newNow: Date(), to: next)
        } else {
            // Faster timelapse: the sim clock carries over; rescale glows.
            reanchorWakes(oldNow: city.simTime, newNow: city.simTime, to: next)
        }
        speed = next
    }

    /// Re-stamp surviving wakes into the clock domain of `newSpeed`,
    /// preserving each glow's fade progress: a woken resident always lives
    /// out the remaining fraction of ~150 real seconds, however fast the
    /// clock is racing. Wakes the outgoing clock had already passed are
    /// dropped, so no wake ever outlives the new domain's envelope (a
    /// sim-inflated `until` would otherwise pin smooth frames — and the
    /// awake screen — for hours of real time after leaving timelapse).
    private func reanchorWakes(oldNow: Date, newNow: Date, to newSpeed: WLSpeed) {
        let duration = Self.wakeDuration * Double(newSpeed.rawValue)
        city.wakes = city.wakes.compactMap { wake in
            let total = wake.until.timeIntervalSince(wake.started)
            guard total > 0 else { return nil }
            let remaining = min(1, wake.until.timeIntervalSince(oldNow) / total)
            guard remaining > 0 else { return nil }
            return WLWake(building: wake.building, window: wake.window,
                          started: newNow.addingTimeInterval(-(1 - remaining) * duration),
                          until: newNow.addingTimeInterval(remaining * duration))
        }
    }

    /// Weekday + time in the user's 12/24-hour style; timelapse swaps the
    /// weekday for the date so racing days stay legible.
    private func clockText(_ date: Date) -> String {
        speed == .x1
            ? date.formatted(.dateTime.weekday(.abbreviated).hour().minute())
            : date.formatted(.dateTime.day().month(.abbreviated).hour().minute())
    }

    private func hourOfDay(_ date: Date) -> Double {
        let parts = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        return Double(parts.hour ?? 0) + Double(parts.minute ?? 0) / 60 + Double(parts.second ?? 0) / 3600
    }

    private func isWeekend(_ date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }

    /// Local-calendar day ordinal, so per-day schedule jitter rolls over
    /// at local midnight (UTC-based math would re-roll every window at a
    /// fixed local afternoon hour).
    private func dayNumber(_ date: Date) -> Int {
        Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
    }

    /// Deterministic 0..<1 hash — every window's routine is a pure
    /// function of (seed, building, window, day), so only the block's
    /// seed needs storing.
    private static func hash(_ values: Int...) -> Double {
        var h: UInt64 = 0x9E37_79B9_7F4A_7C15
        for value in values {
            h ^= UInt64(bitPattern: Int64(value)) &* 0xBF58_476D_1CE4_E5B9
            h = (h ^ (h >> 27)) &* 0x94D0_49BB_1331_11EB
            h ^= h >> 31
        }
        return Double(h % 1_000_000) / 1_000_000
    }

    // MARK: - Resident routine

    private struct WLClock {
        let hour: Double
        let day: Int
        let weekend: Bool
        let yesterdayWeekend: Bool
    }

    private func windowLit(building: Int, window: Int, clock: WLClock) -> Bool {
        let hour = clock.hour
        let day = clock.day
        let seed = city.seed

        let wakeBase = 5.8 + Self.hash(seed, building, window, 1) * 2.8
        let wake = wakeBase + (Self.hash(seed, building, window, day) - 0.5) * 0.8
        let sleepBase = 21.0 + Self.hash(seed, building, window, 4) * 3.2
        let sleep = sleepBase + (Self.hash(seed, building, window, day + 3) - 0.5) * 0.8

        let stayingHome = clock.weekend && Self.hash(seed, building, window, day + 13) < 0.45

        let awakeAtHome: Bool
        if stayingHome {
            awakeAtHome = hour >= wake + 1.2 && hour < sleep + 0.6
        } else {
            let leave = wake + 1.0 + Self.hash(seed, building, window, 2) * 0.9
            let comeHome = 16.2 + Self.hash(seed, building, window, 3) * 3.4
                + (Self.hash(seed, building, window, day + 7) - 0.5) * 0.9
            awakeAtHome = (hour >= wake && hour < leave) || (hour >= comeHome && hour < sleep)
        }
        if awakeAtHome { return true }

        // Night owls whose bedtime slips past midnight: evaluate against
        // YESTERDAY's schedule so the light doesn't snap off at 00:00.
        let ySleep = sleepBase + (Self.hash(seed, building, window, day - 1 + 3) - 0.5) * 0.8
        let yStayingHome = clock.yesterdayWeekend
            && Self.hash(seed, building, window, day - 1 + 13) < 0.45
        let yCutoff = ySleep + (yStayingHome ? 0.6 : 0)
        if yCutoff > 24 && hour < yCutoff - 24 { return true }

        // The occasional 3am kitchen light (5-minute slots)
        let slot = Int(hour * 12)
        return Self.hash(seed, building, window, day * 300 + slot) < 0.005
    }

    // MARK: - Tap to wake

    private func wakeResident(at point: CGPoint, canvasSize: CGSize) {
        let groundY = canvasSize.height - 26
        for (bIndex, building) in city.buildings.enumerated() {
            let top = groundY - building.height
            guard point.x >= building.x, point.x <= building.x + building.width,
                  point.y >= top, point.y <= groundY else { continue }

            // Same cell math as drawScene, inverted.
            let insetX: CGFloat = 6
            let insetY: CGFloat = 8
            let cellWidth = (building.width - insetX * 2) / CGFloat(building.windowCols)
            let cellHeight = (building.height - insetY * 2) / CGFloat(building.windowRows)
            let col = Int((point.x - building.x - insetX) / cellWidth)
            let row = Int((point.y - top - insetY) / cellHeight)
            guard (0..<building.windowCols).contains(col),
                  (0..<building.windowRows).contains(row) else { return }

            GameHaptics.tap()
            let window = row * building.windowCols + col
            let now = speed == .x1 ? Date() : city.simTime
            // Sim duration scales with the multiplier so the glow lasts a
            // couple of real minutes however fast the clock is racing.
            let duration = Self.wakeDuration * Double(speed.rawValue)
            city.wakes.removeAll { $0.until <= now || ($0.building == bIndex && $0.window == window) }
            city.wakes.append(WLWake(building: bIndex, window: window,
                                     started: now, until: now.addingTimeInterval(duration)))
            wantsSmoothFrames = true   // render the fade smoothly right away
            return
        }
    }

    /// Active tap-wake glows for this frame, keyed by building*1000+window.
    private func wakeGlows(simNow: Date) -> [Int: Double] {
        city.wakes.removeAll { simNow >= $0.until }
        var glows: [Int: Double] = [:]
        for wake in city.wakes {
            let total = wake.until.timeIntervalSince(wake.started)
            let elapsed = simNow.timeIntervalSince(wake.started)
            guard total > 0, elapsed >= 0 else { continue }
            // Quick fade-in, slow fade-out — they wake, putter about,
            // then drift back to sleep.
            let fadeIn = min(1, elapsed / (total * 0.05))
            let fadeOut = min(1, (total - elapsed) / (total * 0.3))
            glows[wake.building * 1000 + wake.window] = max(0, min(fadeIn, fadeOut))
        }
        return glows
    }

    // MARK: - Stats

    private func refreshStats() {
        let simNow = speed == .x1 ? Date() : city.simTime
        statAwake = city.statTotal > 0 ? "\(city.statLit)/\(city.statTotal)" : "—"
        statWeekend = isWeekend(simNow)

        let sun = nextSunEvent(after: simNow)
        statSunLabel = sun.label
        statSunTime = sun.time

        wantsSmoothFrames = commuterIntensity(hour: hourOfDay(simNow)) * 13 >= 1
            || !city.wakes.isEmpty

        let timeText = simNow.formatted(.dateTime.hour().minute())
        statA11y = city.statTotal > 0
            ? "City block at \(timeText). \(city.statLit) of \(city.statTotal) windows lit."
            : "City block at \(timeText)."
    }

    /// Sunrise/sunset are the sim's fixed sky keyframes (6:00 / 19:48).
    private func nextSunEvent(after date: Date) -> (label: String, time: String) {
        let hour = hourOfDay(date)
        let sunset = 19.8
        let isSunrise = hour < 6.0 || hour >= sunset
        let target = isSunrise ? 6.0 : sunset
        var day = date
        if hour >= sunset {   // tonight's sun already set — sunrise is tomorrow
            day = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
        }
        let event = Calendar.current.date(bySettingHour: Int(target),
                                          minute: Int((target * 60).truncatingRemainder(dividingBy: 60)),
                                          second: 0, of: day) ?? day
        return (isSunrise ? "Sunrise" : "Sunset",
                event.formatted(.dateTime.hour().minute()))
    }

    // MARK: - Drawing

    private func drawScene(context: GraphicsContext, size: CGSize, date: Date) {
        // Calendar work hoisted once per frame — windowLit runs per window.
        let clock = WLClock(hour: hourOfDay(date),
                            day: dayNumber(date),
                            weekend: isWeekend(date),
                            yesterdayWeekend: isWeekend(date.addingTimeInterval(-86_400)))
        let hour = clock.hour
        let darkness = nightDarkness(hour: hour)
        drawSky(context: context, size: size, hour: hour)
        drawSunMoon(context: context, size: size, hour: hour)
        drawStars(context: context, size: size, darkness: darkness)

        let groundY = size.height - 26
        let glows = wakeGlows(simNow: date)
        var litCount = 0
        var windowCount = 0

        // Buildings
        for (bIndex, building) in city.buildings.enumerated() {
            let top = groundY - building.height
            let facade = CGRect(x: building.x, y: top, width: building.width, height: building.height)
            context.fill(Path(facade), with: .color(Color(white: building.facadeShade)))

            let insetX: CGFloat = 6
            let insetY: CGFloat = 8
            let cellWidth = (building.width - insetX * 2) / CGFloat(building.windowCols)
            let cellHeight = (building.height - insetY * 2) / CGFloat(building.windowRows)

            for row in 0..<building.windowRows {
                for col in 0..<building.windowCols {
                    let windowIndex = row * building.windowCols + col
                    windowCount += 1
                    let lit = windowLit(building: bIndex, window: windowIndex, clock: clock)
                    let wake = glows[bIndex * 1000 + windowIndex]
                    let rect = CGRect(
                        x: building.x + insetX + CGFloat(col) * cellWidth + cellWidth * 0.18,
                        y: top + insetY + CGFloat(row) * cellHeight + cellHeight * 0.2,
                        width: cellWidth * 0.64,
                        height: cellHeight * 0.6
                    )
                    if lit || wake != nil {
                        litCount += 1
                        let warmth = Self.hash(city.seed, bIndex, windowIndex, 9)
                        let warm = Color(red: 1.0,
                                         green: 0.82 - warmth * 0.12,
                                         blue: 0.45 + warmth * 0.15)
                        let alpha = lit ? 1.0 : (wake ?? 0)
                        // Night bloom: a soft halo behind each lit window.
                        if darkness > 0.05 {
                            context.fill(Path(roundedRect: rect.insetBy(dx: -3.5, dy: -3.5),
                                              cornerRadius: 4),
                                         with: .color(warm.opacity(0.16 * darkness * alpha)))
                        }
                        context.fill(Path(rect), with: .color(Color(white: 0.05)))
                        context.fill(Path(rect), with: .color(warm.opacity(alpha)))
                    } else {
                        context.fill(Path(rect), with: .color(Color(white: 0.05)))
                    }
                }
            }
        }

        city.statLit = litCount
        city.statTotal = windowCount

        // Street + commuters
        context.fill(Path(CGRect(x: 0, y: groundY, width: size.width, height: 26)),
                     with: .color(Color(white: 0.12)))
        drawStreetLamps(context: context, size: size, groundY: groundY, darkness: darkness)
        drawCommuters(context: context, size: size, date: date, roadY: groundY + 13)
    }

    private func drawSky(context: GraphicsContext, size: CGSize, hour: Double) {
        // Keyframed sky colors across the day.
        let stops: [(Double, (Double, Double, Double))] = [
            (0.0, (0.02, 0.03, 0.10)), (5.0, (0.02, 0.03, 0.10)),
            (6.5, (0.55, 0.35, 0.45)), (8.0, (0.45, 0.65, 0.90)),
            (13.0, (0.40, 0.66, 0.95)), (17.5, (0.50, 0.60, 0.85)),
            (19.3, (0.90, 0.45, 0.30)), (20.8, (0.15, 0.10, 0.30)),
            (22.0, (0.02, 0.03, 0.10)), (24.0, (0.02, 0.03, 0.10))
        ]
        var lower = stops[0]
        var upper = stops[stops.count - 1]
        for index in 0..<(stops.count - 1) where hour >= stops[index].0 && hour <= stops[index + 1].0 {
            lower = stops[index]
            upper = stops[index + 1]
            break
        }
        let span = max(0.001, upper.0 - lower.0)
        let t = (hour - lower.0) / span
        let rgb = (lower.1.0 + (upper.1.0 - lower.1.0) * t,
                   lower.1.1 + (upper.1.1 - lower.1.1) * t,
                   lower.1.2 + (upper.1.2 - lower.1.2) * t)
        context.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .color(Color(red: rgb.0, green: rgb.1, blue: rgb.2)))
    }

    private func drawSunMoon(context: GraphicsContext, size: CGSize, hour: Double) {
        func arcPosition(progress: Double) -> CGPoint {
            let x = CGFloat(progress) * size.width
            let y = size.height * 0.42 - sin(progress * .pi) * size.height * 0.3
            return CGPoint(x: x, y: y)
        }

        if hour >= 6.0 && hour <= 19.8 {
            let pos = arcPosition(progress: (hour - 6.0) / 13.8)
            context.fill(Path(ellipseIn: CGRect(x: pos.x - 12, y: pos.y - 12, width: 24, height: 24)),
                         with: .color(Color(red: 1.0, green: 0.9, blue: 0.55)))
        } else {
            let nightHour = hour > 19.8 ? hour - 19.8 : hour + 4.2   // 0..~10.2 overnight
            let pos = arcPosition(progress: nightHour / 10.2)
            context.fill(Path(ellipseIn: CGRect(x: pos.x - 9, y: pos.y - 9, width: 18, height: 18)),
                         with: .color(Color(white: 0.85)))
        }
    }

    /// 0 in daylight, ramping to 1 through dusk (19.5–21.5) and dawn (5–7).
    private func nightDarkness(hour: Double) -> Double {
        if hour < 5 { return 1 }
        if hour < 7 { return max(0, (7 - hour) / 2) }
        if hour < 19.5 { return 0 }
        if hour < 21.5 { return (hour - 19.5) / 2 }
        return 1
    }

    private func drawStars(context: GraphicsContext, size: CGSize, darkness: Double) {
        guard darkness > 0.05 else { return }

        // Twinkle phase rides the frame-accumulated walk clock: speeds up
        // with the timelapse multiplier, and continuous across speed
        // changes instead of re-rolling every star when the multiplier flips.
        let slotBase = city.walkPhase / 4
        for star in 0..<56 {
            let x = Self.hash(city.seed, star, 21) * Double(size.width)
            let y = Self.hash(city.seed, star, 22) * Double(size.height) * 0.55
            // Per-star phase offset so they twinkle out of sync.
            let slot = Int(slotBase + Self.hash(city.seed, star, 23) * 900)
            let twinkle = 0.4 + Self.hash(city.seed, star, slot) * 0.6
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.6, height: 1.6)),
                         with: .color(.white.opacity(darkness * twinkle * 0.8)))
        }
    }

    private func drawStreetLamps(context: GraphicsContext, size: CGSize,
                                 groundY: CGFloat, darkness: Double) {
        for lamp in 0..<4 {
            let x = size.width * (0.14 + 0.72 * CGFloat(lamp) / 3)
                + CGFloat((Self.hash(city.seed, lamp, 51) - 0.5) * 14)
            let headY = groundY - 17
            var pole = Path()
            pole.move(to: CGPoint(x: x, y: groundY))
            pole.addLine(to: CGPoint(x: x, y: headY))
            context.stroke(pole, with: .color(Color(white: 0.22)), lineWidth: 1.5)

            if darkness > 0.05 {
                let warm = Color(red: 1.0, green: 0.85, blue: 0.55)
                // Soft bloom around the head plus a faint pool on the pavement.
                context.fill(Path(ellipseIn: CGRect(x: x - 7, y: headY - 7, width: 14, height: 14)),
                             with: .color(warm.opacity(0.22 * darkness)))
                context.fill(Path(ellipseIn: CGRect(x: x - 11, y: groundY - 3, width: 22, height: 6)),
                             with: .color(warm.opacity(0.10 * darkness)))
                context.fill(Path(ellipseIn: CGRect(x: x - 2, y: headY - 2, width: 4, height: 4)),
                             with: .color(warm))
            } else {
                context.fill(Path(ellipseIn: CGRect(x: x - 2, y: headY - 2, width: 4, height: 4)),
                             with: .color(Color(white: 0.3)))
            }
        }
    }

    /// Street traffic 0..1 — rush-hour bell curves at 8:00 and 17:30, plus a
    /// late crowd measured in circular hour distance so the last stragglers
    /// walk out across midnight instead of vanishing at 00:00.
    private func commuterIntensity(hour: Double) -> Double {
        let morning = exp(-pow(hour - 8.0, 2) / 1.4)
        let evening = exp(-pow(hour - 17.5, 2) / 2.0)
        let lateDistance = min(abs(hour - 22.5), 24 - abs(hour - 22.5))
        let late = exp(-pow(lateDistance, 2) / 4.0) * 0.25
        return min(1.0, morning + evening + late)
    }

    private func drawCommuters(context: GraphicsContext, size: CGSize, date: Date, roadY: CGFloat) {
        let count = Int(commuterIntensity(hour: hourOfDay(date)) * 13)
        guard count > 0 else { return }

        // Walk phase is the frame-accumulated clock: dots stroll faster in
        // proportion to the timelapse multiplier and never teleport when
        // the multiplier changes (dt is clamped, so a single frame can't
        // wrap the screen many times even at 1440x).
        let seconds = city.walkPhase
        for k in 0..<count {
            let speed = 22.0 + Self.hash(city.seed, k, 31) * 26
            let offset = Self.hash(city.seed, k, 32) * Double(size.width)
            let travel = (seconds * speed + offset)
                .truncatingRemainder(dividingBy: Double(size.width + 16))
            let x = k.isMultiple(of: 2) ? CGFloat(travel) - 8 : size.width + 8 - CGFloat(travel)
            let shade = 0.5 + Self.hash(city.seed, k, 33) * 0.4
            context.fill(Path(ellipseIn: CGRect(x: x, y: roadY - 2 + CGFloat(k % 3) * 2 - 2,
                                                width: 5, height: 4)),
                         with: .color(Color(white: shade)))
        }
    }

    private func newBlock() {
        city.seed = Int.random(in: 0..<100_000)
        city.founded = Date()
        city.needsSave = false
        SimPersist.save(WLCitySave(seed: city.seed, founded: city.founded), key: Self.storageKey)
        city.wakes = []
        city.builtForWidth = 0   // force a rebuild on the next frame
        blockStamp += 1          // ...and make that frame happen now
        speed = .x1
        refreshStats()
    }
}

#Preview {
    WindowLightsGameView()
}
