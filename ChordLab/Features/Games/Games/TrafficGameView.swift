//
//  TrafficGameView.swift
//  ChordLab
//
//  Traffic Tycoon: one intersection, one light, four growing queues.
//  Tap to switch the light (with an all-red clearance phase) and keep
//  traffic flowing. Nine cars stuck in any lane is gridlock.
//

import SwiftUI

struct TrafficGameView: View {
    private enum Approach: Int, CaseIterable {
        case north   // enters at top, drives down
        case south   // enters at bottom, drives up
        case east    // enters at right, drives left
        case west    // enters at left, drives right

        var isVertical: Bool { self == .north || self == .south }
    }

    private struct TrafficCar: Identifiable {
        let id = UUID()
        /// Distance traveled from the entry edge, in points.
        var progress: CGFloat
        let hue: Double
    }

    private enum LightState {
        case nsGreen
        case ewGreen
        case clearing(next: Bool)   // all red; true = NS green next

        var nsGreen: Bool {
            if case .nsGreen = self { return true }
            return false
        }

        var ewGreen: Bool {
            if case .ewGreen = self { return true }
            return false
        }
    }

    private enum TrafficPhase {
        case ready
        case playing
        case gameOver
    }

    private static let roadWidth: CGFloat = 74
    private static let carLength: CGFloat = 26
    private static let carWidth: CGFloat = 15
    private static let carSpeed: CGFloat = 90
    private static let gridlockLimit = 9

    @State private var phase: TrafficPhase = .ready
    @State private var light = LightState.nsGreen
    @State private var clearingTimeLeft: Double = 0
    @State private var cars: [Approach.RawValue: [TrafficCar]] = [:]
    @State private var spawnCountdown: [Approach.RawValue: Double] = [:]
    @State private var score = 0
    @State private var elapsed: Double = 0
    @State private var boardSize = CGSize.zero
    @State private var isNewRecord = false
    @State private var gridlockedApproach: Approach? = nil

