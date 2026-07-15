//
//  BreakoutGameView.swift
//  ChordLab
//
//  Breakout: drag the paddle, clear the bricks, keep the ball alive.
//

import SwiftUI

struct BreakoutGameView: View {
    private static let brickRows = 6
    private static let brickCols = 7
    private static let ballRadius: CGFloat = 7
    private static let paddleHeight: CGFloat = 14

    private struct Brick: Identifiable {
        let id: Int
        let row: Int
        let col: Int
        var alive = true
    }

    private enum BreakoutPhase {
        case ready       // ball glued to paddle, tap to launch
        case playing
        case gameOver
        case levelCleared
    }

    @State private var phase: BreakoutPhase = .ready
    @State private var bricks: [Brick] = []
    @State private var ballPosition = CGPoint.zero
    @State private var ballVelocity = CGVector.zero
    @State private var paddleX: CGFloat = 0
    @State private var boardSize = CGSize.zero
    @State private var score = 0
    @State private var lives = 3
    @State private var level = 1
    @State private var isNewRecord = false

    private let ticker = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    private var paddleWidth: CGFloat {
        max(56, 96 - CGFloat(level - 1) * 8)
    }

    private var ballSpeed: CGFloat {
        min(720, 380 + CGFloat(level - 1) * 60 + CGFloat(score) * 0.4)
    }

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "breakout")!, onRestart: { newGame() }) {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    StatPill(label: "Score", value: "\(score)", tint: .purple)
                    StatPill(label: "Level", value: "\(level)")
                    StatPill(label: "Lives", value: String(repeating: "♥", count: max(lives, 0)), tint: .red)
                }

                GeometryReader { geo in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appSecondaryBackground)

                        // Bricks
                        ForEach(bricks) { brick in
                            if brick.alive {
                                let rect = brickRect(brick, in: geo.size)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(brickColor(brick.row))
                                    .frame(width: rect.width, height: rect.height)
                                    .position(x: rect.midX, y: rect.midY)
                            }
                        }

                        // Paddle
                        Capsule()
                            .fill(Color.appPrimary)
                            .frame(width: paddleWidth, height: Self.paddleHeight)
                            .position(x: paddleX, y: paddleY(in: geo.size))

                        // Ball
                        Circle()
                            .fill(Color.white)
                            .overlay(Circle().strokeBorder(Color.black.opacity(0.2), lineWidth: 1))
                            .frame(width: Self.ballRadius * 2, height: Self.ballRadius * 2)
                            .position(ballPosition)

                        if phase == .ready {
                            VStack(spacing: 6) {
                                Text(lives < 3 || score > 0 ? "Tap to launch" : "Drag to move • Tap to launch")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            .offset(y: 60)
                        }

                        if phase == .levelCleared {
                            VStack(spacing: 10) {
                                Text("Level \(level - 1) cleared!")
                                    .font(.title2.weight(.bold))
                                ArcadeButton(title: "Level \(level)", systemImage: "play.fill", tint: .purple) {
                                    setupLevel()
                                }
                                .frame(width: 180)
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .contentShape(Rectangle())
                    .onAppear {
                        boardSize = geo.size
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
                                // A near-stationary touch counts as a tap-to-launch.
                                let distance = hypot(value.translation.width, value.translation.height)
                                if phase == .ready && distance < 10 {
                                    launch()
                                }
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
                        title: "Game Over",
                        subtitle: "Score: \(score) • Level \(level)",
                        isVictory: false,
                        newRecord: isNewRecord,
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

    // MARK: - Layout helpers

    private func paddleY(in size: CGSize) -> CGFloat {
        size.height - 36
    }

    private func brickRect(_ brick: Brick, in size: CGSize) -> CGRect {
        let gap: CGFloat = 5
        let sideInset: CGFloat = 10
        let topInset: CGFloat = 16
        let width = (size.width - sideInset * 2 - gap * CGFloat(Self.brickCols - 1)) / CGFloat(Self.brickCols)
        let height: CGFloat = 18
        let x = sideInset + CGFloat(brick.col) * (width + gap)
        let y = topInset + CGFloat(brick.row) * (height + gap)
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func brickColor(_ row: Int) -> Color {
        let colors: [Color] = [.red, .orange, .yellow, .green, .cyan, .purple]
        return colors[row % colors.count]
    }

    // MARK: - Game flow

    private func newGame() {
        score = 0
        lives = 3
        level = 1
        isNewRecord = false
        setupLevel()
    }

    private func setupLevel() {
        bricks = []
        var id = 0
        for row in 0..<Self.brickRows {
            for col in 0..<Self.brickCols {
                bricks.append(Brick(id: id, row: row, col: col))
                id += 1
            }
        }
        paddleX = boardSize.width / 2
        resetBall()
    }

    private func resetBall() {
        phase = .ready
        ballVelocity = .zero
        ballPosition = CGPoint(x: paddleX, y: paddleY(in: boardSize) - Self.paddleHeight / 2 - Self.ballRadius - 1)
    }

    private func launch() {
        GameHaptics.medium()
        let angle = CGFloat.random(in: (-0.35)...0.35) - .pi / 2
        ballVelocity = CGVector(dx: cos(angle) * ballSpeed, dy: sin(angle) * ballSpeed)
        phase = .playing
    }

    private func movePaddle(to x: CGFloat) {
        guard boardSize != .zero else { return }
        paddleX = min(max(x, paddleWidth / 2), boardSize.width - paddleWidth / 2)
        if phase == .ready {
            ballPosition.x = paddleX
        }
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

        // Walls
        if pos.x < r {
            pos.x = r
            vel.dx = abs(vel.dx)
        } else if pos.x > width - r {
            pos.x = width - r
            vel.dx = -abs(vel.dx)
        }
        if pos.y < r {
            pos.y = r
            vel.dy = abs(vel.dy)
        }

        // Paddle
        let py = paddleY(in: boardSize)
        if vel.dy > 0,
           pos.y + r >= py - Self.paddleHeight / 2,
           pos.y + r <= py + Self.paddleHeight / 2 + 14,
           abs(pos.x - paddleX) <= paddleWidth / 2 + r {
            let offset = max(-1, min(1, (pos.x - paddleX) / (paddleWidth / 2)))
            let maxBounceAngle: CGFloat = 1.05   // ~60° from straight up
            let speed = ballSpeed
            vel = CGVector(dx: sin(offset * maxBounceAngle) * speed,
                           dy: -cos(offset * maxBounceAngle) * speed)
            pos.y = py - Self.paddleHeight / 2 - r
            GameHaptics.tap()
        }

        // Bricks
        if let hitIndex = bricks.firstIndex(where: { brick in
            guard brick.alive else { return false }
            let rect = brickRect(brick, in: boardSize).insetBy(dx: -r, dy: -r)
            return rect.contains(pos)
        }) {
            let rect = brickRect(bricks[hitIndex], in: boardSize)
            bricks[hitIndex].alive = false
            score += 10
            GameHaptics.tap()

            // Bounce on the axis of least penetration.
            let fromLeft = abs(pos.x - (rect.minX - r))
            let fromRight = abs(pos.x - (rect.maxX + r))
            let fromTop = abs(pos.y - (rect.minY - r))
            let fromBottom = abs(pos.y - (rect.maxY + r))
            let minHorizontal = min(fromLeft, fromRight)
            let minVertical = min(fromTop, fromBottom)
            if minHorizontal < minVertical {
                vel.dx = fromLeft < fromRight ? -abs(vel.dx) : abs(vel.dx)
            } else {
                vel.dy = fromTop < fromBottom ? -abs(vel.dy) : abs(vel.dy)
            }

            if bricks.allSatisfy({ !$0.alive }) {
                level += 1
                GameHaptics.success()
                ballPosition = pos
                ballVelocity = .zero
                phase = .levelCleared
                return
            }
        }

        // Keep speed consistent with the current target
        let magnitude = sqrt(vel.dx * vel.dx + vel.dy * vel.dy)
        if magnitude > 0 {
            let target = ballSpeed
            vel = CGVector(dx: vel.dx / magnitude * target, dy: vel.dy / magnitude * target)
        }

        // Floor: lose a life
        if pos.y > height + r * 2 {
            lives -= 1
            if lives <= 0 {
                GameHaptics.error()
                isNewRecord = GameScores.shared.report(score: score, for: "breakout")
                phase = .gameOver
            } else {
                GameHaptics.warning()
                resetBall()
            }
            return
        }

        ballPosition = pos
        ballVelocity = vel
    }
}

#Preview {
    BreakoutGameView()
}
