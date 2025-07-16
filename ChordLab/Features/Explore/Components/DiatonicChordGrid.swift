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
    @Binding var selectedChordType: ChordTypeSelector.ChordType
    let onChordPlay: ((Chord) -> Void)?  // Callback when chord is played
    let onChordHold: ((Chord) -> Void)?  // Callback when chord is held
    let onChordTypeChange: ((ChordTypeSelector.ChordType) -> Void)?  // Callback when chord type changes
    
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(TheoryEngine.self) private var theoryEngine
    
    // Swipe gesture states
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @GestureState private var dragState = DragState.inactive
    
    // 2x4 grid layout (7 chords + 1 empty space)
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // Drag state for gesture
    enum DragState {
        case inactive
        case dragging(translation: CGSize)
        
        var translation: CGSize {
            switch self {
            case .inactive:
                return .zero
            case .dragging(let translation):
                return translation
            }
        }
        
        var isDragging: Bool {
            switch self {
            case .inactive:
                return false
            case .dragging:
                return true
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Chord type indicator with swipe hints
            HStack {
                Image(systemName: "chevron.left")
                    .font(.caption)
                    .foregroundColor(selectedChordType == .triads ? .clear : .secondary.opacity(0.5))
                
                Spacer()
                
                Text(selectedChordType == .triads ? "Triads" : "7ths")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(selectedChordType == .sevenths ? .clear : .secondary.opacity(0.5))
            }
            .padding(.horizontal, 4)
            
            // Grid with swipe gesture
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
            .offset(x: dragState.translation.width)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: dragState.translation)
            .gesture(
                DragGesture()
                    .updating($dragState) { value, state, _ in
                        // Apply rubber band effect at edges
                        let translation = value.translation.width
                        let rubberBandTranslation = rubberBandEffect(translation)
                        state = .dragging(translation: CGSize(width: rubberBandTranslation, height: 0))
                    }
                    .onEnded { value in
                        handleSwipeEnd(value.translation.width)
                    }
            )
        }
    }
    
    // Rubber band effect calculation
    private func rubberBandEffect(_ offset: CGFloat) -> CGFloat {
        let threshold: CGFloat = 0
        let resistance: CGFloat = 0.35
        
        // If we're on triads and swiping left (negative), apply rubber band
        if selectedChordType == .triads && offset < threshold {
            return offset * resistance
        }
        
        // If we're on sevenths and swiping right (positive), apply rubber band
        if selectedChordType == .sevenths && offset > threshold {
            return offset * resistance
        }
        
        // Otherwise, allow full movement
        return offset
    }
    
    // Handle swipe end
    private func handleSwipeEnd(_ offset: CGFloat) {
        let threshold: CGFloat = 50 // Minimum swipe distance to trigger change
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            // Swipe right to go to sevenths (from triads)
            if offset > threshold && selectedChordType == .triads {
                selectedChordType = .sevenths
                onChordTypeChange?(.sevenths)
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
            // Swipe left to go to triads (from sevenths)
            else if offset < -threshold && selectedChordType == .sevenths {
                selectedChordType = .triads
                onChordTypeChange?(.triads)
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
            // Otherwise, snap back (rubber band)
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
    
    // Add this computed property for abbreviated names
    private var abbreviatedDegreeName: String {
        switch degreeName.lowercased() {
        case "tonic":
            return "Tonic"
        case "supertonic":
            return "Super."
        case "mediant":
            return "Med."
        case "subdominant":
            return "Sub Dom."
        case "dominant":
            return "Dom."
        case "submediant":
            return "Sub Med."
        case "leading tone", "leadingtone":
            return "Lead."
        default:
            return degreeName
        }
    }
    
    private var abbreviatedRomanNumeral: String {
        switch romanNumeral {
        case "Imaj7":
            return "IM7"
        case "IVmaj7":
            return "IVM7"
        default:
            return romanNumeral
        
        }
    }
    
    private var abbreviatedChordName: String {
        let description = chord.description
        
        // Common chord abbreviation replacements
        let abbreviations = [
            "maj7": "M7",
            "min7": "m7",
            "dom7": "7",
            "dim7": "°7",
            "halfDim7": "ø7",
            "m7♭5": "ø7",
            "maj": "M",
            "min": "m",
            "dim": "°",
            "aug": "+",
            "sus4": "sus",
            "sus2": "sus2"
        ]
        
        var result = description
        
        // Replace each pattern
        for (pattern, replacement) in abbreviations {
            result = result.replacingOccurrences(of: pattern, with: replacement)
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chord symbol
            HStack {
                Text(abbreviatedChordName)
                    .font(.title3)
                    .fontWeight(.bold)
                
                // Roman numeral
                Text("(\(abbreviatedRomanNumeral))")
                    .font(.headline)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
            }
            
            // Scale degree name
            Text(abbreviatedDegreeName)
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
        
        .accessibilityLabel("\(chord.description)")
        .accessibilityElement(children: .contain)  // Keep children accessible but group them
        .accessibilityIdentifier("chord-button-\(chord.description)")
        .accessibilityHint("Tap to play, long press to add to progression")
        .accessibilityAddTraits(.isButton)
        
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
        @State private var selectedChordType: ChordTypeSelector.ChordType = .triads
        
        let mockTriads: [(chord: Chord, romanNumeral: String, function: ChordFunction, degreeName: String)] = [
            (Chord(.C, type: .major), "I", .tonic, "Tonic"),
            (Chord(.D, type: .minor), "ii", .supertonic, "Supertonic"),
            (Chord(.E, type: .minor), "iii", .mediant, "Mediant"),
            (Chord(.F, type: .major), "IV", .subdominant, "Subdominant"),
            (Chord(.G, type: .major), "V", .dominant, "Dominant"),
            (Chord(.A, type: .minor), "vi", .submediant, "Submediant"),
            (Chord(.B, type: .dim), "vii°", .leadingTone, "Leading Tone")
        ]
        
        let mockSevenths: [(chord: Chord, romanNumeral: String, function: ChordFunction, degreeName: String)] = [
            (Chord(.C, type: .maj7), "IM7", .tonic, "Tonic"),
            (Chord(.D, type: .min7), "ii7", .supertonic, "Supertonic"),
            (Chord(.E, type: .min7), "iii7", .mediant, "Mediant"),
            (Chord(.F, type: .maj7), "IVM7", .subdominant, "Subdominant"),
            (Chord(.G, type: .dom7), "V7", .dominant, "Dominant"),
            (Chord(.A, type: .min7), "vi7", .submediant, "Submediant"),
            (Chord(.B, type: .halfDim7), "viiø7", .leadingTone, "Leading Tone")
        ]
        
        var currentChords: [(chord: Chord, romanNumeral: String, function: ChordFunction, degreeName: String)] {
            selectedChordType == .triads ? mockTriads : mockSevenths
        }
        
        var body: some View {
            VStack(spacing: 20) {
                Text("Swipeable DiatonicChordGrid")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("← Swipe to change between Triads and 7ths →")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let selectedChord = selectedChord {
                    Text("Selected: \(selectedChord.description)")
                        .font(.headline)
                        .foregroundColor(.appPrimary)
                }
                
                DiatonicChordGrid(
                    chords: currentChords,
                    selectedChord: $selectedChord,
                    selectedChordIndex: $selectedChordIndex,
                    selectedChordType: $selectedChordType,
                    onChordPlay: { chord in
                        print("Played chord: \(chord.description)")
                    },
                    onChordHold: { chord in
                        print("Held chord: \(chord.description)")
                    },
                    onChordTypeChange: { newType in
                        print("Changed to: \(newType)")
                        // Clear selection when type changes
                        selectedChord = nil
                        selectedChordIndex = nil
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
            .environment(TheoryEngine())
        }
    }
    
    return PreviewWrapper()
}
