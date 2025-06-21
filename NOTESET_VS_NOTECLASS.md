# Understanding NoteSet vs NoteClass in Tonic

This document explains the fundamental differences between `NoteSet` and `NoteClass` in the Tonic library, their usage in the `Chord` struct, and why they are important for music theory calculations.

## Overview of Key Concepts

Before diving into the differences, let's understand the hierarchy:

1. **NoteClass** - A pitch class without octave information (e.g., C, D#, Bb)
2. **Note** - A specific pitch with octave information (e.g., C4, D#5, Bb2)
3. **NoteClassSet** - A collection of unique NoteClass objects
4. **NoteSet** - A collection of unique Note objects (with octave information)

## NoteClass Structure

`NoteClass` represents a note without octave information - just the letter and accidental.

```swift
public struct NoteClass: Sendable, Equatable, Hashable, Codable {
    /// Letter of the note class
    public var letter: Letter        // C, D, E, F, G, A, B
    
    /// Accidental of the note class
    public var accidental: Accidental // natural, sharp, flat, etc.
    
    /// A representative note for this class, in the canonical octave
    public var canonicalNote: Note {
        Note(letter, accidental: accidental, octave: 3) // Yamaha middle C
    }
}
```

### Example: NoteClass
```swift
let cSharp = NoteClass(.C, accidental: .sharp)  // C#
let dFlat = NoteClass(.D, accidental: .flat)    // Db

// These are different NoteClass objects even though they sound the same!
cSharp == dFlat  // false (different spelling)
```

## NoteSet Structure

`NoteSet` is a type alias for a bit set that can store up to 512 different notes:

```swift
public typealias NoteSet = BitSetAdapter<Note, BitSet512>
```

This is a highly efficient data structure that uses bits to represent which notes are present in a collection. It can store notes across multiple octaves.

### Example: NoteSet
```swift
var noteSet = NoteSet()
noteSet.add(Note(.C, octave: 4))    // Add middle C
noteSet.add(Note(.E, octave: 4))    // Add E4
noteSet.add(Note(.G, octave: 4))    // Add G4
noteSet.add(Note(.C, octave: 5))    // Add C5 (different octave)

// noteSet now contains [C4, E4, G4, C5]
noteSet.count  // 4
```

## NoteClassSet Structure

`NoteClassSet` is a type alias for a bit set that stores up to 64 different note classes:

```swift
public typealias NoteClassSet = BitSetAdapter<NoteClass, BitSet64>
```

This only stores pitch classes without octave information.

### Example: NoteClassSet
```swift
var noteClassSet = NoteClassSet()
noteClassSet.add(NoteClass(.C))
noteClassSet.add(NoteClass(.E))
noteClassSet.add(NoteClass(.G))
noteClassSet.add(NoteClass(.C))  // Duplicate, won't add again

// noteClassSet contains [C, E, G]
noteClassSet.count  // 3 (no duplicates)
```

## How They're Used in Chord

The `Chord` struct uses both concepts in different ways:

### 1. Creating a Chord from Notes (with octaves)

```swift
public init?(notes: [Note]) {
    var set = NoteSet()
    for n in notes {
        set.add(n)
    }
    self.init(noteSet: set)
}

public init?(noteSet: NoteSet) {
    var r = NoteSet()
    // Convert all notes to canonical octave for comparison
    noteSet.forEach { r.add($0.noteClass.canonicalNote) }
    
    // Look up chord type based on normalized note set
    if let info = ChordTable.shared.chords[r.hashValue] {
        root = info.root
        type = info.type
        inversion = Chord.getInversion(noteSet: noteSet, noteClasses: info.noteClasses)
    } else {
        return nil
    }
}
```

### 2. Getting Chord Notes

```swift
// Returns note classes (no octave) as an array
public var noteClasses: [NoteClass] {
    let canonicalRoot = root.canonicalNote
    var result = [canonicalRoot.noteClass]
    for interval in type.intervals {
        if let shiftedNote = canonicalRoot.shiftUp(interval) {
            result.append(shiftedNote.noteClass)
        }
    }
    return result
}

// Returns note classes as a set (unique, no octave)
public var noteClassSet: NoteClassSet {
    let canonicalRoot = root.canonicalNote
    var result = NoteClassSet()
    
    result.add(canonicalRoot.noteClass)
    for interval in type.intervals {
        result.add(canonicalRoot.shiftUp(interval)!.noteClass)
    }
    
    return result
}
```

## Why Both Are Important

### 1. Chord Recognition

When identifying a chord from played notes, we need `NoteSet` because:
- It preserves octave information to determine inversions
- It handles the actual notes being played

```swift
// Example: Identifying a C major chord in first inversion
let notes = [
    Note(.E, octave: 3),  // Bass note (3rd)
    Note(.G, octave: 3),
    Note(.C, octave: 4)   // Root an octave up
]

if let chord = Chord(notes: notes) {
    print(chord)            // "C" (C major)
    print(chord.inversion)  // 1 (first inversion)
}
```

### 2. Chord Type Identification

`NoteClassSet` is used for identifying the chord type because:
- Chord quality doesn't depend on octaves
- It's more efficient to compare pitch classes

```swift
// Both of these create the same chord type (C major)
let chord1 = Chord(notes: [
    Note(.C, octave: 3),
    Note(.E, octave: 3),
    Note(.G, octave: 3)
])

let chord2 = Chord(notes: [
    Note(.C, octave: 5),
    Note(.E, octave: 5),
    Note(.G, octave: 5)
])

// Both have the same noteClassSet: {C, E, G}
```

### 3. Voice Leading and Inversions

`NoteSet` preserves the specific voicing:

```swift
// Root position C major
let rootPosition = NoteSet(notes: [
    Note(.C, octave: 3),
    Note(.E, octave: 3),
    Note(.G, octave: 3)
])

// First inversion C major (E in bass)
let firstInversion = NoteSet(notes: [
    Note(.E, octave: 2),  // E below
    Note(.G, octave: 3),
    Note(.C, octave: 4)   // C above
])

// These have the same NoteClassSet but different NoteSets
```

## Practical Example: Building a Chord Progression

```swift
// Create a I-IV-V-I progression in C major
let progression = [
    // I - C major (root position)
    Chord(notes: [
        Note(.C, octave: 4),
        Note(.E, octave: 4),
        Note(.G, octave: 4)
    ]),
    
    // IV - F major (root position)
    Chord(notes: [
        Note(.F, octave: 4),
        Note(.A, octave: 4),
        Note(.C, octave: 5)
    ]),
    
    // V - G major (first inversion for smooth voice leading)
    Chord(notes: [
        Note(.B, octave: 3),  // Leading tone in bass
        Note(.D, octave: 4),
        Note(.G, octave: 4)
    ]),
    
    // I - C major (root position)
    Chord(notes: [
        Note(.C, octave: 4),
        Note(.E, octave: 4),
        Note(.G, octave: 4)
    ])
]

// Analyze the progression
for (index, maybeChord) in progression.enumerated() {
    if let chord = maybeChord {
        print("Chord \(index + 1):")
        print("  Type: \(chord.description)")
        print("  Inversion: \(chord.inversion)")
        print("  Note Classes: \(chord.noteClasses)")
    }
}
```

## Key Takeaways

1. **NoteClass** = Pitch without octave (C, D#, Bb)
2. **Note** = Pitch with octave (C4, D#5, Bb2)
3. **NoteClassSet** = Unique collection of pitch classes (for chord type identification)
4. **NoteSet** = Unique collection of specific notes (for voicing and inversion detection)

5. **Why we need both:**
   - **NoteSet**: Preserves exact voicing, determines inversions, handles actual played notes
   - **NoteClassSet**: Identifies chord types efficiently, ignores octave duplicates

6. **In Chord struct:**
   - Input: Can accept `NoteSet` to identify chords from played notes
   - Output: Provides both `noteClasses` array and `noteClassSet` for different use cases
   - The chord recognition algorithm normalizes notes to canonical octave for type identification but preserves original voicing for inversion calculation

This dual system allows Tonic to handle both the abstract music theory (what type of chord) and the practical performance aspects (how it's voiced) elegantly and efficiently.