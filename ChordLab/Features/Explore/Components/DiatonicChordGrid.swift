//
//  DiatonicChordGrid.swift
//  ChordLab
//
//  Grid displaying all seven diatonic triads for the selected key
//

import SwiftUI
import Tonic

struct DiatonicChordGrid: View {
    let chords: [(chord: Chord, romanNumeral: String, function: ChordFunction, degreeName: String)]
    @Binding var selectedChord: Chord?
    @Binding var selectedChordIndex: Int?
    let onChordPlay: ((Chord) -> Void)?  // Callback when chord is played
    let onChordHold: ((Chord) -> Void)?  // Callback when chord is held
    
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(TheoryEngine.self) private var theoryEngine
    
    // 2x4 grid layout (7 chords + 1 empty space)
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(chords.enumerated()), id: \.offset) { index, chordData in
                    DiatonicChordButton(
                        chord: chordData.chord,
                        romanNumeral: chordData.romanNumeral,
                        degreeName: chordData.degreeName,
                        function: chordData.function,
                        isSelected: selectedChordIndex == index,
                        action: {
                            // Clear any visualized chord from progression player
                            theoryEngine.visualizedChord = nil
                            
                            // Play chord immediately for instant feedback
                            audioEngine.playChord(chordData.chord, velocity: 80)
                            
                            // Update UI state after
                            selectedChord = chordData.chord
                            selectedChordIndex = index
                            onChordPlay?(chordData.chord)
                        },
                        onLongPress: {
                            onChordHold?(chordData.chord)
                        }
                    )
                }
            }
        }
    }
}

struct DiatonicChordButton: View {
    let chord: Chord
    let romanNumeral: String
    let degreeName: String
    let function: ChordFunction
    let isSelected: Bool
    let action: () -> Void
    let onLongPress: (() -> Void)?
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Chord symbol
            HStack {
                Text(chord.description)
                    .font(.title3)
                    .fontWeight(.bold)
                
                // Roman numeral
                Text("(\(romanNumeral))")
                    .font(.headline)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
            }
            
            // Scale degree name
            Text(degreeName)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary.opacity(0.8))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? functionColor : Color.appSecondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isSelected ? Color.clear : functionColor.opacity(0.3),
                    lineWidth: 2
                )
        )
        .foregroundColor(isSelected ? .white : .primary)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            action()
        }
        .onLongPressGesture(minimumDuration: 0.4) {
            onLongPress?()
        } onPressingChanged: { isPressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = isPressing
            }
        }
    }
    
    private var functionColor: Color {
        switch function {
        case .tonic, .submediant:
            return .blue
        case .subdominant, .supertonic:
            return .green
        case .dominant, .leadingTone:
            return .orange
        default:
            return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedChord: Chord?
        @State private var selectedChordIndex: Int?
        
        let mockChords: [(chord: Chord, romanNumeral: String, function: ChordFunction, degreeName: String)] = [
            (Chord(.C, type: .major), "I", .tonic, "Tonic"),
            (Chord(.D, type: .minor), "ii", .supertonic, "Supertonic"),
            (Chord(.E, type: .minor), "iii", .mediant, "Mediant"),
            (Chord(.F, type: .major), "IV", .subdominant, "Subdominant"),
            (Chord(.G, type: .major), "V", .dominant, "Dominant"),
            (Chord(.A, type: .minor), "vi", .submediant, "Submediant"),
            (Chord(.B, type: .dim), "vii°", .leadingTone, "Leading Tone")
        ]
        
        var body: some View {
            VStack(spacing: 20) {
                Text("DiatonicChordGrid Preview")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let selectedChord = selectedChord {
                    Text("Selected: \(selectedChord.description)")
                        .font(.headline)
                        .foregroundColor(.appPrimary)
                }
                
                DiatonicChordGrid(
                    chords: mockChords,
                    selectedChord: $selectedChord,
                    selectedChordIndex: $selectedChordIndex,
                    onChordPlay: { chord in
                        print("Played chord: \(chord.description)")
                    },
                    onChordHold: { chord in
                        print("Held chord: \(chord.description)")
                    }
                )
                .padding()
                
                Text("Tap to play, long press to add to progression")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
            .environment(AudioEngine())
        }
    }
    
    return PreviewWrapper()
}
