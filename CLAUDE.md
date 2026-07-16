# ChordLab - Music Theory Education App

## Quick Reference
- **Architecture**: SwiftUI + @Observable (iOS 17+) + Tonic library + SwiftData
- **Main Services**: TheoryEngine (music theory), AudioEngine (playback), DataManager (persistence)
- **Current State**: Phase 4 (Explore Tab) completed with Piano Chord Visualizer; Arcade (Games) tab added

## Arcade (Games) Section
A self-contained mini-games section, deliberately isolated from the music-theory app:
- **Location**: `ChordLab/Features/Games/` — no dependency on TheoryEngine, AudioEngine, or the SwiftData schema
- **Entry**: 6th tab "Games" (`gamecontroller.fill`) → `GamesHomeView` hub → games open in `fullScreenCover` (tab bar never overlaps game controls)
- **Routing**: `GameHostView` switches on `GameInfo.id`; catalog lives in `GameCatalog` (GamesModels.swift)
- **Scores**: `GameScores.shared` — UserDefaults-backed (`arcade.<gameId>.<field>` keys), `report(score:for:higherIsBetter:)` for bests, counters for wins/bankrolls
- **Shared UI**: `GameScreen` (chrome w/ close+restart), `GameOverOverlay`, `StatPill`, `ArcadeButton`, `PlayingCard`/`PlayingCardView` (card games), `GameHaptics`
- **Games (34)**: TicTacToe (minimax), ConnectFour (alpha-beta), RPS, Dots&Boxes (chain-aware AI), Yahtzee, Snake, 2048, Breakout, WhackAMole, Simon, Reaction Timer, Pong, Tap Flight (flappy), Blackjack (chips/betting), HigherLower, VideoPoker (Jacks or Better), Solitaire (Klondike, tap-to-move + undo), Minesweeper, Sudoku (unique-solution generator), LightsOut, MemoryMatch, WordGuess (Wordle-style), Hangman, plus Sims: Sheepdog (boids herding), Traffic Tycoon (intersection sim), Lemonade Stand (economic sim), Outbreak (turn-based SIR grid), plus RPG: Athanor (deterministic tactical roguelite — 5x5 elemental-chemistry combat, one pure resolve() drives ghost preview/projection/commit, SimPersist mid-fight resume, bequest/Echo-of-the-Fallen meta), plus Watch (ambient, non/minimally interactive): Particle Life, Wealth of Ants (Boltzmann + Gini), Forest Fire (Drossel-Schwabl), Window Lights (real-clock city), Moss Garden (persistent real-time growth), A Small Life (narrated villager, persistent)
- **Conventions**: each game = one file, one `...GameView` struct, helper types nested inside the view (single-module namespace!); timers via `Timer.publish + onReceive`; async sequencing via generation-counter-guarded `Task.sleep`
- **Watch-sim conventions**: `Canvas` + `TimelineView(.animation)` with a plain (non-@Observable) sim class mutated inside the Canvas closure; stats mirrored to `@State` via a slow `Timer.publish`; persistent sims (moss, smalllife) store Codable JSON in UserDefaults and render as a pure function of (seed, age/clock) — never simulate while closed
- **Watch-sim shared infra** (GamesModels.swift): `SimPersist.load/save` for all sim persistence (versioned envelope + `.bak` backup with load fallback, legacy raw-JSON migration; never wipes bytes on decode failure); `SimClock.dt(since:to:cap:)` for every frame delta (never a raw wall-clock subtraction — clamps negative and suspended gaps); `GameScreen(confirmRestart: true)` on Watch sims so restart can't destroy long-running worlds silently; GameHostView keeps the screen awake (`isIdleTimerDisabled`) for `.watch` games only. Idle cheaply: sims idle their TimelineView at 1 Hz and upgrade to 20-30fps only while something visibly moves (see WindowLights `wantsSmoothFrames`); gate canvas gestures on `isPaused`; batch Canvas fills by color/species, never one fill per cell/particle

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