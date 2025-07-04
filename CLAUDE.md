# ChordLab - Music Theory Education App

## Quick Reference
- **Architecture**: SwiftUI + @Observable (iOS 17+) + Tonic library + SwiftData
- **Main Services**: TheoryEngine (music theory), AudioEngine (playback), DataManager (persistence)
- **Current State**: Phase 4 (Explore Tab) completed with Piano Chord Visualizer

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
│   ├── Builder/       # 📋 TODO: Drag-drop progression builder
│   ├── Practice/      # 📋 TODO: Ear training, quizzes
│   └── Profile/       # 📋 TODO: Stats, achievements
└── Shared/
    └── Components/    # Piano/, Common/, Charts/
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

## Next Implementation Tasks
1. **Builder Tab**: Full drag-drop progression builder with analysis
2. **Practice Tab**: Ear training, chord recognition, theory quizzes
3. **Profile Tab**: Statistics, achievements, progress tracking
4. **Polish**: Animations, accessibility, app icon

## Testing Strategy
- Unit tests for all services (87 passing)
- UI tests for critical flows
- Manual testing checklist for each feature
- Performance profiling for smooth 60fps

## Git Workflow
- Branch: `scrollable-piano`
- Commits: Feature-based with clear messages
- Never push unless explicitly requested