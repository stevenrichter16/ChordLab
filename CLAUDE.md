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
│   ├── Learn/         # ✅ ScalePianoView, KeyScaleSelector, 10 interactive lessons
│   ├── Explore/       # ✅ ChordVisualizerView, ProgressionPlayerDock, Glossary/
│   ├── Library/       # ✅ Saved progressions: search/sort, rename/duplicate/delete
│   ├── Builder/       # 📋 TODO: Drag-drop progression builder
│   ├── Practice/      # ✅ Ear training, chord recognition, progressions, quiz
│   └── Profile/       # ✅ Stats, achievements (AchievementsView)
└── Shared/
    └── Components/    # Piano/, Common/, Charts/
```

## Design System (Core/Extensions/DesignSystem.swift + Color+Theme.swift)
- **Brand accent**: AccentColor asset (indigo-blue, light/dark variants);
  `Color.appPrimary` reads it and build settings apply it as global tint
- **Function colors**: `ChordFunction.color` is the ONLY function→color
  mapping (tonic/submediant blue, subdominant/supertonic green,
  dominant/leadingTone orange, else gray) — never roll a new switch
- **Tokens**: AppRadius (chip 8 / card 12 / chrome 20), AppSpacing (4pt
  grid), `.cardShadow()`/`.floatingShadow()` (scheme-aware opacity),
  `Animation.appSpring`/`.appSpringSlow`, instrument-chrome fonts
  (`.chordSymbol`, `.chordSymbolSmall`, `.countdown`, `.monoReadout`)
- **Typography rule**: semantic Dynamic Type for reading text; fixed
  sizes only via the chrome font tokens
- **One tab bar**: FloatingTabBar (material) — Compact/UltraCompact and
  the TabBarStyle picker were deleted; don't reintroduce style switches
- **Piano is off-limits for restyling** (user direction): ChordPianoView,
  PianoKeyView, ScalePianoView, Color+PianoKeys keep their current design

## Practice Tab Architecture
```swift
PracticeGameView<Stimulus>       // Generic session container: setup -> questions -> results
├── PracticeQuestionGenerator    // Static generators; uses throwaway TheoryEngine instances
│                                // so global key state is never mutated mid-game
├── EarTrainingView              // Chord quality by ear (auto-plays, replay button)
├── ChordRecognitionView         // Name the chord shown on ChordPianoView
├── ProgressionChallengeView     // Identify 4-chord Roman numeral patterns by ear
├── TheoryQuizView               // Roman numerals, functions, chord tones
└── ReviewMistakesView           // Replays MissedQuestion queue (mode .review,
                                 // no difficulty picker); correct answer resolves,
                                 // wrong answer re-queues via lastMissedAt bump
// Results are saved via DataManager.recordPracticeSession which also
// advances first_practice / streak / ear_training_pro achievements.
// Every wrong answer (practice + lesson quizzes) feeds the MissedQuestion
// queue via recordMissedQuestion (deduped on prompt + correct answer)
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

## Recent Implementation: ProgressionPlayerDock

### Docked bar + in-place editor (replaced the floating widget)
- Mounted once, via `.safeAreaInset(edge: .bottom)` in ChordVisualizerView,
  so it sits above the custom tab bar (ContentView reserves its 64pt) and
  scroll content clears it automatically
- ALWAYS visible, even with an empty progression (play disabled, hint text,
  glossary reachable) — this is the discoverability fix
- Two states: **mini bar** (play/stop, chord readout or count-in text, loop,
  chevron; tapping the bar toggles) and **expanded editor** that grows out of
  the bar in place (no sheet/modality, piano stays live): controls row
  (BPM, metronome, glossary, save, clear), timeline, analysis strip
- No drag-to-reposition and no PlayerViewState enum anymore; timeline cells
  live in ProgressionTimelineComponents.swift

### Key Features
- Tap chord in timeline to select/visualize
- Hold chord button to reorder (shows arrows)
- Per-chord duration: 1/2/4 beats via the bottom band on expanded cells
  (cycleChordDuration snaps off-grid values); widths scale with beats;
  durations persist through save/load and drafts
- Loop defaults ON (@AppStorage progressionLoopEnabled, toggle in the bar);
  looping playback starts with a 4-beat count-in (clicks + countdown overlay
  on the timeline, "Starting in N…" text in the bar); optional metronome
  click track (@AppStorage)
- Bass doubling on progression playback (root -12 semitones), gated by the
  bassDoublingEnabled preference in Settings > Sound
- Playback styles (@AppStorage progressionPlaybackStyle): block (default)
  or arpeggio — eighth notes cycling up the voicing over a sustained
  bass root, scheduled per slot in playArpeggiatedChord
- MIDI export: dock share button + Library detail menu; MIDIExporter
  writes format-0 SMF bytes (480 ppq, tempo meta, piano program) using
  AudioEngine.voicedNotes (now also static) + the bass-doubling rule;
  MIDIFileExport is the ShareLink Transferable (.mid FileRepresentation)
- BPM adjustment (60-200), default 90
- Save progressions with name/tags
- Draft auto-persists on scenePhase background/inactive and restores at
  launch (7-day staleness cutoff, "Draft restored" caption)
- Playback with visual feedback

### Component Architecture
```swift
ProgressionPlayerDock            // miniBar + expandedEditor, all playback logic
├── ChordTimelineItem            // Bordered cell; function-colored roman
│                                // numeral above the symbol (numeral param)
├── SuggestionChip               // Dashed ghost cell after the timeline: tap to
│                                // audition + append a suggested next chord
├── AnalysisBadge                // Capsule for the analysis strip
├── ChordMoveArrows              // Reorder UI
└── SaveProgressionSheet         // Save dialog
// Cells/badges/arrows live in ProgressionTimelineComponents.swift
```

