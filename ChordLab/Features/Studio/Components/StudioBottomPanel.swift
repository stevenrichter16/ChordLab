//
//  StudioBottomPanel.swift
//  ChordLab
//
//  Bottom panel with chord/note palettes for dragging
//

import SwiftUI
import Tonic

struct StudioBottomPanel: View {
    let trackType: TrackType
    @Binding var selectedDuration: Duration
    let studioSession: StudioSession
    let selectedTrack: Track
    
    @State private var selectedOctave: Int = 4 // Default to octave 4
    @State private var selectedKey: String = "C" // Default to C major
    @State private var showAllNotes: Bool = false // Toggle to show all notes or just scale notes
    
    @Environment(TheoryEngine.self) private var theoryEngine
    
    var body: some View {
        VStack(spacing: 0) {
            // Panel header
            HStack {
                Text(trackType == .chords ? "Chord Palette" : "Note Palette")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if trackType == .melody {
                    HStack(spacing: 8) {
                        // Key selector
                        Menu {
                            ForEach(["C", "G", "D", "A", "E", "B", "F#", "Db", "Ab", "Eb", "Bb", "F"], id: \.self) { key in
                                Button(key) {
                                    selectedKey = key
                                }
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Text("Key:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(selectedKey)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(UIColor.secondarySystemFill))
                            )
                        }
                        .buttonStyle(.plain)
                        
                        // Show all notes toggle
                        Button(action: { showAllNotes.toggle() }) {
                            HStack(spacing: 3) {
                                Image(systemName: showAllNotes ? "music.note.list" : "music.note")
                                    .font(.system(size: 11))
                                Text(showAllNotes ? "All" : "Scale")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(showAllNotes ? Color(UIColor.systemBackground) : Color(UIColor.label))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(showAllNotes ? Color.appPrimary : Color(UIColor.secondarySystemFill))
                            )
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                            .frame(height: 16)
                        
                        // Octave selector
                        OctaveSelector(selectedOctave: $selectedOctave)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor.secondarySystemBackground))
            
            Divider()
            
            // Content based on track type
            switch trackType {
            case .chords:
                ChordPalette(studioSession: studioSession, selectedTrack: selectedTrack)
            case .melody:
                NotePalette(
                    selectedOctave: selectedOctave,
                    selectedKey: selectedKey,
                    showAllNotes: showAllNotes,
                    studioSession: studioSession,
                    selectedTrack: selectedTrack
                )
            case .drums:
                DrumPalette()
            }
        }
    }
}

// MARK: - Chord Palette

struct ChordPalette: View {
    let studioSession: StudioSession
    let selectedTrack: Track
    
    @Environment(TheoryEngine.self) private var theoryEngine
    
    private var availableChords: [(chord: Chord, romanNumeral: String, function: String)] {
        theoryEngine.getDiatonicChordsWithAnalysis().map { item in
            (chord: item.chord, romanNumeral: item.romanNumeral, function: item.function.rawValue)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Diatonic chords
                Text("Diatonic Chords")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                    ForEach(availableChords, id: \.chord.description) { item in
                        ChordDragSource(
                            chord: item.chord,
                            romanNumeral: item.romanNumeral,
                            function: item.function,
                            onTap: {
                                if let selectedBeat = studioSession.selectedBeat {
                                    selectedTrack.setContent(.chord(item.chord), at: selectedBeat)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
                
                // Seventh chords
                Text("Seventh Chords")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                    ForEach(theoryEngine.getSeventhChordsWithAnalysis(), id: \.chord.description) { item in
                        ChordDragSource(
                            chord: item.chord,
                            romanNumeral: item.romanNumeral,
                            function: item.function.rawValue,
                            onTap: {
                                if let selectedBeat = studioSession.selectedBeat {
                                    selectedTrack.setContent(.chord(item.chord), at: selectedBeat)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

struct ChordDragSource: View {
    let chord: Chord
    let romanNumeral: String
    let function: String
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            Text(chord.description)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
            Text(romanNumeral)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 80, height: 50)
        .background(Color.appSecondaryBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.appBorder, lineWidth: 1)
        )
        .onTapGesture {
            onTap()
        }
        .draggable(DraggableChord(chord: chord, romanNumeral: romanNumeral)) {
            // Drag preview
            DragPreview(text: chord.description, color: .blue)
        }
    }
}

// MARK: - Note Palette

struct NotePalette: View {
    let selectedOctave: Int
    let selectedKey: String
    let showAllNotes: Bool
    let studioSession: StudioSession
    let selectedTrack: Track
    
    @Environment(TheoryEngine.self) private var theoryEngine
    @State private var cachedScaleNotes: [NoteClass] = []
    
    // Standard 12 notes in an octave
    private let allNoteClasses: [(Letter, Accidental?)] = [
        (.C, nil), (.C, .sharp), (.D, nil), (.D, .sharp), (.E, nil),
        (.F, nil), (.F, .sharp), (.G, nil), (.G, .sharp), (.A, nil),
        (.A, .sharp), (.B, nil)
    ]
    
    // Get the notes to display based on key and filter settings
    private var displayedNotes: [Note] {
        if showAllNotes {
            // Show all 12 notes
            return allNoteClasses.map { (letter, accidental) in
                if let accidental = accidental {
                    return Note(letter, accidental: accidental, octave: selectedOctave)
                } else {
                    return Note(letter, octave: selectedOctave)
                }
            }
        } else {
            // Show only scale notes for the selected key
            let notes = cachedScaleNotes.map { noteClass in
                Note(noteClass.canonicalNote.letter, 
                     accidental: noteClass.canonicalNote.accidental, 
                     octave: selectedOctave)
            }
            return notes
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
                ForEach(displayedNotes, id: \.description) { note in
                    NoteDragSource(
                        note: note,
                        isInScale: !showAllNotes || isNoteInScale(note),
                        onTap: {
                            if let selectedBeat = studioSession.selectedBeat {
                                // Always use quarter note duration for simplicity
                                selectedTrack.setContent(.note(note, duration: .quarter), at: selectedBeat)
                            }
                        }
                    )
                }
            }
            .padding()
        }
        .onAppear {
            updateScaleNotes()
        }
        .onChange(of: selectedKey) { _, _ in
            updateScaleNotes()
        }
    }
    
    // Helper to check if a note is in the current scale
    private func isNoteInScale(_ note: Note) -> Bool {
        return cachedScaleNotes.contains(note.noteClass)
    }
    
    // Update cached scale notes when key changes
    private func updateScaleNotes() {
        theoryEngine.setKey(selectedKey, scaleType: "major")
        cachedScaleNotes = theoryEngine.getCurrentScaleNotes()
    }
}

struct NoteDragSource: View {
    let note: Note
    let isInScale: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 2) {
            Text(note.noteClass.description)
                .font(.caption)
                .fontWeight(.medium)
            Text("\(note.octave)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 44, height: 44)
        .background(isBlackKey ? Color.black : Color.white)
        .foregroundColor(isBlackKey ? .white : .black)
        .opacity(isInScale ? 1.0 : 0.3)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(
                    isInScale ? Color.appPrimary : Color.appBorder.opacity(0.5),
                    lineWidth: isInScale ? 2 : 1
                )
        )
        .onTapGesture {
            onTap()
        }
        .draggable(DraggableNote(note: note, duration: .quarter)) {
            // Drag preview
            DragPreview(
                text: "\(note.noteClass.description)\(note.octave)",
                color: .green
            )
        }
    }
    
    private var isBlackKey: Bool {
        // Check if the note has a sharp accidental (black keys)
        return note.accidental == .sharp
    }
}

// MARK: - Drum Palette

struct DrumPalette: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                ForEach(DrumType.allCases, id: \.self) { drumType in
                    DrumDragSource(drumType: drumType)
                }
            }
            .padding()
        }
    }
}

struct DrumDragSource: View {
    let drumType: DrumType
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: drumType.icon)
                .font(.title2)
            Text(drumType.rawValue)
                .font(.caption)
        }
        .frame(width: 80, height: 60)
        .background(Color.appSecondaryBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.appBorder, lineWidth: 1)
        )
    }
}

// MARK: - Octave Selector

struct OctaveSelector: View {
    @Binding var selectedOctave: Int
    
