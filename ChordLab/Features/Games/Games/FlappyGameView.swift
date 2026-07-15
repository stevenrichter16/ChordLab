//
//  FlappyGameView.swift
//  ChordLab
//
//  Tap Flight: tap to flap, glide through the gaps, don't clip a pipe.
//

import SwiftUI

struct FlappyGameView: View {
    private struct Pipe: Identifiable {
        let id = UUID()
        var x: CGFloat
        let gapCenter: CGFloat   // 0...1 fraction of board height
        var scored = false
    }

    private enum FlappyPhase {
        case ready
        case playing
        case gameOver
    }

    private static let birdSize: CGFloat = 34
    private static let pipeWidth: CGFloat = 62
    private static let gapHeight: CGFloat = 170
    private static let gravity: CGFloat = 1350
    private static let flapVelocity: CGFloat = -420
    private static let pipeSpeed: CGFloat = 150
    private static let pipeSpacing: CGFloat = 210

    @State private var phase: FlappyPhase = .ready
    @State private var birdY: CGFloat = 0
    @State private var birdVelocity: CGFloat = 0
    @State private var pipes: [Pipe] = []
    @State private var score = 0
    @State private var boardSize = CGSize.zero
    @State private var isNewRecord = false

    private let ticker = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        GameScreen(game: GameCatalog.game(withId: "flappy")!, onRestart: { reset() }) {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    StatPill(label: "Score", value: "\(score)", tint: .orange)
                    StatPill(label: "Best", value: "\(GameScores.shared.best(for: "flappy") ?? 0)")
                }

                GeometryReader { geo in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(colors: [Color.cyan.opacity(0.25), Color.blue.opacity(0.12)],
                                               startPoint: .top, endPoint: .bottom)
                            )
                            .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 12))

                        // Pipes
                        ForEach(pipes) { pipe in
                            pipeView(pipe, in: geo.size)
                        }

                        // Bird
                        Text("🐤")
                            .font(.system(size: Self.birdSize))
                            .rotationEffect(.degrees(Double(max(-30, min(70, birdVelocity / 8)))))
                            .position(x: birdX(in: geo.size), y: birdY)

                        if phase == .ready {
                            VStack(spacing: 8) {
                                Text("Tap to flap")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "hand.tap.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.secondary)
                            }
                            .offset(y: -60)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .contentShape(Rectangle())
                    .onTapGesture { flap() }
                    .onAppear {
                        boardSize = geo.size
                        reset()
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
                        title: "Crashed!",
                        subtitle: "You cleared \(score) pipe\(score == 1 ? "" : "s")",
                        isVictory: false,
                        newRecord: isNewRecord,
                        buttonTitle: "Fly Again"
                    ) {
                        reset()
                    }
                }
            }
            .onReceive(ticker) { _ in
                guard phase == .playing, boardSize != .zero else { return }
                tick(dt: 1.0 / 60.0)
            }
        }
    }

    // MARK: - Rendering

    private func birdX(in size: CGSize) -> CGFloat {
        size.width * 0.3
    }

    private func pipeView(_ pipe: Pipe, in size: CGSize) -> some View {
        let gapCenterY = pipe.gapCenter * size.height
        let topHeight = max(0, gapCenterY - Self.gapHeight / 2)
        let bottomTop = gapCenterY + Self.gapHeight / 2
        let bottomHeight = max(0, size.height - bottomTop)

        return ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.green.gradient)
                .frame(width: Self.pipeWidth, height: topHeight)
                .position(x: pipe.x, y: topHeight / 2)

            RoundedRectangle(cornerRadius: 6)
                .fill(Color.green.gradient)
                .frame(width: Self.pipeWidth, height: bottomHeight)
                .position(x: pipe.x, y: bottomTop + bottomHeight / 2)
        }
    }

    // MARK: - Game logic

    private func reset() {
        phase = .ready
        score = 0
        isNewRecord = false
        birdVelocity = 0
        birdY = boardSize.height * 0.45
        pipes = []
    }

    private func flap() {
        switch phase {
        case .ready:
            phase = .playing
            spawnInitialPipes()
            birdVelocity = Self.flapVelocity
            GameHaptics.medium()
        case .playing:
            birdVelocity = Self.flapVelocity
            GameHaptics.tap()
        case .gameOver:
            break
        }
    }

    private func spawnInitialPipes() {
        pipes = []
        var x = boardSize.width + Self.pipeWidth
        for _ in 0..<4 {
            pipes.append(Pipe(x: x, gapCenter: Self.randomGapCenter()))
            x += Self.pipeSpacing
        }
    }

    private static func randomGapCenter() -> CGFloat {
        CGFloat.random(in: 0.22...0.78)
    }

    private func tick(dt: CGFloat) {
        birdVelocity += Self.gravity * dt
        birdY += birdVelocity * dt

        let birdCenterX = birdX(in: boardSize)
        let radius = Self.birdSize * 0.38

        // Floor / ceiling
        if birdY + radius >= boardSize.height || birdY - radius <= 0 {
            crash()
            return
        }

        for index in pipes.indices {
            pipes[index].x -= Self.pipeSpeed * dt

            // Score when the pipe passes the bird
            if !pipes[index].scored && pipes[index].x + Self.pipeWidth / 2 < birdCenterX - radius {
                pipes[index].scored = true
                score += 1
                GameHaptics.tap()
            }

            // Collision
            let pipe = pipes[index]
            let withinX = abs(pipe.x - birdCenterX) < Self.pipeWidth / 2 + radius
            if withinX {
                let gapCenterY = pipe.gapCenter * boardSize.height
                let gapTop = gapCenterY - Self.gapHeight / 2
                let gapBottom = gapCenterY + Self.gapHeight / 2
                if birdY - radius < gapTop || birdY + radius > gapBottom {
                    crash()
                    return
                }
            }
        }

        // Recycle pipes that scrolled off
        if let first = pipes.first, first.x < -Self.pipeWidth {
            pipes.removeFirst()
            let lastX = pipes.last?.x ?? boardSize.width
            pipes.append(Pipe(x: lastX + Self.pipeSpacing, gapCenter: Self.randomGapCenter()))
        }
    }

    private func crash() {
        GameHaptics.error()
        isNewRecord = GameScores.shared.report(score: score, for: "flappy")
        withAnimation(.easeOut(duration: 0.25)) {
            phase = .gameOver
        }
    }
}

#Preview {
    FlappyGameView()
}
