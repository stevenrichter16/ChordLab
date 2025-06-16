# Tonic API Reference for ChordLab

This document contains the actual Tonic API as discovered during implementation, to ensure correct usage in future development.

## ChordType Enum

The complete ChordType enum from Tonic includes:

### Triads
- `.major` - Major triad
- `.minor` - Minor triad  
- `.dim` - Diminished triad
- `.aug` - Augmented triad
- `.flat5` - Major flat five
- `.sus2` - Suspended 2nd
- `.sus4` - Suspended 4th

### Seventh Chords
- `.maj7` - Major seventh (NOT .majorSeventh or .major7)
- `.min7` - Minor seventh (NOT .minorSeventh or .minor7) 
- `.dom7` - Dominant seventh (NOT .dominant7)
- `.dim7` - Diminished seventh
- `.halfDim7` - Half diminished seventh
- `.maj7_sharp5` - Major seventh sharp five
- `.min_maj7` - Minor major seventh
- `.maj7_flat5` - Major seventh flat five
- `.dom7_flat5` - Dominant seventh flat five
- `.dom7_sharp5` - Dominant seventh sharp five

### Extended Chords
- `.maj9`, `.dom9`, `.min9` - Ninth chords
- `.maj11`, `.dom11`, `.min11` - Eleventh chords
- `.maj13`, `.dom13`, `.min13` - Thirteenth chords
- Many more extended and altered chords...

## Core Types

### NoteClass
Represents a pitch class without octave:
```swift
public enum NoteClass {
    case C, Cs, Db, D, Ds, Eb, E, F, Fs, Gb, G, Gs, Ab, A, As, Bb, B
}

// Creating from string
let note = NoteClass("C#") // Optional initializer
```

### Note
Represents a specific pitch with octave:
```swift
let note = Note(.C, octave: 4)
note.pitch.midiNoteNumber // Int
```

### Chord
```swift
// Creation
let chord = Chord(.C, type: .maj7)
let parsed = Chord.parse("Cmaj7") // Optional

// Properties
chord.root // NoteClass (NOT optional)
chord.type // ChordType
chord.noteClasses // [NoteClass]
chord.description // String representation
```

### Interval
```swift
public enum Interval {
    case m2, M2, m3, M3, P4, A4, d5, P5, A5, m6, M6, m7, M7, P8
    // etc...
}
interval.semitones // Int
```

## What Tonic DOESN'T Provide

1. **No Scale generation** - Must calculate scale notes manually using intervals
2. **No Key type with methods** - Keys are just for reference, not computation
3. **No built-in Roman numeral analysis**
4. **No chord progression analysis**
5. **No voice leading calculations**
6. **No diatonic chord generation**

## Common Pitfalls

1. ❌ `chord.root` is NOT optional - don't use optional binding
2. ❌ `Note.value` doesn't exist - use `note.pitch.midiNoteNumber`
3. ❌ `Scale.notes` doesn't exist - must generate manually
4. ❌ ChordType uses `.maj7` not `.majorSeventh`
5. ❌ No automatic enharmonic equivalence - Cs and Db are different

## Useful Patterns

### Generate scale notes
```swift
private func noteClassIndex(_ noteClass: NoteClass) -> Int {
    let noteClasses: [NoteClass] = [.C, .Db, .D, .Eb, .E, .F, .Gb, .G, .Ab, .A, .Bb, .B]
    return noteClasses.firstIndex(of: noteClass) ?? 0
}

private func noteClassFromIndex(_ index: Int) -> NoteClass {
    let noteClasses: [NoteClass] = [.C, .Db, .D, .Eb, .E, .F, .Gb, .G, .Ab, .A, .Bb, .B]
    return noteClasses[index % 12]
}
```

### Parse chord symbols
```swift
extension Chord {
    static func parse(_ symbol: String) -> Chord? {
        // Custom implementation required
    }
}
```