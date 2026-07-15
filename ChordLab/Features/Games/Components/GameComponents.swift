//
//  GameComponents.swift
//  ChordLab
//
//  Shared UI building blocks for the Arcade section.
//

import SwiftUI
import UIKit

// MARK: - Haptics

enum GameHaptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

// MARK: - Game Screen Container

/// Standard chrome for every game: dark-friendly background, top bar with
/// close + restart, centered title, and the game content below.
struct GameScreen<Content: View>: View {
    @Environment(\.dismiss) private var dismiss

    let game: GameInfo
    var onRestart: (() -> Void)?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    GameHaptics.tap()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .background(Color.appSecondaryBackground, in: Circle())
                }

                Spacer()

                HStack(spacing: 8) {
                    Image(systemName: game.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(game.tint)
                    Text(game.name)
                        .font(.headline)
                }

                Spacer()

                if let onRestart {
                    Button {
                        GameHaptics.tap()
                        onRestart()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 36, height: 36)
                            .background(Color.appSecondaryBackground, in: Circle())
                    }
                } else {
                    Color.clear.frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let label: String
    let value: String
    var tint: Color = .appPrimary

    var body: some View {
        VStack(spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Game Over Overlay

/// Dimmed overlay with a result card. Present conditionally in a ZStack.
struct GameOverOverlay: View {
    let title: String
    var subtitle: String? = nil
    var isVictory: Bool = false
    var newRecord: Bool = false
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Text(isVictory ? "🏆" : "🎮")
                    .font(.system(size: 44))

                Text(title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                if newRecord {
                    Label("New record!", systemImage: "star.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.yellow)
                }

                Button(action: {
                    GameHaptics.tap()
                    action()
                }) {
                    Text(buttonTitle)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.appPrimary, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top, 6)
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.3), radius: 30, y: 10)
            .padding(32)
        }
        .transition(.opacity)
    }
}

// MARK: - Playing Cards (shared by Blackjack, Higher/Lower, Video Poker)

enum CardSuit: String, CaseIterable {
    case spades = "♠"
    case hearts = "♥"
    case diamonds = "♦"
    case clubs = "♣"

    var color: Color {
        switch self {
        case .hearts, .diamonds: return .red
        case .spades, .clubs: return .primary
        }
    }
}

struct PlayingCard: Identifiable, Equatable {
    let id = UUID()
    /// 1 = Ace ... 11 = J, 12 = Q, 13 = K
    let rank: Int
    let suit: CardSuit

    var rankText: String {
        switch rank {
        case 1: return "A"
        case 11: return "J"
        case 12: return "Q"
        case 13: return "K"
        default: return String(rank)
        }
    }

    /// Blackjack value (ace counted as 1 here; hand logic upgrades to 11).
    var blackjackValue: Int {
        min(rank, 10)
    }

    static func standardDeck(count: Int = 1) -> [PlayingCard] {
        var deck: [PlayingCard] = []
        for _ in 0..<count {
            for suit in CardSuit.allCases {
                for rank in 1...13 {
                    deck.append(PlayingCard(rank: rank, suit: suit))
                }
            }
        }
        return deck
    }
}

struct PlayingCardView: View {
    let card: PlayingCard
    var faceUp: Bool = true
    var width: CGFloat = 64

    private var height: CGFloat { width * 1.45 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.12)
                .fill(faceUp ? Color.white : Color.appPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: width * 0.12)
                        .strokeBorder(Color.black.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.18), radius: 3, y: 2)

            if faceUp {
                VStack {
                    HStack {
                        VStack(spacing: -2) {
                            Text(card.rankText)
                                .font(.system(size: width * 0.28, weight: .bold, design: .rounded))
                            Text(card.suit.rawValue)
                                .font(.system(size: width * 0.24))
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .padding(width * 0.09)
                .foregroundStyle(card.suit == .hearts || card.suit == .diamonds ? Color.red : Color.black)

                Text(card.suit.rawValue)
                    .font(.system(size: width * 0.52))
                    .foregroundStyle(card.suit == .hearts || card.suit == .diamonds ? Color.red : Color.black)
                    .offset(y: height * 0.12)
            } else {
                RoundedRectangle(cornerRadius: width * 0.08)
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 2)
                    .padding(width * 0.1)
                Image(systemName: "seal.fill")
                    .font(.system(size: width * 0.3))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Big Action Button

struct ArcadeButton: View {
    let title: String
    var systemImage: String? = nil
    var tint: Color = .appPrimary
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            GameHaptics.tap()
            action()
        } label: {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(isEnabled ? tint : Color.gray.opacity(0.4), in: RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!isEnabled)
    }
}
