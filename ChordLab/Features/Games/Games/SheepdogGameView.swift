//
//  SheepdogGameView.swift
//  ChordLab
//
//  Sheepdog: a boids flock of sheep fears your finger. Herd every sheep
//  into the pen before the clock runs out. Levels add sheep and shrink
//  the pen.
//

import SwiftUI

struct SheepdogGameView: View {
    private struct Sheep: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGVector = .zero
        var penned = false
    }

    private enum SheepdogPhase {
        case ready
        case playing
        case levelCleared
        case gameOver
    }

    private static let levelTime: Double = 45

    @State private var phase: SheepdogPhase = .ready
    @State private var level = 1
    @State private var sheep: [Sheep] = []
    @State private var fingerLocation: CGPoint? = nil
    @State private var timeRemaining: Double = SheepdogGameView.levelTime
    @State private var boardSize = CGSize.zero
    @State private var isNewRecord = false

    private let ticker = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    private var sheepCount: Int {
        8 + level * 2
    }

    private var penRect: CGRect {
        let width = max(84, 150 - CGFloat(level - 1) * 10)
        return CGRect(x: (boardSize.width - width) / 2, y: 14, width: width, height: 78)
    }

    private var pennedCount: Int {
        sheep.filter(\.penned).count
    }

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "sheepdog")!, onRestart: { newGame() }) {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    StatPill(label: "Level", value: "\(level)", tint: .brown)
                    StatPill(label: "Penned", value: "\(pennedCount)/\(sheep.count)", tint: .green)
                    StatPill(label: "Time", value: String(format: "%.0fs", max(0, timeRemaining)),
                             tint: timeRemaining <= 10 ? .red : .appPrimary)
                }

                GeometryReader { geo in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.14))
                            .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 12))

                        // Pen
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.green.opacity(0.28))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.brown, style: StrokeStyle(lineWidth: 3, dash: [7, 5]))
                            )
                            .overlay(
                                Text("PEN")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.brown.opacity(0.7))
                            )
                            .frame(width: penRect.width, height: penRect.height)
                            .position(x: penRect.midX, y: penRect.midY)

                        // Sheep
                        ForEach(sheep) { animal in
                            Text("🐑")
                                .font(.system(size: 21))
                                .opacity(animal.penned ? 0.85 : 1)
                                .position(animal.position)
                        }

                        // The dog (your finger)
                        if let fingerLocation {
                            Text("🐕")
                                .font(.system(size: 26))
                                .position(fingerLocation)
                        }

                        if phase == .ready {
                            VStack(spacing: 8) {
                                Text("Your finger is the dog.\nSheep run away from it — use that.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                ArcadeButton(title: "Start Herding", systemImage: "play.fill", tint: .brown) {
                                    startLevel()
                                }
                                .frame(width: 200)
                            }
                        }

                        if phase == .levelCleared {
                            VStack(spacing: 10) {
                                Text("Flock secured! 🎉")
                                    .font(.title2.weight(.bold))
                                ArcadeButton(title: "Level \(level + 1)", systemImage: "arrow.right", tint: .brown) {
                                    level += 1
                                    startLevel()
                                }
                                .frame(width: 180)
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .contentShape(Rectangle())
                    .onAppear {
                        boardSize = geo.size
                    }
                    .onChange(of: geo.size) { _, newSize in
                        boardSize = newSize
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                fingerLocation = value.location
                            }
                            .onEnded { _ in
                                fingerLocation = nil
                            }
                    )
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
            .padding(.top, 4)
            .overlay {
                if phase == .gameOver {
                    GameOverOverlay(
                        title: "Time's Up",
                        subtitle: "\(pennedCount) of \(sheep.count) penned on level \(level)",
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

    // MARK: - Game flow

    private func newGame() {
        level = 1
        phase = .ready
        sheep = []
        timeRemaining = Self.levelTime
        isNewRecord = false
    }

    private func startLevel() {
        GameHaptics.medium()
        timeRemaining = Self.levelTime
        isNewRecord = false
        sheep = (0..<sheepCount).map { _ in
            Sheep(position: CGPoint(
                x: CGFloat.random(in: boardSize.width * 0.15...boardSize.width * 0.85),
                y: CGFloat.random(in: boardSize.height * 0.4...boardSize.height * 0.9)
            ))
        }
        phase = .playing
    }

    private func endLevel(cleared: Bool) {
        if cleared {
            GameHaptics.success()
            GameScores.shared.report(score: level, for: "sheepdog")
            phase = .levelCleared
        } else {
            GameHaptics.error()
            isNewRecord = GameScores.shared.report(score: level - 1, for: "sheepdog")
            phase = .gameOver
        }
    }

    // MARK: - Boids simulation

    private func tick(dt: CGFloat) {
        timeRemaining -= Double(dt)
        if timeRemaining <= 0 {
            endLevel(cleared: false)
            return
        }

        let positions = sheep.map(\.position)
        let velocities = sheep.map(\.velocity)
        let pennedFlags = sheep.map(\.penned)
        let innerPen = penRect.insetBy(dx: 10, dy: 10)

        for index in sheep.indices where !sheep[index].penned {
            var force = CGVector.zero
            let pos = positions[index]

            var cohesionSum = CGPoint.zero
            var cohesionCount = 0
            var alignSum = CGVector.zero
            var alignCount = 0

            for other in positions.indices where other != index && !pennedFlags[other] {
                let dx = positions[other].x - pos.x
                let dy = positions[other].y - pos.y
                let distSq = dx * dx + dy * dy

                // Separation
                if distSq < 26 * 26 && distSq > 0.01 {
                    let dist = sqrt(distSq)
                    force.dx -= dx / dist * (26 - dist) * 4.5
                    force.dy -= dy / dist * (26 - dist) * 4.5
                }
                // Cohesion
                if distSq < 70 * 70 {
                    cohesionSum.x += positions[other].x
                    cohesionSum.y += positions[other].y
                    cohesionCount += 1
                }
                // Alignment
                if distSq < 50 * 50 {
                    alignSum.dx += velocities[other].dx
                    alignSum.dy += velocities[other].dy
                    alignCount += 1
                }
            }

            if cohesionCount > 0 {
                force.dx += (cohesionSum.x / CGFloat(cohesionCount) - pos.x) * 0.5
                force.dy += (cohesionSum.y / CGFloat(cohesionCount) - pos.y) * 0.5
            }
            if alignCount > 0 {
                force.dx += (alignSum.dx / CGFloat(alignCount) - velocities[index].dx) * 0.9
                force.dy += (alignSum.dy / CGFloat(alignCount) - velocities[index].dy) * 0.9
            }

            // Fear of the dog
            var scared = false
            if let dog = fingerLocation {
                let dx = pos.x - dog.x
                let dy = pos.y - dog.y
                let dist = max(6, sqrt(dx * dx + dy * dy))
                if dist < 120 {
                    scared = true
                    let strength = (120 - dist) * 9
                    force.dx += dx / dist * strength
                    force.dy += dy / dist * strength
                }
            }

            // Soft walls
            let margin: CGFloat = 24
            if pos.x < margin { force.dx += (margin - pos.x) * 6 }
            if pos.x > boardSize.width - margin { force.dx -= (pos.x - (boardSize.width - margin)) * 6 }
            if pos.y < margin { force.dy += (margin - pos.y) * 6 }
            if pos.y > boardSize.height - margin { force.dy -= (pos.y - (boardSize.height - margin)) * 6 }

            // A little wander so the flock never fully settles
            force.dx += CGFloat.random(in: -14...14)
            force.dy += CGFloat.random(in: -14...14)

            var vel = velocities[index]
            vel.dx = (vel.dx + force.dx * dt) * 0.965
            vel.dy = (vel.dy + force.dy * dt) * 0.965

            let maxSpeed: CGFloat = scared ? 135 : 55
            let speed = sqrt(vel.dx * vel.dx + vel.dy * vel.dy)
            if speed > maxSpeed {
                vel.dx = vel.dx / speed * maxSpeed
                vel.dy = vel.dy / speed * maxSpeed
            }

            var newPos = CGPoint(x: pos.x + vel.dx * dt, y: pos.y + vel.dy * dt)
            newPos.x = min(max(newPos.x, 8), boardSize.width - 8)
            newPos.y = min(max(newPos.y, 8), boardSize.height - 8)

            sheep[index].position = newPos
            sheep[index].velocity = vel

            if innerPen.contains(newPos) {
                sheep[index].penned = true
                sheep[index].velocity = .zero
                GameHaptics.tap()
            }
        }

        if !sheep.isEmpty && sheep.allSatisfy(\.penned) {
            endLevel(cleared: true)
        }
    }
}

#Preview {
    SheepdogGameView()
}
