//
//  PongGameView.swift
//  ChordLab
//
//  Pong: drag your paddle, angle your shots, first to 7 beats the AI.
//

import SwiftUI

struct PongGameView: View {
    private static let paddleWidth: CGFloat = 84
    private static let paddleHeight: CGFloat = 12
    private static let ballRadius: CGFloat = 8
    private static let paddleInset: CGFloat = 28
    private static let winningScore = 7
    private static let baseBallSpeed: CGFloat = 380
    private static let maxBallSpeed: CGFloat = 660
    private static let maxBounceAngle: CGFloat = 1.0   // ~57° from vertical

    private enum PongPhase {
        case ready      // ball centered, tap to serve (auto-serves between points)
        case playing
        case over
    }

    private let game = GameCatalog.game(withId: "pong")
        ?? GameInfo(id: "pong", name: "Pong", icon: "circlebadge.2.fill", tint: .mint,
                    category: .arcade, blurb: "First to 7 against the AI paddle.",
                    scoreLabel: "Wins")

    @State private var phase: PongPhase = .ready
    @State private var ballPosition = CGPoint.zero
    @State private var ballVelocity = CGVector.zero
    @State private var ballSpeed: CGFloat = PongGameView.baseBallSpeed
    @State private var playerX: CGFloat = 0
    @State private var aiX: CGFloat = 0
    @State private var boardSize = CGSize.zero
    @State private var playerScore = 0
    @State private var aiScore = 0
    @State private var pointsPlayed = 0
    @State private var rallyHits = 0
    @State private var serveTowardPlayer = true
    @State private var serveGeneration = 0
    @State private var playerWon = false
    @State private var careerWins = 0

    private let ticker = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    /// The AI paddle's speed cap: slow enough to be beatable with sharp
    /// angles, creeping up a little with every rally hit and every point.
    private var aiMaxSpeed: CGFloat {
        min(190 + CGFloat(rallyHits) * 10 + CGFloat(pointsPlayed) * 8, 350)
    }

