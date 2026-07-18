//
//  ProgressionTimelineComponents.swift
//  ChordLab
//
//  Timeline cells and badges shared by the progression player dock
//

import SwiftUI
import Tonic
import UIKit

// MARK: - Chord Timeline Item

struct ChordTimelineItem: View {
    let chord: Chord
    let index: Int
    var beats: Double = 1.0
    var numeral: String? = nil
    let isPlaying: Bool
    let isSelected: Bool
    let onRemove: () -> Void
    let onLongPress: () -> Void
    var onCycleDuration: () -> Void = {}

    @Environment(AudioEngine.self) private var audioEngine
    @Environment(TheoryEngine.self) private var theoryEngine
    @State private var isTapped = false

    private var beatCount: Int { max(Int(beats.rounded()), 1) }
    private var cellWidth: CGFloat { 60 + CGFloat(max(beats - 1, 0)) * 18 }

    // Same function-color language as DiatonicChordGrid
    private var numeralColor: Color {
        guard let numeral else { return .secondary }
        return theoryEngine.determineFunction(romanNumeral: numeral).color
    }

    var body: some View {
        VStack(spacing: 0) {
            // Upper region: chord symbol, remove button, preview/reorder gestures
            ZStack {
                VStack(spacing: 1) {
                    if let numeral {
                        Text(numeral)
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(isPlaying ? .white.opacity(0.85) : numeralColor)
                    }

                    Text(chord.formattedSymbol)
                        .font(.chordSymbol)
                        .foregroundColor(isPlaying ? .white : .primary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack {
                    HStack {
                        Spacer()
                        Button(action: onRemove) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(isPlaying ? .white.opacity(0.8) : .secondary)
                                .frame(width: 28, height: 28)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("Remove \(chord.formattedSymbol)")
                    }
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // Play the chord when tapped (only if not selected)
                if !isSelected {
                    // Set the visualized chord to highlight on piano
                    theoryEngine.visualizedChord = chord

                    // Also set as selected chord to update the display
                    theoryEngine.selectedChord = chord

                    // Play the chord
                    audioEngine.playChord(chord, velocity: 60, duration: 0.8)

                    withAnimation(.easeInOut(duration: 0.1)) {
                        isTapped = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isTapped = false
                        }
                    }

                    // Clear the visualized chord after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if theoryEngine.visualizedChord == chord {
                            withAnimation(.easeOut(duration: 0.3)) {
                                theoryEngine.visualizedChord = nil
                            }
                        }
                    }
                }
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                onLongPress()

                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }

            // Duration band: full-width target cycling 1 -> 2 -> 4 beats
            Button(action: onCycleDuration) {
                HStack(spacing: 3) {
                    ForEach(0..<beatCount, id: \.self) { _ in
                        Circle()
                            .fill(isPlaying ? Color.white : Color.appPrimary.opacity(0.8))
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(height: 20)
            .background(isPlaying ? Color.white.opacity(0.18) : Color.appTertiaryBackground.opacity(0.7))
            .accessibilityLabel("Duration: \(beatCount) beat\(beatCount == 1 ? "" : "s")")
            .accessibilityHint("Double tap to change")
        }
        .frame(width: cellWidth, height: 72)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card)
                .fill(isPlaying ? Color.appPrimary : (isTapped ? Color.appPrimary.opacity(0.8) : Color.appSecondaryBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card)
                .strokeBorder(isSelected ? Color.green : Color.appBorder, lineWidth: isSelected ? 3 : 1)
        )
        .scaleEffect(isPlaying ? 1.05 : (isTapped ? 0.95 : 1.0))
        .opacity(isSelected ? 0.8 : 1.0)  // Dim when selected
        .animation(.easeInOut(duration: 0.2), value: isPlaying)
        .animation(.easeInOut(duration: 0.1), value: isTapped)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: beats)
    }
}

// MARK: - Analysis Badge

struct AnalysisBadge: View {
    let icon: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundColor(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(tint.opacity(0.12)))
    }
}

// MARK: - Suggestion Chip

/// Dashed "ghost" cell offering a theory-guided next chord
struct SuggestionChip: View {
    let chord: Chord
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                Text(chord.formattedSymbol)
                    .font(.chordSymbolSmall)
            }
            .foregroundColor(.appPrimary.opacity(0.75))
            .frame(width: 52, height: 72)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .fill(Color.appPrimary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .strokeBorder(
                        Color.appPrimary.opacity(0.45),
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add suggested chord \(chord.formattedSymbol)")
    }
}

// MARK: - Chord Move Arrows

struct ChordMoveArrows: View {
    let canMoveLeft: Bool
    let canMoveRight: Bool
    let onMoveLeft: () -> Void
    let onMoveRight: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Left arrow
            Button(action: onMoveLeft) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(canMoveLeft ? .white : .gray)
                    .opacity(canMoveLeft ? 1.0 : 0.5)
            }
            .disabled(!canMoveLeft)
            .accessibilityLabel("Move chord left")

            // Right arrow
            Button(action: onMoveRight) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(canMoveRight ? .white : .gray)
                    .opacity(canMoveRight ? 1.0 : 0.5)
            }
            .disabled(!canMoveRight)
            .accessibilityLabel("Move chord right")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.9))
        )
        .floatingShadow()
    }
}

// MARK: - Preview

#Preview("Timeline Items") {
    HStack(spacing: 8) {
        ChordTimelineItem(
            chord: Chord(.C, type: .major),
            index: 0,
            beats: 2,
            numeral: "I",
            isPlaying: false,
            isSelected: false,
            onRemove: {},
            onLongPress: {}
        )

        ChordTimelineItem(
            chord: Chord(.G, type: .dom7),
            index: 1,
            numeral: "V7",
            isPlaying: true,
            isSelected: false,
            onRemove: {},
            onLongPress: {}
        )

        SuggestionChip(chord: Chord(.A, type: .minor), onTap: {})
    }
    .padding()
    .background(Color.appBackground)
    .environment(TheoryEngine())
    .environment(AudioEngine())
}
