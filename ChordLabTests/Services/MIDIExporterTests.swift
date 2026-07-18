//
//  MIDIExporterTests.swift
//  ChordLabTests
//
//  Validates the standard-MIDI-file bytes the exporter emits
//

import XCTest
import Tonic
@testable import ChordLab

final class MIDIExporterTests: XCTestCase {

    func testVariableLengthEncoding() {
        XCTAssertEqual(MIDIExporter.variableLength(0), [0x00])
        XCTAssertEqual(MIDIExporter.variableLength(127), [0x7F])
        XCTAssertEqual(MIDIExporter.variableLength(128), [0x81, 0x00])
        XCTAssertEqual(MIDIExporter.variableLength(480), [0x83, 0x60])
        XCTAssertEqual(MIDIExporter.variableLength(1920), [0x8F, 0x00])
        // Negative input clamps rather than corrupting the stream
        XCTAssertEqual(MIDIExporter.variableLength(-5), [0x00])
    }

    func testFileStructure() {
        let data = MIDIExporter.fileData(
            chords: [(Chord(.C, type: .major), 2.0), (Chord(.G, type: .dom7), 2.0)],
            tempo: 120,
            includeBass: false
        )
        let bytes = [UInt8](data)

        // Header chunk: MThd, length 6, format 0, one track, 480 ppq
        XCTAssertEqual(Array(bytes[0..<4]), Array("MThd".utf8))
        XCTAssertEqual(Array(bytes[4..<8]), [0, 0, 0, 6])
        XCTAssertEqual(Array(bytes[8..<10]), [0, 0])
        XCTAssertEqual(Array(bytes[10..<12]), [0, 1])
        XCTAssertEqual(Array(bytes[12..<14]), [0x01, 0xE0])

        // Track chunk header and its declared length
        XCTAssertEqual(Array(bytes[14..<18]), Array("MTrk".utf8))
        let declaredLength = Int(bytes[18]) << 24 | Int(bytes[19]) << 16 | Int(bytes[20]) << 8 | Int(bytes[21])
        XCTAssertEqual(declaredLength, bytes.count - 22)

        // First event: tempo meta, 120 BPM = 500,000 microseconds/quarter
        XCTAssertEqual(Array(bytes[22..<29]), [0x00, 0xFF, 0x51, 0x03, 0x07, 0xA1, 0x20])

        // Then a program change to piano on channel 0
        XCTAssertEqual(Array(bytes[29..<32]), [0x00, 0xC0, 0x00])

        // File terminates with end-of-track
        XCTAssertEqual(Array(bytes.suffix(4)), [0x00, 0xFF, 0x2F, 0x00])
    }

    func testNoteEventsUsePlaybackVoicing() {
        let chord = Chord(.G, type: .dom7)
        let expected = AudioEngine.voicedNotes(for: chord).map { UInt8($0.pitch.midiNoteNumber) }
        XCTAssertEqual(expected.count, 4)

        let data = MIDIExporter.fileData(chords: [(chord, 1.0)], tempo: 90, includeBass: false)
        let bytes = [UInt8](data)

        // Note-ons start right after header(14) + track header(8) +
        // tempo event(7) + program change(3) = offset 32; each event is
        // [delta 0x00, 0x90, note, 80]
        for (index, note) in expected.enumerated() {
            let offset = 32 + index * 4
            XCTAssertEqual(Array(bytes[offset..<(offset + 4)]), [0x00, 0x90, note, 80])
        }

        // First note-off carries the one-beat delta (480 ticks -> 0x83 0x60)
        let offOffset = 32 + expected.count * 4
        XCTAssertEqual(
            Array(bytes[offOffset..<(offOffset + 5)]),
            [0x83, 0x60, 0x80, expected[0], 0]
        )
    }

    func testBassDoublingAddsRootBelow() {
        let chord = Chord(.C, type: .major)

        let plain = MIDIExporter.fileData(chords: [(chord, 1.0)], tempo: 90, includeBass: false)
        let withBass = MIDIExporter.fileData(chords: [(chord, 1.0)], tempo: 90, includeBass: true)

        // One extra note-on + note-off = 8 extra bytes (4 each, delta 0)
        XCTAssertEqual(withBass.count, plain.count + 8)

        // The bass root leads the chord, an octave below the voicing's root
        let root = AudioEngine.voicedNotes(for: chord).map { UInt8($0.pitch.midiNoteNumber) }[0]
        let bytes = [UInt8](withBass)
        XCTAssertEqual(Array(bytes[32..<36]), [0x00, 0x90, root - 12, 80])
    }

    func testSavedProgressionExportRejectsCorruptSymbols() {
        let good = [ProgressionChord(chordSymbol: "C"), ProgressionChord(chordSymbol: "G7")]
        XCTAssertNotNil(MIDIExporter.fileData(progressionChords: good, tempo: 100, includeBass: true))

        let corrupt = [ProgressionChord(chordSymbol: "C"), ProgressionChord(chordSymbol: "???")]
        XCTAssertNil(MIDIExporter.fileData(progressionChords: corrupt, tempo: 100, includeBass: true))

        XCTAssertNil(MIDIExporter.fileData(progressionChords: [], tempo: 100, includeBass: true))
    }

    func testInstrumentCatalog() {
        // Raw values are General MIDI program numbers
        XCTAssertEqual(AudioEngine.Instrument.piano.rawValue, 0)
        XCTAssertEqual(AudioEngine.Instrument.electricPiano.rawValue, 4)
        XCTAssertEqual(AudioEngine.Instrument.vibraphone.rawValue, 11)
        XCTAssertEqual(AudioEngine.Instrument.nylonGuitar.rawValue, 24)
        XCTAssertEqual(AudioEngine.Instrument.strings.rawValue, 48)

        for instrument in AudioEngine.Instrument.allCases {
            XCTAssertFalse(instrument.displayName.isEmpty)
        }
    }
}
