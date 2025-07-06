//
//  ChordVisualizerStateTests.swift
//  ChordLabTests
//
//  Tests for ChordVisualizerView focusing on state and logic
//  rather than view inspection to avoid environment object issues
//

import XCTest
import SwiftUI
import Tonic
@testable import ChordLab

@MainActor
final class ChordVisualizerStateTests: XCTestCase {
    
    var theoryEngine: TheoryEngine!
    var audioEngine: AudioEngine!
    var dataManager: DataManager!
    
    override func setUp() async throws {
        try await super.setUp()
        
        theoryEngine = TheoryEngine()
        audioEngine = AudioEngine()
        dataManager = DataManager(inMemory: true)
    }
    
    override func tearDown() async throws {
        theoryEngine = nil
        audioEngine = nil
        dataManager = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Helper to get the expected degree name from ChordFunction enum
    private func degreeName(for function: ChordFunction) -> String {
        return function.rawValue
    }
    
    /// Helper to get the expected roman numeral for triads from ChordFunction enum
    private func romanNumeral(for function: ChordFunction) -> String {
        return function.romanNumeralMajor
    }
    
    /// Helper to get the expected roman numeral for seventh chords from ChordFunction enum
    private func romanNumeral7(for function: ChordFunction) -> String {
        return function.romanNumeralMajor7
    }
    
    // MARK: - View Creation Tests
    
    func testViewCanBeCreated() {
        // This test verifies the view can be instantiated
        let view = ChordVisualizerView()
            .environment(theoryEngine)
            .environment(audioEngine)
            .environment(dataManager)
        
        XCTAssertNotNil(view)
    }
    
    // MARK: - State Management Tests
    
    func testTheoryEngineKeyManagement() {
        // Given: Initial state
        XCTAssertEqual(theoryEngine.currentKey, "C")
        XCTAssertEqual(theoryEngine.currentScaleType, "major")
        
        // When: Changing key
        theoryEngine.setKey("G", scaleType: "minor")
        
        // Then: State should update
        XCTAssertEqual(theoryEngine.currentKey, "G")
        XCTAssertEqual(theoryEngine.currentScaleType, "minor")
    }
    
    func testProgressionManagement() {
        // Given: Empty progression
        XCTAssertTrue(theoryEngine.currentProgression.isEmpty)
        
        // When: Adding chords
        let chord1 = Chord(.C, type: .major)
        let chord2 = Chord(.A, type: .minor)
        let chord3 = Chord(.F, type: .major)
        let chord4 = Chord(.G, type: .major)
        
        theoryEngine.addChordToProgression(chord1)
        theoryEngine.addChordToProgression(chord2)
        theoryEngine.addChordToProgression(chord3)
        theoryEngine.addChordToProgression(chord4)
        
        // Then: Progression should contain all chords
        XCTAssertEqual(theoryEngine.currentProgression.count, 4)
        XCTAssertEqual(theoryEngine.currentProgression[0].chord.description, "C")
        XCTAssertEqual(theoryEngine.currentProgression[1].chord.description, "Am")
        XCTAssertEqual(theoryEngine.currentProgression[2].chord.description, "F")
        XCTAssertEqual(theoryEngine.currentProgression[3].chord.description, "G")
    }
    
    func testChordReordering() {
        // Given: A progression
        theoryEngine.addChordToProgression(Chord(.C, type: .major))
        theoryEngine.addChordToProgression(Chord(.G, type: .major))
        theoryEngine.addChordToProgression(Chord(.A, type: .minor))
        theoryEngine.addChordToProgression(Chord(.F, type: .major))
        
        // When: Reordering
        theoryEngine.reorderProgression(from: 3, to: 1)
        
        // Then: Order should change
        XCTAssertEqual(theoryEngine.currentProgression[0].chord.description, "C")
        XCTAssertEqual(theoryEngine.currentProgression[1].chord.description, "F")
        XCTAssertEqual(theoryEngine.currentProgression[2].chord.description, "G")
        XCTAssertEqual(theoryEngine.currentProgression[3].chord.description, "Am")
    }
    
    func testChordReorderingLeftTwice() {
        // Given: A progression with 5 chords
        theoryEngine.addChordToProgression(Chord(.C, type: .major))    // 0
        theoryEngine.addChordToProgression(Chord(.D, type: .minor))    // 1
        theoryEngine.addChordToProgression(Chord(.E, type: .minor))    // 2
        theoryEngine.addChordToProgression(Chord(.F, type: .major))    // 3
        theoryEngine.addChordToProgression(Chord(.G, type: .major))    // 4
        
        // Initial state: C, Dm, Em, F, G
        XCTAssertEqual(theoryEngine.currentProgression[0].chord.description, "C")
        XCTAssertEqual(theoryEngine.currentProgression[1].chord.description, "Dm")
        XCTAssertEqual(theoryEngine.currentProgression[2].chord.description, "Em")
        XCTAssertEqual(theoryEngine.currentProgression[3].chord.description, "F")
        XCTAssertEqual(theoryEngine.currentProgression[4].chord.description, "G")
        
        // When: Moving F (index 3) left once
        theoryEngine.reorderProgression(from: 3, to: 2)
        
        // Then: After first move - C, Dm, F, Em, G
        XCTAssertEqual(theoryEngine.currentProgression[0].chord.description, "C")
        XCTAssertEqual(theoryEngine.currentProgression[1].chord.description, "Dm")
        XCTAssertEqual(theoryEngine.currentProgression[2].chord.description, "F")
        XCTAssertEqual(theoryEngine.currentProgression[3].chord.description, "Em")
        XCTAssertEqual(theoryEngine.currentProgression[4].chord.description, "G")
        
        // When: Moving F (now at index 2) left again
        theoryEngine.reorderProgression(from: 2, to: 1)
        
        // Then: After second move - C, F, Dm, Em, G
        XCTAssertEqual(theoryEngine.currentProgression[0].chord.description, "C")
        XCTAssertEqual(theoryEngine.currentProgression[1].chord.description, "F")
        XCTAssertEqual(theoryEngine.currentProgression[2].chord.description, "Dm")
        XCTAssertEqual(theoryEngine.currentProgression[3].chord.description, "Em")
        XCTAssertEqual(theoryEngine.currentProgression[4].chord.description, "G")
    }
    
    func testChordReorderingRightTwiceLeftOnce() {
        // Given: A progression with 5 chords
        theoryEngine.addChordToProgression(Chord(.C, type: .major))    // 0
        theoryEngine.addChordToProgression(Chord(.D, type: .minor))    // 1
        theoryEngine.addChordToProgression(Chord(.E, type: .minor))    // 2
        theoryEngine.addChordToProgression(Chord(.F, type: .major))    // 3
        theoryEngine.addChordToProgression(Chord(.G, type: .major))    // 4
        
        // Initial state: C, Dm, Em, F, G
        XCTAssertEqual(theoryEngine.currentProgression[0].chord.description, "C")
        XCTAssertEqual(theoryEngine.currentProgression[1].chord.description, "Dm")
        XCTAssertEqual(theoryEngine.currentProgression[2].chord.description, "Em")
        XCTAssertEqual(theoryEngine.currentProgression[3].chord.description, "F")
        XCTAssertEqual(theoryEngine.currentProgression[4].chord.description, "G")
        
        // When: Moving Dm (index 1) right once - to position after Em
        // The "to" index is where it will be inserted after removal, so we use 3
        theoryEngine.reorderProgression(from: 1, to: 3)
        
        // Then: After first move - C, Em, Dm, F, G
        XCTAssertEqual(theoryEngine.currentProgression[0].chord.description, "C")
        XCTAssertEqual(theoryEngine.currentProgression[1].chord.description, "Em")
        XCTAssertEqual(theoryEngine.currentProgression[2].chord.description, "Dm")
        XCTAssertEqual(theoryEngine.currentProgression[3].chord.description, "F")
        XCTAssertEqual(theoryEngine.currentProgression[4].chord.description, "G")
        
        // When: Moving Dm (now at index 2) right again - to position after F
        // The "to" index is 4 (after removal, F will be at index 2, so we insert at 3)
        theoryEngine.reorderProgression(from: 2, to: 4)
        
        // Then: After second move - C, Em, F, Dm, G
        XCTAssertEqual(theoryEngine.currentProgression[0].chord.description, "C")
        XCTAssertEqual(theoryEngine.currentProgression[1].chord.description, "Em")
        XCTAssertEqual(theoryEngine.currentProgression[2].chord.description, "F")
        XCTAssertEqual(theoryEngine.currentProgression[3].chord.description, "Dm")
        XCTAssertEqual(theoryEngine.currentProgression[4].chord.description, "G")
        
        // When: Moving Dm (now at index 3) left once - to position before F (index 2)
        theoryEngine.reorderProgression(from: 3, to: 2)
        
        // Then: After third move - C, Em, Dm, F, G
        XCTAssertEqual(theoryEngine.currentProgression[0].chord.description, "C")
        XCTAssertEqual(theoryEngine.currentProgression[1].chord.description, "Em")
        XCTAssertEqual(theoryEngine.currentProgression[2].chord.description, "Dm")
        XCTAssertEqual(theoryEngine.currentProgression[3].chord.description, "F")
        XCTAssertEqual(theoryEngine.currentProgression[4].chord.description, "G")
    }
    
    func testChordReorderingEmptyProgression() {
        // Given: An empty progression
        XCTAssertTrue(theoryEngine.currentProgression.isEmpty)
        
        // When: Attempting to reorder
        theoryEngine.reorderProgression(from: 0, to: 1)
        
        // Then: Nothing should happen, no crash
        XCTAssertTrue(theoryEngine.currentProgression.isEmpty)
    }
    
    func testChordReorderingSingleChord() {
        // Given: A progression with only one chord
        theoryEngine.addChordToProgression(Chord(.C, type: .major))
        
        // When: Attempting to reorder the single chord
        theoryEngine.reorderProgression(from: 0, to: 0)
        theoryEngine.reorderProgression(from: 0, to: 1)
        
        // Then: The chord should remain in place
        XCTAssertEqual(theoryEngine.currentProgression.count, 1)
        XCTAssertEqual(theoryEngine.currentProgression[0].chord.description, "C")
    }
    
    func testChordReorderingInvalidIndices() {
        // Given: A progression with 3 chords
        theoryEngine.addChordToProgression(Chord(.C, type: .major))
        theoryEngine.addChordToProgression(Chord(.F, type: .major))
        theoryEngine.addChordToProgression(Chord(.G, type: .major))
        
        // When: Attempting reorder with out-of-bounds indices
        theoryEngine.reorderProgression(from: -1, to: 1)  // Negative index
        theoryEngine.reorderProgression(from: 5, to: 1)   // Beyond array bounds
        theoryEngine.reorderProgression(from: 1, to: 10)  // Destination beyond bounds
        
        // Then: Original order should be preserved
        XCTAssertEqual(theoryEngine.currentProgression[0].chord.description, "C")
        XCTAssertEqual(theoryEngine.currentProgression[1].chord.description, "F")
        XCTAssertEqual(theoryEngine.currentProgression[2].chord.description, "G")
    }
    
    func testChordReorderingSamePosition() {
        // Given: A progression with 4 chords
        theoryEngine.addChordToProgression(Chord(.C, type: .major))
        theoryEngine.addChordToProgression(Chord(.D, type: .minor))
        theoryEngine.addChordToProgression(Chord(.E, type: .minor))
        theoryEngine.addChordToProgression(Chord(.F, type: .major))
        
        // When: Trying to move a chord to its current position
        theoryEngine.reorderProgression(from: 2, to: 2)
        
        // Then: Order should remain unchanged
        XCTAssertEqual(theoryEngine.currentProgression[0].chord.description, "C")
        XCTAssertEqual(theoryEngine.currentProgression[1].chord.description, "Dm")
        XCTAssertEqual(theoryEngine.currentProgression[2].chord.description, "Em")
        XCTAssertEqual(theoryEngine.currentProgression[3].chord.description, "F")
    }
    
    func testChordReorderingMovingToBeginning() {
        // Given: User wants to move last chord to beginning using arrow buttons
        theoryEngine.addChordToProgression(Chord(.C, type: .major))    // 0
        theoryEngine.addChordToProgression(Chord(.A, type: .minor))    // 1
        theoryEngine.addChordToProgression(Chord(.F, type: .major))    // 2
        theoryEngine.addChordToProgression(Chord(.G, type: .major))    // 3
        
        // When: Moving G from last position to first, one step at a time
        // Move G left from index 3 to 2
        theoryEngine.reorderProgression(from: 3, to: 2)
        XCTAssertEqual(theoryEngine.currentProgression[2].chord.description, "G")
        XCTAssertEqual(theoryEngine.currentProgression[3].chord.description, "F")
        
        // Move G left from index 2 to 1
        theoryEngine.reorderProgression(from: 2, to: 1)
        XCTAssertEqual(theoryEngine.currentProgression[1].chord.description, "G")
        XCTAssertEqual(theoryEngine.currentProgression[2].chord.description, "Am")
        
        // Move G left from index 1 to 0
        theoryEngine.reorderProgression(from: 1, to: 0)
        
        // Then: G should be at the beginning
        XCTAssertEqual(theoryEngine.currentProgression[0].chord.description, "G")
        XCTAssertEqual(theoryEngine.currentProgression[1].chord.description, "C")
        XCTAssertEqual(theoryEngine.currentProgression[2].chord.description, "Am")
        XCTAssertEqual(theoryEngine.currentProgression[3].chord.description, "F")
    }
    
    func testChordReorderingBuildingProgression() {
        // Given: User is building a ii-V-I progression by reordering
        theoryEngine.addChordToProgression(Chord(.C, type: .major))    // I
        theoryEngine.addChordToProgression(Chord(.G, type: .major))    // V
        theoryEngine.addChordToProgression(Chord(.D, type: .minor))    // ii
        
        // Initial: C, G, Dm (I, V, ii)
        // Want: Dm, G, C (ii, V, I)
        
        // When: Moving Dm to the beginning using left arrows
        // Move Dm from index 2 to 1
        theoryEngine.reorderProgression(from: 2, to: 1)
        XCTAssertEqual(theoryEngine.currentProgression[0].chord.description, "C")
        XCTAssertEqual(theoryEngine.currentProgression[1].chord.description, "Dm")
        XCTAssertEqual(theoryEngine.currentProgression[2].chord.description, "G")
        
        // Move Dm from index 1 to 0
        theoryEngine.reorderProgression(from: 1, to: 0)
        
        // Then: Should have ii-V-I progression
        XCTAssertEqual(theoryEngine.currentProgression[0].chord.description, "Dm")
        XCTAssertEqual(theoryEngine.currentProgression[1].chord.description, "C")
        XCTAssertEqual(theoryEngine.currentProgression[2].chord.description, "G")
        
        // When: Final adjustment - move C to the end
        // Move C from index 1 to 2
        theoryEngine.reorderProgression(from: 1, to: 3)
        
        // Then: Perfect ii-V-I
        XCTAssertEqual(theoryEngine.currentProgression[0].chord.description, "Dm")
        XCTAssertEqual(theoryEngine.currentProgression[1].chord.description, "G")
        XCTAssertEqual(theoryEngine.currentProgression[2].chord.description, "C")
    }
    
    func testChordRemoval() {
        // Given: A progression
        theoryEngine.addChordToProgression(Chord(.C, type: .major))
        theoryEngine.addChordToProgression(Chord(.G, type: .major))
        theoryEngine.addChordToProgression(Chord(.A, type: .minor))
        
        // When: Removing middle chord
        theoryEngine.removeFromProgression(at: 1)
        
        // Then: Should have 2 chords
        XCTAssertEqual(theoryEngine.currentProgression.count, 2)
        XCTAssertEqual(theoryEngine.currentProgression[0].chord.description, "C")
        XCTAssertEqual(theoryEngine.currentProgression[1].chord.description, "Am")
    }
    
    func testDiatonicChordsGeneration() {
        // Given: C major key
        theoryEngine.setKey("C", scaleType: "major")
        
        // When: Getting diatonic chords
        let triads = theoryEngine.getDiatonicChordsWithAnalysis()
        
        // Then: Should have 7 diatonic chords
        XCTAssertEqual(triads.count, 7)
        
        // Verify all diatonic chords in C major
        // I - C major (Tonic)
        XCTAssertEqual(triads[0].chord.description, "C")
        XCTAssertEqual(triads[0].romanNumeral, ChordFunction.tonic.romanNumeralMajor)
        XCTAssertEqual(triads[0].function, .tonic)
        XCTAssertEqual(triads[0].degreeName, ChordFunction.tonic.rawValue)
        
        // ii - D minor (Supertonic)
        XCTAssertEqual(triads[1].chord.description, "Dm")
        XCTAssertEqual(triads[1].romanNumeral, ChordFunction.supertonic.romanNumeralMajor)
        XCTAssertEqual(triads[1].function, .supertonic)
        XCTAssertEqual(triads[1].degreeName, ChordFunction.supertonic.rawValue)
        
        // iii - E minor (Mediant)
        XCTAssertEqual(triads[2].chord.description, "Em")
        XCTAssertEqual(triads[2].romanNumeral, ChordFunction.mediant.romanNumeralMajor)
        XCTAssertEqual(triads[2].function, .mediant)
        XCTAssertEqual(triads[2].degreeName, ChordFunction.mediant.rawValue)
        
        // IV - F major (Subdominant)
        XCTAssertEqual(triads[3].chord.description, "F")
        XCTAssertEqual(triads[3].romanNumeral, ChordFunction.subdominant.romanNumeralMajor)
        XCTAssertEqual(triads[3].function, .subdominant)
        XCTAssertEqual(triads[3].degreeName, ChordFunction.subdominant.rawValue)
        
        // V - G major (Dominant)
        XCTAssertEqual(triads[4].chord.description, "G")
        XCTAssertEqual(triads[4].romanNumeral, ChordFunction.dominant.romanNumeralMajor)
        XCTAssertEqual(triads[4].function, .dominant)
        XCTAssertEqual(triads[4].degreeName, ChordFunction.dominant.rawValue)
        
        // vi - A minor (Submediant)
        XCTAssertEqual(triads[5].chord.description, "Am")
        XCTAssertEqual(triads[5].romanNumeral, ChordFunction.submediant.romanNumeralMajor)
        XCTAssertEqual(triads[5].function, .submediant)
        XCTAssertEqual(triads[5].degreeName, ChordFunction.submediant.rawValue)
        
        // vii° - B diminished (Leading Tone)
        XCTAssertEqual(triads[6].chord.description, "B°")
        XCTAssertEqual(triads[6].romanNumeral, ChordFunction.leadingTone.romanNumeralMajor)
        XCTAssertEqual(triads[6].function, .leadingTone)
        XCTAssertEqual(triads[6].degreeName, ChordFunction.leadingTone.rawValue)
    }
    
    func testDiatonicChordsGenerationAMajor() {
        // Given: A major key
        theoryEngine.setKey("A", scaleType: "major")
        
        // When: Getting diatonic chords
        let triads = theoryEngine.getDiatonicChordsWithAnalysis()
        
        // Then: Should have 7 diatonic chords
        XCTAssertEqual(triads.count, 7)
        
        // Verify all diatonic chords in A major
        // I - A major (Tonic)
        XCTAssertEqual(triads[0].chord.description, "A")
        XCTAssertEqual(triads[0].romanNumeral, romanNumeral(for: .tonic))
        XCTAssertEqual(triads[0].function, .tonic)
        XCTAssertEqual(triads[0].degreeName, degreeName(for: .tonic))
        
        // ii - B minor (Supertonic)
        XCTAssertEqual(triads[1].chord.description, "Bm")
        XCTAssertEqual(triads[1].romanNumeral, romanNumeral(for: .supertonic))
        XCTAssertEqual(triads[1].function, .supertonic)
        XCTAssertEqual(triads[1].degreeName, degreeName(for: .supertonic))
        
        // iii - C# minor (Mediant)
        XCTAssertEqual(triads[2].chord.description, "C♯m")
        XCTAssertEqual(triads[2].romanNumeral, romanNumeral(for: .mediant))
        XCTAssertEqual(triads[2].function, .mediant)
        XCTAssertEqual(triads[2].degreeName, degreeName(for: .mediant))
        
        // IV - D major (Subdominant)
        XCTAssertEqual(triads[3].chord.description, "D")
        XCTAssertEqual(triads[3].romanNumeral, romanNumeral(for: .subdominant))
        XCTAssertEqual(triads[3].function, .subdominant)
        XCTAssertEqual(triads[3].degreeName, degreeName(for: .subdominant))
        
        // V - E major (Dominant)
        XCTAssertEqual(triads[4].chord.description, "E")
        XCTAssertEqual(triads[4].romanNumeral, romanNumeral(for: .dominant))
        XCTAssertEqual(triads[4].function, .dominant)
        XCTAssertEqual(triads[4].degreeName, degreeName(for: .dominant))
        
        // vi - F# minor (Submediant)
        XCTAssertEqual(triads[5].chord.description, "F♯m")
        XCTAssertEqual(triads[5].romanNumeral, romanNumeral(for: .submediant))
        XCTAssertEqual(triads[5].function, .submediant)
        XCTAssertEqual(triads[5].degreeName, degreeName(for: .submediant))
        
        // vii° - G# diminished (Leading Tone)
        XCTAssertEqual(triads[6].chord.description, "G♯°")
        XCTAssertEqual(triads[6].romanNumeral, romanNumeral(for: .leadingTone))
        XCTAssertEqual(triads[6].function, .leadingTone)
        XCTAssertEqual(triads[6].degreeName, degreeName(for: .leadingTone))
    }
    
    func testDiatonicChordsGenerationBMajor() {
        // Given: B major key
        theoryEngine.setKey("B", scaleType: "major")
        
        // When: Getting diatonic chords
        let triads = theoryEngine.getDiatonicChordsWithAnalysis()
        
        // Then: Should have 7 diatonic chords
        XCTAssertEqual(triads.count, 7)
        
        // Verify all diatonic chords in B major
        // I - B major (Tonic)
        XCTAssertEqual(triads[0].chord.description, "B")
        XCTAssertEqual(triads[0].romanNumeral, romanNumeral(for: .tonic))
        XCTAssertEqual(triads[0].function, .tonic)
        XCTAssertEqual(triads[0].degreeName, degreeName(for: .tonic))
        
        // ii - C# minor (Supertonic)
        XCTAssertEqual(triads[1].chord.description, "C♯m")
        XCTAssertEqual(triads[1].romanNumeral, romanNumeral(for: .supertonic))
        XCTAssertEqual(triads[1].function, .supertonic)
        XCTAssertEqual(triads[1].degreeName, degreeName(for: .supertonic))
        
        // iii - D# minor (Mediant)
        XCTAssertEqual(triads[2].chord.description, "D♯m")
        XCTAssertEqual(triads[2].romanNumeral, romanNumeral(for: .mediant))
        XCTAssertEqual(triads[2].function, .mediant)
        XCTAssertEqual(triads[2].degreeName, degreeName(for: .mediant))
        
        // IV - E major (Subdominant)
        XCTAssertEqual(triads[3].chord.description, "E")
        XCTAssertEqual(triads[3].romanNumeral, romanNumeral(for: .subdominant))
        XCTAssertEqual(triads[3].function, .subdominant)
        XCTAssertEqual(triads[3].degreeName, degreeName(for: .subdominant))
        
        // V - F# major (Dominant)
        XCTAssertEqual(triads[4].chord.description, "F♯")
        XCTAssertEqual(triads[4].romanNumeral, romanNumeral(for: .dominant))
        XCTAssertEqual(triads[4].function, .dominant)
        XCTAssertEqual(triads[4].degreeName, degreeName(for: .dominant))
        
        // vi - G# minor (Submediant)
        XCTAssertEqual(triads[5].chord.description, "G♯m")
        XCTAssertEqual(triads[5].romanNumeral, romanNumeral(for: .submediant))
        XCTAssertEqual(triads[5].function, .submediant)
        XCTAssertEqual(triads[5].degreeName, degreeName(for: .submediant))
        
        // vii° - A# diminished (Leading Tone)
        XCTAssertEqual(triads[6].chord.description, "A♯°")
        XCTAssertEqual(triads[6].romanNumeral, romanNumeral(for: .leadingTone))
        XCTAssertEqual(triads[6].function, .leadingTone)
        XCTAssertEqual(triads[6].degreeName, degreeName(for: .leadingTone))
    }
    
    func testDiatonicChordsGenerationDMajor() {
        // Given: D major key
        theoryEngine.setKey("D", scaleType: "major")
        
        // When: Getting diatonic chords
        let triads = theoryEngine.getDiatonicChordsWithAnalysis()
        
        // Then: Should have 7 diatonic chords
        XCTAssertEqual(triads.count, 7)
        
        // Verify all diatonic chords in D major
        // I - D major (Tonic)
        XCTAssertEqual(triads[0].chord.description, "D")
        XCTAssertEqual(triads[0].romanNumeral, romanNumeral(for: .tonic))
        XCTAssertEqual(triads[0].function, .tonic)
        XCTAssertEqual(triads[0].degreeName, degreeName(for: .tonic))
        
        // ii - E minor (Supertonic)
        XCTAssertEqual(triads[1].chord.description, "Em")
        XCTAssertEqual(triads[1].romanNumeral, romanNumeral(for: .supertonic))
        XCTAssertEqual(triads[1].function, .supertonic)
        XCTAssertEqual(triads[1].degreeName, degreeName(for: .supertonic))
        
        // iii - F# minor (Mediant)
        XCTAssertEqual(triads[2].chord.description, "F♯m")
        XCTAssertEqual(triads[2].romanNumeral, romanNumeral(for: .mediant))
        XCTAssertEqual(triads[2].function, .mediant)
        XCTAssertEqual(triads[2].degreeName, degreeName(for: .mediant))
        
        // IV - G major (Subdominant)
        XCTAssertEqual(triads[3].chord.description, "G")
        XCTAssertEqual(triads[3].romanNumeral, romanNumeral(for: .subdominant))
        XCTAssertEqual(triads[3].function, .subdominant)
        XCTAssertEqual(triads[3].degreeName, degreeName(for: .subdominant))
        
        // V - A major (Dominant)
        XCTAssertEqual(triads[4].chord.description, "A")
        XCTAssertEqual(triads[4].romanNumeral, romanNumeral(for: .dominant))
        XCTAssertEqual(triads[4].function, .dominant)
        XCTAssertEqual(triads[4].degreeName, degreeName(for: .dominant))
        
        // vi - B minor (Submediant)
        XCTAssertEqual(triads[5].chord.description, "Bm")
        XCTAssertEqual(triads[5].romanNumeral, romanNumeral(for: .submediant))
        XCTAssertEqual(triads[5].function, .submediant)
        XCTAssertEqual(triads[5].degreeName, degreeName(for: .submediant))
        
        // vii° - C# diminished (Leading Tone)
        XCTAssertEqual(triads[6].chord.description, "C♯°")
        XCTAssertEqual(triads[6].romanNumeral, romanNumeral(for: .leadingTone))
        XCTAssertEqual(triads[6].function, .leadingTone)
        XCTAssertEqual(triads[6].degreeName, degreeName(for: .leadingTone))
    }
    
    func testDiatonicChordsGenerationEMajor() {
        // Given: E major key
        theoryEngine.setKey("E", scaleType: "major")
        
        // When: Getting diatonic chords
        let triads = theoryEngine.getDiatonicChordsWithAnalysis()
        
        // Then: Should have 7 diatonic chords
        XCTAssertEqual(triads.count, 7)
        
        // Verify all diatonic chords in E major
        // I - E major (Tonic)
        XCTAssertEqual(triads[0].chord.description, "E")
        XCTAssertEqual(triads[0].romanNumeral, romanNumeral(for: .tonic))
        XCTAssertEqual(triads[0].function, .tonic)
        XCTAssertEqual(triads[0].degreeName, degreeName(for: .tonic))
        
        // ii - F# minor (Supertonic)
        XCTAssertEqual(triads[1].chord.description, "F♯m")
        XCTAssertEqual(triads[1].romanNumeral, romanNumeral(for: .supertonic))
        XCTAssertEqual(triads[1].function, .supertonic)
        XCTAssertEqual(triads[1].degreeName, degreeName(for: .supertonic))
        
        // iii - G# minor (Mediant)
        XCTAssertEqual(triads[2].chord.description, "G♯m")
        XCTAssertEqual(triads[2].romanNumeral, romanNumeral(for: .mediant))
        XCTAssertEqual(triads[2].function, .mediant)
        XCTAssertEqual(triads[2].degreeName, degreeName(for: .mediant))
        
        // IV - A major (Subdominant)
        XCTAssertEqual(triads[3].chord.description, "A")
        XCTAssertEqual(triads[3].romanNumeral, romanNumeral(for: .subdominant))
        XCTAssertEqual(triads[3].function, .subdominant)
        XCTAssertEqual(triads[3].degreeName, degreeName(for: .subdominant))
        
        // V - B major (Dominant)
        XCTAssertEqual(triads[4].chord.description, "B")
        XCTAssertEqual(triads[4].romanNumeral, romanNumeral(for: .dominant))
        XCTAssertEqual(triads[4].function, .dominant)
        XCTAssertEqual(triads[4].degreeName, degreeName(for: .dominant))
        
        // vi - C# minor (Submediant)
        XCTAssertEqual(triads[5].chord.description, "C♯m")
        XCTAssertEqual(triads[5].romanNumeral, romanNumeral(for: .submediant))
        XCTAssertEqual(triads[5].function, .submediant)
        XCTAssertEqual(triads[5].degreeName, degreeName(for: .submediant))
        
        // vii° - D# diminished (Leading Tone)
        XCTAssertEqual(triads[6].chord.description, "D♯°")
        XCTAssertEqual(triads[6].romanNumeral, romanNumeral(for: .leadingTone))
        XCTAssertEqual(triads[6].function, .leadingTone)
        XCTAssertEqual(triads[6].degreeName, degreeName(for: .leadingTone))
    }
    
    func testDiatonicChordsGenerationFMajor() {
        // Given: F major key
        theoryEngine.setKey("F", scaleType: "major")
        
        // When: Getting diatonic chords
        let triads = theoryEngine.getDiatonicChordsWithAnalysis()
        
        // Then: Should have 7 diatonic chords
        XCTAssertEqual(triads.count, 7)
        
        // Verify all diatonic chords in F major
        // I - F major (Tonic)
        XCTAssertEqual(triads[0].chord.description, "F")
        XCTAssertEqual(triads[0].romanNumeral, romanNumeral(for: .tonic))
        XCTAssertEqual(triads[0].function, .tonic)
        XCTAssertEqual(triads[0].degreeName, degreeName(for: .tonic))
        
        // ii - G minor (Supertonic)
        XCTAssertEqual(triads[1].chord.description, "Gm")
        XCTAssertEqual(triads[1].romanNumeral, romanNumeral(for: .supertonic))
        XCTAssertEqual(triads[1].function, .supertonic)
        XCTAssertEqual(triads[1].degreeName, degreeName(for: .supertonic))
        
        // iii - A minor (Mediant)
        XCTAssertEqual(triads[2].chord.description, "Am")
        XCTAssertEqual(triads[2].romanNumeral, romanNumeral(for: .mediant))
        XCTAssertEqual(triads[2].function, .mediant)
        XCTAssertEqual(triads[2].degreeName, degreeName(for: .mediant))
        
        // IV - Bb major (Subdominant)
        XCTAssertEqual(triads[3].chord.description, "B♭")
        XCTAssertEqual(triads[3].romanNumeral, romanNumeral(for: .subdominant))
        XCTAssertEqual(triads[3].function, .subdominant)
        XCTAssertEqual(triads[3].degreeName, degreeName(for: .subdominant))
        
        // V - C major (Dominant)
        XCTAssertEqual(triads[4].chord.description, "C")
        XCTAssertEqual(triads[4].romanNumeral, romanNumeral(for: .dominant))
        XCTAssertEqual(triads[4].function, .dominant)
        XCTAssertEqual(triads[4].degreeName, degreeName(for: .dominant))
        
        // vi - D minor (Submediant)
        XCTAssertEqual(triads[5].chord.description, "Dm")
        XCTAssertEqual(triads[5].romanNumeral, romanNumeral(for: .submediant))
        XCTAssertEqual(triads[5].function, .submediant)
        XCTAssertEqual(triads[5].degreeName, degreeName(for: .submediant))
        
        // vii° - E diminished (Leading Tone)
        XCTAssertEqual(triads[6].chord.description, "E°")
        XCTAssertEqual(triads[6].romanNumeral, romanNumeral(for: .leadingTone))
        XCTAssertEqual(triads[6].function, .leadingTone)
        XCTAssertEqual(triads[6].degreeName, degreeName(for: .leadingTone))
    }
    
    func testDiatonicChordsGenerationGMajor() {
        // Given: G major key
        theoryEngine.setKey("G", scaleType: "major")
        
        // When: Getting diatonic chords
        let triads = theoryEngine.getDiatonicChordsWithAnalysis()
        
        // Then: Should have 7 diatonic chords
        XCTAssertEqual(triads.count, 7)
        
        // Verify all diatonic chords in G major
        // I - G major (Tonic)
        XCTAssertEqual(triads[0].chord.description, "G")
        XCTAssertEqual(triads[0].romanNumeral, romanNumeral(for: .tonic))
        XCTAssertEqual(triads[0].function, .tonic)
        XCTAssertEqual(triads[0].degreeName, degreeName(for: .tonic))
        
        // ii - A minor (Supertonic)
        XCTAssertEqual(triads[1].chord.description, "Am")
        XCTAssertEqual(triads[1].romanNumeral, romanNumeral(for: .supertonic))
        XCTAssertEqual(triads[1].function, .supertonic)
        XCTAssertEqual(triads[1].degreeName, degreeName(for: .supertonic))
        
        // iii - B minor (Mediant)
        XCTAssertEqual(triads[2].chord.description, "Bm")
        XCTAssertEqual(triads[2].romanNumeral, romanNumeral(for: .mediant))
        XCTAssertEqual(triads[2].function, .mediant)
        XCTAssertEqual(triads[2].degreeName, degreeName(for: .mediant))
        
        // IV - C major (Subdominant)
        XCTAssertEqual(triads[3].chord.description, "C")
        XCTAssertEqual(triads[3].romanNumeral, romanNumeral(for: .subdominant))
        XCTAssertEqual(triads[3].function, .subdominant)
        XCTAssertEqual(triads[3].degreeName, degreeName(for: .subdominant))
        
        // V - D major (Dominant)
        XCTAssertEqual(triads[4].chord.description, "D")
        XCTAssertEqual(triads[4].romanNumeral, romanNumeral(for: .dominant))
        XCTAssertEqual(triads[4].function, .dominant)
        XCTAssertEqual(triads[4].degreeName, degreeName(for: .dominant))
        
        // vi - E minor (Submediant)
        XCTAssertEqual(triads[5].chord.description, "Em")
        XCTAssertEqual(triads[5].romanNumeral, romanNumeral(for: .submediant))
        XCTAssertEqual(triads[5].function, .submediant)
        XCTAssertEqual(triads[5].degreeName, degreeName(for: .submediant))
        
        // vii° - F# diminished (Leading Tone)
        XCTAssertEqual(triads[6].chord.description, "F♯°")
        XCTAssertEqual(triads[6].romanNumeral, romanNumeral(for: .leadingTone))
        XCTAssertEqual(triads[6].function, .leadingTone)
        XCTAssertEqual(triads[6].degreeName, degreeName(for: .leadingTone))
    }
    
    func testSeventhChordsGenerationGMajor() {
        // Given: G major key
        theoryEngine.setKey("G", scaleType: "major")
        
        // When: Getting seventh chords
        let sevenths = theoryEngine.getSeventhChordsWithAnalysis()
        
        // Then: Should have 7 seventh chords
        XCTAssertEqual(sevenths.count, 7)
        
        // Verify all seventh chords in G major
        // Imaj7 - G major 7 (Tonic)
        XCTAssertEqual(sevenths[0].chord.description, "Gmaj7")
        XCTAssertEqual(sevenths[0].romanNumeral, romanNumeral7(for: .tonic))
        XCTAssertEqual(sevenths[0].function, .tonic)
        XCTAssertEqual(sevenths[0].degreeName, degreeName(for: .tonic))
        
        // ii7 - A minor 7 (Supertonic)
        XCTAssertEqual(sevenths[1].chord.description, "Am7")
        XCTAssertEqual(sevenths[1].romanNumeral, romanNumeral7(for: .supertonic))
        XCTAssertEqual(sevenths[1].function, .supertonic)
        XCTAssertEqual(sevenths[1].degreeName, degreeName(for: .supertonic))
        
        // iii7 - B minor 7 (Mediant)
        XCTAssertEqual(sevenths[2].chord.description, "Bm7")
        XCTAssertEqual(sevenths[2].romanNumeral, romanNumeral7(for: .mediant))
        XCTAssertEqual(sevenths[2].function, .mediant)
        XCTAssertEqual(sevenths[2].degreeName, degreeName(for: .mediant))
        
        // IVmaj7 - C major 7 (Subdominant)
        XCTAssertEqual(sevenths[3].chord.description, "Cmaj7")
        XCTAssertEqual(sevenths[3].romanNumeral, romanNumeral7(for: .subdominant))
        XCTAssertEqual(sevenths[3].function, .subdominant)
        XCTAssertEqual(sevenths[3].degreeName, degreeName(for: .subdominant))
        
        // V7 - D dominant 7 (Dominant)
        XCTAssertEqual(sevenths[4].chord.description, "D7")
        XCTAssertEqual(sevenths[4].romanNumeral, romanNumeral7(for: .dominant))
        XCTAssertEqual(sevenths[4].function, .dominant)
        XCTAssertEqual(sevenths[4].degreeName, degreeName(for: .dominant))
        
        // vi7 - E minor 7 (Submediant)
        XCTAssertEqual(sevenths[5].chord.description, "Em7")
        XCTAssertEqual(sevenths[5].romanNumeral, romanNumeral7(for: .submediant))
        XCTAssertEqual(sevenths[5].function, .submediant)
        XCTAssertEqual(sevenths[5].degreeName, degreeName(for: .submediant))
        
        // vii°7 - F# half-diminished 7 (Leading Tone)
        XCTAssertEqual(sevenths[6].chord.description, "F♯ø7")
        XCTAssertEqual(sevenths[6].romanNumeral, romanNumeral7(for: .leadingTone))
        XCTAssertEqual(sevenths[6].function, .leadingTone)
        XCTAssertEqual(sevenths[6].degreeName, degreeName(for: .leadingTone))
    }
    
    func testSeventhChordsGenerationAMajor() {
        // Given: A major key
        theoryEngine.setKey("A", scaleType: "major")
        
        // When: Getting seventh chords
        let sevenths = theoryEngine.getSeventhChordsWithAnalysis()
        
        // Then: Should have 7 seventh chords
        XCTAssertEqual(sevenths.count, 7)
        
        // Verify all seventh chords in A major
        // Imaj7 - A major 7 (Tonic)
        XCTAssertEqual(sevenths[0].chord.description, "Amaj7")
        XCTAssertEqual(sevenths[0].romanNumeral, romanNumeral7(for: .tonic))
        XCTAssertEqual(sevenths[0].function, .tonic)
        XCTAssertEqual(sevenths[0].degreeName, degreeName(for: .tonic))
        
        // ii7 - B minor 7 (Supertonic)
        XCTAssertEqual(sevenths[1].chord.description, "Bm7")
        XCTAssertEqual(sevenths[1].romanNumeral, romanNumeral7(for: .supertonic))
        XCTAssertEqual(sevenths[1].function, .supertonic)
        XCTAssertEqual(sevenths[1].degreeName, degreeName(for: .supertonic))
        
        // iii7 - C# minor 7 (Mediant)
        XCTAssertEqual(sevenths[2].chord.description, "C♯m7")
        XCTAssertEqual(sevenths[2].romanNumeral, romanNumeral7(for: .mediant))
        XCTAssertEqual(sevenths[2].function, .mediant)
        XCTAssertEqual(sevenths[2].degreeName, degreeName(for: .mediant))
        
        // IVmaj7 - D major 7 (Subdominant)
        XCTAssertEqual(sevenths[3].chord.description, "Dmaj7")
        XCTAssertEqual(sevenths[3].romanNumeral, romanNumeral7(for: .subdominant))
        XCTAssertEqual(sevenths[3].function, .subdominant)
        XCTAssertEqual(sevenths[3].degreeName, degreeName(for: .subdominant))
        
        // V7 - E dominant 7 (Dominant)
        XCTAssertEqual(sevenths[4].chord.description, "E7")
        XCTAssertEqual(sevenths[4].romanNumeral, romanNumeral7(for: .dominant))
        XCTAssertEqual(sevenths[4].function, .dominant)
        XCTAssertEqual(sevenths[4].degreeName, degreeName(for: .dominant))
        
        // vi7 - F# minor 7 (Submediant)
        XCTAssertEqual(sevenths[5].chord.description, "F♯m7")
        XCTAssertEqual(sevenths[5].romanNumeral, romanNumeral7(for: .submediant))
        XCTAssertEqual(sevenths[5].function, .submediant)
        XCTAssertEqual(sevenths[5].degreeName, degreeName(for: .submediant))
        
        // vii°7 - G# half-diminished 7 (Leading Tone)
        XCTAssertEqual(sevenths[6].chord.description, "G♯ø7")
        XCTAssertEqual(sevenths[6].romanNumeral, romanNumeral7(for: .leadingTone))
        XCTAssertEqual(sevenths[6].function, .leadingTone)
        XCTAssertEqual(sevenths[6].degreeName, degreeName(for: .leadingTone))
    }
    
    func testSeventhChordsGenerationBMajor() {
        // Given: B major key
        theoryEngine.setKey("B", scaleType: "major")
        
        // When: Getting seventh chords
        let sevenths = theoryEngine.getSeventhChordsWithAnalysis()
        
        // Then: Should have 7 seventh chords
        XCTAssertEqual(sevenths.count, 7)
        
        // Verify all seventh chords in B major
        // Imaj7 - B major 7 (Tonic)
        XCTAssertEqual(sevenths[0].chord.description, "Bmaj7")
        XCTAssertEqual(sevenths[0].romanNumeral, romanNumeral7(for: .tonic))
        XCTAssertEqual(sevenths[0].function, .tonic)
        XCTAssertEqual(sevenths[0].degreeName, degreeName(for: .tonic))
        
        // ii7 - C# minor 7 (Supertonic)
        XCTAssertEqual(sevenths[1].chord.description, "C♯m7")
        XCTAssertEqual(sevenths[1].romanNumeral, romanNumeral7(for: .supertonic))
        XCTAssertEqual(sevenths[1].function, .supertonic)
        XCTAssertEqual(sevenths[1].degreeName, degreeName(for: .supertonic))
        
        // iii7 - D# minor 7 (Mediant)
        XCTAssertEqual(sevenths[2].chord.description, "D♯m7")
        XCTAssertEqual(sevenths[2].romanNumeral, romanNumeral7(for: .mediant))
        XCTAssertEqual(sevenths[2].function, .mediant)
        XCTAssertEqual(sevenths[2].degreeName, degreeName(for: .mediant))
        
        // IVmaj7 - E major 7 (Subdominant)
        XCTAssertEqual(sevenths[3].chord.description, "Emaj7")
        XCTAssertEqual(sevenths[3].romanNumeral, romanNumeral7(for: .subdominant))
        XCTAssertEqual(sevenths[3].function, .subdominant)
        XCTAssertEqual(sevenths[3].degreeName, degreeName(for: .subdominant))
        
        // V7 - F# dominant 7 (Dominant)
        XCTAssertEqual(sevenths[4].chord.description, "F♯7")
        XCTAssertEqual(sevenths[4].romanNumeral, romanNumeral7(for: .dominant))
        XCTAssertEqual(sevenths[4].function, .dominant)
        XCTAssertEqual(sevenths[4].degreeName, degreeName(for: .dominant))
        
        // vi7 - G# minor 7 (Submediant)
        XCTAssertEqual(sevenths[5].chord.description, "G♯m7")
        XCTAssertEqual(sevenths[5].romanNumeral, romanNumeral7(for: .submediant))
        XCTAssertEqual(sevenths[5].function, .submediant)
        XCTAssertEqual(sevenths[5].degreeName, degreeName(for: .submediant))
        
        // vii°7 - A# half-diminished 7 (Leading Tone)
        XCTAssertEqual(sevenths[6].chord.description, "A♯ø7")
        XCTAssertEqual(sevenths[6].romanNumeral, romanNumeral7(for: .leadingTone))
        XCTAssertEqual(sevenths[6].function, .leadingTone)
        XCTAssertEqual(sevenths[6].degreeName, degreeName(for: .leadingTone))
    }
    
    func testSeventhChordsGenerationCMajor() {
        // Given: C major key
        theoryEngine.setKey("C", scaleType: "major")
        
        // When: Getting seventh chords
        let sevenths = theoryEngine.getSeventhChordsWithAnalysis()
        
        // Then: Should have 7 seventh chords
        XCTAssertEqual(sevenths.count, 7)
        
        // Verify all seventh chords in C major
        // Imaj7 - C major 7 (Tonic)
        XCTAssertEqual(sevenths[0].chord.description, "Cmaj7")
        XCTAssertEqual(sevenths[0].romanNumeral, romanNumeral7(for: .tonic))
        XCTAssertEqual(sevenths[0].function, .tonic)
        XCTAssertEqual(sevenths[0].degreeName, degreeName(for: .tonic))
        
        // ii7 - D minor 7 (Supertonic)
        XCTAssertEqual(sevenths[1].chord.description, "Dm7")
        XCTAssertEqual(sevenths[1].romanNumeral, romanNumeral7(for: .supertonic))
        XCTAssertEqual(sevenths[1].function, .supertonic)
        XCTAssertEqual(sevenths[1].degreeName, degreeName(for: .supertonic))
        
        // iii7 - E minor 7 (Mediant)
        XCTAssertEqual(sevenths[2].chord.description, "Em7")
        XCTAssertEqual(sevenths[2].romanNumeral, romanNumeral7(for: .mediant))
        XCTAssertEqual(sevenths[2].function, .mediant)
        XCTAssertEqual(sevenths[2].degreeName, degreeName(for: .mediant))
        
        // IVmaj7 - F major 7 (Subdominant)
        XCTAssertEqual(sevenths[3].chord.description, "Fmaj7")
        XCTAssertEqual(sevenths[3].romanNumeral, romanNumeral7(for: .subdominant))
        XCTAssertEqual(sevenths[3].function, .subdominant)
        XCTAssertEqual(sevenths[3].degreeName, degreeName(for: .subdominant))
        
        // V7 - G dominant 7 (Dominant)
        XCTAssertEqual(sevenths[4].chord.description, "G7")
        XCTAssertEqual(sevenths[4].romanNumeral, romanNumeral7(for: .dominant))
        XCTAssertEqual(sevenths[4].function, .dominant)
        XCTAssertEqual(sevenths[4].degreeName, degreeName(for: .dominant))
        
        // vi7 - A minor 7 (Submediant)
        XCTAssertEqual(sevenths[5].chord.description, "Am7")
        XCTAssertEqual(sevenths[5].romanNumeral, romanNumeral7(for: .submediant))
        XCTAssertEqual(sevenths[5].function, .submediant)
        XCTAssertEqual(sevenths[5].degreeName, degreeName(for: .submediant))
        
        // vii°7 - B half-diminished 7 (Leading Tone)
        XCTAssertEqual(sevenths[6].chord.description, "Bø7")
        XCTAssertEqual(sevenths[6].romanNumeral, romanNumeral7(for: .leadingTone))
        XCTAssertEqual(sevenths[6].function, .leadingTone)
        XCTAssertEqual(sevenths[6].degreeName, degreeName(for: .leadingTone))
    }
    
    func testSeventhChordsGenerationDMajor() {
        // Given: D major key
        theoryEngine.setKey("D", scaleType: "major")
        
        // When: Getting seventh chords
        let sevenths = theoryEngine.getSeventhChordsWithAnalysis()
        
        // Then: Should have 7 seventh chords
        XCTAssertEqual(sevenths.count, 7)
        
        // Verify all seventh chords in D major
        // Imaj7 - D major 7 (Tonic)
        XCTAssertEqual(sevenths[0].chord.description, "Dmaj7")
        XCTAssertEqual(sevenths[0].romanNumeral, romanNumeral7(for: .tonic))
        XCTAssertEqual(sevenths[0].function, .tonic)
        XCTAssertEqual(sevenths[0].degreeName, degreeName(for: .tonic))
        
        // ii7 - E minor 7 (Supertonic)
        XCTAssertEqual(sevenths[1].chord.description, "Em7")
        XCTAssertEqual(sevenths[1].romanNumeral, romanNumeral7(for: .supertonic))
        XCTAssertEqual(sevenths[1].function, .supertonic)
        XCTAssertEqual(sevenths[1].degreeName, degreeName(for: .supertonic))
        
        // iii7 - F# minor 7 (Mediant)
        XCTAssertEqual(sevenths[2].chord.description, "F♯m7")
        XCTAssertEqual(sevenths[2].romanNumeral, romanNumeral7(for: .mediant))
        XCTAssertEqual(sevenths[2].function, .mediant)
        XCTAssertEqual(sevenths[2].degreeName, degreeName(for: .mediant))
        
        // IVmaj7 - G major 7 (Subdominant)
        XCTAssertEqual(sevenths[3].chord.description, "Gmaj7")
        XCTAssertEqual(sevenths[3].romanNumeral, romanNumeral7(for: .subdominant))
        XCTAssertEqual(sevenths[3].function, .subdominant)
        XCTAssertEqual(sevenths[3].degreeName, degreeName(for: .subdominant))
        
        // V7 - A dominant 7 (Dominant)
        XCTAssertEqual(sevenths[4].chord.description, "A7")
        XCTAssertEqual(sevenths[4].romanNumeral, romanNumeral7(for: .dominant))
        XCTAssertEqual(sevenths[4].function, .dominant)
        XCTAssertEqual(sevenths[4].degreeName, degreeName(for: .dominant))
        
        // vi7 - B minor 7 (Submediant)
        XCTAssertEqual(sevenths[5].chord.description, "Bm7")
        XCTAssertEqual(sevenths[5].romanNumeral, romanNumeral7(for: .submediant))
        XCTAssertEqual(sevenths[5].function, .submediant)
        XCTAssertEqual(sevenths[5].degreeName, degreeName(for: .submediant))
        
        // vii°7 - C# half-diminished 7 (Leading Tone)
        XCTAssertEqual(sevenths[6].chord.description, "C♯ø7")
        XCTAssertEqual(sevenths[6].romanNumeral, romanNumeral7(for: .leadingTone))
        XCTAssertEqual(sevenths[6].function, .leadingTone)
        XCTAssertEqual(sevenths[6].degreeName, degreeName(for: .leadingTone))
    }
    
    func testSeventhChordsGenerationEMajor() {
        // Given: E major key
        theoryEngine.setKey("E", scaleType: "major")
        
        // When: Getting seventh chords
        let sevenths = theoryEngine.getSeventhChordsWithAnalysis()
        
        // Then: Should have 7 seventh chords
        XCTAssertEqual(sevenths.count, 7)
        
        // Verify all seventh chords in E major
        // Imaj7 - E major 7 (Tonic)
        XCTAssertEqual(sevenths[0].chord.description, "Emaj7")
        XCTAssertEqual(sevenths[0].romanNumeral, romanNumeral7(for: .tonic))
        XCTAssertEqual(sevenths[0].function, .tonic)
        XCTAssertEqual(sevenths[0].degreeName, degreeName(for: .tonic))
        
        // ii7 - F# minor 7 (Supertonic)
        XCTAssertEqual(sevenths[1].chord.description, "F♯m7")
        XCTAssertEqual(sevenths[1].romanNumeral, romanNumeral7(for: .supertonic))
        XCTAssertEqual(sevenths[1].function, .supertonic)
        XCTAssertEqual(sevenths[1].degreeName, degreeName(for: .supertonic))
        
        // iii7 - G# minor 7 (Mediant)
        XCTAssertEqual(sevenths[2].chord.description, "G♯m7")
        XCTAssertEqual(sevenths[2].romanNumeral, romanNumeral7(for: .mediant))
        XCTAssertEqual(sevenths[2].function, .mediant)
        XCTAssertEqual(sevenths[2].degreeName, degreeName(for: .mediant))
        
        // IVmaj7 - A major 7 (Subdominant)
        XCTAssertEqual(sevenths[3].chord.description, "Amaj7")
        XCTAssertEqual(sevenths[3].romanNumeral, romanNumeral7(for: .subdominant))
        XCTAssertEqual(sevenths[3].function, .subdominant)
        XCTAssertEqual(sevenths[3].degreeName, degreeName(for: .subdominant))
        
        // V7 - B dominant 7 (Dominant)
        XCTAssertEqual(sevenths[4].chord.description, "B7")
        XCTAssertEqual(sevenths[4].romanNumeral, romanNumeral7(for: .dominant))
        XCTAssertEqual(sevenths[4].function, .dominant)
        XCTAssertEqual(sevenths[4].degreeName, degreeName(for: .dominant))
        
        // vi7 - C# minor 7 (Submediant)
        XCTAssertEqual(sevenths[5].chord.description, "C♯m7")
        XCTAssertEqual(sevenths[5].romanNumeral, romanNumeral7(for: .submediant))
        XCTAssertEqual(sevenths[5].function, .submediant)
        XCTAssertEqual(sevenths[5].degreeName, degreeName(for: .submediant))
        
        // vii°7 - D# half-diminished 7 (Leading Tone)
        XCTAssertEqual(sevenths[6].chord.description, "D♯ø7")
        XCTAssertEqual(sevenths[6].romanNumeral, romanNumeral7(for: .leadingTone))
        XCTAssertEqual(sevenths[6].function, .leadingTone)
        XCTAssertEqual(sevenths[6].degreeName, degreeName(for: .leadingTone))
    }
    
    func testSeventhChordsGenerationFMajor() {
        // Given: F major key
        theoryEngine.setKey("F", scaleType: "major")
        
        // When: Getting seventh chords
        let sevenths = theoryEngine.getSeventhChordsWithAnalysis()
        
        // Then: Should have 7 seventh chords
        XCTAssertEqual(sevenths.count, 7)
        
        // Verify all seventh chords in F major
        // Imaj7 - F major 7 (Tonic)
        XCTAssertEqual(sevenths[0].chord.description, "Fmaj7")
        XCTAssertEqual(sevenths[0].romanNumeral, romanNumeral7(for: .tonic))
        XCTAssertEqual(sevenths[0].function, .tonic)
        XCTAssertEqual(sevenths[0].degreeName, degreeName(for: .tonic))
        
        // ii7 - G minor 7 (Supertonic)
        XCTAssertEqual(sevenths[1].chord.description, "Gm7")
        XCTAssertEqual(sevenths[1].romanNumeral, romanNumeral7(for: .supertonic))
        XCTAssertEqual(sevenths[1].function, .supertonic)
        XCTAssertEqual(sevenths[1].degreeName, degreeName(for: .supertonic))
        
        // iii7 - A minor 7 (Mediant)
        XCTAssertEqual(sevenths[2].chord.description, "Am7")
        XCTAssertEqual(sevenths[2].romanNumeral, romanNumeral7(for: .mediant))
        XCTAssertEqual(sevenths[2].function, .mediant)
        XCTAssertEqual(sevenths[2].degreeName, degreeName(for: .mediant))
        
        // IVmaj7 - Bb major 7 (Subdominant)
        XCTAssertEqual(sevenths[3].chord.description, "B♭maj7")
        XCTAssertEqual(sevenths[3].romanNumeral, romanNumeral7(for: .subdominant))
        XCTAssertEqual(sevenths[3].function, .subdominant)
        XCTAssertEqual(sevenths[3].degreeName, degreeName(for: .subdominant))
        
        // V7 - C dominant 7 (Dominant)
        XCTAssertEqual(sevenths[4].chord.description, "C7")
        XCTAssertEqual(sevenths[4].romanNumeral, romanNumeral7(for: .dominant))
        XCTAssertEqual(sevenths[4].function, .dominant)
        XCTAssertEqual(sevenths[4].degreeName, degreeName(for: .dominant))
        
        // vi7 - D minor 7 (Submediant)
        XCTAssertEqual(sevenths[5].chord.description, "Dm7")
        XCTAssertEqual(sevenths[5].romanNumeral, romanNumeral7(for: .submediant))
        XCTAssertEqual(sevenths[5].function, .submediant)
        XCTAssertEqual(sevenths[5].degreeName, degreeName(for: .submediant))
        
        // vii°7 - E half-diminished 7 (Leading Tone)
        XCTAssertEqual(sevenths[6].chord.description, "Eø7")
        XCTAssertEqual(sevenths[6].romanNumeral, romanNumeral7(for: .leadingTone))
        XCTAssertEqual(sevenths[6].function, .leadingTone)
        XCTAssertEqual(sevenths[6].degreeName, degreeName(for: .leadingTone))
    }
    
    func testChordVisualizationState() {
        // Given: No selected chord
        XCTAssertNil(theoryEngine.selectedChord)
        XCTAssertNil(theoryEngine.visualizedChord)
        
        // When: Selecting a chord from timeline
        let chord = Chord(.C, type: .major)
        theoryEngine.selectedChord = chord
        
        // Then: Selected chord should be set
        XCTAssertEqual(theoryEngine.selectedChord?.description, chord.description)
    }
    
    func testProgressionTempo() {
        // Given: Default tempo
        XCTAssertEqual(theoryEngine.currentProgressionTempo, 120)
        
        // When: Changing tempo
        theoryEngine.currentProgressionTempo = 140
        
        // Then: Tempo should update
        XCTAssertEqual(theoryEngine.currentProgressionTempo, 140)
    }
    
    func testDataManagerIntegration() throws {
        // Given: Initial user data
        let userData = try dataManager.getOrCreateUserData()
        
        // When: Updating via DataManager
        try dataManager.updateUserData { data in
            data.currentKey = "D"
            data.currentScale = "minor"
        }
        
        // Then: Changes should persist
        let updatedData = try dataManager.getOrCreateUserData()
        XCTAssertEqual(updatedData.currentKey, "D")
        XCTAssertEqual(updatedData.currentScale, "minor")
    }
    
    // MARK: - Chord Tone Role Mapping Tests
    
    func testChordToneRolesMajorTriad() {
        // Given: A C major triad
        let chord = Chord(.C, type: .major)
        
        // When: Getting chord tone roles
        let roles = theoryEngine.getChordToneRoles(for: chord)
        
        // Then: Should have correct roles
        XCTAssertEqual(roles.count, 3)
        XCTAssertEqual(roles[0].note, .C)
        XCTAssertEqual(roles[0].role, "Root")
        XCTAssertEqual(roles[1].note, .E)
        XCTAssertEqual(roles[1].role, "Third")
        XCTAssertEqual(roles[2].note, .G)
        XCTAssertEqual(roles[2].role, "Fifth")
    }
    
    func testChordToneRolesMinorTriad() {
        // Given: An A minor triad
        let chord = Chord(.A, type: .minor)
        
        // When: Getting chord tone roles
        let roles = theoryEngine.getChordToneRoles(for: chord)
        
        // Then: Should have correct roles
        XCTAssertEqual(roles.count, 3)
        XCTAssertEqual(roles[0].note, .A)
        XCTAssertEqual(roles[0].role, "Root")
        XCTAssertEqual(roles[1].note, .C)
        XCTAssertEqual(roles[1].role, "Third")
        XCTAssertEqual(roles[2].note, .E)
        XCTAssertEqual(roles[2].role, "Fifth")
    }
    
    func testChordToneRolesDiminishedTriad() {
        // Given: A B diminished triad
        let chord = Chord(.B, type: .dim)
        
        // When: Getting chord tone roles
        let roles = theoryEngine.getChordToneRoles(for: chord)
        
        // Then: Should have correct roles
        XCTAssertEqual(roles.count, 3)
        XCTAssertEqual(roles[0].note, .B)
        XCTAssertEqual(roles[0].role, "Root")
        XCTAssertEqual(roles[1].note, .D)
        XCTAssertEqual(roles[1].role, "Third")
        XCTAssertEqual(roles[2].note, .F)
        XCTAssertEqual(roles[2].role, "Fifth")
    }
    
    func testChordToneRolesMajor7() {
        // Given: A D major 7 chord
        let chord = Chord(.D, type: .maj7)
        
        // When: Getting chord tone roles
        let roles = theoryEngine.getChordToneRoles(for: chord)
        
        // Then: Should have correct roles including seventh
        XCTAssertEqual(roles.count, 4)
        XCTAssertEqual(roles[0].note, .D)
        XCTAssertEqual(roles[0].role, "Root")
        XCTAssertEqual(roles[1].note, .Fs)
        XCTAssertEqual(roles[1].role, "Third")
        XCTAssertEqual(roles[2].note, .A)
        XCTAssertEqual(roles[2].role, "Fifth")
        XCTAssertEqual(roles[3].note, .Cs)
        XCTAssertEqual(roles[3].role, "Seventh")
    }
    
    func testChordToneRolesMinor7() {
        // Given: An E minor 7 chord
        let chord = Chord(.E, type: .min7)
        
        // When: Getting chord tone roles
        let roles = theoryEngine.getChordToneRoles(for: chord)
        
        // Then: Should have correct roles
        XCTAssertEqual(roles.count, 4)
        XCTAssertEqual(roles[0].note, .E)
        XCTAssertEqual(roles[0].role, "Root")
        XCTAssertEqual(roles[1].note, .G)
        XCTAssertEqual(roles[1].role, "Third")
        XCTAssertEqual(roles[2].note, .B)
        XCTAssertEqual(roles[2].role, "Fifth")
        XCTAssertEqual(roles[3].note, .D)
        XCTAssertEqual(roles[3].role, "Seventh")
    }
    
    func testChordToneRolesDominant7() {
        // Given: A G7 chord
        let chord = Chord(.G, type: .dom7)
        
        // When: Getting chord tone roles
        let roles = theoryEngine.getChordToneRoles(for: chord)
        
        // Then: Should have correct roles
        XCTAssertEqual(roles.count, 4)
        XCTAssertEqual(roles[0].note, .G)
        XCTAssertEqual(roles[0].role, "Root")
        XCTAssertEqual(roles[1].note, .B)
        XCTAssertEqual(roles[1].role, "Third")
        XCTAssertEqual(roles[2].note, .D)
        XCTAssertEqual(roles[2].role, "Fifth")
        XCTAssertEqual(roles[3].note, .F)
        XCTAssertEqual(roles[3].role, "Seventh")
    }
    
    func testChordToneRolesHalfDiminished7() {
        // Given: A B half-diminished 7 chord
        let chord = Chord(.B, type: .halfDim7)
        
        // When: Getting chord tone roles
        let roles = theoryEngine.getChordToneRoles(for: chord)
        
        // Then: Should have correct roles
        XCTAssertEqual(roles.count, 4)
        XCTAssertEqual(roles[0].note, .B)
        XCTAssertEqual(roles[0].role, "Root")
        XCTAssertEqual(roles[1].note, .D)
        XCTAssertEqual(roles[1].role, "Third")
        XCTAssertEqual(roles[2].note, .F)
        XCTAssertEqual(roles[2].role, "Fifth")
        XCTAssertEqual(roles[3].note, .A)
        XCTAssertEqual(roles[3].role, "Seventh")
    }
    
    func testChordToneRolesAugmentedTriad() {
        // Given: A C augmented triad
        let chord = Chord(.C, type: .aug)
        
        // When: Getting chord tone roles
        let roles = theoryEngine.getChordToneRoles(for: chord)
        
        // Then: Should have correct roles
        XCTAssertEqual(roles.count, 3)
        XCTAssertEqual(roles[0].note, .C)
        XCTAssertEqual(roles[0].role, "Root")
        XCTAssertEqual(roles[1].note, .E)
        XCTAssertEqual(roles[1].role, "Third")
        XCTAssertEqual(roles[2].note, .Gs)
        XCTAssertEqual(roles[2].role, "Fifth")
    }
    
    func testChordToneRolesWithFlats() {
        // Given: An F major 7 chord (contains B♭)
        let chord = Chord(.F, type: .maj7)
        
        // When: Getting chord tone roles
        let roles = theoryEngine.getChordToneRoles(for: chord)
        
        // Then: Should have correct roles with flats
        XCTAssertEqual(roles.count, 4)
        XCTAssertEqual(roles[0].note, .F)
        XCTAssertEqual(roles[0].role, "Root")
        XCTAssertEqual(roles[1].note, .A)
        XCTAssertEqual(roles[1].role, "Third")
        XCTAssertEqual(roles[2].note, .C)
        XCTAssertEqual(roles[2].role, "Fifth")
        XCTAssertEqual(roles[3].note, .E)
        XCTAssertEqual(roles[3].role, "Seventh")
    }
    
    func testChordToneRolesEdgeCase() {
        // Given: A chord with fewer than 3 notes (edge case)
        // Note: This would require creating a custom chord, which may not be possible
        // with the current API. Testing that standard chords always have at least 3 notes.
        
        // Test with various chord types to ensure they all have expected note counts
        let testCases: [(Chord, Int)] = [
            (Chord(.C, type: .major), 3),
            (Chord(.D, type: .minor), 3),
            (Chord(.E, type: .dim), 3),
            (Chord(.F, type: .aug), 3),
            (Chord(.G, type: .maj7), 4),
            (Chord(.A, type: .min7), 4),
            (Chord(.B, type: .dom7), 4),
            (Chord(.C, type: .halfDim7), 4)
        ]
        
        for (chord, expectedCount) in testCases {
            let roles = theoryEngine.getChordToneRoles(for: chord)
            XCTAssertEqual(roles.count, expectedCount, "Chord \(chord.description) should have \(expectedCount) roles")
        }
    }
    
    func testChordToneRolesConsistency() {
        // Given: Multiple calls for the same chord
        let chord = Chord(.C, type: .maj7)
        
        // When: Getting roles multiple times
        let roles1 = theoryEngine.getChordToneRoles(for: chord)
        let roles2 = theoryEngine.getChordToneRoles(for: chord)
        let roles3 = theoryEngine.getChordToneRoles(for: chord)
        
        // Then: Results should be consistent
        XCTAssertEqual(roles1.count, roles2.count)
        XCTAssertEqual(roles2.count, roles3.count)
        
        for i in 0..<roles1.count {
            XCTAssertEqual(roles1[i].note, roles2[i].note)
            XCTAssertEqual(roles2[i].note, roles3[i].note)
            XCTAssertEqual(roles1[i].role, roles2[i].role)
            XCTAssertEqual(roles2[i].role, roles3[i].role)
        }
    }
    
    // MARK: - Key Change Persistence Tests
    
    func testKeyChangePersistence() async throws {
        // Given: Initial state
        let initialData = try dataManager.getOrCreateUserData()
        let originalKey = initialData.currentKey
        
        // When: Changing key in theory engine
        theoryEngine.setKey("G", scaleType: "major")
        
        // Then: Verify theory engine updated
        XCTAssertEqual(theoryEngine.currentKey, "G")
        
        // When: Manually persisting to DataManager (simulating what ChordVisualizerView does)
        try dataManager.updateUserData { userData in
            userData.currentKey = "G"
            userData.currentScale = "major"
        }
        
        // Then: Verify persistence
        let updatedData = try dataManager.getOrCreateUserData()
        XCTAssertEqual(updatedData.currentKey, "G")
        XCTAssertEqual(updatedData.currentScale, "major")
        XCTAssertNotEqual(updatedData.currentKey, originalKey)
    }
    
    func testMultipleKeyChangePersistence() async throws {
        // Given: A sequence of key changes
        let keySequence = ["C", "G", "D", "A", "E", "B", "F"]
        
        for key in keySequence {
            // When: Setting key
            theoryEngine.setKey(key, scaleType: "major")
            
            // And: Persisting to DataManager
            try dataManager.updateUserData { userData in
                userData.currentKey = key
                userData.currentScale = "major"
            }
            
            // Then: Verify immediate persistence
            let data = try dataManager.getOrCreateUserData()
            XCTAssertEqual(data.currentKey, key)
            XCTAssertEqual(data.currentScale, "major")
        }
        
        // Final verification
        let finalData = try dataManager.getOrCreateUserData()
        XCTAssertEqual(finalData.currentKey, "F")
    }
    
    func testKeyChangeWithScaleTypePersistence() async throws {
        // Test different scale types
        let testCases: [(key: String, scale: String)] = [
            ("C", "major"),
            ("A", "minor"),
            ("D", "major"),
            ("B", "minor")
        ]
        
        for testCase in testCases {
            // When: Setting key and scale
            theoryEngine.setKey(testCase.key, scaleType: testCase.scale)
            
            // And: Persisting
            try dataManager.updateUserData { userData in
                userData.currentKey = testCase.key
                userData.currentScale = testCase.scale
            }
            
            // Then: Verify persistence
            let data = try dataManager.getOrCreateUserData()
            XCTAssertEqual(data.currentKey, testCase.key)
            XCTAssertEqual(data.currentScale, testCase.scale)
        }
    }
    
    func testKeyChangePersistenceFailureHandling() async throws {
        // Given: Current state
        let initialKey = theoryEngine.currentKey
        
        // When: Setting a new key in theory engine
        theoryEngine.setKey("D", scaleType: "major")
        XCTAssertEqual(theoryEngine.currentKey, "D")
        
        // But: Not persisting to DataManager (simulating a failure/interruption)
        
        // Then: DataManager should still have the old value
        let data = try dataManager.getOrCreateUserData()
        XCTAssertNotEqual(data.currentKey, "D")
        
        // And: Theory engine and DataManager are out of sync
        XCTAssertNotEqual(theoryEngine.currentKey, data.currentKey)
    }
    
    func testKeyChangeClearsCachedData() {
        // Given: Initial state with some data
        theoryEngine.setKey("C", scaleType: "major")
        let initialTriads = theoryEngine.getDiatonicChordsWithAnalysis()
        XCTAssertEqual(initialTriads.count, 7)
        
        // When: Changing key
        theoryEngine.setKey("G", scaleType: "major")
        
        // Then: New chords should be different
        let newTriads = theoryEngine.getDiatonicChordsWithAnalysis()
        XCTAssertEqual(newTriads.count, 7)
        
        // Verify the tonic changed
        XCTAssertEqual(initialTriads[0].chord.root, .C)
        XCTAssertEqual(newTriads[0].chord.root, .G)
    }
    
    func testKeyChangeMaintainsProgression() {
        // Given: A progression in C major
        theoryEngine.setKey("C", scaleType: "major")
        theoryEngine.addChordToProgression(Chord(.C, type: .major))
        theoryEngine.addChordToProgression(Chord(.F, type: .major))
        theoryEngine.addChordToProgression(Chord(.G, type: .major))
        
        let originalProgressionCount = theoryEngine.currentProgression.count
        XCTAssertEqual(originalProgressionCount, 3)
        
        // When: Changing key
        theoryEngine.setKey("G", scaleType: "major")
        
        // Then: Progression should be maintained
        XCTAssertEqual(theoryEngine.currentProgression.count, originalProgressionCount)
        XCTAssertEqual(theoryEngine.currentProgression[0].chord.description, "C")
        XCTAssertEqual(theoryEngine.currentProgression[1].chord.description, "F")
        XCTAssertEqual(theoryEngine.currentProgression[2].chord.description, "G")
    }
    
    func testKeyChangeUpdatesRomanNumerals() {
        // Given: A chord that exists in multiple keys
        let fChord = Chord(.F, type: .major)
        
        // When: In C major
        theoryEngine.setKey("C", scaleType: "major")
        let romanInC = theoryEngine.getRomanNumeral(for: "F")
        
        // When: In G major
        theoryEngine.setKey("G", scaleType: "major")
        let romanInG = theoryEngine.getRomanNumeral(for: "F")
        
        // Then: Roman numerals should be different
        XCTAssertNotEqual(romanInC, romanInG)
        XCTAssertEqual(romanInC, "IV") // F is IV in C major
        XCTAssertEqual(romanInG, "♭VII") // F is ♭VII in G major
    }
    
    func testRapidKeyChanges() async throws {
        // Test rapid key changes don't cause issues
        let keys = ["C", "G", "D", "A", "E", "B", "F", "C"]
        
        for (index, key) in keys.enumerated() {
            // Rapidly change keys
            theoryEngine.setKey(key, scaleType: "major")
            
            // Immediately persist
            try dataManager.updateUserData { userData in
                userData.currentKey = key
            }
            
            // Verify state is consistent
            XCTAssertEqual(theoryEngine.currentKey, key)
            
            // Small delay to simulate real usage
            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        }
        
        // Final verification
        let finalData = try dataManager.getOrCreateUserData()
        XCTAssertEqual(finalData.currentKey, "C")
        XCTAssertEqual(theoryEngine.currentKey, "C")
    }
    
    func testKeyChangeAffectsDiatonicChords() {
        // Given: Two different keys
        theoryEngine.setKey("C", scaleType: "major")
        let cMajorTriads = theoryEngine.getDiatonicChordsWithAnalysis()
        
        theoryEngine.setKey("F", scaleType: "major")
        let fMajorTriads = theoryEngine.getDiatonicChordsWithAnalysis()
        
        // Then: Verify specific differences
        // In C major: vii° is B dim
        // In F major: vii° is E dim
        XCTAssertEqual(cMajorTriads[6].chord.root, .B)
        XCTAssertEqual(fMajorTriads[6].chord.root, .E)
        
        // In C major: IV is F major
        // In F major: IV is Bb major
        XCTAssertEqual(cMajorTriads[3].chord.root, .F)
        XCTAssertEqual(fMajorTriads[3].chord.root, .Bb)
    }
    
    // MARK: - Chord Type Switching Tests
    
    func testChordTypeSwitchingBasic() {
        // Given: Initial state with C major
        theoryEngine.setKey("C", scaleType: "major")
        
        // When: Getting triads
        let triads = theoryEngine.getDiatonicChordsWithAnalysis()
        
        // Then: Should have 7 triads with 3 notes each
        XCTAssertEqual(triads.count, 7)
        XCTAssertEqual(triads[0].chord.noteClasses.count, 3)
        XCTAssertEqual(triads[0].chord.description, "C")
        
        // When: Getting sevenths
        let sevenths = theoryEngine.getSeventhChordsWithAnalysis()
        
        // Then: Should have 7 seventh chords with 4 notes each
        XCTAssertEqual(sevenths.count, 7)
        XCTAssertEqual(sevenths[0].chord.noteClasses.count, 4)
        XCTAssertEqual(sevenths[0].chord.description, "Cmaj7")
    }
    
    func testChordTypeSwitchingPreservesKey() {
        // Given: Set to G major
        theoryEngine.setKey("G", scaleType: "major")
        
        // When: Getting different chord types
        let triads = theoryEngine.getDiatonicChordsWithAnalysis()
        let sevenths = theoryEngine.getSeventhChordsWithAnalysis()
        
        // Then: Both should be in G major
        XCTAssertEqual(triads[0].chord.root, .G)
        XCTAssertEqual(sevenths[0].chord.root, .G)
        
        // And: Key should remain unchanged
        XCTAssertEqual(theoryEngine.currentKey, "G")
    }
    
    func testChordTypeSwitchingRomanNumerals() {
        // Given: D major key
        theoryEngine.setKey("D", scaleType: "major")
        
        // When: Getting triads and sevenths
        let triads = theoryEngine.getDiatonicChordsWithAnalysis()
        let sevenths = theoryEngine.getSeventhChordsWithAnalysis()
        
        // Then: Roman numerals should differ appropriately
        // Triads
        XCTAssertEqual(triads[0].romanNumeral, "I")
        XCTAssertEqual(triads[1].romanNumeral, "ii")
        XCTAssertEqual(triads[3].romanNumeral, "IV")
        XCTAssertEqual(triads[4].romanNumeral, "V")
        
        // Sevenths
        XCTAssertEqual(sevenths[0].romanNumeral, "Imaj7")
        XCTAssertEqual(sevenths[1].romanNumeral, "ii7")
        XCTAssertEqual(sevenths[3].romanNumeral, "IVmaj7")
        XCTAssertEqual(sevenths[4].romanNumeral, "V7")
    }
    
    func testChordTypeSwitchingFunctions() {
        // Given: Any major key
        theoryEngine.setKey("F", scaleType: "major")
        
        // When: Getting both chord types
        let triads = theoryEngine.getDiatonicChordsWithAnalysis()
        let sevenths = theoryEngine.getSeventhChordsWithAnalysis()
        
        // Then: Functions should be the same for corresponding positions
        for i in 0..<7 {
            XCTAssertEqual(triads[i].function, sevenths[i].function,
                          "Function should match at position \(i)")
            XCTAssertEqual(triads[i].degreeName, sevenths[i].degreeName,
                          "Degree name should match at position \(i)")
        }
    }
    
    func testChordTypeSwitchingSpecificChords() {
        // Given: A major key
        theoryEngine.setKey("A", scaleType: "major")
        
        // When: Getting specific chord comparisons
        let triads = theoryEngine.getDiatonicChordsWithAnalysis()
        let sevenths = theoryEngine.getSeventhChordsWithAnalysis()
        
        // Then: Verify specific chord transformations
        // I -> Imaj7
        XCTAssertEqual(triads[0].chord.description, "A")
        XCTAssertEqual(sevenths[0].chord.description, "Amaj7")
        
        // ii -> ii7
        XCTAssertEqual(triads[1].chord.description, "Bm")
        XCTAssertEqual(sevenths[1].chord.description, "Bm7")
        
        // V -> V7
        XCTAssertEqual(triads[4].chord.description, "E")
        XCTAssertEqual(sevenths[4].chord.description, "E7")
        
        // vii° -> viiø7
        XCTAssertEqual(triads[6].chord.description, "G♯°")
        XCTAssertEqual(sevenths[6].chord.description, "G♯ø7")
    }
    
    func testChordTypeSwitchingPerformance() {
        // Test that switching between types is efficient
        theoryEngine.setKey("E", scaleType: "major")
        
        // Measure multiple switches
        let startTime = Date()
        
        for _ in 0..<10 {
            _ = theoryEngine.getDiatonicChordsWithAnalysis()
            _ = theoryEngine.getSeventhChordsWithAnalysis()
        }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        // Should complete quickly (under 0.1 seconds for 20 operations)
        XCTAssertLessThan(elapsedTime, 0.1, "Chord type switching should be fast")
    }
    
    func testChordTypeSwitchingWithProgressions() {
        // Given: A progression with mixed chord types
        theoryEngine.setKey("C", scaleType: "major")
        
        // Add some triads
        theoryEngine.addChordToProgression(Chord(.C, type: .major))
        theoryEngine.addChordToProgression(Chord(.F, type: .major))
        
        // Add some seventh chords
        theoryEngine.addChordToProgression(Chord(.D, type: .min7))
        theoryEngine.addChordToProgression(Chord(.G, type: .dom7))
        
        // When: Getting different chord type analyses
        let triads = theoryEngine.getDiatonicChordsWithAnalysis()
        let sevenths = theoryEngine.getSeventhChordsWithAnalysis()
        
        // Then: Progression should remain unchanged
        XCTAssertEqual(theoryEngine.currentProgression.count, 4)
        XCTAssertEqual(theoryEngine.currentProgression[0].chord.description, "C")
        XCTAssertEqual(theoryEngine.currentProgression[1].chord.description, "F")
        XCTAssertEqual(theoryEngine.currentProgression[2].chord.description, "Dm7")
        XCTAssertEqual(theoryEngine.currentProgression[3].chord.description, "G7")
        
        // And: Both chord lists should be available
        XCTAssertEqual(triads.count, 7)
        XCTAssertEqual(sevenths.count, 7)
    }
    
    func testChordTypeSwitchingCaching() {
        // Test that repeated calls are consistent
        theoryEngine.setKey("B", scaleType: "major")
        
        // Get triads multiple times
        let triads1 = theoryEngine.getDiatonicChordsWithAnalysis()
        let triads2 = theoryEngine.getDiatonicChordsWithAnalysis()
        let triads3 = theoryEngine.getDiatonicChordsWithAnalysis()
        
        // All should be identical
        XCTAssertEqual(triads1.count, triads2.count)
        XCTAssertEqual(triads2.count, triads3.count)
        
        for i in 0..<triads1.count {
            XCTAssertEqual(triads1[i].chord.description, triads2[i].chord.description)
            XCTAssertEqual(triads2[i].chord.description, triads3[i].chord.description)
        }
        
        // Same for sevenths
        let sevenths1 = theoryEngine.getSeventhChordsWithAnalysis()
        let sevenths2 = theoryEngine.getSeventhChordsWithAnalysis()
        
        XCTAssertEqual(sevenths1.count, sevenths2.count)
        for i in 0..<sevenths1.count {
            XCTAssertEqual(sevenths1[i].chord.description, sevenths2[i].chord.description)
        }
    }
    
    func testChordTypeSwitchingEdgeCases() {
        // Test with all major keys using NoteClass for proper comparison
        let allKeys: [(String, NoteClass)] = [
            ("C", .C),
            ("G", .G),
            ("D", .D),
            ("A", .A),
            ("E", .E),
            ("B", .B),
            ("F", .F),
            ("Bb", .Bb),
            ("Eb", .Eb),
            ("Ab", .Ab),
            ("Db", .Db),
            ("Gb", .Gb)
        ]
        
        for (keyName, expectedRoot) in allKeys {
            theoryEngine.setKey(keyName, scaleType: "major")
            
            let triads = theoryEngine.getDiatonicChordsWithAnalysis()
            let sevenths = theoryEngine.getSeventhChordsWithAnalysis()
            
            // Basic validations
            XCTAssertEqual(triads.count, 7, "Key \(keyName) should have 7 triads")
            XCTAssertEqual(sevenths.count, 7, "Key \(keyName) should have 7 seventh chords")
            
            // Verify root notes match using NoteClass comparison
            XCTAssertEqual(triads[0].chord.root, expectedRoot,
                          "Tonic triad root should be \(expectedRoot)")
            XCTAssertEqual(sevenths[0].chord.root, expectedRoot,
                          "Tonic seventh root should be \(expectedRoot)")
        }
    }
    
    func testChordTypeMixedSelection() {
        // Test selecting chords from different types
        theoryEngine.setKey("D", scaleType: "major")
        
        // Get both types
        let triads = theoryEngine.getDiatonicChordsWithAnalysis()
        let sevenths = theoryEngine.getSeventhChordsWithAnalysis()
        
        // Simulate selecting a triad
        theoryEngine.selectedChord = triads[0].chord
        XCTAssertEqual(theoryEngine.selectedChord?.description, "D")
        
        // Then selecting a seventh
        theoryEngine.selectedChord = sevenths[1].chord
        XCTAssertEqual(theoryEngine.selectedChord?.description, "Em7")
        
        // Visualized chord should update accordingly
        theoryEngine.visualizedChord = triads[4].chord
        XCTAssertEqual(theoryEngine.visualizedChord?.description, "A")
    }
    
    func testChordTypeRoleMapping() {
        // Test that chord tone roles work correctly for both types
        theoryEngine.setKey("C", scaleType: "major")
        
        // Test triad roles
        let cMajor = Chord(.C, type: .major)
        let triadRoles = theoryEngine.getChordToneRoles(for: cMajor)
        XCTAssertEqual(triadRoles.count, 3)
        
        // Test seventh chord roles
        let cMaj7 = Chord(.C, type: .maj7)
        let seventhRoles = theoryEngine.getChordToneRoles(for: cMaj7)
        XCTAssertEqual(seventhRoles.count, 4)
        
        // Verify the first three roles match
        for i in 0..<3 {
            XCTAssertEqual(triadRoles[i].note, seventhRoles[i].note)
            XCTAssertEqual(triadRoles[i].role, seventhRoles[i].role)
        }
        
        // Seventh chord has additional seventh role
        XCTAssertEqual(seventhRoles[3].role, "Seventh")
    }
    
    // MARK: - Timeline Integration Tests
    
    func testTimelineChordSelection() {
        // Given: A progression with multiple chords
        theoryEngine.setKey("C", scaleType: "major")
        theoryEngine.addChordToProgression(Chord(.C, type: .major))
        theoryEngine.addChordToProgression(Chord(.F, type: .major))
        theoryEngine.addChordToProgression(Chord(.G, type: .major))
        theoryEngine.addChordToProgression(Chord(.A, type: .minor))
        
        // When: Selecting a chord from the timeline
        let selectedChord = theoryEngine.currentProgression[2].chord
        theoryEngine.selectedChord = selectedChord
        
        // Then: Selected chord should be set
        XCTAssertEqual(theoryEngine.selectedChord?.description, "G")
        
        // And: Visualized chord should be available for display
        theoryEngine.visualizedChord = selectedChord
        XCTAssertEqual(theoryEngine.visualizedChord?.description, "G")
    }
    
    func testTimelineSelectionClearsGridSelection() {
        // Given: A chord selected from the diatonic grid
        theoryEngine.setKey("D", scaleType: "major")
        let diatonicChords = theoryEngine.getDiatonicChordsWithAnalysis()
        let gridChord = diatonicChords[0].chord
        
        // Simulate grid selection
        theoryEngine.selectedChord = gridChord
        XCTAssertEqual(theoryEngine.selectedChord?.description, "D")
        
        // When: Selecting a chord from timeline
        theoryEngine.addChordToProgression(Chord(.G, type: .major))
        let timelineChord = theoryEngine.currentProgression[0].chord
        theoryEngine.selectedChord = timelineChord
        
        // Then: Grid selection should be replaced by timeline selection
        XCTAssertEqual(theoryEngine.selectedChord?.description, "G")
        XCTAssertNotEqual(theoryEngine.selectedChord?.description, gridChord.description)
    }
    
    func testTimelineProgressionPlayback() {
        // Given: A progression ready for playback
        theoryEngine.addChordToProgression(Chord(.C, type: .major))
        theoryEngine.addChordToProgression(Chord(.A, type: .minor))
        theoryEngine.addChordToProgression(Chord(.F, type: .major))
        theoryEngine.addChordToProgression(Chord(.G, type: .major))
        
        // When: Setting tempo
        theoryEngine.currentProgressionTempo = 140
        
        // Then: Progression and tempo should be ready for playback
        XCTAssertEqual(theoryEngine.currentProgression.count, 4)
        XCTAssertEqual(theoryEngine.currentProgressionTempo, 140)
        
        // Verify all chords are valid
        for playbackChord in theoryEngine.currentProgression {
            XCTAssertNotNil(playbackChord.chord)
            XCTAssertFalse(playbackChord.chord.noteClasses.isEmpty)
        }
    }
    
    func testTimelineChordReorderingIntegration() {
        // Given: A progression in the timeline
        theoryEngine.addChordToProgression(Chord(.C, type: .major))
        theoryEngine.addChordToProgression(Chord(.F, type: .major))
        theoryEngine.addChordToProgression(Chord(.G, type: .major))
        
        // When: Reordering via timeline interaction
        theoryEngine.reorderProgression(from: 2, to: 1)
        
        // Then: Timeline should reflect new order
        XCTAssertEqual(theoryEngine.currentProgression[0].chord.description, "C")
        XCTAssertEqual(theoryEngine.currentProgression[1].chord.description, "G")
        XCTAssertEqual(theoryEngine.currentProgression[2].chord.description, "F")
    }
    
    func testTimelineChordRemovalIntegration() {
        // Given: A progression
        theoryEngine.addChordToProgression(Chord(.D, type: .minor))
        theoryEngine.addChordToProgression(Chord(.G, type: .major))
        theoryEngine.addChordToProgression(Chord(.C, type: .major))
        
        // When: Removing a chord from timeline
        theoryEngine.removeFromProgression(at: 1)
        
        // Then: Timeline should update
        XCTAssertEqual(theoryEngine.currentProgression.count, 2)
        XCTAssertEqual(theoryEngine.currentProgression[0].chord.description, "Dm")
        XCTAssertEqual(theoryEngine.currentProgression[1].chord.description, "C")
    }
    
    func testTimelineEmptyStateHandling() {
        // Given: No progression
        XCTAssertTrue(theoryEngine.currentProgression.isEmpty)
        
        // When: Checking if timeline should be shown
        let shouldShowTimeline = !theoryEngine.currentProgression.isEmpty
        
        // Then: Timeline should not be shown
        XCTAssertFalse(shouldShowTimeline)
        
        // When: Adding first chord
        theoryEngine.addChordToProgression(Chord(.C, type: .major))
        
        // Then: Timeline should now be shown
        let shouldShowTimelineAfter = !theoryEngine.currentProgression.isEmpty
        XCTAssertTrue(shouldShowTimelineAfter)
    }
    
    func testTimelineMaxProgressionLength() {
        // Test that there's a reasonable limit to progression length
        // (Assuming max 16 chords for performance reasons)
        
        // Given: Add many chords
        for i in 0..<20 {
            let noteClass: NoteClass = [.C, .D, .E, .F, .G, .A, .B][i % 7]
            let chordType: ChordType = i % 2 == 0 ? .major : .minor
            theoryEngine.addChordToProgression(Chord(noteClass, type: chordType))
        }
        
        // Then: Should have a reasonable number of chords
        // (This test assumes no hard limit, but tracks behavior)
        XCTAssertEqual(theoryEngine.currentProgression.count, 20)
        
        // Verify all chords are valid and playable
        for playbackChord in theoryEngine.currentProgression {
            XCTAssertNotNil(playbackChord.chord)
            XCTAssertFalse(playbackChord.chord.noteClasses.isEmpty)
        }
    }
    
    func testTimelineChordVisualization() {
        // Given: A progression with a selected chord
        theoryEngine.addChordToProgression(Chord(.E, type: .minor))
        theoryEngine.addChordToProgression(Chord(.A, type: .minor))
        theoryEngine.addChordToProgression(Chord(.D, type: .major))
        
        // When: Selecting middle chord for visualization
        let chordToVisualize = theoryEngine.currentProgression[1].chord
        theoryEngine.selectedChord = chordToVisualize
        theoryEngine.visualizedChord = chordToVisualize
        
        // Then: Both should be set correctly
        XCTAssertEqual(theoryEngine.selectedChord?.description, "Am")
        XCTAssertEqual(theoryEngine.visualizedChord?.description, "Am")
    }
    
    func testTimelineTempoChanges() {
        // Given: A progression with default tempo
        theoryEngine.addChordToProgression(Chord(.C, type: .major))
        theoryEngine.addChordToProgression(Chord(.G, type: .major))
        XCTAssertEqual(theoryEngine.currentProgressionTempo, 120)
        
        // When: Changing tempo multiple times
        theoryEngine.currentProgressionTempo = 60
        XCTAssertEqual(theoryEngine.currentProgressionTempo, 60)
        
        theoryEngine.currentProgressionTempo = 200
        XCTAssertEqual(theoryEngine.currentProgressionTempo, 200)
        
        theoryEngine.currentProgressionTempo = 140
        XCTAssertEqual(theoryEngine.currentProgressionTempo, 140)
        
        // Then: Tempo should update each time
        XCTAssertEqual(theoryEngine.currentProgressionTempo, 140)
    }
    
    func testTimelineNonDiatonicChords() {
        // Given: Set key to C major
        theoryEngine.setKey("C", scaleType: "major")
        
        // When: Adding non-diatonic chords to timeline
        theoryEngine.addChordToProgression(Chord(.C, type: .major))      // I
        theoryEngine.addChordToProgression(Chord(.Eb, type: .major))     // bIII (borrowed)
        theoryEngine.addChordToProgression(Chord(.F, type: .minor))      // iv (borrowed)
        theoryEngine.addChordToProgression(Chord(.G, type: .major))      // V
        
        // Then: All chords should be in progression
        XCTAssertEqual(theoryEngine.currentProgression.count, 4)
        
        // Verify roman numeral analysis works for non-diatonic chords
        let ebRoman = theoryEngine.getRomanNumeral(for: "Eb")
        let fmRoman = theoryEngine.getRomanNumeral(for: "Fm")
        
        XCTAssertEqual(ebRoman, "♭III")
        XCTAssertEqual(fmRoman, "iv")
    }
    
    func testTimelineMixedChordTypes() {
        // Given: A progression with mixed triads and seventh chords
        theoryEngine.setKey("G", scaleType: "major")
        
        theoryEngine.addChordToProgression(Chord(.G, type: .major))      // I
        theoryEngine.addChordToProgression(Chord(.C, type: .maj7))       // IVmaj7
        theoryEngine.addChordToProgression(Chord(.D, type: .dom7))       // V7
        theoryEngine.addChordToProgression(Chord(.E, type: .minor))      // vi
        
        // Then: Timeline should handle mixed types
        XCTAssertEqual(theoryEngine.currentProgression.count, 4)
        XCTAssertEqual(theoryEngine.currentProgression[0].chord.noteClasses.count, 3) // Triad
        XCTAssertEqual(theoryEngine.currentProgression[1].chord.noteClasses.count, 4) // Seventh
        XCTAssertEqual(theoryEngine.currentProgression[2].chord.noteClasses.count, 4) // Seventh
        XCTAssertEqual(theoryEngine.currentProgression[3].chord.noteClasses.count, 3) // Triad
    }
    
    func testTimelineProgressionClearingBehavior() {
        // Given: A progression with chords
        theoryEngine.addChordToProgression(Chord(.C, type: .major))
        theoryEngine.addChordToProgression(Chord(.F, type: .major))
        theoryEngine.addChordToProgression(Chord(.G, type: .major))
        XCTAssertEqual(theoryEngine.currentProgression.count, 3)
        
        // When: Clearing the progression
        theoryEngine.clearProgression()
        
        // Then: Progression should be empty
        XCTAssertTrue(theoryEngine.currentProgression.isEmpty)
        
        // And: Tempo should reset to default
        XCTAssertEqual(theoryEngine.currentProgressionTempo, 120)
    }
    
    func testTimelineSelectionPersistence() {
        // Given: A progression with a selected chord
        theoryEngine.addChordToProgression(Chord(.A, type: .minor))
        theoryEngine.addChordToProgression(Chord(.D, type: .minor))
        theoryEngine.addChordToProgression(Chord(.G, type: .major))
        
        let selectedChord = theoryEngine.currentProgression[1].chord
        theoryEngine.selectedChord = selectedChord
        
        // When: Adding more chords
        theoryEngine.addChordToProgression(Chord(.C, type: .major))
        
        // Then: Selection should persist
        XCTAssertEqual(theoryEngine.selectedChord?.description, selectedChord.description)
        
        // When: Reordering
        theoryEngine.reorderProgression(from: 1, to: 3)
        
        // Then: Selected chord reference should still be valid
        XCTAssertEqual(theoryEngine.selectedChord?.description, "Dm")
    }
}
