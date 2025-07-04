# ChordLab Quick Reference

## Current Focus: FloatingProgressionPlayer
- **File**: `/Features/Explore/Components/FloatingProgressionPlayer.swift`
- **States**: minimized → intermediate → expanded
- **Recent Fix**: Ellipsis button opacity (full background + rounded overlay)

## Key Files to Know
```
Features/Explore/
├── Views/ChordVisualizerView.swift      # Main Explore tab
├── Components/
│   ├── FloatingProgressionPlayer.swift   # Current work
│   ├── DiatonicChordGrid.swift          # Chord buttons
│   ├── ChordPianoView.swift             # Piano visualization
│   └── SaveProgressionSheet.swift       # Save dialog

Core/Services/
├── TheoryEngine.swift                    # Music theory logic
├── AudioEngine.swift                     # Sound playback
└── DataManager.swift                     # SwiftData persistence
```

## Common Patterns

### Chord Creation
```swift
Chord(.C, type: .major)     // ✅ Correct
Chord(.C, type: .maj7)      // ✅ Correct
Chord(.Am)                  // ❌ Wrong - use Chord(.A, type: .minor)
```

### Environment Objects
```swift
@Environment(TheoryEngine.self) private var theoryEngine
@Environment(AudioEngine.self) private var audioEngine
@Environment(DataManager.self) private var dataManager
```

### State Management
```swift
// Timeline selection
theoryEngine.selectedChord = chord      // From timeline
theoryEngine.visualizedChord = chord    // For piano highlight

// Progression
theoryEngine.currentProgression: [PlaybackChord]
theoryEngine.currentProgressionTempo: Int
```

## UI Components

### Color Scheme
- `Color.appBackground` - Main background
- `Color.appSecondaryBackground` - Cards/buttons
- `Color.appTertiaryBackground` - Subtle elements
- `Color.appPrimary` - Accent color
- `Color.appBorder` - Borders

### Standard Sizes
- Chord buttons: 70pt height
- Intermediate player: 56pt height
- Tab bar: 49pt (system)
- Corner radius: 12-16pt

## Performance Tips
1. Use precalculated chord data when possible
2. Avoid print statements in production
3. Decouple audio from visual updates
4. Cache expensive calculations in @State
5. Use lazy loading for chord types

## Testing
- Run all tests: `Cmd+U`
- Test file naming: `*Tests.swift`
- Use `@MainActor` for UI tests
- Mock services with `inMemory: true`

## Git Commands
```bash
git status              # Check changes
git add -A              # Stage all
git commit -m "msg"     # Commit
# Never push unless asked
```