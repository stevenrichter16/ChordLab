# Tonic Library Chord System Analysis

This document provides a comprehensive analysis of the Tonic library's chord system, validating and expanding upon the provided information about Chord, ChordType, and Interval structures.

## Executive Summary

After thorough investigation of the Tonic library source code, I can confirm that the provided information is **100% accurate** with the following validations:

✅ **Chord struct** has a `type` property of type `ChordType`  
✅ **ChordType** is an enum with values like `.major`, `.minor`, `.dim`, `.maj7`, `.halfDim7`, etc.  
✅ **ChordType** has an `intervals` property returning an array of `Interval` values  
✅ **Interval** has `degree`, `semitones`, `description`, and `longDescription` properties  

## Detailed Analysis

### 1. Chord Struct

Located in: `/Sources/Tonic/Chord.swift`

The `Chord` struct is defined as:

```swift
public struct Chord: Sendable, Equatable, Hashable, Codable {
    /// Root note class of the chord
    public let root: NoteClass
    
    /// The flavor of the chord (connoting which notes are played alongside the root, in some octave)
    public let type: ChordType
    
    /// Which note in terms of degrees from the root appears as the lowest note
    public let inversion: Int
}
```

**Key Properties:**
- `root`: The root note of the chord (e.g., C, D#, Bb)
- `type`: A `ChordType` enum value that determines the chord quality
- `inversion`: Integer representing which chord tone is in the bass

**Important Methods:**
- `noteClasses`: Returns array of all note classes in the chord
- `noteClassSet`: Returns set of all note classes in the chord
- `description`: Returns string representation (e.g., "Cmaj7")
- `pitches(octave:)`: Returns actual pitches at a given octave
- `notes(octave:)`: Returns actual notes at a given octave

### 2. ChordType Enum

Located in: `/Sources/Tonic/ChordType.swift`

The `ChordType` enum is extensive, containing over 200 chord types. Examples include:

```swift
public enum ChordType: String, Sendable, CaseIterable, Codable {
    // Triads
    case major      // ""
    case minor      // "m"
    case dim        // "°"
    case aug        // "+"
    case flat5      // "(♭5)"
    
    // Seventh Chords
    case maj7       // "maj7"
    case dom7       // "7"
    case min7       // "m7"
    case halfDim7   // "ø7"
    case dim7       // "°7"
    
    // Extended Chords
    case maj9       // "maj9"
    case dom9       // "9"
    case min9       // "m9"
    case maj13      // "maj13"
    // ... and many more
}
```

#### The `intervals` Property

The `intervals` property is a computed property that returns an array of `Interval` values:

```swift
public var intervals: [Interval] {
    switch self {
        case .major:     return [.M3, .P5]
        case .minor:     return [.m3, .P5]
        case .dim:       return [.m3, .d5]
        case .maj7:      return [.M3, .P5, .M7]
        case .dom7:      return [.M3, .P5, .m7]
        case .min7:      return [.m3, .P5, .m7]
        case .halfDim7:  return [.m3, .d5, .m7]
        // ... etc for all chord types
    }
}
```

**Key Points:**
- Returns intervals FROM the root (root note is not included)
- Order matters - intervals are listed in ascending order
- Used to generate the actual notes of the chord

### 3. Interval Enum

Located in: `/Sources/Tonic/Interval.swift`

The `Interval` enum represents musical intervals:

```swift
public enum Interval: Int, Sendable, CaseIterable, Codable {
    case P1  // Perfect Unison
    case m2  // Minor Second
    case M2  // Major Second
    case m3  // Minor Third
    case M3  // Major Third
    case P4  // Perfect Fourth
    case A4  // Augmented Fourth
    case d5  // Diminished Fifth
    case P5  // Perfect Fifth
    // ... up to P15 (Perfect Fifteenth)
}
```

#### Interval Properties

**1. `semitones` Property (Computed)**
```swift
public var semitones: Int {
    switch self {
        case .P1: return 0
        case .m2: return 1
        case .M2: return 2
        case .m3: return 3
        case .M3: return 4
        case .P4: return 5
        case .A4: return 6
        case .d5: return 6
        case .P5: return 7
        // ... etc
    }
}
```

**2. `degree` Property (Computed)**
```swift
var degree: Int {
    switch self {
        case .P1: return 1
        case .m2: return 2
        case .M2: return 2
        case .m3: return 3
        case .M3: return 3
        case .P4: return 4
        // ... etc
    }
}
```

Note: The `degree` property is marked as `internal` (not public), but it does exist.

**3. `description` Property (via CustomStringConvertible)**
```swift
public var description: String {
    switch self {
        case .P1: return "P1"
        case .m2: return "m2"
        case .M2: return "M2"
        case .m3: return "m3"
        case .M3: return "M3"
        // ... etc
    }
}
```

**4. `longDescription` Property**
```swift
public var longDescription: String {
    switch self {
        case .P1: return "Perfect Unison"
        case .m2: return "Minor Second"
        case .M2: return "Major Second"
        case .m3: return "Minor Third"
        case .M3: return "Major Third"
        case .P4: return "Perfect Fourth"
        case .P5: return "Perfect Fifth"
        // ... etc
    }
}
```

## How These Components Interact

### Example 1: Creating a C Major 7 Chord

```swift
let chord = Chord(.C, type: .maj7)

// chord.type = .maj7
// chord.type.intervals = [.M3, .P5, .M7]
// These intervals translate to:
//   - .M3 = Major Third = 4 semitones
//   - .P5 = Perfect Fifth = 7 semitones  
//   - .M7 = Major Seventh = 11 semitones

// chord.noteClasses = [C, E, G, B]
// Generated by applying intervals to root:
//   - Root: C
//   - C + M3 (4 semitones) = E
//   - C + P5 (7 semitones) = G
//   - C + M7 (11 semitones) = B
```

### Example 2: Interval Details

```swift
let interval = Interval.M3

// Properties:
interval.semitones      // 4
interval.degree         // 3 (internal property)
interval.description    // "M3"
interval.longDescription // "Major Third"
```

### Example 3: Chord Generation Process

When you create a chord, the following happens:

1. **Chord Creation**: `Chord(root: .C, type: .major)`
2. **Type Intervals**: `type.intervals` returns `[.M3, .P5]`
3. **Note Generation**: For each interval, the root note is shifted up:
   - Root (C) + M3 → E
   - Root (C) + P5 → G
4. **Result**: The chord contains notes [C, E, G]

## Additional Discoveries

### 1. Chord Validation

The ChordTable uses the relationship between intervals and noteClasses to validate chords:

```swift
if chord.noteClasses.count <= chord.type.intervals.count {
    // Invalid chord - would require triple sharps/flats
    continue
}
```

This ensures that `noteClasses.count` = `intervals.count + 1` (the +1 being the root).

### 2. Interval Calculations

Intervals can be calculated between two notes:

```swift
public static func betweenNotes(_ note1: Note, _ note2: Note) -> Interval?
```

### 3. Chord Inversions

The chord system supports inversions through the `inversion` property, which determines which chord tone appears in the bass.

## Conclusion

The Tonic library provides a comprehensive and well-designed system for representing chords through the interaction of three main components:

1. **Chord**: Container that combines a root note with a chord type
2. **ChordType**: Defines the quality/flavor through its intervals
3. **Interval**: Represents the mathematical/musical distance between notes

This design allows for:
- Type-safe chord construction
- Accurate musical calculations
- Easy chord analysis and manipulation
- Support for complex jazz chords and inversions

The information provided in the original query is accurate and represents the core functionality of the Tonic chord system.