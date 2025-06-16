//
//  Tonic+Extensions.swift
//  ChordLab
//
//  Extensions for the Tonic music theory library
//

import Foundation
import Tonic

// Note: Tonic's Note type already provides access to MIDI note number via note.pitch.midiNoteNumber

extension Chord {
    /// Get the symbol representation of this chord
    var symbol: String {
        return description
    }
    
    /// Check if this chord contains a specific note class
    func contains(_ noteClass: NoteClass) -> Bool {
        return noteClasses.contains(noteClass)
    }
    
    /// Get the chord quality as a string
    var quality: String {
        // Return the chord type description
        return type.description
    }
}

extension NoteClass {
    /// Initialize from string representation
    init?(_ string: String) {
        switch string {
        case "C": self = .C
        case "C♯", "C#": self = .Cs
        case "D♭", "Db": self = .Db
        case "D": self = .D
        case "D♯", "D#": self = .Ds
        case "E♭", "Eb": self = .Eb
        case "E": self = .E
        case "F": self = .F
        case "F♯", "F#": self = .Fs
        case "G♭", "Gb": self = .Gb
        case "G": self = .G
        case "G♯", "G#": self = .Gs
        case "A♭", "Ab": self = .Ab
        case "A": self = .A
        case "A♯", "A#": self = .As
        case "B♭", "Bb": self = .Bb
        case "B": self = .B
        default: return nil
        }
    }
}

extension Interval {
    /// Common interval names
    var name: String {
        switch semitones {
        case 0: return "Unison"
        case 1: return "Minor 2nd"
        case 2: return "Major 2nd"
        case 3: return "Minor 3rd"
        case 4: return "Major 3rd"
        case 5: return "Perfect 4th"
        case 6: return "Tritone"
        case 7: return "Perfect 5th"
        case 8: return "Minor 6th"
        case 9: return "Major 6th"
        case 10: return "Minor 7th"
        case 11: return "Major 7th"
        case 12: return "Octave"
        default: return "\(semitones) semitones"
        }
    }
}