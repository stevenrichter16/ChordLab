import XCTest
@testable import ChordLab
import Tonic

final class TonicExoticScalesTests: XCTestCase {
    
    // Store output for analysis
    private var testOutput: String = ""
    
    private func output(_ text: String) {
        print(text)
        testOutput += text + "\n"
    }
    
    // MARK: - Test each exotic scale type
    
    func testBluesScale() {
        print("\n=== BLUES SCALE ===")
        
        // Blues scale intervals: 1, b3, 4, b5, 5, b7
        let bluesIntervals: [Interval] = [.P1, .m3, .P4, .d5, .P5, .m7]
        
        // Test different approaches to create a blues scale
        testScaleApproaches(name: "Blues", intervals: bluesIntervals, root: .C)
    }
    
    func testWholeToneScale() {
        print("\n=== WHOLE TONE SCALE ===")
        
        // Whole tone scale intervals: 1, 2, 3, #4, #5, b7
        let wholeToneIntervals: [Interval] = [.P1, .M2, .M3, .A4, .A5, .m7]
        
        testScaleApproaches(name: "Whole Tone", intervals: wholeToneIntervals, root: .C)
    }
    
    func testChromaticScale() {
        print("\n=== CHROMATIC SCALE ===")
        
        // Chromatic scale: all 12 semitones
        let chromaticIntervals: [Interval] = [
            .P1, .m2, .M2, .m3, .M3, .P4, .A4, .P5, .m6, .M6, .m7, .M7
        ]
        
        testScaleApproaches(name: "Chromatic", intervals: chromaticIntervals, root: .C)
    }
    
    func testPentatonicMajorScale() {
        print("\n=== PENTATONIC MAJOR SCALE ===")
        
        // Major pentatonic intervals: 1, 2, 3, 5, 6
        let majorPentIntervals: [Interval] = [.P1, .M2, .M3, .P5, .M6]
        
        testScaleApproaches(name: "Major Pentatonic", intervals: majorPentIntervals, root: .C)
    }
    
    func testPentatonicMinorScale() {
        print("\n=== PENTATONIC MINOR SCALE ===")
        
        // Minor pentatonic intervals: 1, b3, 4, 5, b7
        let minorPentIntervals: [Interval] = [.P1, .m3, .P4, .P5, .m7]
        
        testScaleApproaches(name: "Minor Pentatonic", intervals: minorPentIntervals, root: .A)
    }
    
    func testHungarianMinorScale() {
        print("\n=== HUNGARIAN MINOR SCALE ===")
        
        // Hungarian minor intervals: 1, 2, b3, #4, 5, b6, 7
        let hungarianIntervals: [Interval] = [.P1, .M2, .m3, .A4, .P5, .m6, .M7]
        
        testScaleApproaches(name: "Hungarian Minor", intervals: hungarianIntervals, root: .C)
    }
    
    func testArabianScale() {
        print("\n=== ARABIAN SCALE (Phrygian Dominant) ===")
        
        // Arabian/Phrygian Dominant intervals: 1, b2, 3, 4, 5, b6, b7
        let arabianIntervals: [Interval] = [.P1, .m2, .M3, .P4, .P5, .m6, .m7]
        
        testScaleApproaches(name: "Arabian", intervals: arabianIntervals, root: .C)
    }
    
    func testHarmonicMinorScale() {
        print("\n=== HARMONIC MINOR SCALE ===")
        
        // Harmonic minor intervals: 1, 2, b3, 4, 5, b6, 7
        let harmonicMinorIntervals: [Interval] = [.P1, .M2, .m3, .P4, .P5, .m6, .M7]
        
        testScaleApproaches(name: "Harmonic Minor", intervals: harmonicMinorIntervals, root: .A)
    }
    
    func testMelodicMinorScale() {
        print("\n=== MELODIC MINOR SCALE ===")
        
        // Melodic minor intervals: 1, 2, b3, 4, 5, 6, 7
        let melodicMinorIntervals: [Interval] = [.P1, .M2, .m3, .P4, .P5, .M6, .M7]
        
        testScaleApproaches(name: "Melodic Minor", intervals: melodicMinorIntervals, root: .A)
    }
    
    // MARK: - Helper Methods
    
    private func testScaleApproaches(name: String, intervals: [Interval], root: NoteClass) {
        print("\nTesting \(name) scale rooted at \(root)")
        print("Intervals: \(intervals.map { $0.description }.joined(separator: ", "))")
        
        // Generate scale notes
        let scaleNotes = generateScaleNotes(root: root, intervals: intervals)
        print("Scale notes: \(scaleNotes.map { $0.description }.joined(separator: ", "))")
        
        // Try to create a Key object (if Tonic supports it)
        testKeyCreation(root: root, scaleName: name)
        
        // Test manual chord generation from scale notes
        testManualChordGeneration(scaleNotes: scaleNotes, scaleName: name)
        
        print("\n" + String(repeating: "-", count: 50))
    }
    
    private func generateScaleNotes(root: NoteClass, intervals: [Interval]) -> [NoteClass] {
        return intervals.compactMap { interval in
            root.canonicalNote.shiftUp(interval)?.noteClass
        }
    }
    