    private let ticker = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "traffic")!, onRestart: { newGame() }) {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    StatPill(label: "Through", value: "\(score)", tint: .indigo)
                    StatPill(label: "Best", value: "\(GameScores.shared.best(for: "traffic") ?? 0)")
                    StatPill(label: "Waiting", value: "\(maxQueueLength)",
                             tint: maxQueueLength >= Self.gridlockLimit - 2 ? .red : .appPrimary)
                }

                GeometryReader { geo in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.12))
                            .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 12))

                        roadLayer(size: geo.size)
                        lightLayer(size: geo.size)
                        carLayer(size: geo.size)

                        if phase == .ready {
                            VStack(spacing: 8) {
                                Text("Tap anywhere to switch the light.\nDon't let any queue reach \(Self.gridlockLimit).")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                                ArcadeButton(title: "Open the Roads", systemImage: "play.fill", tint: .indigo) {
                                    startGame()
                                }
                                .frame(width: 200)
                            }
                            .padding(12)
                            .background(Color.appBackground.opacity(0.92), in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        switchLight()
                    }
                    .onAppear {
                        boardSize = geo.size
                    }
                    .onChange(of: geo.size) { _, newSize in
                        boardSize = newSize
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
            .padding(.top, 4)
            .overlay {
                if phase == .gameOver {
                    GameOverOverlay(
                        title: "Gridlock! 🚨",
                        subtitle: "\(score) cars made it through before the \(approachName(gridlockedApproach)) queue jammed.",
                        isVictory: false,
                        newRecord: isNewRecord,
                        buttonTitle: "Try Again"
                    ) {
                        newGame()
                    }
                }
            }
            .onReceive(ticker) { _ in
                guard phase == .playing, boardSize != .zero else { return }
                tick(dt: 1.0 / 60.0)
            }
        }
    }

    private var maxQueueLength: Int {
        Approach.allCases.map { waitingCount(for: $0) }.max() ?? 0
    }

    private func approachName(_ approach: Approach?) -> String {
        switch approach {
        case .north: return "northern"
        case .south: return "southern"
        case .east: return "eastern"
        case .west: return "western"
        case nil: return ""
        }
    }

    // MARK: - Rendering

    private func roadLayer(size: CGSize) -> some View {
        ZStack {
            // Vertical + horizontal roads
            Rectangle()
                .fill(Color.gray.opacity(0.45))
                .frame(width: Self.roadWidth, height: size.height)
                .position(x: size.width / 2, y: size.height / 2)
            Rectangle()
                .fill(Color.gray.opacity(0.45))
                .frame(width: size.width, height: Self.roadWidth)
                .position(x: size.width / 2, y: size.height / 2)

            // Center lane dashes
            Path { path in
                path.move(to: CGPoint(x: size.width / 2, y: 0))
                path.addLine(to: CGPoint(x: size.width / 2, y: size.height))
                path.move(to: CGPoint(x: 0, y: size.height / 2))
                path.addLine(to: CGPoint(x: size.width, y: size.height / 2))
            }
            .stroke(style: StrokeStyle(lineWidth: 2, dash: [7, 9]))
            .foregroundStyle(Color.yellow.opacity(0.4))
        }
    }

    private func lightLayer(size: CGSize) -> some View {
        let offset = Self.roadWidth / 2 + 14
        return ZStack {
            lightDot(isGreen: light.nsGreen)
                .position(x: size.width / 2 - offset, y: size.height / 2 - offset)
            lightDot(isGreen: light.nsGreen)
                .position(x: size.width / 2 + offset, y: size.height / 2 + offset)
            lightDot(isGreen: light.ewGreen)
                .position(x: size.width / 2 + offset, y: size.height / 2 - offset)
            lightDot(isGreen: light.ewGreen)
                .position(x: size.width / 2 - offset, y: size.height / 2 + offset)
        }
    }

    private func lightDot(isGreen: Bool) -> some View {
        Circle()
            .fill(isGreen ? Color.green : Color.red)
            .frame(width: 13, height: 13)
            .overlay(Circle().strokeBorder(Color.black.opacity(0.3), lineWidth: 1))
            .shadow(color: (isGreen ? Color.green : Color.red).opacity(0.7), radius: 4)
    }

    private func carLayer(size: CGSize) -> some View {
        ForEach(Approach.allCases, id: \.rawValue) { approach in
            ForEach(cars[approach.rawValue] ?? []) { car in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hue: car.hue, saturation: 0.65, brightness: 0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color.black.opacity(0.25), lineWidth: 1)
                    )
                    .frame(width: approach.isVertical ? Self.carWidth : Self.carLength,
                           height: approach.isVertical ? Self.carLength : Self.carWidth)
                    .position(carPosition(car, approach: approach, size: size))
            }
        }
    }

    private func carPosition(_ car: TrafficCar, approach: Approach, size: CGSize) -> CGPoint {
        let laneOffset = Self.roadWidth / 4
        switch approach {
        case .north:
            return CGPoint(x: size.width / 2 - laneOffset, y: car.progress)
        case .south:
            return CGPoint(x: size.width / 2 + laneOffset, y: size.height - car.progress)
        case .east:
            return CGPoint(x: size.width - car.progress, y: size.height / 2 - laneOffset)
        case .west:
            return CGPoint(x: car.progress, y: size.height / 2 + laneOffset)
        }
    }

    // MARK: - Simulation

    private func pathLength(for approach: Approach) -> CGFloat {
        approach.isVertical ? boardSize.height : boardSize.width
    }

    private func stopLine(for approach: Approach) -> CGFloat {
        pathLength(for: approach) / 2 - Self.roadWidth / 2 - Self.carLength / 2 - 4
    }

    private func greenFor(_ approach: Approach) -> Bool {
        approach.isVertical ? light.nsGreen : light.ewGreen
    }

    /// Cars stopped short of the intersection.
    private func waitingCount(for approach: Approach) -> Int {
        let stop = stopLine(for: approach)
        return (cars[approach.rawValue] ?? []).filter { $0.progress <= stop + 1 }.count
    }

    private func startGame() {
        GameHaptics.medium()
        phase = .playing
    }

    private func newGame() {
        cars = [:]
        spawnCountdown = [:]
        for approach in Approach.allCases {
            cars[approach.rawValue] = []
            spawnCountdown[approach.rawValue] = Double.random(in: 0.5...2.5)
        }
        score = 0
        elapsed = 0
        light = .nsGreen
        clearingTimeLeft = 0
        gridlockedApproach = nil
        isNewRecord = false
        phase = .ready
    }

    private func switchLight() {
        guard phase == .playing else { return }
        if case .clearing = light { return }
        GameHaptics.tap()
        light = .clearing(next: light.ewGreen)   // whoever was red goes next
        clearingTimeLeft = 0.9
    }

    private func tick(dt: Double) {
        elapsed += dt

        // Clearance phase countdown
        if case .clearing(let nsNext) = light {
            clearingTimeLeft -= dt
            if clearingTimeLeft <= 0 {
                light = nsNext ? .nsGreen : .ewGreen
            }
        }

        for approach in Approach.allCases {
            moveCars(on: approach, dt: CGFloat(dt))
            spawn(on: approach, dt: dt)
        }
    }

    private func moveCars(on approach: Approach, dt: CGFloat) {
        guard var lane = cars[approach.rawValue] else { return }
        let stop = stopLine(for: approach)
        let length = pathLength(for: approach)
        let green = greenFor(approach)

        for index in lane.indices {
            // Target: stay behind the car ahead...
            var limit = index == 0
                ? CGFloat.greatestFiniteMagnitude
                : lane[index - 1].progress - Self.carLength - 5
            // ...and behind the stop line on red, unless already past it.
            if !green && lane[index].progress <= stop {
                limit = min(limit, stop)
            }
            lane[index].progress = min(lane[index].progress + Self.carSpeed * dt, limit)
        }

        // Cars past the far edge have made it through.
        let before = lane.count
        lane.removeAll { $0.progress > length + Self.carLength }
        let passed = before - lane.count
        if passed > 0 {
            score += passed
            GameHaptics.tap()
        }

        cars[approach.rawValue] = lane
    }

    private func spawn(on approach: Approach, dt: Double) {
        var countdown = spawnCountdown[approach.rawValue] ?? 1
        countdown -= dt
        if countdown <= 0 {
            // Arrival rate creeps up over time; each road drifts differently.
            let pressure = min(elapsed / 90.0, 1.0)
            let base = 3.4 - pressure * 1.9
            let jitter = Double.random(in: 0.7...1.5)
            countdown = base * jitter

            var lane = cars[approach.rawValue] ?? []
            let entryBlocked = lane.last.map { $0.progress < Self.carLength + 6 } ?? false
            if entryBlocked {
                // No room to enter: this is what gridlock looks like.
                if lane.count >= Self.gridlockLimit {
                    gridlock(on: approach)
                    return
                }
            } else {
                lane.append(TrafficCar(progress: -Self.carLength / 2,
                                       hue: Double.random(in: 0...1)))
                cars[approach.rawValue] = lane
                if lane.count >= Self.gridlockLimit && waitingCount(for: approach) >= Self.gridlockLimit {
                    gridlock(on: approach)
                }
            }
        }
        spawnCountdown[approach.rawValue] = countdown
    }

    private func gridlock(on approach: Approach) {
        guard phase == .playing else { return }
        gridlockedApproach = approach
        GameHaptics.error()
        isNewRecord = GameScores.shared.report(score: score, for: "traffic")
        withAnimation(.easeOut(duration: 0.25)) {
            phase = .gameOver
        }
    }
}

#Preview {
    TrafficGameView()
}
