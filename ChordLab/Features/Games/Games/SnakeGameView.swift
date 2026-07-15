//
//  SnakeGameView.swift
//  ChordLab
//
//  Classic snake: swipe to steer, eat food, don't hit walls or yourself.
//

import SwiftUI

struct SnakeGameView: View {
    private static let columns = 15
    private static let rows = 21
    private static let baseInterval = 0.22
    private static let minInterval = 0.08

    private struct SnakePoint: Equatable, Hashable {
        var x: Int
        var y: Int
    }

    private enum SnakeDirection {
        case up, down, left, right

        var dx: Int {
            switch self {
            case .left: return -1
            case .right: return 1
            default: return 0
            }
        }

        var dy: Int {
            switch self {
            case .up: return -1
            case .down: return 1
            default: return 0
            }
        }

        var opposite: SnakeDirection {
            switch self {
            case .up: return .down
            case .down: return .up
            case .left: return .right
            case .right: return .left
            }
        }
    }

    private enum SnakePhase {
        case ready, playing, gameOver
    }

    @State private var snake: [SnakePoint] = []
    @State private var direction: SnakeDirection = .up
    @State private var pendingDirection: SnakeDirection?
    @State private var food = SnakePoint(x: 3, y: 3)
    @State private var phase: SnakePhase = .ready
    @State private var score = 0
    @State private var accumulated: Double = 0
    @State private var isNewRecord = false

    private let ticker = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    private var stepInterval: Double {
        max(Self.minInterval, Self.baseInterval - Double(score) * 0.006)
    }

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "snake")!, onRestart: { resetGame() }) {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    StatPill(label: "Score", value: "\(score)", tint: .green)
                    StatPill(label: "Best", value: "\(GameScores.shared.best(for: "snake") ?? 0)")
                }

                GeometryReader { geo in
                    let cell = min(geo.size.width / CGFloat(Self.columns),
                                   geo.size.height / CGFloat(Self.rows))
                    let boardWidth = cell * CGFloat(Self.columns)
                    let boardHeight = cell * CGFloat(Self.rows)

                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appSecondaryBackground)

                        // Food
                        Text("🍎")
                            .font(.system(size: cell * 0.8))
                            .position(x: (CGFloat(food.x) + 0.5) * cell,
                                      y: (CGFloat(food.y) + 0.5) * cell)

                        // Snake
                        ForEach(Array(snake.enumerated()), id: \.element) { index, segment in
                            RoundedRectangle(cornerRadius: cell * 0.28)
                                .fill(index == 0 ? Color.green : Color.green.opacity(0.75))
                                .frame(width: cell * 0.92, height: cell * 0.92)
                                .position(x: (CGFloat(segment.x) + 0.5) * cell,
                                          y: (CGFloat(segment.y) + 0.5) * cell)
                        }

                        if phase == .ready {
                            VStack(spacing: 8) {
                                Text("Swipe to steer")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                ArcadeButton(title: "Start", systemImage: "play.fill", tint: .green) {
                                    startGame()
                                }
                                .frame(width: 160)
                            }
                        }
                    }
                    .frame(width: boardWidth, height: boardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 12)
                            .onEnded { value in
                                handleSwipe(translation: value.translation)
                            }
                    )
                }
                .padding(.horizontal, 12)
            }
            .padding(.vertical, 8)
            .overlay {
                if phase == .gameOver {
                    GameOverOverlay(
                        title: "Game Over",
                        subtitle: "You ate \(score) apple\(score == 1 ? "" : "s")",
                        isVictory: false,
                        newRecord: isNewRecord,
                        buttonTitle: "Play Again"
                    ) {
                        resetGame()
                        startGame()
                    }
                }
            }
            .onReceive(ticker) { _ in
                guard phase == .playing else { return }
                accumulated += 0.05
                if accumulated >= stepInterval {
                    accumulated = 0
                    step()
                }
            }
            .onAppear {
                resetGame()
            }
        }
    }

    // MARK: - Game logic

    private func resetGame() {
        let startX = Self.columns / 2
        let startY = Self.rows / 2
        snake = [
            SnakePoint(x: startX, y: startY),
            SnakePoint(x: startX, y: startY + 1),
            SnakePoint(x: startX, y: startY + 2)
        ]
        direction = .up
        pendingDirection = nil
        score = 0
        accumulated = 0
        isNewRecord = false
        phase = .ready
        placeFood()
    }

    private func startGame() {
        GameHaptics.medium()
        phase = .playing
    }

    private func handleSwipe(translation: CGSize) {
        let proposed: SnakeDirection
        if abs(translation.width) > abs(translation.height) {
            proposed = translation.width > 0 ? .right : .left
        } else {
            proposed = translation.height > 0 ? .down : .up
        }
        guard phase == .playing else { return }
        // Can't reverse into yourself; queue relative to the last applied direction.
        if proposed != direction.opposite && proposed != direction {
            pendingDirection = proposed
        }
    }

    private func step() {
        if let pending = pendingDirection {
            direction = pending
            pendingDirection = nil
        }

        guard let head = snake.first else { return }
        let newHead = SnakePoint(x: head.x + direction.dx, y: head.y + direction.dy)

        // Wall collision
        if newHead.x < 0 || newHead.x >= Self.columns || newHead.y < 0 || newHead.y >= Self.rows {
            endGame()
            return
        }

        let ateFood = newHead == food
        // Self collision (tail cell frees up unless we grow)
        let occupied = ateFood ? snake : Array(snake.dropLast())
        if occupied.contains(newHead) {
            endGame()
            return
        }

        snake.insert(newHead, at: 0)
        if ateFood {
            score += 1
            GameHaptics.tap()
            placeFood()
        } else {
            snake.removeLast()
        }
    }

    private func placeFood() {
        let taken = Set(snake)
        var free: [SnakePoint] = []
        for x in 0..<Self.columns {
            for y in 0..<Self.rows {
                let p = SnakePoint(x: x, y: y)
                if !taken.contains(p) {
                    free.append(p)
                }
            }
        }
        if let spot = free.randomElement() {
            food = spot
        }
    }

    private func endGame() {
        GameHaptics.error()
        isNewRecord = GameScores.shared.report(score: score, for: "snake")
        withAnimation(.easeOut(duration: 0.25)) {
            phase = .gameOver
        }
    }
}

#Preview {
    SnakeGameView()
}
