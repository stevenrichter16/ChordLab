//
//  ChordNoteButton.swift
//  ChordLab
//
//  Interactive button for chord notes with audio playback
//

import SwiftUI
import Tonic

struct ChordNoteButton: View {
    let note: NoteClass
    let role: ChordToneRole?
    let octave: Int = 4
    
    @State private var isPressed = false
    @Environment(AudioEngine.self) private var audioEngine
    
    private var backgroundColor: Color {
        if isPressed {
            return roleColor.opacity(0.3)
        }
        return Color.appSecondaryBackground
    }
    
    private var borderColor: Color {
        return roleColor.opacity(0.8)
    }
    
    private var textColor: Color {
        if isPressed {
            return roleColor
        }
        return .primary
    }
    
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
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(backgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(borderColor, lineWidth: 2)
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .accessibilityLabel("Play \(note.description), \(roleDescription)")
    }
    
    private func formatNote() -> String {
        note.description
            .replacingOccurrences(of: "#", with: "♯")
            .replacingOccurrences(of: "b", with: "♭")
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
        
        // Visual feedback after
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
        // Example chord: C Major
        HStack(spacing: 8) {
            ChordNoteButton(note: .C, role: .root)
            ChordNoteButton(note: .E, role: .third)
            ChordNoteButton(note: .G, role: .fifth)
        }
        
        // Example chord: D Minor
        HStack(spacing: 8) {
            ChordNoteButton(note: .D, role: .root)
            ChordNoteButton(note: .F, role: .third)
            ChordNoteButton(note: .A, role: .fifth)
        }
    }
    .padding()
    .background(Color.appBackground)
    .environment(AudioEngine())
}
