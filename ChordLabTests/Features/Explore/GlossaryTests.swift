//
//  GlossaryTests.swift
//  ChordLabTests
//
//  Validates the progression glossary content and key-aware rendering
//

import XCTest
import Tonic
@testable import ChordLab

final class GlossaryTests: XCTestCase {

    func testGlossaryContentIntegrity() {
        let entries = GlossaryLibrary.all
        XCTAssertGreaterThanOrEqual(entries.count, 12)
        XCTAssertEqual(Set(entries.map(\.id)).count, entries.count, "Glossary ids must be unique")

        for entry in entries {
            XCTAssertFalse(entry.name.isEmpty)
            XCTAssertFalse(entry.numerals.isEmpty)
            XCTAssertFalse(entry.details.isEmpty)
            XCTAssertGreaterThanOrEqual(entry.degrees.count, 2, "\(entry.id) needs at least two chords")

            for spec in entry.degrees {
                XCTAssertTrue((0..<7).contains(spec.degreeIndex),
                              "\(entry.id): degree index \(spec.degreeIndex) out of range")
                XCTAssertTrue([1.0, 2.0, 4.0].contains(spec.beats),
                              "\(entry.id): beats \(spec.beats) not in the 1/2/4 grid")
            }
        }
    }

    func testEveryCategoryHasEntries() {
        for category in GlossaryCategory.allCases {
            XCTAssertFalse(GlossaryLibrary.entries(in: category).isEmpty,
                           "Category \(category.rawValue) has no entries")
        }
    }

    func testEntriesRenderInEveryKey() {
        let keys = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]

        for key in keys {
            let engine = TheoryEngine()
            engine.setKey(key, scaleType: "major")

            for entry in GlossaryLibrary.all {
                let chords = entry.playbackChords(in: engine)
                XCTAssertEqual(chords.count, entry.degrees.count,
                               "\(entry.id) should fully render in \(key) major")

                let chips = entry.chipData(in: engine)
                XCTAssertEqual(chips.count, entry.degrees.count)
            }
        }
    }

    func testAxisOfAwesomeRendersInC() throws {
        let engine = TheoryEngine()
        engine.setKey("C", scaleType: "major")

        let entry = try XCTUnwrap(GlossaryLibrary.all.first { $0.id == "axis-of-awesome" })
        let symbols = entry.playbackChords(in: engine).map { $0.chord.formattedSymbol }
        XCTAssertEqual(symbols, ["C", "G", "Am", "F"])
    }

    func testJazzTurnaroundRendersSeventhsInC() throws {
        let engine = TheoryEngine()
        engine.setKey("C", scaleType: "major")

        let entry = try XCTUnwrap(GlossaryLibrary.all.first { $0.id == "jazz-turnaround" })
        let rendered = entry.playbackChords(in: engine)
        XCTAssertEqual(rendered.map { $0.chord.formattedSymbol }, ["Dm7", "G7", "Cmaj7"])
        XCTAssertEqual(rendered.map(\.duration), [2.0, 2.0, 4.0])

        // The rendered progression should analyze as the pattern it claims to be
        let analysis = engine.analyzeProgression(rendered.map { $0.chord })
        XCTAssertEqual(analysis.pattern, .iiVI)
        XCTAssertEqual(analysis.cadence, .authentic)
    }

    func testTwelveBarBluesShape() throws {
        let entry = try XCTUnwrap(GlossaryLibrary.all.first { $0.id == "twelve-bar-blues" })
        XCTAssertEqual(entry.degrees.count, 12)
        XCTAssertEqual(entry.degrees.map(\.degreeIndex),
                       [0, 0, 0, 0, 3, 3, 0, 0, 4, 3, 0, 4])
        XCTAssertTrue(entry.degrees.allSatisfy { $0.beats == 4.0 })
    }
}
