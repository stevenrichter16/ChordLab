//
//  ChordFunction.swift
//  ChordLab
//
//  Chord function enumeration for harmonic analysis
//

import Foundation

enum ChordFunction: String, CaseIterable {
    case tonic = "Tonic"
    case supertonic = "Supertonic"
    case mediant = "Mediant"
    case subdominant = "Subdominant"
    case dominant = "Dominant"
    case submediant = "Submediant"
    case leadingTone = "Leading Tone"
    case secondaryDominant = "Secondary Dominant"
    case neapolitan = "Neapolitan"
    case augmentedSixth = "Augmented Sixth"
    case borrowed = "Borrowed"
    case chromatic = "Chromatic"
    
    var abbreviation: String {
        switch self {
        case .tonic: return "T"
        case .supertonic: return "ST"
        case .mediant: return "M"
        case .subdominant: return "SD"
        case .dominant: return "D"
        case .submediant: return "SM"
        case .leadingTone: return "LT"
        case .secondaryDominant: return "V/"
        case .neapolitan: return "N"
        case .augmentedSixth: return "Aug6"
        case .borrowed: return "b"
        case .chromatic: return "chr"
        }
    }
    
    var description: String {
        switch self {
        case .tonic:
            return "The home chord, provides stability and resolution"
        case .supertonic:
            return "Often leads to the dominant, creates forward motion"
        case .mediant:
            return "Bridges tonic and dominant, adds color"
        case .subdominant:
            return "Moves away from tonic, prepares for dominant"
        case .dominant:
            return "Creates tension that resolves to tonic"
        case .submediant:
            return "Deceptive resolution option, adds variety"
        case .leadingTone:
            return "Strong pull to tonic, usually diminished"
        case .secondaryDominant:
            return "Dominant of another chord, adds chromatic interest"
        case .neapolitan:
            return "Flat II chord, dramatic subdominant function"
        case .augmentedSixth:
            return "Chromatic predominant, strong pull to dominant"
        case .borrowed:
            return "Chord from parallel key, adds modal color"
        case .chromatic:
            return "Non-diatonic chord for color or voice leading"
        }
    }
}