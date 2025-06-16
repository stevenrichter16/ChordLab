//
//  VoiceLeading.swift
//  ChordLab
//
//  Voice leading analysis and options
//

import Foundation
import Tonic

struct VoiceLeadingOption {
    let toChord: Chord
    let smoothness: Int
    let commonTones: [NoteClass]
    let description: String
    
    init(toChord: Chord, smoothness: Int, commonTones: [NoteClass], description: String) {
        self.toChord = toChord
        self.smoothness = smoothness
        self.commonTones = commonTones
        self.description = description
    }
    
    static func calculate(from fromChord: Chord, to toChord: Chord) -> VoiceLeadingOption {
        let fromNotes = Set(fromChord.noteClasses)
        let toNotes = Set(toChord.noteClasses)
        
        // Find common tones
        let common = fromNotes.intersection(toNotes)
        let commonTones = Array(common)
        
        // Calculate total semitone movement
        var totalMovement = 0
        let fromArray = Array(fromNotes).sorted { noteClassIndex($0) < noteClassIndex($1) }
        let toArray = Array(toNotes).sorted { noteClassIndex($0) < noteClassIndex($1) }
        
        for i in 0..<min(fromArray.count, toArray.count) {
            let fromNote = fromArray[i]
            let toNote = toArray[i]
            let distance = abs(noteClassIndex(fromNote) - noteClassIndex(toNote))
            // Use the shorter distance (considering octave equivalence)
            let movement = min(distance, 12 - distance)
            totalMovement += movement
        }
        
        // Generate description
        let description = generateDescription(
            fromChord: fromChord,
            toChord: toChord,
            commonTones: commonTones.count,
            movement: totalMovement
        )
        
        return VoiceLeadingOption(
            toChord: toChord,
            smoothness: totalMovement,
            commonTones: commonTones,
            description: description
        )
    }
    
    private static func generateDescription(fromChord: Chord, toChord: Chord, commonTones: Int, movement: Int) -> String {
        if commonTones == 3 {
            return "Same chord - no voice movement needed"
        } else if commonTones == 2 {
            return "Very smooth - two common tones"
        } else if commonTones == 1 {
            return "Smooth - one common tone"
        } else if movement <= 4 {
            return "Stepwise motion - no common tones but close movement"
        } else if movement <= 8 {
            return "Moderate movement - some leaps required"
        } else {
            return "Large movement - significant leaps required"
        }
    }
}

// Helper function to get the index of a note class
private func noteClassIndex(_ noteClass: NoteClass) -> Int {
    let noteClasses: [NoteClass] = [.C, .Db, .D, .Eb, .E, .F, .Gb, .G, .Ab, .A, .Bb, .B]
    return noteClasses.firstIndex(of: noteClass) ?? 0
}