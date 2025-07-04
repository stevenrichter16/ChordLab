//
//  ScrollablePianoView.swift
//  ChordLab
//
//  A horizontally scrollable piano keyboard with multiple octaves
//

import SwiftUI
import Tonic

struct ScrollablePianoView: View {
    @Environment(TheoryEngine.self) private var theoryEngine
    @Environment(AudioEngine.self) private var audioEngine
    
    @State private var playingNotes: Set<String> = []
    @State private var scrollProxy: ScrollViewProxy?
    @State private var cachedScaleNotes: [NoteClass] = []
    @State private var cachedRootNoteClass: NoteClass? = nil
    
    // Configuration
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
                    HStack(spacing: 4) {
                        ForEach(startOctave...endOctave, id: \.self) { octave in
                            OctaveGroupView(
                                octave: octave,
                                whiteKeyWidth: whiteKeyWidth,
                                whiteKeyHeight: whiteKeyHeight,
                                blackKeyWidth: blackKeyWidth,
                                blackKeyHeight: blackKeyHeight,
                                playingNotes: $playingNotes,
                                scaleNotes: cachedScaleNotes,
                                rootNoteClass: cachedRootNoteClass
                            )
                            .id("octave\(octave)")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 2) // Space for octave labels
                }
                .background(Color.appSecondaryBackground)
                .cornerRadius(15)
                .onAppear {
                    scrollProxy = proxy
                    updateCachedNotes()
                    // Center on C4 initially
                    proxy.scrollTo("octave4", anchor: .center)
                }
                .onChange(of: theoryEngine.currentKey) { _, _ in
                    updateCachedNotes()
                    scrollToRootNote()
                }
                .onChange(of: theoryEngine.currentScaleType) { _, _ in
                    updateCachedNotes()
                    scrollToRootNote()
                }
            }
        }
        .frame(height: 95)
    }
    
    private func updateCachedNotes() {
        cachedScaleNotes = theoryEngine.getCurrentScaleNotes()
        cachedRootNoteClass = NoteClass(theoryEngine.currentKey)
    }
    
    private func scrollToRootNote() {
        guard let proxy = scrollProxy else { return }
        
        // Find the octave containing the root note (default to octave 4)
        let targetOctave = 4
        
        withAnimation(.easeOut(duration: 0.3)) {
            proxy.scrollTo("octave\(targetOctave)", anchor: .center)
        }
    }
}


// MARK: - Individual Key View

struct ScrollablePianoKeyView: View {
    let note: String
    let octave: Int
    let isBlack: Bool
    let width: CGFloat
    let height: CGFloat
    @Binding var playingNotes: Set<String>
    let scaleNotes: [NoteClass]
    let rootNoteClass: NoteClass?
    
    @Environment(TheoryEngine.self) private var theoryEngine
    @Environment(AudioEngine.self) private var audioEngine
    
    private var noteIdentifier: String {
        //print("in noteIdentier computed property - note: \(note)")
        return "\(note)\(octave)"
    }
    
    private var isPlaying: Bool {
        playingNotes.contains(noteIdentifier)
    }
    
    // G gets passed into here (in the scale it's f##)
    private var highlightState: KeyHighlightState {
        // noteClass will be .G
        let noteClass = noteClassFromString(note)
        
        let isInScale = scaleNotes.contains { scaleNote in
            scaleNote.canonicalNote.pitch.pitchClass == noteClass.canonicalNote.pitch.pitchClass
        }
        
        let isRoot = rootNoteClass != nil && 
                     noteClass.canonicalNote.pitch.pitchClass == 
                     rootNoteClass!.canonicalNote.pitch.pitchClass
        
        if isPlaying {
            return .playing
        } else if isRoot {
            return .root
        } else if isInScale {
            return .scale
        } else {
            return .none
        }
    }
    
    private var shouldShowLabel: Bool {
        highlightState != .none
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
                .offset(y: highlightState == .root || highlightState == .chord ? -3 : 0)
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
        case .root, .chord:
            return isBlack ? Color(red: 0, green: 81/255, blue: 213/255) : Color.blue // #0051d5 for black keys
        case .scale:
            return isBlack ? Color.black : Color.white
        case .none:
            return isBlack ? Color.black : Color.white
        }
    }
    
    private var borderColor: Color {
        switch highlightState {
        case .scale:
            return Color.green
        case .root:
            return Color.blue.opacity(0.8)
        default:
            return isBlack ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2)
        }
    }
    
    private var borderWidth: CGFloat {
        switch highlightState {
        case .scale:
            return 3  // Green border 3px
        case .root:
            return 2
        default:
            return 1
        }
    }
    
    private var labelColor: Color {
        if isBlack || highlightState == .root || highlightState == .chord || highlightState == .playing {
            return .white
        } else {
            return .black
        }
    }
    
    private var shadowColor: Color {
        switch highlightState {
        case .playing:
            return Color.yellow.opacity(0.8)
        case .root, .chord:
            return Color.blue.opacity(0.6)
        case .scale:
            return Color.clear
        case .none:
            return Color.clear
        }
    }
    
    private var shadowRadius: CGFloat {
        switch highlightState {
        case .playing:
            return 15
        case .root, .chord:
            return 10
        case .scale:
            return 0
        case .none:
            return 0
        }
    }
    
    private var shadowY: CGFloat {
        switch highlightState {
        case .root, .chord:
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
        if note == "C" {
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

// MARK: - Key Highlight State

enum KeyHighlightState {
    case none
    case scale
    case chord
    case root
    case playing
}

// MARK: - Pulsing Animation Modifier

struct PulsingModifier: ViewModifier {
    let isPulsing: Bool
    @State private var opacity: Double = 1.0
    
    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? opacity : 1.0)
            .animation(
                isPulsing ?
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true) :
                    .default,
                value: opacity
            )
            .onAppear {
                if isPulsing {
                    opacity = 0.85
                }
            }
            .onChange(of: isPulsing) { _, newValue in
                opacity = newValue ? 0.85 : 1.0
            }
    }
}

// MARK: - Preview

#Preview {
    ScrollablePianoView()
        .environment(TheoryEngine())
        .environment(AudioEngine())
        .padding()
        .background(Color.appBackground)
}
