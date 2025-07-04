# TheoryEngine Modifications for Piano Chord Visualizer

## Analysis of Existing Methods

After reviewing the TheoryEngine and creating comprehensive unit tests, here's my assessment of the methods we'll use for the Piano Chord Visualizer:

### Methods That Work As-Is ✅

1. **`getDiatonicChords() -> [Chord]`**
   - Returns all 7 diatonic triads for the current key
   - Uses Tonic's `Key.primaryTriads` internally
   - Correctly returns chords in scale order
   - **No modifications needed**

2. **`getRomanNumeral(for chordSymbol: String) -> String`**
   - Converts chord symbols to Roman numerals
   - Handles both diatonic and chromatic chords
   - Correctly applies uppercase/lowercase based on chord quality
   - Adds ° symbol for diminished chords
   - **No modifications needed** for PCV
   - **Note**: Has a limitation where borrowed chord qualities aren't detected (e.g., Fm in C major returns "iv" instead of "♭iv" or "iv*")

3. **`setKey(_ key: String, scaleType: String)`**
   - Sets the current key and scale type
   - Works with all white keys (C, D, E, F, G, A, B)
   - **No modifications needed**

### Methods That Were Updated ✅

1. **`determineFunction(romanNumeral: String) -> ChordFunction`**
   - Was private, now public
   - Works correctly for all scale degrees
   - **Status**: Already updated to public access level ✅

### New Methods Added ✅

The following helper methods have been added to TheoryEngine for the Piano Chord Visualizer:

```swift
// MARK: - Piano Chord Visualizer Support

/// Returns the scale degree name for a given index (0-6)
func getScaleDegreeName(for index: Int) -> String {
    let names = ["Tonic", "Supertonic", "Mediant", "Subdominant", "Dominant", "Submediant", "Leading Tone"]
    guard index >= 0 && index < names.count else { return "Unknown" }
    return names[index]
}

/// Returns chord tone roles for visualization (root, third, fifth)
func getChordToneRoles(for chord: Chord) -> [(note: NoteClass, role: String)] {
    let notes = chord.noteClasses
    guard notes.count >= 3 else { return [] }
    
    return [
        (notes[0], "Root"),
        (notes[1], "Third"),
        (notes[2], "Fifth")
    ]
}

/// Returns all diatonic triads with complete visualization data
func getDiatonicChordsWithAnalysis() -> [(chord: Chord, romanNumeral: String, function: ChordFunction, degreeName: String)] {
    let chords = getDiatonicChords()
    
    return chords.enumerated().map { index, chord in
        let roman = getRomanNumeral(for: chord.description)
        let function = determineFunction(romanNumeral: roman)
        let degreeName = getScaleDegreeName(for: index)
        
        return (chord, roman, function, degreeName)
    }
}
```

**Status**: All methods have been implemented and tested ✅

## Implementation Status ✅

All required methods have been implemented:

1. **Completed**:
   - ✅ Made `determineFunction` public
   - ✅ Added `getScaleDegreeName` method
   - ✅ Added `getChordToneRoles` method
   - ✅ Added `getDiatonicChordsWithAnalysis` convenience method

2. **Future Enhancements** (not needed for PCV MVP):
   - Add caching for diatonic chords per key
   - Add methods for chord inversions
   - Add methods for extended chords (7ths, 9ths, etc.)

## Test Results Summary

All tests pass for the current implementation:
- ✅ `getDiatonicChords()` returns correct triads for all major keys
- ✅ Roman numeral generation works correctly
- ✅ Chord function determination is accurate
- ✅ Integration between methods works seamlessly

## Recommendations

1. The existing TheoryEngine is well-suited for the Piano Chord Visualizer with minimal modifications
2. Only need to change `determineFunction` from private to internal (already done)
3. Add 2-3 helper methods for better visualization support
4. The core functionality leverages Tonic effectively and doesn't need changes
5. For PCV, we only need diatonic triads, so the borrowed chord limitation in getRomanNumeral won't affect us

## Example Usage in PCV

```swift
// In ChordVisualizerView
@State private var selectedKey = "C"
@State private var diatonicChords: [(chord: Chord, romanNumeral: String, degreeName: String)] = []

func updateChords() {
    theoryEngine.setKey(selectedKey, scaleType: "major")
    let chords = theoryEngine.getDiatonicChords()
    
    diatonicChords = chords.enumerated().map { index, chord in
        let roman = theoryEngine.getRomanNumeral(for: chord.description)
        let degreeName = theoryEngine.getScaleDegreeName(for: index)
        return (chord, roman, degreeName)
    }
}
```