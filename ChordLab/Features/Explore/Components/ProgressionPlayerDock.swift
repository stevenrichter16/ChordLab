//
//  ProgressionPlayerDock.swift
//  ChordLab
//
//  Now-Playing-style progression player docked above the tab bar.
//  Collapsed: a mini bar with play, the chord readout, loop, and an
//  expand chevron. Expanded: the full editor (timeline, analysis strip,
//  BPM, metronome, glossary, save/clear) grows out of the bar in place —
//  no modality, so the piano above stays live.
//

import SwiftUI
import Tonic
import UIKit

/// How the dock renders each chord slot during progression playback
enum ProgressionPlaybackStyle: String, CaseIterable, Identifiable {
    case block
    case arpeggio

    var id: String { rawValue }
}

struct ProgressionPlayerDock: View {
    @State private var isExpanded = false
    @State private var isPlaying = false
    @State private var currentPlayIndex: Int? = nil
    @State private var playbackTimer: Timer? = nil
    @State private var countInRemaining: Int? = nil
    @State private var showRestoredCaption = false
    @AppStorage("progressionLoopEnabled") private var isLooping = true
    @AppStorage("metronomeEnabled") private var metronomeEnabled = false
    @AppStorage("progressionPlaybackStyle") private var playbackStyle: ProgressionPlaybackStyle = .block
    @State private var showingSaveSheet = false
    @State private var showingGlossary = false

    // Tap-hold reorder state
    @State private var selectedChordIndex: Int? = nil
    @State private var showArrows = false
    @State private var arrowDismissTimer: Timer?
    @State private var showBPMSlider = false
    @State private var sliderBPM: Double = 90

    @Environment(AudioEngine.self) private var audioEngine
    @Environment(TheoryEngine.self) private var theoryEngine

    // Computed property to get chords from TheoryEngine
    private var progression: [Chord] {
        theoryEngine.currentProgression.map { $0.chord }
    }

    // Use tempo from TheoryEngine
    private var tempo: Int {
        theoryEngine.currentProgressionTempo
    }

    private func beats(at index: Int) -> Double {
        index < theoryEngine.currentProgression.count
            ? theoryEngine.currentProgression[index].duration
            : 1.0
    }

    // Live analysis of the working progression (nil when empty; cheap at
    // the <=16 chords a timeline realistically holds)
    private var progressionAnalysis: ProgressionAnalysis? {
        progression.isEmpty ? nil : theoryEngine.analyzeProgression(progression)
    }

    // Up to two theory-guided next-chord ideas for the ghost chips
    private var suggestedNextChords: [Chord] {
        guard !progression.isEmpty else { return [] }
        return Array(
            theoryEngine.getChordSuggestions(
                after: progression.map { $0.description },
                limit: 3
            ).prefix(2)
        )
    }

    private var progressionString: String {
        progression.map { $0.formattedSymbol }.joined(separator: " - ")
    }

