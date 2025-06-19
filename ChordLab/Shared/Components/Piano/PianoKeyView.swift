//
//  PianoKeyView.swift
//  ChordLab
//
//  Individual piano key component with audio playback
//

import SwiftUI
import Tonic

struct PianoKeyView: View {
    let note: String
    let noteClass: NoteClass
    let octave: Int
    let isHighlighted: Bool
    let isRoot: Bool
    let keyWidth: CGFloat
    let audioEngine: AudioEngine
    let enharmonicSpelling: String?  // New parameter for enharmonic display
    let isOctaveRoot: Bool  // New parameter to indicate this is the root note in the next octave
    
    // Default initializer with optional enharmonicSpelling
    init(note: String,
         noteClass: NoteClass,
         octave: Int,
         isHighlighted: Bool,
         isRoot: Bool,
         keyWidth: CGFloat,
         audioEngine: AudioEngine,
         enharmonicSpelling: String? = nil,
         isOctaveRoot: Bool = false) {
        self.note = note
        self.noteClass = noteClass
        self.octave = octave
        self.isHighlighted = isHighlighted
        self.isRoot = isRoot
        self.keyWidth = keyWidth
        self.audioEngine = audioEngine
        self.enharmonicSpelling = enharmonicSpelling
        self.isOctaveRoot = isOctaveRoot
    }
    
    var isBlackKey: Bool {
        note.contains("#") || note.contains("♯") || note.contains("b") || note.contains("♭")
    }
    
    var body: some View {
        if isBlackKey {
            blackKeyView
        } else {
            whiteKeyView
        }
    }
    
    private var whiteKeyView: some View {
        Rectangle()
            .fill(keyColor)
            .frame(width: keyWidth, height: keyWidth * 3)
            .overlay(
                VStack {
                    Spacer()
                    Text(note)
                        .font(.system(size: max(10, keyWidth * 0.5), weight: isRoot ? .bold : .regular))
                        .foregroundColor(textColor)
                        .minimumScaleFactor(0.5)
                        .padding(.bottom, 4)
                }
            )
            .overlay(
                Rectangle()
                    .stroke(Color.black, lineWidth: 1)
            )
            .onTapGesture {
                playNote()
            }
    }
    
    private var blackKeyView: some View {
        Rectangle()
            .fill(keyColor)
            .frame(width: keyWidth * 0.6, height: keyWidth * 1.75)
            .overlay(
                VStack {
                    Spacer()
                    Text(formatBlackKeyName())
                        .font(.system(size: max(8, keyWidth * 0.3), weight: isRoot ? .bold : .regular))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .padding(.bottom, 4)
                }
            )
            .overlay(
                Rectangle()
                    .stroke(Color.black, lineWidth: 1))
            .onTapGesture {
                playNote()
            }
    }
    
    private var keyColor: Color {
        let baseColor: Color
        
        if isRoot || isOctaveRoot {
            baseColor = isBlackKey ? Color.orange.darker() : Color.orange
        } else if isHighlighted {
            baseColor = isBlackKey ? Color.blue.darker() : Color.blue
        } else {
            baseColor = isBlackKey ? Color.black : Color.white
        }
        
        // Apply lighter opacity for octave root
        return isOctaveRoot ? baseColor.opacity(0.4) : baseColor
    }
    
    private var textColor: Color {
        if isBlackKey {
            return .white
        } else {
            // For white keys, use dark text for better contrast
            return isRoot ? .white : .black
        }
    }
    
    private func formatBlackKeyName() -> String {
        // Replace # with ♯ and b with ♭ for better display
        return formatNoteName(note)
    }
    
    private func formatNoteName(_ name: String) -> String {
        // Replace # with ♯ and b with ♭ for better display
        return name
            .replacingOccurrences(of: "#", with: "♯")
            .replacingOccurrences(of: "b", with: "♭")
    }
    
    private func playNote() {
        // Create a Note object for audio playback
        let note = Note(
            noteClass.canonicalNote.letter,
            accidental: noteClass.canonicalNote.accidental,
            octave: octave
        )
        audioEngine.playNote(note)
    }
}

// Color extension for darker shades
extension Color {
    func darker() -> Color {
        return self.opacity(0.8)
    }
}

// MARK: - Preview

#Preview("White Key") {
    HStack {
        PianoKeyView(
            note: "C",
            noteClass: .C,
            octave: 4,
            isHighlighted: false,
            isRoot: false,
            keyWidth: 40,
            audioEngine: AudioEngine()
        )
        
        PianoKeyView(
            note: "D",
            noteClass: .D,
            octave: 4,
            isHighlighted: true,
            isRoot: false,
            keyWidth: 40,
            audioEngine: AudioEngine()
        )
        
        PianoKeyView(
            note: "E",
            noteClass: .E,
            octave: 4,
            isHighlighted: false,
            isRoot: true,
            keyWidth: 40,
            audioEngine: AudioEngine()
        )
    }
    .padding()
}

#Preview("Black Key") {
    HStack {
        PianoKeyView(
            note: "C#",
            noteClass: .Cs,
            octave: 4,
            isHighlighted: false,
            isRoot: false,
            keyWidth: 40,
            audioEngine: AudioEngine()
        )
        
        PianoKeyView(
            note: "Bb",
            noteClass: .As,
            octave: 4,
            isHighlighted: true,
            isRoot: false,
            keyWidth: 40,
            audioEngine: AudioEngine()
        )
        
        PianoKeyView(
            note: "Gb",
            noteClass: .Fs,
            octave: 4,
            isHighlighted: false,
            isRoot: true,
            keyWidth: 40,
            audioEngine: AudioEngine()
        )
    }
    .padding()
}
