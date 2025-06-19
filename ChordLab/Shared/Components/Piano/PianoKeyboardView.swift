//
//  PianoKeyboardView.swift
//  ChordLab
//
//  Advanced piano keyboard visualization with multi-octave support
//

import SwiftUI
import Tonic

struct PianoKeyboardView: View {
    @Environment(TheoryEngine.self) private var theoryEngine
    @Environment(AudioEngine.self) private var audioEngine
    
    let startOctave: Int
    let octaveCount: Int
    let keyWidth: CGFloat
    let startFromRootNote: Bool
    
    // Standard piano key pattern for one octave
    let whiteKeys = ["C", "D", "E", "F", "G", "A", "B"]
    
    // Black key positions and their pitch classes
    let blackKeyData: [(position: Double, sharpName: String, flatName: String, noteClass: NoteClass)] = [
        (0.5, "C#", "Db", .Cs),
        (1.5, "D#", "Eb", .Ds),
        (3.5, "F#", "Gb", .Fs),
        (4.5, "G#", "Ab", .Gs),
        (5.5, "A#", "Bb", .As)
    ]
    
    private var rootNote: String {
        theoryEngine.currentKey
    }
    
    // Compute the ordered white keys starting from the root note
    private var orderedWhiteKeys: [String] {
        guard startFromRootNote else { return whiteKeys }
        
        // Find the index of the root note letter (ignoring sharps/flats)
        let rootLetter = rootNote.first.map(String.init) ?? "C"
        guard let startIndex = whiteKeys.firstIndex(of: rootLetter) else { return whiteKeys }
        
        // Reorder the keys to start from the root note
        return Array(whiteKeys[startIndex...] + whiteKeys[..<startIndex])
    }
    
    // Get the enharmonic spelling for a white key if it exists in the current scale
    private func getEnharmonicSpelling(for whiteKeyNote: String) -> String? {
        let scaleNotes = theoryEngine.getCurrentScaleNotes()
        let whiteKeyNoteClass = noteClassFromString(whiteKeyNote)
        let whiteKeyPitchClass = whiteKeyNoteClass.canonicalNote.pitch.pitchClass
        
        // Check if any scale note has the same pitch class but different spelling
        for scaleNote in scaleNotes {
            let scalePitchClass = scaleNote.canonicalNote.pitch.pitchClass
            
            // If pitch classes match but the note names are different, we have an enharmonic
            if scalePitchClass == whiteKeyPitchClass &&
               scaleNote.description != whiteKeyNote {
                return scaleNote.description
            }
        }
        
        return nil
    }
    
    // Computed property to determine octave range
    private var octaveRange: ClosedRange<Int> {
        startOctave...(startOctave + octaveCount - 1)
    }
    
