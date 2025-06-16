# ChordLab Implementation Plan

## Overview
This document outlines a comprehensive, incremental implementation plan for the ChordLab music theory education app. Each phase builds upon the previous one and can be tested independently.

## Core Technologies
- **SwiftUI** (iOS 17+) with @Observable macro
- **SwiftData** for persistent storage
- **Tonic** library for music theory calculations
- **AVFoundation** for audio playback
- **Charts** framework for visualizations

## Implementation Phases

### Phase 1: Core Infrastructure (2-3 days)
**Goal**: Set up the foundation with core models, services, and SwiftData integration.

#### Tasks:
1. **Project Setup**
   - Create Xcode project with SwiftUI and SwiftData
   - Add Tonic package dependency
   - Create folder structure as per CLAUDE.md
   - Set up Info.plist and app configuration

2. **SwiftData Models**
   ```
   Core/Models/Persistence/
   ├── UserData.swift (user preferences, current key)
   ├── ChordHistory.swift (recently viewed chords)
   ├── SavedProgression.swift (user-created progressions)
   ├── PracticeSession.swift (practice scores and history)
   └── Achievement.swift (unlocked achievements)
   ```

3. **Core Services**
   ```
   Core/Services/
   ├── TheoryEngine.swift (from project_files)
   ├── AudioEngine.swift (from project_files)
   ├── DataManager.swift (SwiftData ModelContainer)
   └── SettingsManager.swift (UserDefaults wrapper)
   ```

4. **Extensions**
   ```
   Core/Extensions/
   ├── Tonic+Extensions.swift
   ├── Color+Theme.swift
   └── View+Modifiers.swift
   ```

**Testable Output**: 
- App launches with SwiftData container initialized
- TheoryEngine can generate chords
- AudioEngine can play test notes

### Phase 2: Navigation & App Shell (1 day)
**Goal**: Create the main navigation structure with placeholder views.

#### Tasks:
1. **Main App Structure**
   ```
   ├── ChordLabApp.swift (with SwiftData container)
   └── Shared/Navigation/ContentView.swift (TabView)
   ```

2. **Placeholder Views**
   - Create minimal view for each tab
   - Add tab icons and labels
   - Set up environment objects

**Testable Output**:
- App shows 5 tabs with proper icons
- Can navigate between all tabs
- Environment objects accessible in all views

### Phase 3: Learn Tab - Modified Approach (2-3 days)
**Goal**: Create a functional Learn tab focused on immediate educational value without dependencies on unbuilt features.

#### Tasks:
1. **Key Picker Component**
   ```
   Features/Learn/KeyPicker/
   └── KeyPickerView.swift
   ```
   - Grid layout showing all 12 keys
   - Major/Minor/Modal scale selection
   - Updates TheoryEngine and persists to DataManager
   - Visual indication of current selection

2. **Scale Display Component**
   ```
   Features/Learn/Components/
   ├── ScaleDisplayView.swift
   └── ScalePianoView.swift
   ```
   - Shows current scale notes with degree numbers (1-7)
   - Piano visualization highlighting scale notes
   - Play scale button with ascending/descending options
   - Shows intervals between notes

3. **Diatonic Chords Component**
   ```
   Features/Learn/Components/
   ├── DiatonicChordsView.swift
   └── ChordGridItem.swift
   ```
   - Grid showing all diatonic chords for current key
   - Roman numeral notation (I, ii, iii, IV, V, vi, vii°)
   - Tap to play functionality
   - Shows chord tones when tapped
   - Highlights chord function (tonic, subdominant, dominant)

4. **Theory Cards**
   ```
   Features/Learn/Components/
   ├── TheoryCardView.swift
   └── TheoryContent.swift
   ```
   - Reusable card component for theory concepts
   - Initial content covering:
     - How scales are constructed
     - Understanding chord types
     - Basic chord progressions (I-IV-V, ii-V-I)
   - Simple, educational explanations

5. **Update LearnTabView**
   - Remove placeholder quick actions
   - Integrate new functional components
   - Add navigation to key picker
   - Clean, educational-focused layout

**Testable Output**:
- Key picker opens and updates current key
- Scale display shows correct notes for any key/scale
- Piano highlights scale notes accurately  
- All diatonic chords play correctly when tapped
- Theory cards provide educational value
- Everything works immediately without dead ends

### Phase 4: Explore Tab (3-4 days)
**Goal**: Build the chord explorer with search, filtering, and detailed analysis.

#### Tasks:
1. **Explore Views**
   ```
   Features/Explore/Views/
   ├── ExploreView.swift
   ├── ChordCard.swift
   └── CategoryPill.swift
   ```

2. **Chord Detail**
   ```
   Features/Explore/ChordDetail/
   ├── ChordDetailView.swift
   ├── ChordHeaderSection.swift
   ├── IntervalsSection.swift
   ├── VoiceLeadingSection.swift
   └── TheoryNotesSection.swift
   ```

3. **Piano Component**
   ```
   Shared/Components/Piano/
   ├── PianoKeyboardView.swift
   ├── PianoKeyView.swift
   └── PianoHighlight.swift
   ```

4. **SwiftData Integration**
   - Track viewed chords
   - Save favorite chords
   - Store search history

**Testable Output**:
- Can search and filter chords
- Chord details show all analysis
- Piano visualization works
- Audio playback for each chord
- Chord history updates

### Phase 5: Builder Tab (3-4 days)
**Goal**: Create the progression builder with drag-and-drop functionality.