    let octaveRange = 2...6 // C2 to C6 is a reasonable range
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(octaveRange, id: \.self) { octave in
                Button(action: { selectedOctave = octave }) {
                    Text("\(octave)")
                        .font(.caption)
                        .fontWeight(selectedOctave == octave ? .medium : .regular)
                        .frame(width: 22, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(selectedOctave == octave ? Color.appPrimary : Color(UIColor.tertiarySystemFill))
                        )
                        .foregroundColor(
                            selectedOctave == octave ? Color(UIColor.systemBackground) : Color(UIColor.label)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Drag Preview

struct DragPreview: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.9))
            .cornerRadius(6)
            .shadow(radius: 4)
    }
}

// MARK: - Preview

#Preview("Chord Palette") {
    struct PreviewWrapper: View {
        @State private var selectedDuration: Duration = .quarter
        let session = StudioSession()
        let track = Track(name: "Chords", type: .chords)
        
        var body: some View {
            StudioBottomPanel(
                trackType: .chords,
                selectedDuration: $selectedDuration,
                studioSession: session,
                selectedTrack: track
            )
            .frame(height: 200)
            .environment(TheoryEngine())
        }
    }
    
    return PreviewWrapper()
}

#Preview("Note Palette") {
    struct PreviewWrapper: View {
        @State private var selectedDuration: Duration = .quarter
        let session = StudioSession()
        let track = Track(name: "Melody", type: .melody)
        
        init() {
            session.selectedBeat = 0 // Set a selected beat for testing
        }
        
        var body: some View {
            StudioBottomPanel(
                trackType: .melody,
                selectedDuration: $selectedDuration,
                studioSession: session,
                selectedTrack: track
            )
            .frame(height: 200)
            .environment(TheoryEngine())
        }
    }
    
    return PreviewWrapper()
}

#Preview("Drum Palette") {
    struct PreviewWrapper: View {
        @State private var selectedDuration: Duration = .quarter
        let session = StudioSession()
        let track = Track(name: "Drums", type: .drums)
        
        var body: some View {
            StudioBottomPanel(
                trackType: .drums,
                selectedDuration: $selectedDuration,
                studioSession: session,
                selectedTrack: track
            )
            .frame(height: 200)
            .environment(TheoryEngine())
        }
    }
    
    return PreviewWrapper()
}