    // Initialize with octave range (default to 2 octaves starting at C3)
    init(startOctave: Int = 3, octaveCount: Int = 2, keyWidth: CGFloat = 20, startFromRootNote: Bool = false) {
        self.startOctave = startOctave
        self.octaveCount = octaveCount
        self.keyWidth = keyWidth
        self.startFromRootNote = startFromRootNote
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(octaveRange), id: \.self) { currentOctave in
                octaveView(for: currentOctave)
            }
        }
        .frame(height: keyWidth * 4)
    }
    
    @ViewBuilder
    private func octaveView(for octave: Int) -> some View {
        ZStack(alignment: .topLeading) {
            whiteKeysView(for: octave)
            blackKeysView(for: octave)
        }
        
        // Add separator between octaves
        if octave < octaveRange.upperBound {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1, height: keyWidth * 4)
        }
    }
    
    @ViewBuilder
    private func whiteKeysView(for octave: Int) -> some View {
        HStack(spacing: 1) {
            ForEach(Array(orderedWhiteKeys.enumerated()), id: \.offset) { index, note in
                whiteKeyView(note: note, octave: octave, isLastKey: false)
            }
            
            // Add the root note of the next octave when in scale mode
            if startFromRootNote {
                let rootLetter = rootNote.first.map(String.init) ?? "C"
                whiteKeyView(note: rootLetter, octave: octave + 1, isLastKey: true)
            }
        }
    }
        
    @ViewBuilder
    private func whiteKeyView(note: String, octave: Int, isLastKey: Bool) -> some View {
        let noteClass = noteClassFromString(note)
        let isHighlighted = shouldHighlightKey(noteClass: noteClass)
        let isRoot = isRootNote(noteClass: noteClass)
        let enharmonicSpelling = isHighlighted ? getEnharmonicSpelling(for: note) : nil
        
        PianoKeyView(
            note: note,
            noteClass: noteClass,
            octave: octave,
            isHighlighted: isHighlighted,
            isRoot: isRoot,
            keyWidth: keyWidth,
            audioEngine: audioEngine,
            enharmonicSpelling: enharmonicSpelling,
            isOctaveRoot: isLastKey && isRoot
        )
        // Temporarily disabled overlay to debug
        // .overlay(alignment: .bottom) {
        //     if note == "C" {
        //         octaveLabel(octave)
        //     }
        // }
    }
    
    @ViewBuilder
    private func blackKeysView(for octave: Int) -> some View {
        ForEach(getOrderedBlackKeys(), id: \.sharpName) { keyData in
            blackKeyView(keyData: keyData, octave: octave)
        }
    }
    
    // Get black keys ordered according to the current white key ordering
    private func getOrderedBlackKeys() -> [(position: Double, sharpName: String, flatName: String, noteClass: NoteClass)] {
        guard startFromRootNote else { return blackKeyData }
        
        let rootLetter = rootNote.first.map(String.init) ?? "C"
        guard let startIndex = whiteKeys.firstIndex(of: rootLetter) else { return blackKeyData }
        
        // Map old positions to new positions based on the reordering
        return blackKeyData.compactMap { keyData in
            // Calculate the original white key index
            let originalWhiteKeyIndex = Int(keyData.position)
            
            // Calculate new position based on the rotation
            let newWhiteKeyIndex = (originalWhiteKeyIndex - startIndex + 7) % 7
            let fractionalPart = keyData.position - Double(originalWhiteKeyIndex)
            let newPosition = Double(newWhiteKeyIndex) + fractionalPart
            
            return (position: newPosition, sharpName: keyData.sharpName, flatName: keyData.flatName, noteClass: keyData.noteClass)
        }.filter { $0.position >= 0 && $0.position < 6.5 } // Keep only keys that fit in one octave
    }
    
    @ViewBuilder
    private func blackKeyView(keyData: (position: Double, sharpName: String, flatName: String, noteClass: NoteClass), octave: Int) -> some View {
        let prefersFlats = theoryEngine.currentKeyPrefersFlats()
        let displayNote = prefersFlats ? keyData.flatName : keyData.sharpName
        let isHighlighted = shouldHighlightKey(noteClass: keyData.noteClass)
        let isRoot = isRootNote(noteClass: keyData.noteClass)
        
        PianoKeyView(
            note: displayNote,
            noteClass: keyData.noteClass,
            octave: octave,
            isHighlighted: isHighlighted,
            isRoot: isRoot,
            keyWidth: keyWidth,
            audioEngine: audioEngine,
            enharmonicSpelling: nil
        )
        .offset(x: (keyData.position * (keyWidth + 1)) + (keyWidth * 0.2))
    }
    
    @ViewBuilder
    private func octaveLabel(_ octave: Int) -> some View {
        Text("\(octave)")
            .font(.system(size: 8))
            .foregroundColor(.gray)
            .padding(.bottom, 2)
    }
    
    private func shouldHighlightKey(noteClass: NoteClass) -> Bool {
        let scaleNotes = theoryEngine.getCurrentScaleNotes()
        
        // Compare by pitch class instead of NoteClass
        // This automatically handles enharmonic equivalents
        let keyPitchClass = noteClass.canonicalNote.pitch.pitchClass
        
        return scaleNotes.contains { scaleNote in
            scaleNote.canonicalNote.pitch.pitchClass == keyPitchClass
        }
    }
    
    private func isRootNote(noteClass: NoteClass) -> Bool {
        if let rootNoteClass = NoteClass(rootNote) {
            // Compare by pitch class for enharmonic equivalence
            return noteClass.canonicalNote.pitch.pitchClass ==
                   rootNoteClass.canonicalNote.pitch.pitchClass
        }
        return false
    }
    
    private func noteClassFromString(_ note: String) -> NoteClass {
        // Convert string note to NoteClass
        // Handle sharps and flats including enharmonics
        switch note {
        case "C": return .C
        case "C#", "C♯": return .Cs
        case "Cb", "C♭": return .Cb
        case "D": return .D
        case "D#", "D♯": return .Ds
        case "Db", "D♭": return .Db
        case "E": return .E
        case "E#", "E♯": return .Es
        case "Eb", "E♭": return .Eb
        case "F": return .F
        case "F#", "F♯": return .Fs
        case "Fb", "F♭": return .Fb
        case "G": return .G
        case "G#", "G♯": return .Gs
        case "Gb", "G♭": return .Gb
        case "A": return .A
        case "A#", "A♯": return .As
        case "Ab", "A♭": return .Ab
        case "B": return .B
        case "B#", "B♯": return .Bs
        case "Bb", "B♭": return .Bb
        default: return .C
        }
    }
}

// MARK: - Preview

#Preview {
    PianoKeyboardView()
        .environment(TheoryEngine())
        .environment(AudioEngine())
        .padding()
}
