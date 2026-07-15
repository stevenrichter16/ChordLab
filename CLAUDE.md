# ChordLab - Music Theory Education App

## Quick Reference
- **Architecture**: SwiftUI + @Observable (iOS 17+) + Tonic library + SwiftData
- **Main Services**: TheoryEngine (music theory), AudioEngine (playback), DataManager (persistence)
- **Current State**: Explore (Piano Chord Visualizer, all 12 keys), Practice (4 playable modes), Profile (live stats + achievements), and Library (full CRUD) implemented

## Project Structure
```
ChordLab/
├── Core/
│   ├── Models/        # Theory models, Persistence models
│   ├── Services/      # TheoryEngine, AudioEngine, DataManager
│   └── Extensions/    # Tonic+Extensions, Color+Theme, View+Modifiers
├── Features/
│   ├── Learn/         # ✅ ScalePianoView, KeyScaleSelector
│   ├── Explore/       # ✅ ChordVisualizerView, FloatingProgressionPlayer
│   ├── Library/       # ✅ Saved progressions: search/sort, rename/duplicate/delete
│   ├── Builder/       # 📋 TODO: Drag-drop progression builder
│   ├── Practice/      # ✅ Ear training, chord recognition, progressions, quiz
│   └── Profile/       # ✅ Stats, achievements (AchievementsView)
└── Shared/
    └── Components/    # Piano/, Common/, Charts/
```

## Practice Tab Architecture
```swift
PracticeGameView<Stimulus>       // Generic session container: setup -> questions -> results
├── PracticeQuestionGenerator    // Static generators; uses throwaway TheoryEngine instances
│                                // so global key state is never mutated mid-game
├── EarTrainingView              // Chord quality by ear (auto-plays, replay button)
├── ChordRecognitionView         // Name the chord shown on ChordPianoView
├── ProgressionChallengeView     // Identify 4-chord Roman numeral patterns by ear
└── TheoryQuizView               // Roman numerals, functions, chord tones
// Results are saved via DataManager.recordPracticeSession which also
// advances first_practice / streak / ear_training_pro achievements
```

## Key Tonic API Patterns
```swift
// Chord creation
Chord(.C, type: .maj7)  // NOT .majorSeventh
Chord.parse("Cmaj7")    // returns optional

// Chord types
.major, .minor, .dim, .aug              // triads
.maj7, .min7, .dom7, .dim7, .halfDim7   // sevenths

// Note/NoteClass
NoteClass.C, .Cs, .Db   // pitch classes
Note(.C, octave: 3)     // C3 = middle C (Yamaha standard)

// Key operations
Key(root: .C, scale: .major)
key.primaryTriads       // diatonic triads
key.preferredAccidental // .sharp or .flat
```

## Recent Implementation: FloatingProgressionPlayer

### Three View States
1. **Minimized**: Play button + chord count badge
2. **Intermediate**: Horizontal timeline with play/ellipsis buttons
3. **Expanded**: Full controls with BPM, loop, save, timeline

### Key Features
- Drag to reposition (with screen edge bounce-back)
- Tap chord in timeline to select/visualize
- Hold chord button to reorder (shows arrows)
- BPM adjustment (60-200)
- Save progressions with name/tags
- Playback with visual feedback

### Component Architecture
```swift
FloatingProgressionPlayer
├── MinimalChordTimelineItem    // Borderless design for intermediate view
├── ChordTimelineItem           // Standard bordered design
├── ChordMoveArrows            // Reorder UI
├── SaveProgressionSheet        // Save dialog
└── PlayerViewState enum        // State management
```

## TheoryEngine Key Methods
```swift
// Chord analysis
getDiatonicChordsWithAnalysis() -> [(chord, romanNumeral, function, degreeName)]
getSeventhChordsWithAnalysis()   -> [(chord, romanNumeral, function, degreeName)]
getRomanNumeral(for: String)     -> String
determineFunction(romanNumeral:) -> ChordFunction

// Progression management
addChordToProgression(Chord)
removeFromProgression(at: Int)
reorderProgression(from: Int, to: Int)
currentProgression: [PlaybackChord]
currentProgressionTempo: Int

// Visualization support
selectedChord: Chord?        // For timeline selection
visualizedChord: Chord?      // For piano highlighting
```

## Performance Optimizations Applied
1. **Precalculated chord data** for C-B major keys
2. **Lazy loading** - only calculate visible chord type
3. **Caching** scale notes to avoid redundant calculations
4. **Decoupled** audio from visual updates
5. **Removed** print statements from hot paths

## Current Issues & Solutions
- **Ellipsis button transparency**: Fixed with full opaque background + rounded overlay
- **Chord button heights**: Adjusted to 56pt for intermediate view
- **Drag state management**: Reset on drop with proper cleanup
- **Timeline selection**: Clears grid selection, updates display

## Key Invariants (learned the hard way)
- **Chord voicing must accumulate octaves**: use `AudioEngine.voicedNotes(for:)`
  everywhere a chord is spelled into octaves; per-note comparison folds notes
  after a pitch-class wrap back down an octave (G7 bug)
- **Roman numerals carry quality suffixes** ("ii7", "V7", "Imaj7", "vii°7");
  `determineFunction` strips suffixes before matching the degree
- **Chord.parse normalizes unicode accidentals** so `formattedSymbol` output
  ("B♭m7") round-trips

## Next Implementation Tasks
1. **Builder Tab**: Full drag-drop progression builder with analysis (BuildTabView exists but is not in the tab bar)
2. **Learn Tab**: Structured lessons and theory tips
3. **Polish**: Animations, accessibility, app icon
4. **Audio**: Load a SoundFont into AVAudioUnitSampler for richer piano tone

## Testing Strategy
- Unit tests for all services (87 passing)
- UI tests for critical flows
- Manual testing checklist for each feature
- Performance profiling for smooth 60fps

## Git Workflow
- Feature branches off `main`
- Commits: Feature-based with clear messages
- Never push unless explicitly requested