    private func testKeyCreation(root: NoteClass, scaleName: String) {
        print("\n--- Testing Key object creation ---")
        
        // Try major key
        let majorKey = Key(root: root, scale: .major)
        print("Major Key created: \(majorKey)")
        
        // Check what Tonic provides
        print("Primary triads: \(majorKey.primaryTriads.map { $0.description }.joined(separator: ", "))")
        print("All chords: \(majorKey.chords.map { $0.description }.joined(separator: ", "))")
        
        // Try minor key
        let minorKey = Key(root: root, scale: .minor)
        print("\nMinor Key created: \(minorKey)")
        
        print("Primary triads: \(minorKey.primaryTriads.map { $0.description }.joined(separator: ", "))")
        print("All chords: \(minorKey.chords.map { $0.description }.joined(separator: ", "))")
        
        // Check what scales Tonic supports
        print("\n--- Checking Scale enum cases ---")
        // Note: Tonic only has .major and .minor as Scale cases
    }
    
    private func testManualChordGeneration(scaleNotes: [NoteClass], scaleName: String) {
        print("\n--- Manual chord generation from scale ---")
        
        var triads: [Chord] = []
        var sevenths: [Chord] = []
        
        // Try to build triads on each scale degree
        for (index, root) in scaleNotes.enumerated() {
            // For triads, try to find 3rd and 5th in the scale
            if let triad = buildTriad(root: root, availableNotes: scaleNotes) {
                triads.append(triad)
                print("Degree \(index + 1) triad: \(triad.description)")
            } else {
                print("Degree \(index + 1) triad: Could not build")
            }
            
            // For seventh chords, add the 7th
            if let seventh = buildSeventhChord(root: root, availableNotes: scaleNotes) {
                sevenths.append(seventh)
                print("Degree \(index + 1) seventh: \(seventh.description)")
            }
        }
        
        print("\nTotal triads built: \(triads.count)")
        print("Total seventh chords built: \(sevenths.count)")
    }
    
    private func buildTriad(root: NoteClass, availableNotes: [NoteClass]) -> Chord? {
        // Find third and fifth in the available notes
        var third: NoteClass?
        var fifth: NoteClass?
        
        for note in availableNotes {
            let interval = root.canonicalNote.semitones(to: note.canonicalNote)
            
            // Check for major third (4 semitones) or minor third (3 semitones)
            if interval == 3 || interval == 4 {
                third = note
            }
            // Check for perfect fifth (7 semitones) or diminished fifth (6 semitones) or augmented fifth (8 semitones)
            else if interval == 6 || interval == 7 || interval == 8 {
                fifth = note
            }
        }
        
        // Determine chord type based on intervals
        if let third = third, let fifth = fifth {
            let thirdInterval = root.canonicalNote.semitones(to: third.canonicalNote)
            let fifthInterval = root.canonicalNote.semitones(to: fifth.canonicalNote)
            
            if thirdInterval == 4 && fifthInterval == 7 {
                return Chord(root, type: .major)
            } else if thirdInterval == 3 && fifthInterval == 7 {
                return Chord(root, type: .minor)
            } else if thirdInterval == 3 && fifthInterval == 6 {
                return Chord(root, type: .dim)
            } else if thirdInterval == 4 && fifthInterval == 8 {
                return Chord(root, type: .aug)
            }
        }
        
        return nil
    }
    
    private func buildSeventhChord(root: NoteClass, availableNotes: [NoteClass]) -> Chord? {
        // First try to build a triad
        guard let baseTriad = buildTriad(root: root, availableNotes: availableNotes) else {
            return nil
        }
        
        // Find seventh in the available notes
        var seventh: NoteClass?
        
        for note in availableNotes {
            let interval = root.canonicalNote.semitones(to: note.canonicalNote)
            
            // Check for major seventh (11 semitones) or minor seventh (10 semitones)
            if interval == 10 || interval == 11 {
                seventh = note
            }
        }
        
        // Determine seventh chord type
        if let seventh = seventh {
            let seventhInterval = root.canonicalNote.semitones(to: seventh.canonicalNote)
            
            switch (baseTriad.type, seventhInterval) {
            case (.major, 11):
                return Chord(root, type: .maj7)
            case (.major, 10):
                return Chord(root, type: .dom7)
            case (.minor, 10):
                return Chord(root, type: .min7)
            case (.dim, 10):
                return Chord(root, type: .halfDim7)
            case (.dim, 9):
                return Chord(root, type: .dim7)
            default:
                break
            }
        }
        
        return baseTriad
    }
    
    // MARK: - Run all tests
    
    func testAllExoticScales() {
        // This is a convenience method to run all tests and see output
        testBluesScale()
        testWholeToneScale()
        testChromaticScale()
        testPentatonicMajorScale()
        testPentatonicMinorScale()
        testHungarianMinorScale()
        testArabianScale()
        testHarmonicMinorScale()
        testMelodicMinorScale()
        
        // Save output to file
        let outputPath = "/tmp/tonic_exotic_scales_output.txt"
        do {
            try testOutput.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print("\n\nTest output saved to: \(outputPath)")
        } catch {
            print("Failed to save output: \(error)")
        }
    }
}