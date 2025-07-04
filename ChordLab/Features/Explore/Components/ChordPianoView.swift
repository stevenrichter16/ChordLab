//
//  ChordPianoView.swift
//  ChordLab
//
//  Piano visualization for chord display in PCV
//  Refactored to match ScrollablePianoView UI
//

import SwiftUI
import Tonic

struct ChordPianoView: View {
    let highlightedChord: Chord?
    let currentKey: String
    @Binding var playingChordNotes: Set<String>  // Binding from parent
    
    @Environment(TheoryEngine.self) private var theoryEngine
    @Environment(AudioEngine.self) private var audioEngine
    
    @State private var playingNotes: Set<String> = []
    @State private var scrollProxy: ScrollViewProxy?
    @State private var cachedChordNotes: [NoteClass] = []
    @State private var cachedChordToneRoles: [NoteClass: ChordToneRole] = [:]
    
    // Configuration - matching ScrollablePianoView
    private let startOctave = 2
    private let endOctave = 6
    private let whiteKeyWidth: CGFloat = 28
    private let whiteKeyHeight: CGFloat = 100
    private let blackKeyWidth: CGFloat = 20
    private let blackKeyHeight: CGFloat = 65
    
    var body: some View {
        VStack(spacing: 10) {
            // Scrollable piano keyboard
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {  // Increased spacing from 4 to 8
                        ForEach(startOctave...endOctave, id: \.self) { octave in
                            ChordOctaveGroupView(
                                octave: octave,
                                whiteKeyWidth: whiteKeyWidth,
                                whiteKeyHeight: whiteKeyHeight,
                                blackKeyWidth: blackKeyWidth,
                                blackKeyHeight: blackKeyHeight,
                                playingNotes: $playingNotes,
                                chordNotes: cachedChordNotes,
                                chordToneRoles: cachedChordToneRoles,
                                playingChordNotes: $playingChordNotes
                            )
                            .id("octave\(octave)")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 15)      // Increased top padding for octave labels
                    .padding(.bottom, 5)    // Some bottom padding
                }
                .background(Color.appSecondaryBackground)
                .cornerRadius(15)
                .onAppear {
                    scrollProxy = proxy
                    updateCachedChordNotes()
                    // Center on C4 initially
                    proxy.scrollTo("octave4", anchor: .center)
                }
                .onChange(of: highlightedChord) { _, _ in
                    updateCachedChordNotes()
                    if highlightedChord != nil {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("octave4", anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(height: 120)  // Increased from 95 to accommodate octave labels
    }
    
    private func updateCachedChordNotes() {
        guard let chord = highlightedChord else {
            cachedChordNotes = []
            cachedChordToneRoles = [:]
            return
        }
        
        cachedChordNotes = chord.noteClasses
        
        // Get chord tone roles and convert to our internal enum
        let roles = theoryEngine.getChordToneRoles(for: chord)
        var roleMap: [NoteClass: ChordToneRole] = [:]
        
        for (index, role) in roles.enumerated() {
            switch role.role {
            case "Root":
                roleMap[role.note] = .root
            case "Third":
                roleMap[role.note] = .third
            case "Fifth":
                roleMap[role.note] = .fifth
            case "Seventh":
                roleMap[role.note] = .seventh
            default:
                break
            }
        }
        
        cachedChordToneRoles = roleMap
    }
}

// MARK: - Chord Tone Role Enum

enum ChordToneRole {
    case root
    case third
    case fifth
    case seventh
}

// MARK: - Chord Octave Group View

struct ChordOctaveGroupView: View {
    let octave: Int
    let whiteKeyWidth: CGFloat
    let whiteKeyHeight: CGFloat
    let blackKeyWidth: CGFloat
    let blackKeyHeight: CGFloat
    @Binding var playingNotes: Set<String>
    let chordNotes: [NoteClass]
    let chordToneRoles: [NoteClass: ChordToneRole]
    @Binding var playingChordNotes: Set<String>
    
    @Environment(TheoryEngine.self) private var theoryEngine
    @Environment(AudioEngine.self) private var audioEngine
    
    private let whiteKeys = ["C", "D", "E", "F", "G", "A", "B"]
    private let blackKeyPositions: [(sharpNote: String, flatNote: String, position: CGFloat)] = [
        ("C#", "Db", 21), ("D#", "Eb", 50), ("F#", "Gb", 108), ("G#", "Ab", 137), ("A#", "Bb", 166)
    ]
    
    private func getCorrectEnharmonic(sharp: String, flat: String) -> String {
        // If the key prefers flats, use flat
        if theoryEngine.currentKeyPrefersFlats() {
            return flat
        }
        return sharp
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Piano keys
            ZStack(alignment: .topLeading) {
                // White keys
                HStack(spacing: 1) {
                    ForEach(whiteKeys, id: \.self) { note in
                        ChordPianoKeyView(
                            note: note,
                            octave: octave,
                            isBlack: false,
                            width: whiteKeyWidth,
                            height: whiteKeyHeight,
                            playingNotes: $playingNotes,
                            chordNotes: chordNotes,
                            chordToneRoles: chordToneRoles,
                            playingChordNotes: $playingChordNotes
                        )
                    }
                }
                
                // Black keys with absolute positioning
                ForEach(blackKeyPositions, id: \.position) { keyData in
                    let displayNote = getCorrectEnharmonic(sharp: keyData.sharpNote, flat: keyData.flatNote)
                    
                    ChordPianoKeyView(
                        note: displayNote,
                        octave: octave,
                        isBlack: true,
                        width: blackKeyWidth,
                        height: blackKeyHeight,
                        playingNotes: $playingNotes,
                        chordNotes: chordNotes,
                        chordToneRoles: chordToneRoles,
                        playingChordNotes: $playingChordNotes
                    )
                    .offset(x: keyData.position)
                }
            }
            .overlay(alignment: .trailing) {
                // Vertical separator line
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1)
                    .padding(.vertical, 10)
            }
            .overlay(alignment: .topLeading) {
                // Octave label
                Text("C\(octave)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - Individual Chord Piano Key View

struct ChordPianoKeyView: View {
    let note: String
    let octave: Int
    let isBlack: Bool
    let width: CGFloat
    let height: CGFloat
    @Binding var playingNotes: Set<String>
    let chordNotes: [NoteClass]
    let chordToneRoles: [NoteClass: ChordToneRole]
    @Binding var playingChordNotes: Set<String>
    
    @Environment(TheoryEngine.self) private var theoryEngine
    @Environment(AudioEngine.self) private var audioEngine
    
    private var noteIdentifier: String {
        return "\(note)\(octave)"
    }
    
    private var isPlaying: Bool {
        playingNotes.contains(noteIdentifier)
    }
    
    private var highlightState: ChordKeyHighlightState {
        let noteClass = noteClassFromString(note)
        
        // Check if this specific note (with octave) is playing as part of the chord
        let isPlayingInChord = playingChordNotes.contains(noteIdentifier)
        
        // Check if this note is in the chord
        let isInChord = chordNotes.contains { chordNote in
            chordNote.canonicalNote.pitch.pitchClass == noteClass.canonicalNote.pitch.pitchClass
        }
        
        if isPlaying {
            return .playing
        } else if isInChord {
            // Determine which chord tone this is
            if let role = chordToneRoles.first(where: { $0.key.canonicalNote.pitch.pitchClass == noteClass.canonicalNote.pitch.pitchClass })?.value {
                // If this specific note is playing as part of the chord, return a playing variant
                if isPlayingInChord {
                    switch role {
                    case .root:
                        return .rootPlaying
                    case .third:
                        return .thirdPlaying
                    case .fifth:
                        return .fifthPlaying
                    case .seventh:
                        return .seventhPlaying
                    }
                } else {
                    // Not playing, just highlighted as part of chord structure
                    switch role {
                    case .root:
                        return .root
                    case .third:
                        return .third
                    case .fifth:
                        return .fifth
                    case .seventh:
                        return .seventh
                    }
                }
            }
            return .none
        } else {
            return .none
        }
    }
    
    private var shouldShowLabel: Bool {
        highlightState != .none || (note == "C" && highlightState != .none)
    }
    
    var body: some View {
        Button(action: playNote) {
            RoundedRectangle(cornerRadius: isBlack ? 3 : 4)
                .fill(keyColor)
                .frame(width: width, height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: isBlack ? 3 : 4)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .overlay(alignment: .bottom) {
                    if shouldShowLabel {
                        Text(formatKeyLabel())
                            .font(.system(size: isBlack ? 9 : 10, weight: .semibold))
                            .foregroundColor(labelColor)
                            .padding(.bottom, isBlack ? 4 : 8)
                    }
                }
                .scaleEffect(isPlaying ? 0.95 : 1.0)
                .offset(y: {
                    switch highlightState {
                    case .root, .third, .fifth, .seventh:
                        return -3
                    case .rootPlaying, .thirdPlaying, .fifthPlaying, .seventhPlaying:
                        return -5  // More offset when playing
                    default:
                        return 0
                    }
                }())
                .offset(y: isPlaying ? 3 : 0)
                .shadow(
                    color: shadowColor,
                    radius: shadowRadius,
                    x: 0,
                    y: shadowY
                )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.1), value: isPlaying)
        .animation(.easeInOut(duration: 0.3), value: highlightState)
        .modifier(PulsingModifier(isPulsing: highlightState == .root))
    }
    
    private var keyColor: Color {
        switch highlightState {
        case .playing:
            return Color(red: 1.0, green: 0.8, blue: 0.0) // Yellow (#ffcc00)
        case .root:
            return isBlack ? Color(red: 0, green: 81/255, blue: 213/255) : Color.blue
        case .third:
            return isBlack ? Color(red: 0, green: 153/255, blue: 51/255) : Color.green
        case .fifth:
            return isBlack ? Color(red: 230/255, green: 126/255, blue: 0) : Color.orange
        case .seventh:
            return isBlack ? Color(red: 128/255, green: 0, blue: 128/255) : Color.purple
        case .rootPlaying:
            return Color.blue.opacity(0.8)  // Brighter blue when playing
        case .thirdPlaying:
            return Color.green.opacity(0.8)  // Brighter green when playing
        case .fifthPlaying:
            return Color.orange.opacity(0.8)  // Brighter orange when playing
        case .seventhPlaying:
            return Color.purple.opacity(0.8)  // Brighter purple when playing
        case .none:
            return isBlack ? Color.black : Color.white
        }
    }
    
    private var borderColor: Color {
        switch highlightState {
        case .root, .rootPlaying:
            return Color.blue.opacity(highlightState == .rootPlaying ? 1.0 : 0.8)
        case .third, .thirdPlaying:
            return Color.green.opacity(highlightState == .thirdPlaying ? 1.0 : 0.8)
        case .fifth, .fifthPlaying:
            return Color.orange.opacity(highlightState == .fifthPlaying ? 1.0 : 0.8)
        case .seventh, .seventhPlaying:
            return Color.purple.opacity(highlightState == .seventhPlaying ? 1.0 : 0.8)
        default:
            return isBlack ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2)
        }
    }
    
    private var borderWidth: CGFloat {
        switch highlightState {
        case .root, .third, .fifth, .seventh:
            return 2
        case .rootPlaying, .thirdPlaying, .fifthPlaying, .seventhPlaying:
            return 3  // Thicker border when playing
        default:
            return 1
        }
    }
    
    private var labelColor: Color {
        if isBlack || highlightState != .none {
            return .white
        } else {
            return .black
        }
    }
    
    private var shadowColor: Color {
        switch highlightState {
        case .playing:
            return Color.yellow.opacity(0.8)
        case .root:
            return Color.blue.opacity(0.6)
        case .third:
            return Color.green.opacity(0.6)
        case .fifth:
            return Color.orange.opacity(0.6)
        case .seventh:
            return Color.purple.opacity(0.6)
        case .rootPlaying:
            return Color.blue  // Full opacity when playing
        case .thirdPlaying:
            return Color.green
        case .fifthPlaying:
            return Color.orange
        case .seventhPlaying:
            return Color.purple
        case .none:
            return Color.clear
        }
    }
    
    private var shadowRadius: CGFloat {
        switch highlightState {
        case .playing:
            return 15
        case .root, .third, .fifth, .seventh:
            return 10
        case .rootPlaying, .thirdPlaying, .fifthPlaying, .seventhPlaying:
            return 20  // Larger glow when playing
        case .none:
            return 0
        }
    }
    
    private var shadowY: CGFloat {
        switch highlightState {
        case .root, .third, .fifth, .seventh:
            return 5
        case .rootPlaying, .thirdPlaying, .fifthPlaying, .seventhPlaying:
            return 5
        default:
            return 0
        }
    }
    
    private func formatKeyLabel() -> String {
        let formattedNote = note
            .replacingOccurrences(of: "#", with: "♯")
            .replacingOccurrences(of: "b", with: "♭")
        
        // Show octave number for C notes
        if true {
            return "\(formattedNote)\(octave)"
        } else {
            return formattedNote
        }
    }
    
    private func playNote() {
        // Add playing animation
        playingNotes.insert(noteIdentifier)
        
        // Play the note
        let noteClass = noteClassFromString(note)
        let tonicNote = Note(
            noteClass.canonicalNote.letter,
            accidental: noteClass.canonicalNote.accidental,
            octave: octave
        )
        audioEngine.playNote(tonicNote)
        
        // Remove playing state after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            playingNotes.remove(noteIdentifier)
        }
    }
    
    private func noteClassFromString(_ note: String) -> NoteClass {
        switch note {
        case "C": return .C
        case "C#", "C♯": return .Cs
        case "D": return .D
        case "D#", "D♯": return .Ds
        case "Db", "D♭": return .Db
        case "E": return .E
        case "Eb", "E♭": return .Eb
        case "F": return .F
        case "F#", "F♯": return .Fs
        case "G": return .G
        case "G#", "G♯": return .Gs
        case "Gb", "G♭": return .Gb
        case "A": return .A
        case "A#", "A♯": return .As
        case "Ab", "A♭": return .Ab
        case "B": return .B
        case "Bb", "B♭": return .Bb
        default: return .C
        }
    }
}

// MARK: - Chord Key Highlight State

enum ChordKeyHighlightState {
    case none
    case root
    case third
    case fifth
    case seventh
    case rootPlaying
    case thirdPlaying
    case fifthPlaying
    case seventhPlaying
    case playing  // Individual note playing (not chord)
}

// MARK: - Preview

#Preview {
    VStack {
        ChordPianoView(
            highlightedChord: Chord(.C, type: .major),
            currentKey: "C",
            playingChordNotes: .constant(Set<String>())
        )
        .frame(height: 120)
        .padding()
    }
    .background(Color.appBackground)
    .environment(TheoryEngine())
    .environment(AudioEngine())
}
