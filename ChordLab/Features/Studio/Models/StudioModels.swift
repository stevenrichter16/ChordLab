//
//  StudioModels.swift
//  ChordLab
//
//  Data models for the Studio DAW feature
//

import Foundation
import SwiftUI
import Tonic

// MARK: - Track Types

enum TrackType {
    case chords
    case melody
    case drums
    
    var icon: String {
        switch self {
        case .chords: return "pianokeys"
        case .melody: return "music.note"
        case .drums: return "drum"
        }
    }
    
    var color: Color {
        switch self {
        case .chords: return .blue
        case .melody: return .green
        case .drums: return .orange
        }
    }
}

// MARK: - Musical Content

enum MusicalContent: Identifiable, Equatable {
    case chord(Chord, id: UUID = UUID())
    case note(Note, duration: Duration, id: UUID = UUID())
    case drumHit(DrumType, id: UUID = UUID())
    
    var id: UUID {
        switch self {
        case .chord(_, let id), .note(_, _, let id), .drumHit(_, let id):
            return id
        }
    }
    
    static func == (lhs: MusicalContent, rhs: MusicalContent) -> Bool {
        lhs.id == rhs.id
    }
}

enum Duration: Double, CaseIterable, Codable {
    case sixteenth = 0.25
    case eighth = 0.5
    case quarter = 1.0
    case half = 2.0
    case whole = 4.0
    
    var symbol: String {
        switch self {
        case .sixteenth: return "♬"
        case .eighth: return "♪"
        case .quarter: return "♩"
        case .half: return "𝅗𝅥"
        case .whole: return "𝅝"
        }
    }
}

enum DrumType: String, CaseIterable {
    case kick = "Kick"
    case snare = "Snare"
    case hihat = "Hi-Hat"
    case crash = "Crash"
    
    var icon: String {
        switch self {
        case .kick: return "circle.fill"
        case .snare: return "circle"
        case .hihat: return "line.horizontal.2.decrease.circle"
        case .crash: return "star.circle"
        }
    }
}

// MARK: - Track Model

@Observable
class Track: Identifiable {
    let id = UUID()
    var name: String
    var type: TrackType
    var content: [Int: MusicalContent] = [:] // beat -> content
    var isMuted = false
    var isSolo = false
    var volume: Double = 0.8
    
    init(name: String, type: TrackType) {
        self.name = name
        self.type = type
    }
    
    func contentAt(beat: Int) -> MusicalContent? {
        content[beat]
    }
    
    func setContent(_ content: MusicalContent, at beat: Int) {
        self.content[beat] = content
    }
    
    func removeContent(at beat: Int) {
        content.removeValue(forKey: beat)
    }
    
    func clearAll() {
        content.removeAll()
    }
}

// MARK: - Studio Session

@Observable
class StudioSession {
    var tracks: [Track] = []
    var currentBeat: Int = 0
    var isPlaying = false
    var tempo = 120
    var beatsPerMeasure = 16
    var selectedTrackId: UUID?
    var selectedBeat: Int?
    
    // Grid settings
    let totalBeats = 32 // 8 measures of 4/4
    let subdivision = 4 // Quarter note grid
    
    init() {
        // Create default tracks
        tracks = [
            Track(name: "Chords", type: .chords),
            Track(name: "Melody", type: .melody)
        ]
    }
    
    func addTrack(name: String, type: TrackType) {
        let track = Track(name: name, type: type)
        tracks.append(track)
    }
    
    func removeTrack(id: UUID) {
        tracks.removeAll { $0.id == id }
    }
    
    func clearAll() {
        tracks.forEach { $0.clearAll() }
        currentBeat = 0
        isPlaying = false
    }
}

// MARK: - Draggable Items

struct DraggableChord: Codable, Transferable {
    let chordSymbol: String
    let romanNumeral: String
    
    init(chord: Chord, romanNumeral: String) {
        self.chordSymbol = chord.description
        self.romanNumeral = romanNumeral
    }
    
    var chord: Chord? {
        Chord.parse(chordSymbol)
    }
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .draggableChord)
    }
}

struct DraggableNote: Codable, Transferable {
    let pitch: Int // MIDI pitch
    let octave: Int
    let duration: Duration
    
    init(note: Note, duration: Duration) {
        self.pitch = Int(note.pitch.midiNoteNumber)
        self.octave = note.octave
        self.duration = duration
    }
    
    var note: Note {
        // Convert MIDI pitch back to Note
        // MIDI 60 = C4 (middle C)
        return Note(pitch: Pitch(Int8(pitch)))
    }
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .draggableNote)
    }
}

// MARK: - UTType Extensions

import UniformTypeIdentifiers

extension UTType {
    static let draggableChord = UTType(exportedAs: "com.chordlab.draggableChord")
    static let draggableNote = UTType(exportedAs: "com.chordlab.draggableNote")
}

