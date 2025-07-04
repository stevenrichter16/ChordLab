//
//  ChordVisualizerView.swift
//  ChordLab
//
//  Main container view for the Piano Chord Visualizer
//

import SwiftUI
import Tonic
import UIKit

struct ChordVisualizerView: View {
    @Environment(TheoryEngine.self) private var theoryEngine
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(DataManager.self) private var dataManager
    
    @State private var selectedKey = "C"
    @State private var selectedChord: Chord?
    @State private var selectedChordIndex: Int?
    @State private var selectedChordType: ChordTypeSelector.ChordType = .triads
    @State private var diatonicTriads: [(chord: Chord, romanNumeral: String, function: ChordFunction, degreeName: String)] = []
    @State private var diatonicSevenths: [(chord: Chord, romanNumeral: String, function: ChordFunction, degreeName: String)] = []
    @State private var cachedChordToneRoles: [NoteClass: ChordToneRole] = [:]
    @State private var playingChordNotes: Set<String> = []  // Track which chord notes are playing
    
    // Progression builder states
    @State private var holdTimer: Timer? = nil
    @State private var isHoldingChord = false
    @State private var heldChordIndex: Int? = nil
    
    // Computed property to check if we should show the progression player
    private var showProgressionPlayer: Bool {
        !theoryEngine.currentProgression.isEmpty
    }
    
    // Computed property for current chords based on selected type
    private var currentDiatonicChords: [(chord: Chord, romanNumeral: String, function: ChordFunction, degreeName: String)] {
        selectedChordType == .triads ? diatonicTriads : diatonicSevenths
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Title
//                Text("Piano Chord Visualizer")
//                    .font(.largeTitle)
//                    .fontWeight(.bold)
//                    .padding(.top)
                
                // Key selector with chord type toggle
                HStack(alignment: .bottom) {
                    KeySelector(selectedKey: $selectedKey)
                    
                    Spacer()
                    
                    // Minimalist chord type toggle
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("Type")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        MinimalistChordToggle(selectedChordType: $selectedChordType)
                    }
                }
                .padding(.horizontal)
                
                // Piano visualization with overlay option
                ZStack(alignment: .topTrailing) {
                    ChordPianoView(
                        highlightedChord: theoryEngine.visualizedChord ?? selectedChord,
                        currentKey: selectedKey,
                        playingChordNotes: $playingChordNotes
                    )
                    
                    // Alternative: Overlay the toggle on the piano
                    // Uncomment to use this approach instead
                    /*
                    MinimalistChordToggle(selectedChordType: $selectedChordType)
                        .padding(8)
                        .background(
                            Color.appBackground.opacity(0.9)
                                .cornerRadius(8)
                        )
                        .padding(.trailing, 8)
                        .padding(.top, 8)
                    */
                }
                .padding(.horizontal)
                
                // Current chord display
                if let chord = selectedChord {
                    HStack(spacing: 12) {
                        Text(chord.formattedSymbol)
                            .font(.system(size: 18, weight: .bold))
                        
                        // Only show roman numeral and degree name if we have a selected index
                        if let index = selectedChordIndex, index < currentDiatonicChords.count {
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text(currentDiatonicChords[index].romanNumeral)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text(currentDiatonicChords[index].degreeName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.appPrimary)
                        } else {
                            // For chords selected from timeline, determine roman numeral and function
                            let romanNumeral = theoryEngine.getRomanNumeral(for: chord.description)
                            let function = theoryEngine.determineFunction(romanNumeral: romanNumeral)
                            
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text(romanNumeral)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text(function.rawValue)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.appPrimary)
                        }
                    }
                    
