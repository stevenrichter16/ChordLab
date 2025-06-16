//
//  ChordAnalysis.swift
//  ChordLab
//
//  Comprehensive chord analysis data
//

import Foundation
import Tonic

struct ChordAnalysis {
    let chord: Chord
    let romanNumeral: String
    let function: ChordFunction
    let scale: Scale
    let isInKey: Bool
    let commonProgressions: [String]
    let voiceLeading: [VoiceLeadingOption]
    
    init(chord: Chord, 
         romanNumeral: String, 
         function: ChordFunction, 
         scale: Scale, 
         isInKey: Bool, 
         commonProgressions: [String] = [], 
         voiceLeading: [VoiceLeadingOption] = []) {
        self.chord = chord
        self.romanNumeral = romanNumeral
        self.function = function
        self.scale = scale
        self.isInKey = isInKey
        self.commonProgressions = commonProgressions
        self.voiceLeading = voiceLeading
    }
}