//
//  CompactChordNoteButton.swift
//  ChordLab
//
//  Compact version of ChordNoteButton for space-efficient display
//

import SwiftUI
import Tonic

struct CompactChordNoteButton: View {
    let note: NoteClass
    let role: ChordToneRole?
    let octave: Int = 4
    
    @State private var isPressed = false
    @Environment(AudioEngine.self) private var audioEngine
    
    private var roleColor: Color {
        switch role {
        case .root:
            return .blue
        case .third:
            return .green
        case .fifth:
            return .orange
        case .seventh:
            return .purple
        case .none:
            return .gray
        }
    }
    
    var body: some View {
        Button(action: playNote) {
            Text(formatNote())
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(roleColor)
                        .opacity(isPressed ? 0.6 : 1.0)
                )
                .overlay(
                    Circle()
                        .strokeBorder(roleColor.opacity(0.3), lineWidth: 1)
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .accessibilityLabel("Play \(note.description), \(roleDescription)")
    }
    
    private func formatNote() -> String {
        note.description
            .replacingOccurrences(of: "♯", with: "#")
            .replacingOccurrences(of: "♭", with: "b")
    }
    
    private var roleDescription: String {
        switch role {
        case .root:
            return "root note"
        case .third:
            return "third"
        case .fifth:
            return "fifth"
        case .seventh:
            return "seventh"
        case .none:
            return "chord tone"
        }
    }
    
    private func playNote() {
        // Play the note immediately
        let tonicNote = Note(
            note.canonicalNote.letter,
            accidental: note.canonicalNote.accidental,
            octave: octave
        )
        audioEngine.playNote(tonicNote)
        
        // Visual feedback
        withAnimation(.easeInOut(duration: 0.1)) {
            isPressed = true
        }
        
        // Reset visual state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Compact Chord Note Buttons")
            .font(.title2)
            .fontWeight(.bold)
        
        // C Major triad
        HStack(spacing: 6) {
            CompactChordNoteButton(note: .C, role: .root)
            CompactChordNoteButton(note: .E, role: .third)
            CompactChordNoteButton(note: .G, role: .fifth)
        }
        
        // G7 chord
        HStack(spacing: 6) {
            CompactChordNoteButton(note: .G, role: .root)
            CompactChordNoteButton(note: .B, role: .third)
            CompactChordNoteButton(note: .D, role: .fifth)
            CompactChordNoteButton(note: .F, role: .seventh)
        }
        
        // Size comparison
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Original:")
                ChordNoteButton(note: .C, role: .root)
            }
            
            HStack {
                Text("Compact:")
                CompactChordNoteButton(note: .C, role: .root)
            }
        }
    }
    .padding()
    .background(Color.appBackground)
    .environment(AudioEngine())
}