import XCTest
@testable import ChordLab
import Tonic

final class TonicScaleExplorationTests: XCTestCase {
    
    func testTonicKeyAPI() {
        print("\n=== EXPLORING TONIC KEY API ===\n")
        
        // Test what Tonic provides for major and minor keys
        let cMajor = Key(root: .C, scale: .major)
        let aMinor = Key(root: .A, scale: .minor)
        
        print("C Major Key:")
        print("  Primary triads: \(cMajor.primaryTriads.map { $0.description })")
        print("  All chords: \(cMajor.chords.map { $0.description })")
        print("  Scale property: \(cMajor.scale)")
        
        print("\nA Minor Key:")
        print("  Primary triads: \(aMinor.primaryTriads.map { $0.description })")
        print("  All chords: \(aMinor.chords.map { $0.description })")
        print("  Scale property: \(aMinor.scale)")
        
        // Test if we can access scale intervals or notes
        print("\n--- Testing Scale enum ---")
        print("Scale.major: \(Scale.major)")
        print("Scale.minor: \(Scale.minor)")
        
        // Check if Scale has any other cases or properties
        // Note: Swift doesn't allow runtime introspection of enum cases
        
        // Test creating chords manually for exotic scales
        testExoticScaleChordGeneration()
    }
    
    func testExoticScaleChordGeneration() {
        print("\n\n=== MANUAL EXOTIC SCALE CHORD GENERATION ===")
        
        // Blues scale example
        print("\n--- C Blues Scale ---")
        let bluesNotes = generateBluesScale(root: .C)
        print("Blues notes: \(bluesNotes.map { $0.description })")
        
        // Try to build chords from blues scale
        let bluesChords = generateChordsFromScale(scaleNotes: bluesNotes, scaleName: "Blues")
        print("Possible triads: \(bluesChords.map { $0.description })")
        
        // Whole tone scale example
        print("\n--- C Whole Tone Scale ---")
        let wholeToneNotes = generateWholeToneScale(root: .C)
        print("Whole tone notes: \(wholeToneNotes.map { $0.description })")
        
        let wholeToneChords = generateChordsFromScale(scaleNotes: wholeToneNotes, scaleName: "Whole Tone")
        print("Possible triads: \(wholeToneChords.map { $0.description })")
        
        // Harmonic minor example
        print("\n--- A Harmonic Minor Scale ---")
        let harmonicMinorNotes = generateHarmonicMinorScale(root: .A)
        print("Harmonic minor notes: \(harmonicMinorNotes.map { $0.description })")
        
        let harmonicMinorChords = generateChordsFromScale(scaleNotes: harmonicMinorNotes, scaleName: "Harmonic Minor")
        print("Possible triads: \(harmonicMinorChords.map { $0.description })")
    }
    
    private func generateBluesScale(root: NoteClass) -> [NoteClass] {
        // Blues: 1, b3, 4, b5, 5, b7
        let intervals: [Interval] = [.P1, .m3, .P4, .d5, .P5, .m7]
        return intervals.compactMap { root.canonicalNote.shiftUp($0)?.noteClass }
    }
    
    private func generateWholeToneScale(root: NoteClass) -> [NoteClass] {
        // Whole tone: 1, 2, 3, #4, #5, b7
        let intervals: [Interval] = [.P1, .M2, .M3, .A4, .A5, .m7]
        return intervals.compactMap { root.canonicalNote.shiftUp($0)?.noteClass }
    }
    
    private func generateHarmonicMinorScale(root: NoteClass) -> [NoteClass] {
        // Harmonic minor: 1, 2, b3, 4, 5, b6, 7
        let intervals: [Interval] = [.P1, .M2, .m3, .P4, .P5, .m6, .M7]
        return intervals.compactMap { root.canonicalNote.shiftUp($0)?.noteClass }
    }
    
    private func generateChordsFromScale(scaleNotes: [NoteClass], scaleName: String) -> [Chord] {
        var chords: [Chord] = []
        
        // For each note in the scale, try to build a triad
        for (index, root) in scaleNotes.enumerated() {
            // Look for notes that could form thirds and fifths
            for possibleThird in scaleNotes {
                for possibleFifth in scaleNotes {
                    if let chord = tryBuildChord(root: root, third: possibleThird, fifth: possibleFifth) {
                        // Check if this chord is already in our list
                        if !chords.contains(where: { $0.root == chord.root && $0.type == chord.type }) {
                            chords.append(chord)
                        }
                    }
                }
            }
        }
        
        return chords.sorted { $0.description < $1.description }
    }
    
    private func tryBuildChord(root: NoteClass, third: NoteClass, fifth: NoteClass) -> Chord? {
        let thirdInterval = root.canonicalNote.semitones(to: third.canonicalNote)
        let fifthInterval = root.canonicalNote.semitones(to: fifth.canonicalNote)
        
        // Major chord: major third (4 semitones) + perfect fifth (7 semitones)
        if thirdInterval == 4 && fifthInterval == 7 {
            return Chord(root, type: .major)
        }
        // Minor chord: minor third (3 semitones) + perfect fifth (7 semitones)
        else if thirdInterval == 3 && fifthInterval == 7 {
            return Chord(root, type: .minor)
        }
        // Diminished chord: minor third (3 semitones) + diminished fifth (6 semitones)
        else if thirdInterval == 3 && fifthInterval == 6 {
            return Chord(root, type: .dim)
        }
        // Augmented chord: major third (4 semitones) + augmented fifth (8 semitones)
        else if thirdInterval == 4 && fifthInterval == 8 {
            return Chord(root, type: .aug)
        }
        
        return nil
    }
    
    func testTonicLimitations() {
        print("\n\n=== TONIC LIMITATIONS ===")
        
        // Test what happens when we try to create exotic keys
        print("\n--- Attempting to create exotic keys ---")
        
        // Tonic only supports .major and .minor scales
        // There's no .blues, .wholeTone, .harmonic, etc.
        
        let key = Key(root: .C, scale: .major)
        print("Key scales available: major and minor only")
        print("Key provides automatic chord generation for major/minor keys")
        print("For exotic scales, we must implement chord generation manually")
        
        print("\n--- Summary ---")
        print("1. Tonic's Key struct only supports major and minor scales")
        print("2. Key.primaryTriads returns I, IV, V for major; i, iv, v for minor")
        print("3. Key.chords returns all diatonic triads for the key")
        print("4. For exotic scales, we need to:")
        print("   - Generate scale notes manually using intervals")
        print("   - Build chords manually from available scale notes")
        print("   - Implement our own chord progression logic")
    }
}