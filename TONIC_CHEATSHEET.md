# Tonic Library Cheatsheet

## Essential Types & Creation

### Chords
```swift
// Create chords
Chord(.C, type: .major)         // C major
Chord(.A, type: .minor)         // A minor
Chord(.G, type: .dom7)          // G7
Chord(.D, type: .maj7)          // Dmaj7
Chord(.B, type: .halfDim7)      // Bø7
Chord.parse("Cmaj7")            // Optional<Chord>

// Chord types (use these exact values!)
.major, .minor, .dim, .aug                      // Triads
.maj7, .min7, .dom7, .dim7, .halfDim7          // Sevenths
.sus2, .sus4, .add9, .maj9, .min9              // Extended
```

### Notes & NoteClasses
```swift
// NoteClass (pitch without octave)
NoteClass.C, .Cs, .Db, .D, .Ds, .Eb            // etc.
NoteClass("C#")                                  // Optional init
NoteClass("Db")                                  // Enharmonic

// Note (pitch with octave)
Note(.C, octave: 3)                             // Middle C (Yamaha)
Note(.A, accidental: .natural, octave: 4)       // A4 = 440Hz
note.pitch.midiNoteNumber                       // Int8
```

### Keys & Scales
```swift
// Create key
let key = Key(root: .C, scale: .major)
key.noteSet.array                               // All notes in key
key.primaryTriads                               // Diatonic triads
key.preferredAccidental                         // .sharp or .flat

// Scale types
Scale.major, .minor, .dorian, .phrygian
Scale.lydian, .mixolydian, .locrian
Scale.harmonicMinor, .melodicMinor
```

## Common Operations

### Chord Analysis
```swift
chord.root                      // NoteClass
chord.noteClasses              // [NoteClass]
chord.type                     // ChordType
chord.description              // "Cmaj7"
```

### Intervals
```swift
Interval.P1                    // Unison
Interval.m2, .M2               // Minor/Major 2nd
Interval.m3, .M3               // Minor/Major 3rd
Interval.P4, .A4               // Perfect/Aug 4th
Interval.P5                    // Perfect 5th
Interval.m6, .M6               // Minor/Major 6th
Interval.m7, .M7               // Minor/Major 7th

// Transposition
note.shiftUp(.M3)              // Up major 3rd
note.shiftDown(.P5)            // Down perfect 5th
```

## Gotchas & Tips

### ❌ Common Mistakes
```swift
Chord(.Am)                     // WRONG - no .Am
Chord(.C, type: .majorSeventh) // WRONG - use .maj7
Note(.C, octave: 4)            // Middle C is octave 3!
```

### ✅ Correct Usage
```swift
Chord(.A, type: .minor)        // A minor
Chord(.C, type: .maj7)         // Cmaj7
Note(.C, octave: 3)            // Middle C
```

### Enharmonic Spelling
```swift
// Tonic respects key context
let fMajor = Key(root: .F, scale: .major)
fMajor.preferredAccidental     // .flat (prefers Bb over A#)
```

### MIDI Conversion
```swift
let note = Note(.C, octave: 3)
let midi = note.pitch.midiNoteNumber  // 60
// Note: Tonic uses Yamaha standard (C3 = 60)