### Analysis strip & resolve (expanded editor)
- Under the timeline: pattern badge (analyzeProgression, hidden for .other),
  cadence badge, and a Resolve menu — Authentic appends V7(2 beats)+I(4),
  Plagal appends IV(2)+I(4) via `TheoryEngine.appendResolution(_:)`

### Progression Glossary (Features/Explore/Glossary/)
- `GlossaryLibrary.all`: 13 degree-based famous progressions (pop/rock/jazz/
  classical/blues/cadences); `GlossaryProgression.playbackChords(in:)` renders
  them in the CURRENT key via the diatonic analysis arrays
- `GlossaryView` sheet: entry points are the book buttons in
  ChordVisualizerView's header and the dock's expanded controls row;
  per-chord chips play single chords,
  play button runs a cancellable Task loop (one entry at a time), Add appends
  chords+durations to the WIP (adopts suggestedTempo only when WIP was empty)
- Audio handoff: `TheoryEngine.playbackHaltToken` (bumped by
  `requestPlaybackHalt()`); the player observes it via .onChange and stops —
  needed because sheets never fire the covered view's onDisappear

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
- **Timeline selection**: Clears grid selection, updates display
- (Floating-widget issues — ellipsis transparency, drag state, edge
  bounce-back — are moot since the dock redesign removed that chrome)

## Key Invariants (learned the hard way)
- **Chord voicing must accumulate octaves**: use `AudioEngine.voicedNotes(for:)`
  everywhere a chord is spelled into octaves; per-note comparison folds notes
  after a pitch-class wrap back down an octave (G7 bug)
- **Roman numerals carry quality suffixes** ("ii7", "V7", "Imaj7", "viiø7");
  `determineFunction` strips suffixes before matching the degree, and every
  pattern/cadence/suggestion matcher compares `baseNumeral()` output so
  seventh-chord progressions match their triad patterns
- **NoteClass(String) must cover edge enharmonics** (E#, B#, Cb, Fb) — F#
  major's vii chord is rooted on E#, and a parse failure silently drops
  chords from saved progressions
- **Chord.parse normalizes unicode accidentals** so `formattedSymbol` output
  ("B♭m7") round-trips
- **Precalculated triad/seventh tables are major-only** and keyed by root
  alone; `get*ChordsWithAnalysis` must gate the fast path on
  `currentScaleType == "major"` or minor keys silently get major chords
- **Transposition refuses non-diatonic content**: `transposedProgressionChords`
  verifies the stored chord IS the source key's diatonic chord at its
  degree before re-rendering, else returns nil (the detail view alerts)

## Audio
- The sampler loads `Resources/Sounds/GeneralUser.sf2` (GeneralUser GS,
  program 0 piano) asynchronously off the main thread at launch (a sync
  load stalls cold start ~1s); `AudioEngine.isInstrumentLoaded` gates the
  velocity scaling (sampled piano: 80/70%, sine fallback: 50/40%)
- **Note-offs are ownership-checked**: every play invocation stamps its MIDI
  notes in `noteOwners`; a scheduled stop only fires for notes it still owns,
  so re-triggering a note never gets silenced by an older pending stop
- **Progression slots go through `chordSlotDuration(interval:isLast:)`**:
  interior chords stop at 0.9× their slot (clean re-trigger of repeats),
  the final non-looping chord gets ≥1.2s to ring out
- **Instrument selection**: `AudioEngine.Instrument` — 20 GM voices in six
  categories (keys/mallets/organs/guitars/ensemble/synths, all from the
  same bank; solo winds excluded as chord-hostile), persisted as
  "instrumentProgram"; Settings > Sound navigationLink picker calls
  `setInstrument` which stops all notes and reloads the bank on a serial
  queue off-thread
- License permits bundling (see `Resources/Sounds/GeneralUser-LICENSE.txt`);
  attribution shown in Settings > About

## Lessons (Learn tab)
```swift
LessonLibrary.all            // 10 lessons in curriculum order; ids are stable strings
LessonDetailView             // pages (demo piano + tappable chords) -> quiz -> completion
UserData.completedLessons    // persisted ids; DataManager.markLessonCompleted is idempotent
// theory_expert achievement target is synced to LessonLibrary.all.count on Learn appear
```

## Onboarding & Icon
- First-run walkthrough (`OnboardingView`) presents as a fullScreenCover
  gated by @AppStorage("hasCompletedOnboarding")
- App icon: generated light/dark/tinted 1024px PNGs in AppIcon.appiconset
  (chord-tone dots over piano keys, matching the root/third/fifth colors)

## Library detail (ProgressionDetailView)
- Pattern/cadence badges + Transpose to… menu (all 12 keys) via
  `TheoryEngine.transposedProgressionChords` — numeral degrees re-render
  through the target key's diatonic sets (throwaway engines, durations
  kept, legacy chord/numeral columns synced; non-diatonic content alerts
  instead of guessing)
- Export MIDI ShareLink in the toolbar menu

## Next Implementation Tasks
1. **Glossary v2**: borrowed/secondary chords in entries, minor-key variants
2. **Native drag-to-reorder** on dock timeline cells (still long-press + arrows)
3. **Drums/groove layer**: percussion channel needs a second sampler node
   (GS percussion bank), deliberately out of scope so far

## Testing Strategy
- Unit tests for all services
- UI tests for critical flows
- Manual testing checklist for each feature
- Performance profiling for smooth 60fps

## Git Workflow
- Feature branches off `main`
- Commits: Feature-based with clear messages
- Never push unless explicitly requested