//
//  MIDIExporter.swift
//  ChordLab
//
//  Renders a chord progression into a standard MIDI file (format 0) so
//  progressions can leave the app for GarageBand, Logic, or any DAW.
//  Pure byte-writing on top of AudioEngine's voicing — no AVFoundation.
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers
import Tonic

enum MIDIExporter {

    /// Pulses per quarter note in the emitted file
    static let ticksPerQuarter = 480

    struct VoicedChord {
        let noteNumbers: [UInt8]
        let beats: Double
    }

    // MARK: - Entry points

    /// Renders playable chords (the dock's working progression) using the
    /// same voicing and bass-doubling rules as live playback.
    static func fileData(
        chords: [(chord: Chord, beats: Double)],
        tempo: Int,
        includeBass: Bool
    ) -> Data {
        let voiced = chords.map { entry -> VoicedChord in
            var numbers = AudioEngine.voicedNotes(for: entry.chord)
                .map { UInt8($0.pitch.midiNoteNumber) }

            if includeBass, let root = numbers.first, root >= 12, !numbers.contains(root - 12) {
                numbers.insert(root - 12, at: 0)
            }

            return VoicedChord(noteNumbers: numbers, beats: max(entry.beats, 0.25))
        }

        return fileData(voiced: voiced, tempo: tempo)
    }

    /// Renders a saved progression. Returns nil when any stored symbol no
    /// longer parses (corrupt data) rather than emitting a partial file.
    static func fileData(
        progressionChords: [ProgressionChord],
        tempo: Int,
        includeBass: Bool
    ) -> Data? {
        var pairs: [(chord: Chord, beats: Double)] = []
        for stored in progressionChords {
            guard let chord = Chord.parse(stored.chordSymbol) else { return nil }
            pairs.append((chord, stored.duration))
        }
        guard !pairs.isEmpty else { return nil }

        return fileData(chords: pairs, tempo: tempo, includeBass: includeBass)
    }

    // MARK: - File assembly

    static func fileData(voiced: [VoicedChord], tempo: Int) -> Data {
        var track = Data()

        // Tempo meta event at t=0: microseconds per quarter note
        let microsecondsPerQuarter = 60_000_000 / max(tempo, 1)
        track.append(contentsOf: [0x00, 0xFF, 0x51, 0x03])
        track.append(contentsOf: [
            UInt8((microsecondsPerQuarter >> 16) & 0xFF),
            UInt8((microsecondsPerQuarter >> 8) & 0xFF),
            UInt8(microsecondsPerQuarter & 0xFF)
        ])

        // Program change: acoustic grand piano on channel 0
        track.append(contentsOf: [0x00, 0xC0, 0x00])

        for chord in voiced {
            let ticks = max(Int(chord.beats * Double(ticksPerQuarter)), 1)

            // All note-ons together on the downbeat
            for noteNumber in chord.noteNumbers {
                track.append(contentsOf: variableLength(0))
                track.append(contentsOf: [0x90, noteNumber, 80])
            }

            // First note-off carries the chord's length; the rest follow at 0
            for (index, noteNumber) in chord.noteNumbers.enumerated() {
                track.append(contentsOf: variableLength(index == 0 ? ticks : 0))
                track.append(contentsOf: [0x80, noteNumber, 0])
            }
        }

        // End of track
        track.append(contentsOf: [0x00, 0xFF, 0x2F, 0x00])

        var data = Data()
        data.append(contentsOf: Array("MThd".utf8))
        data.append(contentsOf: bigEndian32(6))
        data.append(contentsOf: bigEndian16(0))                          // format 0
        data.append(contentsOf: bigEndian16(1))                          // one track
        data.append(contentsOf: bigEndian16(UInt16(ticksPerQuarter)))    // division
        data.append(contentsOf: Array("MTrk".utf8))
        data.append(contentsOf: bigEndian32(UInt32(track.count)))
        data.append(track)
        return data
    }

    // MARK: - Encoding primitives

    /// MIDI variable-length quantity: 7 data bits per byte, high bit set on
    /// every byte except the last
    static func variableLength(_ value: Int) -> [UInt8] {
        var remaining = max(value, 0)
        var bytes: [UInt8] = [UInt8(remaining & 0x7F)]
        remaining >>= 7

        while remaining > 0 {
            bytes.insert(UInt8((remaining & 0x7F) | 0x80), at: 0)
            remaining >>= 7
        }
        return bytes
    }

    private static func bigEndian16(_ value: UInt16) -> [UInt8] {
        [UInt8(value >> 8), UInt8(value & 0xFF)]
    }

    private static func bigEndian32(_ value: UInt32) -> [UInt8] {
        [
            UInt8((value >> 24) & 0xFF),
            UInt8((value >> 16) & 0xFF),
            UInt8((value >> 8) & 0xFF),
            UInt8(value & 0xFF)
        ]
    }
}

// MARK: - Share payload

/// Wraps exported MIDI bytes so ShareLink can hand receivers a real
/// .mid file with a sensible name
struct MIDIFileExport: Transferable {
    let data: Data
    let filename: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .midi) { export in
            let safeName = export.filename
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ":", with: "-")
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(safeName.isEmpty ? "Progression" : safeName)
                .appendingPathExtension("mid")

            try export.data.write(to: url)
            return SentTransferredFile(url)
        }
    }
}
