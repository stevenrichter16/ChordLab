# ChordLab Tonic Integration Analysis

## Overview
ChordLab extensively uses the Tonic music theory library (https://github.com/AudioKit/Tonic) for its core music theory functionality. This document provides a comprehensive analysis of how Tonic is integrated throughout the ChordLab codebase.

## Tonic Library Overview

### Core Tonic Models Used

1. **NoteClass** - Represents a pitch class without octave (C, C#, D, etc.)
   - Used throughout for scale and chord construction
   - Provides enharmonic spelling support
   - Has 12 static instances (.C, .Cs, .Db, .D, etc.)

2. **Note** - Represents a specific pitch with octave
   - Properties: letter, accidental, octave
   - Provides MIDI note number via `note.pitch.midiNoteNumber`
   - Uses Yamaha standard (middle C = C3)

3. **Chord** - Represents a chord with root, type, and inversion
   - Properties: root (NoteClass), type (ChordType), inversion (Int)
   - Methods: noteClasses, noteClassSet
   - Can be parsed from strings: `Chord.parse("Cmaj7")`

4. **ChordType** - Enum of chord types (over 100 types)
   - Triads: .major, .minor, .dim, .aug, .flat5
   - Sevenths: .maj7, .min7, .dom7, .halfDim7, .dim7
   - Extended: .maj9, .dom9, .min9, .maj11, .dom11, .min11, .maj13, .dom13, .min13
   - And many more specialized types

5. **Key** - Represents a musical key (root + scale)
   - Properties: root (NoteClass), scale (Scale), noteSet
   - Methods: primaryTriads, chords, preferredAccidental

6. **Scale** - Represents a scale as a set of intervals
   - Over 100 predefined scales (.major, .minor, .dorian, .lydian, etc.)
   - Properties: intervals, description

7. **Interval** - Represents the distance between notes
   - Cases: .P1, .m2, .M2, .m3, .M3, .P4, .A4, .P5, .m6, .M6, .m7, .M7
   - Properties: semitones

8. **Pitch** - Low-level pitch representation
   - Properties: midiNoteNumber, pitchClass

## ChordLab Integration Points

### 1. Core Services

#### TheoryEngine.swift
The central music theory service heavily relies on Tonic:

```swift
import Tonic

@Observable
final class TheoryEngine {
    // Uses Tonic Key for scale management
    private var currentTonicKey: Key? {
        guard let rootNote = NoteClass(currentKey) else { return nil }
        let scale = getScaleFromType(currentScaleType)
        return Key(root: rootNote, scale: scale)
    }
    
    // Leverages Key.primaryTriads for diatonic chord generation
    func getDiatonicChords() -> [Chord] {
        guard let key = currentTonicKey else { return [] }
        return key.primaryTriads
    }
    
    // Uses Chord.parse() for string-to-chord conversion
    func analyzeChord(_ chordSymbol: String) -> ChordAnalysis? {
        guard let chord = Chord.parse(chordSymbol) else { return nil }
        // ...
    }
}
```

Key integrations:
- Uses `Key` for scale and chord generation
- Leverages `Key.primaryTriads` for diatonic chords
- Uses `Key.preferredAccidental` for enharmonic spelling
- Parses chords with `Chord.parse()`
- Accesses note properties via `NoteClass` and `Note`

#### AudioEngine.swift
Audio playback service uses Tonic for MIDI conversion:

```swift
import Tonic

func playNote(_ note: Note, velocity: UInt8 = 80, duration: Double = 1.0) {
    let noteNumber = UInt8(note.pitch.midiNoteNumber)
    samplerNode.startNote(noteNumber, withVelocity: velocity, onChannel: 0)
}

func playChord(_ chord: Chord, velocity: UInt8 = 80, duration: Double = 1.0) {
    let notes = chord.noteClasses.map { noteClass in
        Note(noteClass.letter, accidental: noteClass.accidental, octave: 3)
    }
    for note in notes {
        playNote(note, velocity: velocity, duration: duration)
    }
}
```

### 2. Models

#### ChordAnalysis.swift
```swift
import Tonic

struct ChordAnalysis {
    let chord: Chord           // Tonic Chord
    let scale: Scale          // Tonic Scale
    // ...
}
```

#### VoiceLeading.swift
```swift
import Tonic

struct VoiceLeadingOption {
    let toChord: Chord
    let commonTones: [NoteClass]
    // ...
}
```

### 3. UI Components

#### PianoKeyboardView.swift
Uses Tonic for scale highlighting and note mapping:

```swift
import Tonic

let blackKeyData: [(position: Double, sharpName: String, flatName: String, noteClass: NoteClass)] = [
    (0.5, "C#", "Db", .Cs),
    (1.5, "D#", "Eb", .Ds),
    // ...
]

private func isNoteInScale(_ noteClass: NoteClass) -> Bool {
    return scaleNotes.contains(noteClass)
}
```

#### KeyScaleSelector.swift
Manages key and scale selection using Tonic types:

```swift
let keys = ["C", "C♯/D♭", "D", "D♯/E♭", "E", "F", "F♯/G♭", "G", "G♯/A♭", "A", "A♯/B♭", "B"]
let scaleTypes = ["Major", "Minor", "Dorian", "Phrygian", "Lydian", "Mixolydian", "Locrian"]
```

### 4. Extensions

#### Tonic+Extensions.swift
Provides convenience methods and properties:

```swift
extension Chord {
    var symbol: String { return description }
    func contains(_ noteClass: NoteClass) -> Bool
    var quality: String
}

extension NoteClass {
    init?(_ string: String)  // String to NoteClass conversion
}

extension Interval {
    var name: String  // Human-readable interval names
}
```

## Key Tonic Features Utilized

1. **Scale Generation**
   - Uses Tonic's 100+ predefined scales
   - Leverages `Key.noteSet` for scale notes
   - Uses `Key.primaryTriads` for diatonic chords

2. **Chord Parsing and Construction**
   - `Chord.parse()` for string-to-chord conversion
   - Direct construction: `Chord(.C, type: .maj7)`
   - Access to chord tones via `chord.noteClasses`

3. **Enharmonic Spelling**
   - `Key.preferredAccidental` for correct note spelling
   - Support for both sharp and flat representations

4. **MIDI Integration**
   - `Note.pitch.midiNoteNumber` for audio playback
   - Yamaha standard octave numbering (C3 = middle C)

5. **Music Theory Calculations**
   - Interval calculations for voice leading
   - Chord type identification from note sets
   - Roman numeral analysis support

## Areas Not Using Tonic (Custom Implementation)

1. **Roman Numeral Analysis**
   - Custom implementation in TheoryEngine
   - Tonic provides basic support but ChordLab extends it

2. **Voice Leading Calculations**
   - Custom smoothness scoring algorithm
   - Uses Tonic's NoteClass for calculations

3. **Progression Analysis**
   - Pattern recognition (ii-V-I, etc.)
   - Cadence identification
   - Custom implementation using Tonic primitives

4. **Chord Suggestions**
   - Music theory rules for chord progressions
   - Built on top of Tonic's chord and scale data

## Benefits of Tonic Integration

1. **Robust Music Theory Foundation**
   - Battle-tested library with comprehensive coverage
   - Accurate enharmonic spelling
   - Extensive chord and scale definitions

2. **Clean API**
   - Type-safe Swift enums and structs
   - Intuitive method names
   - Good Swift integration

3. **Performance**
   - Efficient bitset-based implementations
   - Fast chord and scale lookups
   - Minimal memory footprint

4. **Extensibility**
   - Easy to add custom scales and chords
   - Clean separation of concerns
   - Well-documented codebase

## Potential Improvements

1. **Leverage More Tonic Features**
   - Use Tonic's chord inversion support more extensively
   - Explore Tonic's pitch color functionality
   - Utilize more of the exotic scales

2. **Reduce Custom Code**
   - Some manual scale generation could use Tonic's built-in methods
   - Voice leading could potentially use more Tonic primitives

3. **Performance Optimizations**
   - Cache frequently used Tonic objects
   - Batch operations for chord analysis

## Conclusion

ChordLab makes excellent use of the Tonic library, leveraging it for all core music theory primitives while building custom educational features on top. The integration is clean, type-safe, and performant. Tonic provides the solid foundation that allows ChordLab to focus on the educational user experience rather than reimplementing basic music theory concepts.