    var body: some View {
        GameScreen(game: game, onRestart: { newGame() }) {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    StatPill(label: "You", value: "\(playerScore)", tint: game.tint)
                    StatPill(label: "AI", value: "\(aiScore)", tint: .red)
                    StatPill(label: "Wins", value: "\(careerWins)", tint: .yellow)
                }

                GeometryReader { geo in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appSecondaryBackground)

                        // Center dashed line
                        Path { path in
                            path.move(to: CGPoint(x: 8, y: geo.size.height / 2))
                            path.addLine(to: CGPoint(x: geo.size.width - 8, y: geo.size.height / 2))
                        }
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
                        .foregroundStyle(Color.primary.opacity(0.15))

                        // Big translucent scores on each half
                        Text("\(aiScore)")
                            .font(.system(size: 88, weight: .black, design: .rounded))
                            .foregroundStyle(Color.primary.opacity(0.10))
                            .contentTransition(.numericText())
                            .position(x: geo.size.width / 2, y: geo.size.height * 0.25)
                        Text("\(playerScore)")
                            .font(.system(size: 88, weight: .black, design: .rounded))
                            .foregroundStyle(Color.primary.opacity(0.10))
                            .contentTransition(.numericText())
                            .position(x: geo.size.width / 2, y: geo.size.height * 0.75)

                        // AI paddle (top)
                        Capsule()
                            .fill(Color.red.opacity(0.85))
                            .frame(width: Self.paddleWidth, height: Self.paddleHeight)
                            .position(x: aiX, y: Self.paddleInset)

                        // Player paddle (bottom)
                        Capsule()
                            .fill(game.tint)
                            .frame(width: Self.paddleWidth, height: Self.paddleHeight)
                            .position(x: playerX, y: geo.size.height - Self.paddleInset)

                        // Ball
                        Circle()
                            .fill(Color.white)
                            .overlay(Circle().strokeBorder(Color.black.opacity(0.2), lineWidth: 1))
                            .frame(width: Self.ballRadius * 2, height: Self.ballRadius * 2)
                            .position(ballPosition)

                        if phase == .ready {
                            Text(pointsPlayed == 0 ? "Drag to move • Tap to serve" : "Tap to serve")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .position(x: geo.size.width / 2, y: geo.size.height / 2 + 50)
                                .transition(.opacity)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .contentShape(Rectangle())
                    .onAppear {
                        boardSize = geo.size
                        careerWins = GameScores.shared.counter("wins", for: "pong")
                        newGame()
                    }
                    .onChange(of: geo.size) { _, newSize in
                        boardSize = newSize
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                movePaddle(to: value.location.x)
                            }
                            .onEnded { value in
                                // A near-stationary touch counts as a tap-to-serve.
                                let distance = hypot(value.translation.width, value.translation.height)
                                if phase == .ready && distance < 10 {
                                    serve()
                                }
                            }
                    )
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
            .padding(.top, 4)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: playerScore)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: aiScore)
            .overlay {
                if phase == .over {
                    GameOverOverlay(
                        title: playerWon ? "You Win!" : "AI Wins",
                        subtitle: "Final score \(playerScore) – \(aiScore)",
                        isVictory: playerWon,
                        buttonTitle: "Play Again"
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
        serveGeneration += 1
        playerScore = 0
        aiScore = 0
        pointsPlayed = 0
        rallyHits = 0
        ballSpeed = Self.baseBallSpeed
        playerWon = false
        playerX = boardSize.width / 2
        aiX = boardSize.width / 2
        ballPosition = CGPoint(x: boardSize.width / 2, y: boardSize.height / 2)
        ballVelocity = .zero
        serveTowardPlayer = true
        phase = .ready
    }

    private func serve() {
        guard phase == .ready, boardSize != .zero else { return }
        serveGeneration += 1   // cancel any pending auto-serve
        let angle = CGFloat.random(in: -0.5...0.5)
        ballVelocity = CGVector(dx: sin(angle) * ballSpeed,
                                dy: (serveTowardPlayer ? 1 : -1) * cos(angle) * ballSpeed)
        GameHaptics.medium()
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            phase = .playing
        }
    }

    /// Recenter the ball after a point: brief pause, then auto-serve toward
    /// whoever just conceded (tapping serves early).
    private func resetForServe() {
        phase = .ready
        ballSpeed = Self.baseBallSpeed
        rallyHits = 0
        ballVelocity = .zero
        ballPosition = CGPoint(x: boardSize.width / 2, y: boardSize.height / 2)
        serveGeneration += 1
        let generation = serveGeneration

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard generation == serveGeneration, phase == .ready else { return }
            serve()
        }
    }

    private func movePaddle(to x: CGFloat) {
        guard boardSize != .zero, phase != .over else { return }
        playerX = min(max(x, Self.paddleWidth / 2), boardSize.width - Self.paddleWidth / 2)
    }

    // MARK: - Physics

    private func tick(dt: CGFloat) {
        var pos = ballPosition
        var vel = ballVelocity

        pos.x += vel.dx * dt
        pos.y += vel.dy * dt

        let r = Self.ballRadius
        let width = boardSize.width
        let height = boardSize.height

        // Side walls
        if pos.x < r {
            pos.x = r
            vel.dx = abs(vel.dx)
        } else if pos.x > width - r {
            pos.x = width - r
            vel.dx = -abs(vel.dx)
        }

        // AI paddle chases the ball with a capped speed.
        let diff = pos.x - aiX
        let maxStep = aiMaxSpeed * dt
        if abs(diff) > maxStep {
            aiX += diff > 0 ? maxStep : -maxStep
        } else {
            aiX = pos.x
        }
        aiX = min(max(aiX, Self.paddleWidth / 2), width - Self.paddleWidth / 2)

        // Player paddle (bottom)
        let py = height - Self.paddleInset
        if vel.dy > 0,
           pos.y + r >= py - Self.paddleHeight / 2,
           pos.y + r <= py + Self.paddleHeight / 2 + 14,
           abs(pos.x - playerX) <= Self.paddleWidth / 2 + r {
            let offset = max(-1, min(1, (pos.x - playerX) / (Self.paddleWidth / 2)))
            vel = bounce(offset: offset, upward: true)
            pos.y = py - Self.paddleHeight / 2 - r
        }

        // AI paddle (top)
        let ay = Self.paddleInset
        if vel.dy < 0,
           pos.y - r <= ay + Self.paddleHeight / 2,
           pos.y - r >= ay - Self.paddleHeight / 2 - 14,
           abs(pos.x - aiX) <= Self.paddleWidth / 2 + r {
            let offset = max(-1, min(1, (pos.x - aiX) / (Self.paddleWidth / 2)))
            vel = bounce(offset: offset, upward: false)
            pos.y = ay + Self.paddleHeight / 2 + r
        }

        // Past the top: player scores. Past the bottom: AI scores.
        if pos.y < -r * 2 {
            pointScored(byPlayer: true)
            return
        }
        if pos.y > height + r * 2 {
            pointScored(byPlayer: false)
            return
        }

        ballPosition = pos
        ballVelocity = vel
    }

    /// Angle the ball off a paddle based on where it hit, speeding it up a bit.
    private func bounce(offset: CGFloat, upward: Bool) -> CGVector {
        ballSpeed = min(ballSpeed + 16, Self.maxBallSpeed)
        rallyHits += 1
        GameHaptics.tap()
        return CGVector(dx: sin(offset * Self.maxBounceAngle) * ballSpeed,
                        dy: (upward ? -1 : 1) * cos(offset * Self.maxBounceAngle) * ballSpeed)
    }

    private func pointScored(byPlayer: Bool) {
        pointsPlayed += 1
        if byPlayer {
            playerScore += 1
            GameHaptics.medium()
        } else {
            aiScore += 1
            GameHaptics.warning()
        }
        // Serve toward whoever just conceded the point.
        serveTowardPlayer = !byPlayer

        if playerScore >= Self.winningScore {
            playerWon = true
            GameHaptics.success()
            GameScores.shared.incrementCounter("wins", for: "pong")
            let wins = GameScores.shared.counter("wins", for: "pong")
            GameScores.shared.setValue(wins, for: "pong")
            careerWins = wins
            ballVelocity = .zero
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                phase = .over
            }
        } else if aiScore >= Self.winningScore {
            playerWon = false
            GameHaptics.error()
            ballVelocity = .zero
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                phase = .over
            }
        } else {
            resetForServe()
        }
    }
}

#Preview {
    PongGameView()
}
