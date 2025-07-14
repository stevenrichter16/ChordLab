//
//  ChordFormatter.swift
//  ChordLab
//
//  Created by Steven Richter on 7/9/25.
//


//
//  ChordFormatter.swift
//  ChordLab
//
//  Utilities for formatting and abbreviating chord-related text
//

import Foundation
import Tonic

// MARK: - ChordFormatter

struct ChordFormatter {
    
    // MARK: - Degree Name Formatting
    
    static func abbreviatedDegreeName(_ degreeName: String) -> String {
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
    
    // MARK: - Roman Numeral Formatting
    
    static func abbreviatedRomanNumeral(_ romanNumeral: String) -> String {
        switch romanNumeral {
        case "Imaj7", "IMaj7", "IM7":
            return "IM7"
        case "IVmaj7", "IVMaj7", "IVM7":
            return "IVM7"
        case "iim7", "IIm7", "ii7":
            return "ii7"
        case "iiim7", "IIIm7", "iii7":
            return "iii7"
        case "vim7", "VIm7", "vi7":
            return "vi7"
        case "viim7b5", "VIIm7b5", "viiø7":
            return "viiø7"
        default:
            return romanNumeral
        }
    }
    
    // MARK: - Chord Name Formatting
    
    static func abbreviatedChordName(_ chordDescription: String) -> String {
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
        
        var result = chordDescription
        
        // Replace each pattern
        for (pattern, replacement) in abbreviations {
            result = result.replacingOccurrences(of: pattern, with: replacement)
        }
        
        return result
    }
    
    // Convenience method for Chord objects
    static func abbreviatedChordName(for chord: Chord) -> String {
        abbreviatedChordName(chord.description)
    }
}

// MARK: - Extensions for Convenience

extension Chord {
    /// Returns the abbreviated chord symbol (e.g., "CM7" instead of "Cmaj7")
    var abbreviatedSymbol: String {
        ChordFormatter.abbreviatedChordName(for: self)
    }
}

extension String {
    /// Returns the abbreviated degree name if this string represents a scale degree
    var abbreviatedDegreeName: String {
        ChordFormatter.abbreviatedDegreeName(self)
    }
    
    /// Returns the abbreviated roman numeral if this string represents one
    var abbreviatedRomanNumeral: String {
        ChordFormatter.abbreviatedRomanNumeral(self)
    }
    
    /// Returns the abbreviated chord name if this string represents a chord symbol
    var abbreviatedChordSymbol: String {
        ChordFormatter.abbreviatedChordName(self)
    }
}

// MARK: - Alternative: Formatting Options

extension ChordFormatter {
    enum Style {
        case full           // Cmaj7, Supertonic, IMaj7
        case abbreviated    // CM7, Super., IM7
        case compact        // C△7, ST, I△7 (very short)
        case jazz          // C△7, ii-7, viiø7
    }
    
    static func formatChord(_ chord: Chord, style: Style = .abbreviated) -> String {
        switch style {
        case .full:
            return chord.description
        case .abbreviated:
            return abbreviatedChordName(for: chord)
        case .compact:
            // Even more compact notation
            let root = chord.root.description
            switch chord.type {
            case .maj7:
                return "\(root)△7"
            case .min7:
                return "\(root)-7"
            case .dom7:
                return "\(root)7"
            case .halfDim7:
                return "\(root)ø7"
            case .dim7:
                return "\(root)°7"
            default:
                return abbreviatedChordName(for: chord)
            }
        case .jazz:
            // Jazz notation style
            return chord.description
                .replacingOccurrences(of: "maj7", with: "△7")
                .replacingOccurrences(of: "min7", with: "-7")
                .replacingOccurrences(of: "halfDim7", with: "ø7")
                .replacingOccurrences(of: "m7♭5", with: "ø7")
        }
    }
    
    static func formatDegreeName(_ name: String, style: Style = .abbreviated) -> String {
        switch style {
        case .full:
            return name
        case .abbreviated:
            return abbreviatedDegreeName(name)
        case .compact, .jazz:
            // Very short degree names
            switch name.lowercased() {
            case "tonic": return "T"
            case "supertonic": return "ST"
            case "mediant": return "M"
            case "subdominant": return "SD"
            case "dominant": return "D"
            case "submediant": return "SM"
            case "leading tone", "leadingtone": return "LT"
            default: return name
            }
        }
    }
}
