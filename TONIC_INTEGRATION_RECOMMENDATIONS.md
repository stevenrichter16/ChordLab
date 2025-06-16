# Tonic Integration Recommendations for ChordLab

## Executive Summary

After analyzing both the Tonic library and ChordLab's current implementation, I've identified several areas where ChordLab could better leverage Tonic's built-in functionality. While ChordLab correctly uses Tonic for basic music theory primitives, it's reimplementing some features that Tonic already provides.

## Key Findings

### 1. Features ChordLab is Unnecessarily Reimplementing

#### Scale Generation
**Current Implementation:**
- ChordLab manually defines intervals for each scale type in `getCurrentScaleNotes()`
- Manually calculates scale notes using `shiftUp()` for each interval

**Tonic Already Provides:**
- 100+ predefined scales with correct intervals
- `Key` struct that automatically generates scale notes
- Proper enharmonic spelling based on key

**Recommendation:**
```swift
// Replace manual scale generation with:
func getCurrentScaleNotes() -> [NoteClass] {
    guard let rootNote = NoteClass(currentKey) else { return [] }
    
    let scale: Scale
    switch currentScaleType.lowercased() {
    case "major": scale = .major
    case "minor": scale = .minor
    case "harmonicminor": scale = .harmonicMinor
    case "melodicminor": scale = .melodicMinor
    case "dorian": scale = .dorian
    case "phrygian": scale = .phrygian
    case "lydian": scale = .lydian
    case "mixolydian": scale = .mixolydian
    case "locrian": scale = .locrian
    default: scale = .major
    }
    
    let key = Key(root: rootNote, scale: scale)
    // Note: Key.noteSet returns notes in scale order starting from root
    return Array(key.noteSet).map { $0.noteClass }
}
```

#### Diatonic Chord Generation
**Current Implementation:**
- Manually builds triads by stacking thirds from scale degrees
- Determines chord quality by measuring intervals

**Tonic Already Provides:**
- `Key.primaryTriads` returns the seven diatonic triads in order
- `Key.chords` returns all chords that fit in the key

**Recommendation:**
```swift
func getDiatonicChords() -> [Chord] {
    guard let rootNote = NoteClass(currentKey) else { return [] }
    let scale = getScaleFromType(currentScaleType)
    let key = Key(root: rootNote, scale: scale)
    return key.primaryTriads
}
```

### 2. Features ChordLab Correctly Implements (Not in Tonic)

The following features are correctly implemented by ChordLab as they're not provided by Tonic:

- **Roman Numeral Analysis** - Converting chords to Roman numerals based on key
- **Chord Function Determination** - Identifying tonic, dominant, subdominant, etc.
- **Voice Leading Calculations** - Analyzing smoothness between chord transitions
- **Progression Pattern Recognition** - Identifying common patterns like ii-V-I
- **Cadence Analysis** - Detecting authentic, plagal, deceptive cadences
- **Borrowed Chord Detection** - Identifying non-diatonic chords and their origins
- **Chord Suggestions** - Theory-based recommendations for next chords
- **Secondary Dominant Analysis** - V/V, V/ii detection (currently disabled in tests)

### 3. Additional Tonic Features to Leverage

#### More Scale Types
ChordLab currently supports 9 scale types, but Tonic provides 100+, including:
- Jazz scales (bebop, altered, etc.)
- World music scales (Arabian, Chinese, Indian ragas)
- Modern scales (whole tone, augmented, etc.)

**Recommendation:** Add a scale browser feature showcasing Tonic's full scale collection.

#### Chord Parsing
ChordLab has a basic `Chord.parse()` extension, but could improve it using Tonic's `ChordTable`:
```swift
// Better chord parsing using Tonic's internals
static func parse(_ symbol: String) -> Chord? {
    // Parse root note more robustly
    // Use ChordTable for chord type detection
    // Handle more complex chord symbols
}
```

### 4. Implementation Priority

1. **High Priority** (Quick wins with immediate benefits):
   - Replace manual scale generation with Tonic's `Key` struct
   - Use `Key.primaryTriads` for diatonic chord generation
   - Add more scale types to the UI

2. **Medium Priority** (Moderate effort, good value):
   - Improve chord parsing using `ChordTable`
   - Add support for more exotic scales in practice modes
   - Leverage `Key.preferredAccidental` for better enharmonic spelling

3. **Low Priority** (Nice to have):
   - Use `Pitch.pitchColor` for visual representations
   - Explore `BitSet` for efficient note set operations

## Benefits of These Changes

1. **Reduced Code Complexity** - Less manual implementation to maintain
2. **Better Accuracy** - Tonic's implementations are well-tested
3. **Improved Performance** - Tonic's optimized algorithms
4. **Enhanced Features** - Access to 100+ scales out of the box
5. **Better Enharmonic Spelling** - Tonic handles this correctly per key

## What NOT to Change

Keep ChordLab's implementations of:
- All Roman numeral analysis logic
- Voice leading algorithms
- Progression analysis features
- UI-specific music theory logic
- Educational features and explanations

These represent ChordLab's unique value proposition and are not provided by Tonic.

## Conclusion

ChordLab has built excellent music theory features on top of Tonic. By leveraging more of Tonic's built-in functionality, the codebase can be simplified while gaining access to additional scales and improved accuracy. The recommended changes maintain all of ChordLab's unique educational features while reducing code duplication.