#### Tasks:
1. **Builder Views**
   ```
   Features/Builder/Views/
   ├── BuilderView.swift
   ├── TimelineSection.swift
   ├── ControlsSection.swift
   └── SuggestionsSection.swift
   ```

2. **Timeline Components**
   ```
   Features/Builder/Timeline/
   ├── TimelineItemView.swift
   ├── EmptyTimelineView.swift
   └── TimelineDragDelegate.swift
   ```

3. **Analysis Views**
   ```
   Features/Builder/Analysis/
   ├── ProgressionAnalysisView.swift
   ├── RomanNumeralAnalysisSection.swift
   └── PatternRecognitionSection.swift
   ```

4. **Audio Integration**
   - AudioSequencer implementation
   - Metronome functionality
   - Tempo control

5. **SwiftData Integration**
   - Save/load progressions
   - Store progression history
   - Track favorite progressions

**Testable Output**:
- Can add/remove chords from timeline
- Drag and drop reordering works
- Playback with tempo control
- Analysis updates in real-time
- Can save and reload progressions

### Phase 6: Practice Tab (3-4 days)
**Goal**: Implement practice modes with score tracking.

#### Tasks:
1. **Practice Views**
   ```
   Features/Practice/Views/
   ├── PracticeView.swift
   ├── PracticeModeCard.swift
   ├── DailyStreakBanner.swift
   └── RecentScoresSection.swift
   ```

2. **Ear Training**
   ```
   Features/Practice/EarTraining/
   ├── EarTrainingView.swift
   ├── QuestionCard.swift
   └── AnswerButton.swift
   ```

3. **Additional Modes** (Basic implementations)
   ```
   Features/Practice/ChordRecognition/
   Features/Practice/ProgressionChallenge/
   Features/Practice/TheoryQuiz/
   ```

4. **SwiftData Integration**
   - Store practice sessions
   - Track scores and streaks
   - Save difficulty preferences
   - Achievement progress

**Testable Output**:
- Ear training fully functional
- Scores persist between sessions
- Daily streak tracking works
- Can view practice history
- Difficulty adapts to performance

### Phase 7: Profile Tab (2 days)
**Goal**: Add user statistics, achievements, and settings.

#### Tasks:
1. **Profile Views**
   ```
   Features/Profile/Views/
   ├── ProfileView.swift
   ├── ProfileHeaderView.swift
   ├── StatisticsSection.swift
   └── AchievementsSection.swift
   ```

2. **Settings**
   ```
   Features/Profile/Settings/
   └── SettingsView.swift
   ```

3. **Charts Integration**
   ```
   Shared/Components/Charts/
   ├── ProgressChart.swift
   └── PracticeStatsChart.swift
   ```

4. **Achievement System**
   - Define achievements
   - Track progress
   - Show badges

**Testable Output**:
- Statistics reflect actual usage
- Achievements unlock properly
- Settings persist
- Progress charts display data

### Phase 8: Polish & Optimization (2-3 days)
**Goal**: Add final touches, animations, and optimize performance.

#### Tasks:
1. **UI Polish**
   - Add loading states
   - Implement error handling
   - Add empty states
   - Smooth transitions

2. **Animations**
   - Chord card animations
   - Timeline interactions
   - Achievement unlocks
   - Success/failure feedback

3. **Performance**
   - Optimize SwiftData queries
   - Lazy loading for lists
   - Audio preloading
   - Memory management

4. **Additional Features**
   - Export progressions (MIDI/Share)
   - Sound font loading
   - Localization support
   - Accessibility

**Testable Output**:
- Smooth animations throughout
- No performance issues
- All features polished
- Export functionality works

## Testing Strategy

### Unit Tests
```
Tests/ChordLabTests/
├── TheoryEngineTests.swift
├── AudioEngineTests.swift
├── SwiftDataTests.swift
└── ViewModelTests.swift
```

### UI Tests
```
Tests/ChordLabUITests/
├── NavigationTests.swift
├── LearnTabTests.swift
├── ExploreTabTests.swift
├── BuilderTabTests.swift
└── PracticeTabTests.swift
```

## SwiftData Schema

### Core Models
```swift
@Model
class UserData {
    var id: UUID
    var currentKey: String
    var currentScale: String
    var preferredTempo: Int
    var createdAt: Date
    var modifiedAt: Date
}

@Model
class ChordHistory {
    var id: UUID
    var chordSymbol: String
    var keyContext: String
    var viewedAt: Date
    var isFavorite: Bool
}

@Model
class SavedProgression {
    var id: UUID
    var name: String
    var chords: [String]
    var key: String
    var tempo: Int
    var createdAt: Date
    var modifiedAt: Date
    var isFavorite: Bool
}

@Model
class PracticeSession {
    var id: UUID
    var mode: String
    var score: Int
    var totalQuestions: Int
    var difficulty: String
    var duration: TimeInterval
    var completedAt: Date
}

@Model
class Achievement {
    var id: UUID
    var identifier: String
    var unlockedAt: Date
    var progress: Double
}
```

## Resources Needed
1. **Audio Files**
   - Piano.sf2 (SoundFont file)
   - Metronome.aiff

2. **JSON Content**
   - Intervals.json
   - Chords.json
   - Progressions.json

3. **Images**
   - App icon
   - Tab icons
   - Achievement badges

## Success Metrics
- Each phase can be tested independently
- Core functionality works before adding features
- Performance remains smooth with SwiftData
- User progress persists correctly
- All audio playback functions properly

## Notes
- Start with Phase 1 to ensure solid foundation
- Each phase builds on previous work
- Test thoroughly before moving to next phase
- SwiftData models can be extended as needed
- Keep UI simple initially, polish in Phase 8