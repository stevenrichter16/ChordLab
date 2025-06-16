//
//  ProgressionAnalysis.swift
//  ChordLab
//
//  Chord progression analysis structures
//

import Foundation
import Tonic

struct ProgressionAnalysis {
    let chords: [Chord]
    let romanNumerals: [String]
    let key: String
    let pattern: ProgressionPattern
    let cadence: CadenceType?
    let tonalCenter: String
    let harmonicRhythm: String
    
    init(chords: [Chord] = [],
         romanNumerals: [String] = [],
         key: String = "C",
         pattern: ProgressionPattern = .other,
         cadence: CadenceType? = nil,
         tonalCenter: String = "C",
         harmonicRhythm: String = "Regular") {
        self.chords = chords
        self.romanNumerals = romanNumerals
        self.key = key
        self.pattern = pattern
        self.cadence = cadence
        self.tonalCenter = tonalCenter
        self.harmonicRhythm = harmonicRhythm
    }
}

enum ProgressionPattern: String, CaseIterable {
    case iiVI = "ii-V-I"
    case IVivIV = "I-V-vi-IV"
    case IviIVV = "I-vi-IV-V"
    case blues = "12-Bar Blues"
    case popRock = "Pop/Rock"
    case circle = "Circle Progression"
    case ragtime = "Ragtime"
    case pachelbel = "Pachelbel"
    case other = "Other"
    
    var description: String {
        switch self {
        case .iiVI:
            return "Jazz standard progression"
        case .IVivIV:
            return "Modern pop progression"
        case .IviIVV:
            return "50s doo-wop progression"
        case .blues:
            return "Classic blues progression"
        case .popRock:
            return "Common pop/rock pattern"
        case .circle:
            return "Circle of fifths based"
        case .ragtime:
            return "Classic ragtime progression"
        case .pachelbel:
            return "Canon progression"
        case .other:
            return "Custom progression"
        }
    }
}

enum CadenceType: String, CaseIterable {
    case authentic = "Authentic"
    case plagal = "Plagal"
    case deceptive = "Deceptive"
    case half = "Half"
    
    var description: String {
        switch self {
        case .authentic:
            return "V-I: Strong resolution"
        case .plagal:
            return "IV-I: Amen cadence"
        case .deceptive:
            return "V-vi: Unexpected resolution"
        case .half:
            return "Ends on V: Unresolved"
        }
    }
}