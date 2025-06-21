//
//  OctaveGroupView.swift
//  ChordLab
//
//  Created by Steven Richter on 6/21/25.
//

import CoreFoundation
import CoreGraphics
import Tonic
import SwiftUI


// MARK: - Octave Group View

struct OctaveGroupView: View {
    let octave: Int
    let whiteKeyWidth: CGFloat
    let whiteKeyHeight: CGFloat
    let blackKeyWidth: CGFloat
    let blackKeyHeight: CGFloat
    @Binding var playingNotes: Set<String>
    let scaleNotes: [NoteClass]
    let rootNoteClass: NoteClass?
    
    @Environment(TheoryEngine.self) private var theoryEngine
    @Environment(AudioEngine.self) private var audioEngine
    
    private let whiteKeys = ["C", "D", "E", "F", "G", "A", "B"]
    private let blackKeyPositions: [(sharpNote: String, flatNote: String, position: CGFloat)] = [
        ("C#", "Db", 21), ("D#", "Eb", 50), ("F#", "Gb", 108), ("G#", "Ab", 137), ("A#", "Bb", 166)
    ]
    
    private func getCorrectEnharmonic(sharp: String, flat: String) -> String {
        // If the key prefers flats and this note is in the scale, use flat
        if theoryEngine.currentKeyPrefersFlats() {
            // Check if this black key pitch is in the scale
            let sharpNoteClass = NoteClass(sharp.replacingOccurrences(of: "#", with: "♯"))
            if let noteClass = sharpNoteClass {
                let pitchClass = noteClass.canonicalNote.pitch.pitchClass
                
                // Check if this pitch class is in the scale
                for scaleNote in scaleNotes {
                    if scaleNote.canonicalNote.pitch.pitchClass == pitchClass {
                        // This black key is in the scale, use the flat spelling
                        print("in getCorrectHarminic - flat: \(flat)")
                        return flat
                    }
                }
            }
        }
        
        // Default to sharp for sharp keys or non-scale notes
        //print("in getCorrectHarmonic - sharp: \(sharp)")
        return sharp
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Piano keys
            ZStack(alignment: .topLeading) {
                // White keys
                HStack(spacing: 1) {
                    ForEach(whiteKeys, id: \.self) { note in
                        ScrollablePianoKeyView(
                            note: note,
                            octave: octave,
                            isBlack: false,
                            width: whiteKeyWidth,
                            height: whiteKeyHeight,
                            playingNotes: $playingNotes,
                            scaleNotes: scaleNotes,
                            rootNoteClass: rootNoteClass
                        )
                    }
                }
                
                // Black keys with absolute positioning
                ForEach(blackKeyPositions, id: \.position) { keyData in
                    let displayNote = getCorrectEnharmonic(sharp: keyData.sharpNote, flat: keyData.flatNote)
                    var a = print("Display note:", displayNote)
                    
                    ScrollablePianoKeyView(
                        note: displayNote,
                        octave: octave,
                        isBlack: true,
                        width: blackKeyWidth,
                        height: blackKeyHeight,
                        playingNotes: $playingNotes,
                        scaleNotes: scaleNotes,
                        rootNoteClass: rootNoteClass
                    )
                    .offset(x: keyData.position)
                }
            }
        }
    }
}