                    // Chord notes
                    HStack(spacing: 8) {
                        ForEach(chord.noteClasses, id: \.self) { note in
                            ChordNoteButton(
                                note: note,
                                role: cachedChordToneRoles[note]
                            )
                        }
                    }
                } else {
                    Text("Select a chord")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 3)
                }
                
                // Diatonic chord grid
                DiatonicChordGrid(
                    chords: currentDiatonicChords,
                    selectedChord: $selectedChord,
                    selectedChordIndex: $selectedChordIndex,
                    onChordPlay: { chord in
                        playChordOnPiano(chord)
                    },
                    onChordHold: { chord in
                        addChordToProgression(chord)
                    }
                )
                .padding(.horizontal)
                
                // Color legend
                ColorLegend(showSeventh: selectedChordType == .sevenths)
                    .padding()
                    .padding(.bottom)
            }
        }
        .background(Color.appBackground)
        .overlay(
            Group {
                if showProgressionPlayer {
                    FloatingProgressionPlayer()
                }
            }
        )
        .onAppear {
            updateChords()
            // Ensure audio engine is ready
            if !audioEngine.isPlaying {
                audioEngine.start()
            }
        }
        .onChange(of: selectedKey) { _, _ in
            updateChords()
        }
        .onChange(of: selectedChord) { _, newChord in
            updateChordToneRoles(for: newChord)
        }
        .onChange(of: selectedChordType) { _, newType in
            // Clear selection when switching between triads and 7ths
            selectedChord = nil
            selectedChordIndex = nil
            cachedChordToneRoles = [:]
            
            // Load the other chord type if not already loaded
            if newType == .sevenths && diatonicSevenths.isEmpty {
                diatonicSevenths = theoryEngine.getSeventhChordsWithAnalysis()
            } else if newType == .triads && diatonicTriads.isEmpty {
                diatonicTriads = theoryEngine.getDiatonicChordsWithAnalysis()
            }
        }
        .onChange(of: theoryEngine.selectedChord) { _, newChord in
            // When a chord is selected from the progression timeline
            if let chord = newChord {
                // Clear the diatonic chord grid selection
                selectedChordIndex = nil
                
                // Update the selected chord to show in the display
                selectedChord = chord
                
                // Update chord tone roles
                updateChordToneRoles(for: chord)
                
                // Clear the theory engine's selected chord after processing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    theoryEngine.selectedChord = nil
                }
            }
        }
    }
    
    private func updateChords() {
        theoryEngine.setKey(selectedKey, scaleType: "major")
        
        // Clear both arrays when key changes (they're no longer valid)
        diatonicTriads = []
        diatonicSevenths = []
        
        // Only calculate what we're currently displaying
        if selectedChordType == .triads {
            diatonicTriads = theoryEngine.getDiatonicChordsWithAnalysis()
        } else {
            diatonicSevenths = theoryEngine.getSeventhChordsWithAnalysis()
        }
        
        // Clear selection when switching
        selectedChord = nil
        selectedChordIndex = nil
        cachedChordToneRoles = [:]
        
        // Persist the key selection in background after a delay
        Task { @MainActor in
            // Small delay to avoid blocking UI
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            do {
                try dataManager.updateUserData { userData in
                    userData.currentKey = selectedKey
                }
            } catch {
                // Silently fail - not critical for UI
            }
        }
    }
    
    private func updateChordToneRoles(for chord: Chord?) {
        guard let chord = chord else {
            cachedChordToneRoles = [:]
            return
        }
        
        // Get chord tone roles from TheoryEngine
        let roles = theoryEngine.getChordToneRoles(for: chord)
        var roleMap: [NoteClass: ChordToneRole] = [:]
        
        for role in roles {
            switch role.role {
            case "Root":
                roleMap[role.note] = .root
            case "Third":
                roleMap[role.note] = .third
            case "Fifth":
                roleMap[role.note] = .fifth
            case "Seventh":
                roleMap[role.note] = .seventh
            default:
                break
            }
        }
        
        cachedChordToneRoles = roleMap
    }
    
    private func playChordOnPiano(_ chord: Chord) {
        // Do the visual update asynchronously to not block audio
        Task { @MainActor in
            // Clear previous playing notes
            playingChordNotes.removeAll()
            
            // Calculate which notes are playing based on the chord
            // AudioEngine plays chords starting at octave 4
            let baseOctave = 4
            var currentOctave = baseOctave
            var noteIdentifiers: Set<String> = []
            
            for (index, noteClass) in chord.noteClasses.enumerated() {
                // Handle octave wrapping for proper voicing
                if index > 0 {
                    let previousNoteClass = chord.noteClasses[index - 1]
                    let previousSemitone = previousNoteClass.intValue
                    let currentSemitone = noteClass.intValue
                    
                    if currentSemitone < previousSemitone {
                        currentOctave = baseOctave + 1
                    }
                }
                
                // Create the note identifier (e.g., "C4", "E4", "G4")
                let noteString = noteClass.description
                    .replacingOccurrences(of: "♯", with: "#")
                    .replacingOccurrences(of: "♭", with: "b")
                let noteIdentifier = "\(noteString)\(currentOctave)"
                noteIdentifiers.insert(noteIdentifier)
            }
            
            // Update all at once
            playingChordNotes = noteIdentifiers
            
            // Clear the playing notes after the chord duration (matching AudioEngine default of 0.5s)
            try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
            playingChordNotes.removeAll()
        }
    }
    
    private func addChordToProgression(_ chord: Chord) {
        theoryEngine.addChordToProgression(chord)
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Color Legend

struct ColorLegend: View {
    let showSeventh: Bool
    
    var body: some View {
        HStack(spacing: 24) {
            LegendItem(color: .blue, label: "Root")
            LegendItem(color: .green, label: "Third")
            LegendItem(color: .orange, label: "Fifth")
            if showSeventh {
                LegendItem(color: .purple, label: "Seventh")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.appSecondaryBackground.opacity(0.5))
        .cornerRadius(12)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 16, height: 16)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    ChordVisualizerView()
        .environment(TheoryEngine())
        .environment(AudioEngine())
        .environment(DataManager(inMemory: true))
}