    // The working progression as a shareable .mid file
    private var midiExport: MIDIFileExport? {
        guard !theoryEngine.currentProgression.isEmpty else { return nil }

        let data = MIDIExporter.fileData(
            chords: theoryEngine.currentProgression.map { ($0.chord, $0.duration) },
            tempo: tempo,
            includeBass: audioEngine.bassDoublingEnabled
        )
        return MIDIFileExport(data: data, filename: "\(theoryEngine.currentKey) Progression")
    }

    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedEditor
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            miniBar
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appSecondaryBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.appBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
        .overlay(alignment: .top) {
            if showRestoredCaption {
                Text("Draft restored")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.appSecondaryBackground))
                    .overlay(Capsule().strokeBorder(Color.appBorder, lineWidth: 1))
                    .offset(y: -32)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isExpanded)
        .onAppear {
            if theoryEngine.draftWasRestored {
                theoryEngine.draftWasRestored = false
                withAnimation { showRestoredCaption = true }

                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showRestoredCaption = false
                    }
                }
            }
        }
        .onDisappear {
            arrowDismissTimer?.invalidate()
            // Playback is driven by a Timer that outlives this view; without
            // this, audio keeps advancing after the user switches tabs
            stopPlayback()
        }
        .onChange(of: theoryEngine.playbackHaltToken) { _, _ in
            // Another surface (the glossary sheet) is taking over audio;
            // a sheet never fires this view's onDisappear, so stop here
            if isPlaying {
                stopPlayback()
                // A playback timer that came due between the halt request
                // and this observer firing may have just started a chord —
                // silence it so nothing rings under the new surface
                audioEngine.stopAllNotes()
            }
        }
        .sheet(isPresented: $showingSaveSheet) {
            SaveProgressionSheet(
                playbackChords: theoryEngine.currentProgression,
                currentKey: theoryEngine.currentKey,
                tempo: tempo
            )
        }
        .sheet(isPresented: $showingGlossary) {
            GlossaryView()
        }
    }

    // MARK: - Mini Bar

    private var miniBar: some View {
        HStack(spacing: 12) {
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(width: 36, height: 36)
            .background(
                progression.isEmpty
                    ? Color.appPrimary.opacity(0.35)
                    : (isPlaying ? Color.red : Color.appPrimary)
            )
            .clipShape(Circle())
            .disabled(progression.isEmpty)
            .accessibilityLabel(isPlaying ? "Stop progression" : "Play progression")

            if let count = countInRemaining {
                Text("Starting in \(count)…")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.appPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if !progression.isEmpty {
                Text(progressionString)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Hold any chord to start building")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: { isLooping.toggle() }) {
                Image(systemName: "repeat")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isLooping ? .appPrimary : .secondary.opacity(0.5))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(isLooping ? "Disable loop" : "Enable loop")

            Button(action: toggleExpanded) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appPrimary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(isExpanded ? "Collapse player" : "Expand player")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture(perform: toggleExpanded)
    }

    // MARK: - Expanded Editor

    private var expandedEditor: some View {
        VStack(spacing: 0) {
            // Controls row
            HStack(spacing: 8) {
                // BPM Button
                Button(action: {
                    if showBPMSlider {
                        // Save the BPM when closing
                        theoryEngine.currentProgressionTempo = Int(sliderBPM)
                    } else {
                        // Initialize slider with current BPM
                        sliderBPM = Double(tempo)
                    }
                    showBPMSlider.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 12))
                        Text("\(showBPMSlider ? Int(sliderBPM) : tempo)")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(showBPMSlider ? .white : .primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(showBPMSlider ? Color.appPrimary : Color.appTertiaryBackground)
                )
                .accessibilityLabel("Tempo: \(tempo) beats per minute")

                // Metronome click track toggle
                Button(action: { metronomeEnabled.toggle() }) {
                    Image(systemName: "metronome")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(metronomeEnabled ? .white : .secondary)
                }
                .frame(width: 30, height: 30)
                .background(metronomeEnabled ? Color.appPrimary : Color.appTertiaryBackground)
                .clipShape(Circle())
                .accessibilityLabel(metronomeEnabled ? "Disable metronome" : "Enable metronome")

                // Playback style: block chords or broken-chord arpeggio
                Menu {
                    Picker("Playback style", selection: $playbackStyle) {
                        Text("Block Chords").tag(ProgressionPlaybackStyle.block)
                        Text("Arpeggio").tag(ProgressionPlaybackStyle.arpeggio)
                    }
                } label: {
                    Image(systemName: "music.quarternote.3")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(playbackStyle == .arpeggio ? .white : .secondary)
                        .frame(width: 30, height: 30)
                }
                .background(playbackStyle == .arpeggio ? Color.appPrimary : Color.appTertiaryBackground)
                .clipShape(Circle())
                .accessibilityLabel("Playback style")

                // Progression glossary (famous progressions to audition/add)
                Button(action: { showingGlossary = true }) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.appPrimary)
                }
                .frame(width: 30, height: 30)
                .background(Color.appPrimary.opacity(0.1))
                .clipShape(Circle())
                .accessibilityLabel("Progression glossary")

                Spacer()

                // Share the working progression as a .mid file
                if let export = midiExport {
                    ShareLink(item: export, preview: SharePreview("\(theoryEngine.currentKey) progression")) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                            .foregroundColor(.appPrimary)
                            .frame(width: 30, height: 30)
                            .background(Color.appPrimary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Export MIDI")
                }

                // Save button
                Button(action: { showingSaveSheet = true }) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 14))
                        .foregroundColor(.appPrimary)
                }
                .frame(width: 30, height: 30)
                .background(Color.appPrimary.opacity(0.1))
                .clipShape(Circle())
                .disabled(progression.isEmpty)
                .accessibilityLabel("Save progression")

                // Clear button
                Button(action: clearProgression) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                }
                .frame(width: 30, height: 30)
                .background(Color.red.opacity(0.1))
                .clipShape(Circle())
                .disabled(progression.isEmpty)
                .accessibilityLabel("Clear progression")
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // BPM Slider (appears when BPM button is tapped)
            if showBPMSlider {
                Slider(value: $sliderBPM, in: 60...200, step: 10)
                    .accentColor(.appPrimary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }

            // Timeline
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if progression.isEmpty {
                            Text("Hold chord buttons to build progression")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(Array(progression.enumerated()), id: \.offset) { index, chord in
                                ChordTimelineItem(
                                    chord: chord,
                                    index: index,
                                    beats: beats(at: index),
                                    numeral: theoryEngine.getRomanNumeral(for: chord.description),
                                    isPlaying: currentPlayIndex == index,
                                    isSelected: selectedChordIndex == index,
                                    onRemove: { removeChord(at: index) },
                                    onLongPress: {
                                        // Only show arrows if reordering is possible
                                        if progression.count > 1 {
                                            selectedChordIndex = index
                                            showArrows = true
                                            startArrowDismissTimer()
                                        }
                                    },
                                    onCycleDuration: {
                                        theoryEngine.cycleChordDuration(at: index)

                                        let feedback = UIImpactFeedbackGenerator(style: .light)
                                        feedback.impactOccurred()
                                    }
                                )
                                .id(index)
                            }

                            // Ghost chips: theory-guided next-chord ideas;
                            // tap auditions the chord and appends it
                            ForEach(suggestedNextChords, id: \.description) { chord in
                                SuggestionChip(chord: chord) {
                                    audioEngine.playChord(chord, velocity: 60, duration: 0.8)
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        theoryEngine.addChordToProgression(chord)
                                    }

                                    let feedback = UIImpactFeedbackGenerator(style: .light)
                                    feedback.impactOccurred()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .frame(height: 96)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.appTertiaryBackground.opacity(0.5))
                        .onTapGesture {
                            // Only handle tap if arrows are showing
                            if showArrows {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedChordIndex = nil
                                    showArrows = false
                                    arrowDismissTimer?.invalidate()
                                }
                            }
                        }
                )
                .overlay {
                    if let count = countInRemaining {
                        Text("\(count)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundColor(.appPrimary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.appSecondaryBackground.opacity(0.9))
                            )
                            .transition(.opacity)
                    }
                }
                .overlay {
                    // Reorder arrows float over the timeline while active
                    if let selectedIndex = selectedChordIndex, showArrows, selectedIndex < progression.count {
                        ChordMoveArrows(
                            canMoveLeft: selectedIndex > 0,
                            canMoveRight: selectedIndex < progression.count - 1,
                            onMoveLeft: { moveChord(from: selectedIndex, direction: .left) },
                            onMoveRight: { moveChord(from: selectedIndex, direction: .right) }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .contentShape(Rectangle())
                .onChange(of: selectedChordIndex) { _, newIndex in
                    if let index = newIndex {
                        withAnimation {
                            proxy.scrollTo(index, anchor: .center)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, progressionAnalysis == nil ? 4 : 12)

            // Live analysis strip: named pattern, cadence, one-tap resolve
            if let analysis = progressionAnalysis {
                HStack(spacing: 8) {
                    if analysis.pattern != .other {
                        AnalysisBadge(icon: "sparkles", text: analysis.pattern.rawValue, tint: .appPrimary)
                    }

                    if let cadence = analysis.cadence {
                        AnalysisBadge(icon: "flag.checkered", text: "\(cadence.rawValue) cadence", tint: .green)
                    }

                    Spacer()

                    Menu {
                        Button("Authentic (V7 → I)") { resolve(.authentic) }
                        Button("Plagal (IV → I)") { resolve(.plagal) }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.right.circle")
                                .font(.system(size: 12))
                            Text("Resolve")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(.appPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.appPrimary.opacity(0.12)))
                    }
                    .accessibilityLabel("Resolve progression with a cadence")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            }

            Divider()
                .padding(.top, 4)
        }
    }

    // MARK: - Actions

    private func toggleExpanded() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isExpanded.toggle()
        }

        // Leaving edit mode dismisses any reorder state
        if !isExpanded {
            selectedChordIndex = nil
            showArrows = false
            arrowDismissTimer?.invalidate()
        }
    }

    private func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }

    private func startPlayback() {
        guard !progression.isEmpty else { return }

        isPlaying = true

        // Looping is jam mode: give the player a downbeat to come in on
        if isLooping {
            countInRemaining = 4
            tickCountIn()
        } else {
            currentPlayIndex = 0
            playNextChord()
        }
    }

    private func tickCountIn() {
        guard isPlaying, let remaining = countInRemaining else { return }

        guard remaining > 0 else {
            countInRemaining = nil
            currentPlayIndex = 0
            playNextChord()
            return
        }

        audioEngine.playClick()

        playbackTimer = Timer.scheduledTimer(withTimeInterval: 60.0 / Double(tempo), repeats: false) { _ in
            countInRemaining = remaining - 1
            tickCountIn()
        }
    }

    private func playNextChord() {
        guard isPlaying, let index = currentPlayIndex else { return }

        if index >= progression.count {
            if isLooping {
                currentPlayIndex = 0
                playNextChord()
            } else {
                stopPlayback()
            }
            return
        }

        // Highlight the chord on piano
        theoryEngine.visualizedChord = progression[index]

        // Also set as selected chord to update the display
        theoryEngine.selectedChord = progression[index]

        // Honor the chord's length in beats
        let beats = index < theoryEngine.currentProgression.count
            ? theoryEngine.currentProgression[index].duration
            : 1.0
        let beatInterval = 60.0 / Double(tempo)
        let interval = beatInterval * beats

        // Stop just before the next chord so repeated chords re-trigger
        // cleanly; the final chord of a non-looping pass rings out
        let isLast = index == progression.count - 1 && !isLooping
        switch playbackStyle {
        case .block:
            audioEngine.playChord(
                progression[index],
                velocity: 80,
                duration: audioEngine.chordSlotDuration(interval: interval, isLast: isLast),
                includeBass: audioEngine.bassDoublingEnabled
            )
        case .arpeggio:
            playArpeggiatedChord(
                progression[index],
                beats: beats,
                beatInterval: beatInterval,
                isLast: isLast
            )
        }

        // Optional click track, aligned to this slot's beats
        if metronomeEnabled {
            for beat in 1..<max(Int(beats.rounded()), 1) {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(beat) * beatInterval) {
                    if isPlaying {
                        audioEngine.playClick()
                    }
                }
            }
            audioEngine.playClick()
        }

        playbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            currentPlayIndex = (currentPlayIndex ?? 0) + 1
            playNextChord()
        }
    }

    /// Broken-chord rendering of one slot: a sustained bass root (when the
    /// preference is on) under eighth notes cycling up through the voicing
    private func playArpeggiatedChord(_ chord: Chord, beats: Double, beatInterval: TimeInterval, isLast: Bool) {
        let notes = audioEngine.voicedNotes(for: chord)
        guard !notes.isEmpty else { return }

        if audioEngine.bassDoublingEnabled {
            let root = notes[0]
            if root.pitch.midiNoteNumber >= 12 {
                let slot = beatInterval * beats
                audioEngine.playNote(
                    Note(root.letter, accidental: root.accidental, octave: root.octave - 1),
                    velocity: 66,
                    duration: audioEngine.chordSlotDuration(interval: slot, isLast: isLast)
                )
            }
        }

        let step = beatInterval / 2
        let stepCount = max(Int((beats * 2).rounded()), 1)

        for stepIndex in 0..<stepCount {
            let note = notes[stepIndex % notes.count]

            DispatchQueue.main.asyncAfter(deadline: .now() + Double(stepIndex) * step) {
                // The slot may have been stopped mid-pattern
                if isPlaying {
                    audioEngine.playNote(note, velocity: 72, duration: step * 1.6)
                }
            }
        }
    }

    private func stopPlayback() {
        isPlaying = false
        currentPlayIndex = nil
        countInRemaining = nil
        playbackTimer?.invalidate()
        playbackTimer = nil

        // Clear the visualized chord and selected chord
        theoryEngine.visualizedChord = nil
        theoryEngine.selectedChord = nil
    }

    private func resolve(_ cadence: TheoryEngine.ResolutionCadence) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            theoryEngine.appendResolution(cadence)
        }

        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
    }

    private func removeChord(at index: Int) {
        theoryEngine.removeFromProgression(at: index)

        // Clean up selection if needed
        if selectedChordIndex == index {
            selectedChordIndex = nil
            showArrows = false
            arrowDismissTimer?.invalidate()
        } else if let selected = selectedChordIndex, selected > index {
            // Adjust selected index if a chord before it was removed
            selectedChordIndex = selected - 1
        }

        if theoryEngine.currentProgression.isEmpty {
            stopPlayback()
        }
    }

    private func clearProgression() {
        theoryEngine.clearProgression()
        stopPlayback()
        selectedChordIndex = nil
        showArrows = false
        arrowDismissTimer?.invalidate()
    }

    // MARK: - Chord Movement

    private enum MoveDirection {
        case left, right
    }

    private func moveChord(from index: Int, direction: MoveDirection) {
        let targetIndex = direction == .left ? index - 1 : index + 1

        // Validate move
        guard targetIndex >= 0 && targetIndex < progression.count else { return }

        // Perform move
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            theoryEngine.reorderProgression(from: index, to: targetIndex + (direction == .left ? 0 : 1))

            // Update selected index to follow the chord
            selectedChordIndex = targetIndex

            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()

            // Reset timer
            startArrowDismissTimer()
        }
    }

    private func startArrowDismissTimer() {
        arrowDismissTimer?.invalidate()
        arrowDismissTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self.selectedChordIndex = nil
                    self.showArrows = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Dock") {
    struct DockPreview: View {
        @State private var theoryEngine = TheoryEngine()
        @State private var audioEngine = AudioEngine()

        var body: some View {
            VStack {
                Spacer()

                ProgressionPlayerDock()
                    .padding(.horizontal, 10)
            }
            .background(Color.appBackground)
            .environment(theoryEngine)
            .environment(audioEngine)
            .onAppear {
                theoryEngine.addChordToProgression(Chord(.C, type: .major))
                theoryEngine.addChordToProgression(Chord(.A, type: .minor))
                theoryEngine.addChordToProgression(Chord(.F, type: .major))
                theoryEngine.addChordToProgression(Chord(.G, type: .major))
            }
        }
    }

    return DockPreview()
}
