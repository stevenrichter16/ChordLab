//
//  WindowLightsGameView.swift
//  ChordLab
//
//  Window Lights: a city block synced to the real clock. Every window
//  belongs to a simulated resident with a daily routine — lights come on
//  when they wake, go dark when they commute, and the block sleeps when
//  they do. Entirely a pure function of time: nothing is stored.
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

    private final class WLCity {
        var buildings: [WLBuilding] = []
        var builtForWidth: CGFloat = 0
        var seed: Int = Int.random(in: 0..<100_000)

        func buildIfNeeded(width: CGFloat) {
            guard width > 60, abs(width - builtForWidth) > 1 else { return }
            builtForWidth = width
            buildings = []
            var cursor: CGFloat = 6
            var index = 0
            while cursor < width - 50 {
                let bWidth = CGFloat(WindowLightsGameView.hash(seed, index, 1) * 34 + 42)
                let bHeight = CGFloat(WindowLightsGameView.hash(seed, index, 2) * 150 + 96)
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

    @State private var city = WLCity()
    @State private var timelapse = false
    @State private var timelapseAnchor = Date()
    /// Bumped on restart so the new skyline appears immediately
    /// instead of at the next 1Hz timeline tick.
    @State private var blockStamp = 0

    private static let clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE HH:mm"
        return formatter
    }()

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "windowlights")!, onRestart: { newBlock() }) {
            VStack(spacing: 10) {
                TimelineView(.animation(minimumInterval: timelapse ? 1.0 / 30.0 : 1.0)) { timeline in
                    let simDate = currentSimDate(realNow: timeline.date)

                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            StatPill(label: "City time",
                                     value: Self.clockFormatter.string(from: simDate),
                                     tint: .indigo)

                            Button {
                                GameHaptics.tap()
                                timelapseAnchor = Date()
                                timelapse.toggle()
                            } label: {
                                Label(timelapse ? "Real time" : "Timelapse",
                                      systemImage: timelapse ? "clock.fill" : "forward.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(timelapse ? .white : .secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(timelapse ? Color.indigo : Color.appSecondaryBackground,
                                                in: Capsule())
                            }
                        }

                        Canvas { context, size in
                            city.buildIfNeeded(width: size.width)
                            drawScene(context: context, size: size, date: simDate)
                        }
                        .id(blockStamp)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 12)
                    }
                }

                Text(timelapse ? "One minute here is 24 hours there."
                               : "This block lives on your clock. Visit at night.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 8)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Time

    private func currentSimDate(realNow: Date) -> Date {
        guard timelapse else { return realNow }
        let elapsed = realNow.timeIntervalSince(timelapseAnchor)
        return timelapseAnchor.addingTimeInterval(elapsed * 1440)   // 24h per minute
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
    /// function of (building, window, day), so nothing needs storing.
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

    // MARK: - Drawing

    private func drawScene(context: GraphicsContext, size: CGSize, date: Date) {
        // Calendar work hoisted once per frame — windowLit runs per window.
        let clock = WLClock(hour: hourOfDay(date),
                            day: dayNumber(date),
                            weekend: isWeekend(date),
                            yesterdayWeekend: isWeekend(date.addingTimeInterval(-86_400)))
        let hour = clock.hour
        drawSky(context: context, size: size, hour: hour)
        drawSunMoon(context: context, size: size, hour: hour)
        drawStars(context: context, size: size, hour: hour)

        let groundY = size.height - 26

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
                    let lit = windowLit(building: bIndex, window: windowIndex, clock: clock)
                    let rect = CGRect(
                        x: building.x + insetX + CGFloat(col) * cellWidth + cellWidth * 0.18,
                        y: top + insetY + CGFloat(row) * cellHeight + cellHeight * 0.2,
                        width: cellWidth * 0.64,
                        height: cellHeight * 0.6
                    )
                    if lit {
                        let warmth = Self.hash(city.seed, bIndex, windowIndex, 9)
                        context.fill(Path(rect),
                                     with: .color(Color(red: 1.0,
                                                        green: 0.82 - warmth * 0.12,
                                                        blue: 0.45 + warmth * 0.15)))
                    } else {
                        context.fill(Path(rect), with: .color(Color(white: 0.05)))
                    }
                }
            }
        }

        // Street + commuters
        context.fill(Path(CGRect(x: 0, y: groundY, width: size.width, height: 26)),
                     with: .color(Color(white: 0.12)))
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

    private func drawStars(context: GraphicsContext, size: CGSize, hour: Double) {
        let darkness: Double
        if hour < 5 { darkness = 1 }
        else if hour < 7 { darkness = max(0, (7 - hour) / 2) }
        else if hour < 19.5 { darkness = 0 }
        else if hour < 21.5 { darkness = (hour - 19.5) / 2 }
        else { darkness = 1 }
        guard darkness > 0.05 else { return }

        for star in 0..<56 {
            let x = Self.hash(city.seed, star, 21) * Double(size.width)
            let y = Self.hash(city.seed, star, 22) * Double(size.height) * 0.55
            // Per-star phase offset so they twinkle out of sync.
            let twinkle = 0.4 + Self.hash(city.seed, star, Int((hour + Self.hash(city.seed, star, 23)) * 900)) * 0.6
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.6, height: 1.6)),
                         with: .color(.white.opacity(darkness * twinkle * 0.8)))
        }
    }

    private func drawCommuters(context: GraphicsContext, size: CGSize, date: Date, roadY: CGFloat) {
        let hour = hourOfDay(date)
        // Rush-hour bell curves at 8:00 and 17:30.
        let morning = exp(-pow(hour - 8.0, 2) / 1.4)
        let evening = exp(-pow(hour - 17.5, 2) / 2.0)
        let late = exp(-pow(hour - 22.5, 2) / 4.0) * 0.25
        let intensity = min(1.0, morning + evening + late)
        let count = Int(intensity * 13)
        guard count > 0 else { return }

        let seconds = date.timeIntervalSinceReferenceDate
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
        city.builtForWidth = 0   // force a rebuild on the next frame
        blockStamp += 1          // ...and make that frame happen now
        timelapse = false
    }
}

#Preview {
    WindowLightsGameView()
}
