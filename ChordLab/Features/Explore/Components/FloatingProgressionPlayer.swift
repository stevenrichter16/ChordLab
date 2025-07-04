//
//  FloatingProgressionPlayer.swift
//  ChordLab
//
//  Floating draggable chord progression player for the Piano Chord Visualizer
//

import SwiftUI
import Tonic
import UIKit
import UniformTypeIdentifiers

// Extension for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

enum PlayerViewState: String, CaseIterable {
    case minimized = "Minimized"
    case intermediate = "Simple"
    case expanded = "Full"
    
    var icon: String {
        switch self {
        case .minimized: return "square.stack"
        case .intermediate: return "square.stack.fill"
        case .expanded: return "square.stack.3d.up.fill"
        }
    }
}

struct FloatingProgressionPlayer: View {
    @State private var viewState: PlayerViewState = .minimized
    @State private var isPlaying = false
    @State private var currentPlayIndex: Int? = nil
    @State private var playbackTimer: Timer? = nil
    @State private var isLooping = false
    @State private var dragOffset = CGSize.zero
    @State private var position = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 200)
    @State private var showingSaveSheet = false
    @State private var showingViewMenu = false
    
    // Tap-hold reorder state
    @State private var selectedChordIndex: Int? = nil
    @State private var showArrows = false
    @State private var arrowDismissTimer: Timer?
    @State private var showBPMSlider = false
    @State private var sliderBPM: Double = 120
    
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
    
    var body: some View {
        Group {
            switch viewState {
            case .minimized:
                minimizedView
            case .intermediate:
                intermediateView
            case .expanded:
                expandedView
            }
        }
        .position(x: position.x + dragOffset.width, y: position.y + dragOffset.height)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewState)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
        .onDisappear {
            arrowDismissTimer?.invalidate()
        }
    }
    
    // MARK: - Minimized View
    
    private var minimizedView: some View {
        HStack(spacing: 8) {
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(width: 36, height: 36)
            .background(isPlaying ? Color.red : Color.appPrimary)
            .clipShape(Circle())
            
            if !progression.isEmpty {
                Text(progressionString)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            } else {
                Text("No progression")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            // Ellipsis menu
            Menu {
                ForEach(PlayerViewState.allCases, id: \.self) { state in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewState = state
                        }
                    }) {
                        Label(state.rawValue, systemImage: state.icon)
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.appPrimary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appSecondaryBackground)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    position.x += value.translation.width
                    position.y += value.translation.height
                    dragOffset = .zero
                }
        )
    }
    
    // MARK: - Intermediate View
    
    private var intermediateView: some View {
        HStack(spacing: 0) {
                // Play button - vertical rectangle
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44)
                        .frame(maxHeight: .infinity)
                }
                .background(isPlaying ? Color.red : Color.appPrimary)
                .cornerRadius(16, corners: [.topLeft, .bottomLeft])
                
                // Timeline
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {  // No spacing for seamless minimal design
                            if progression.isEmpty {
                                Text("Hold chord buttons to build progression")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 40)
                                    .frame(minWidth: 200)
                                    .frame(maxHeight: .infinity)
                            } else {
                                ForEach(Array(progression.enumerated()), id: \.offset) { index, chord in
                                    MinimalChordTimelineItem(
                                        chord: chord,
                                        index: index,
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
                                        }
                                    )
                                    .id(index)
                                }
                                
                                // Spacer to ensure last chord is visible
                                Color.clear
                                    .frame(width: 44, height: 1)
                            }
                        }
                        .padding(.horizontal, 12)
                        .frame(maxHeight: .infinity)
                    }
                    .background(Color.appTertiaryBackground.opacity(0.3))
                    .onChange(of: selectedChordIndex) { _, newIndex in
                        if let index = newIndex {
                            withAnimation {
                                proxy.scrollTo(index, anchor: .center)
                            }
                        }
                    }
                } // Close ScrollViewReader
            } // Close HStack
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appSecondaryBackground)
                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        )
        .overlay(
            // Ellipsis menu on the right side
            HStack {
                Spacer()
                Menu {
                    ForEach(PlayerViewState.allCases, id: \.self) { state in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                viewState = state
                            }
                        }) {
                            Label(state.rawValue, systemImage: state.icon)
                        }
                    }
                } label: {
                    ZStack {
                        // Full opaque background to cover corners
                        Rectangle()
                            .fill(Color.appTertiaryBackground)
                            .frame(width: 44)
                        
                        // Rounded corner overlay
                        Rectangle()
                            .fill(Color.appTertiaryBackground)
                            .frame(width: 44)
                            .cornerRadius(16, corners: [.topRight, .bottomRight])
                        
                        // Ellipsis icon
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(width: 44)
                    .frame(maxHeight: .infinity)
                }
            }
        )
        .overlay(
            // Arrows overlay for intermediate view
            Group {
                if let selectedIndex = selectedChordIndex, showArrows, selectedIndex < progression.count {
                    ChordMoveArrows(
                        canMoveLeft: selectedIndex > 0,
                        canMoveRight: selectedIndex < progression.count - 1,
                        onMoveLeft: { moveChord(from: selectedIndex, direction: .left) },
                        onMoveRight: { moveChord(from: selectedIndex, direction: .right) }
                    )
                    .offset(y: 60)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        )
        .frame(maxWidth: UIScreen.main.bounds.width - 20) // Use UIScreen instead of GeometryReader
        .frame(height: 56) // Reduced height for intermediate view
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    var newX = position.x + value.translation.width
                    var newY = position.y + value.translation.height
                    
                    let screenWidth = UIScreen.main.bounds.width
                    let screenHeight = UIScreen.main.bounds.height
                    
                    // Calculate view width (limited by screen width)
                    let viewWidth = min(screenWidth - 20, 350)
                    let halfWidth = viewWidth / 2
                    
                    // Ensure the view stays within screen bounds with bounce back
                    newX = max(halfWidth + 10, min(screenWidth - halfWidth - 10, newX))
                    newY = max(50, min(screenHeight - 50, newY))
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        position.x = newX
                        position.y = newY
                        dragOffset = .zero
                    }
                }
        )
    }
    
    // MARK: - Expanded View
    
    @ViewBuilder
    private var expandedView: some View {
        ZStack {
            VStack(spacing: 0) {
                // Compact header with drag handle and ellipsis menu
                HStack {
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 5)
                    
                    Spacer()
                    
                    // Ellipsis menu
                    Menu {
                        ForEach(PlayerViewState.allCases, id: \.self) { state in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    viewState = state
                                }
                            }) {
                                Label(state.rawValue, systemImage: state.icon)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.appPrimary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .contentShape(Rectangle()) // Make entire header area draggable
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            position.x += value.translation.width
                            position.y += value.translation.height
                            dragOffset = .zero
                        }
                )
                
                // Condensed controls
                HStack(spacing: 12) {
                    // Play button
                    Button(action: togglePlayback) {
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(width: 36, height: 36)
                    .background(isPlaying ? Color.red : Color.appPrimary)
                    .clipShape(Circle())
                    
                    // Loop toggle
                    Button(action: { isLooping.toggle() }) {
                        Image(systemName: "repeat")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isLooping ? .white : .secondary)
                    }
                    .frame(width: 30, height: 30)
                    .background(isLooping ? Color.appPrimary : Color.appTertiaryBackground)
                    .clipShape(Circle())
                    
                    Spacer()
                    
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
                    
                    // Clear button
                    Button(action: clearProgression) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                    .frame(width: 30, height: 30)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
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
                                        }
                                    )
                                    .id(index)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    .frame(height: 84)
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
                .padding(.bottom, 12)
                
//                // Hint for reordering
//                if progression.count > 1 && selectedChordIndex == nil {
//                    Text("Hold to reorder")
//                        .font(.caption2)
//                        .foregroundColor(.secondary)
//                        .padding(.bottom, 8)
//                }
            } // End VStack
            
            // Arrows overlay - positioned above everything
            if let selectedIndex = selectedChordIndex, showArrows, selectedIndex < progression.count {
                ChordMoveArrows(
                    canMoveLeft: selectedIndex > 0,
                    canMoveRight: selectedIndex < progression.count - 1,
                    onMoveLeft: { moveChord(from: selectedIndex, direction: .left) },
                    onMoveRight: { moveChord(from: selectedIndex, direction: .right) }
                )
                .offset(y: 105) // Position it above the timeline
                .transition(.scale.combined(with: .opacity))
                .zIndex(1000) // Ensure it's on top
            }
        } // End ZStack
        .frame(width: 350)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appSecondaryBackground)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .sheet(isPresented: $showingSaveSheet) {
            SaveProgressionSheet(
                chords: progression,
                currentKey: theoryEngine.currentKey,
                tempo: tempo
            )
        }
    }
    
    // MARK: - Helper Views
    
    private var progressionString: String {
        let chordSymbols = progression.compactMap { chord in
            chord.formattedSymbol
        }
        return chordSymbols.joined(separator: " - ")
    }
    
    // MARK: - Actions
    
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
        currentPlayIndex = 0
        playNextChord()
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
        
        // Play the chord
        audioEngine.playChord(progression[index], velocity: 80, duration: 0.8)
        
        // Schedule next chord
        let interval = 60.0 / Double(tempo) // Convert BPM to seconds
        playbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            currentPlayIndex = (currentPlayIndex ?? 0) + 1
            playNextChord()
        }
    }
    
    private func stopPlayback() {
        isPlaying = false
        currentPlayIndex = nil
        playbackTimer?.invalidate()
        playbackTimer = nil
        
        // Clear the visualized chord and selected chord
        theoryEngine.visualizedChord = nil
        theoryEngine.selectedChord = nil
    }
    
    private func adjustTempo(_ change: Int) {
        theoryEngine.currentProgressionTempo = max(60, min(200, theoryEngine.currentProgressionTempo + change))
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

// MARK: - Chord Move Arrows

struct ChordMoveArrows: View {
    let canMoveLeft: Bool
    let canMoveRight: Bool
    let onMoveLeft: () -> Void
    let onMoveRight: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Left arrow
            Button(action: onMoveLeft) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(canMoveLeft ? .white : .gray)
                    .opacity(canMoveLeft ? 1.0 : 0.5)
            }
            .disabled(!canMoveLeft)
            
            // Right arrow
            Button(action: onMoveRight) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(canMoveRight ? .white : .gray)
                    .opacity(canMoveRight ? 1.0 : 0.5)
            }
            .disabled(!canMoveRight)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.9))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Minimal Chord Timeline Item (for intermediate view)

struct MinimalChordTimelineItem: View {
    let chord: Chord
    let index: Int
    let isPlaying: Bool
    let isSelected: Bool
    let onRemove: () -> Void
    let onLongPress: () -> Void
    
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(TheoryEngine.self) private var theoryEngine
    @State private var isTapped = false
    
    var body: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(isPlaying ? Color.appPrimary : (isTapped ? Color.appPrimary.opacity(0.8) : Color.appSecondaryBackground))
                .overlay(
                    // Side borders only
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(isPlaying ? Color.clear : Color.appBorder)
                            .frame(width: 1)
                        Spacer()
                        Rectangle()
                            .fill(isPlaying ? Color.clear : Color.appBorder)
                            .frame(width: 1)
                    }
                )
                .overlay(
                    // Selection indicator - only on sides
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(isSelected ? Color.green : Color.clear)
                            .frame(width: isSelected ? 3 : 0)
                        Spacer()
                        Rectangle()
                            .fill(isSelected ? Color.green : Color.clear)
                            .frame(width: isSelected ? 3 : 0)
                    }
                )
            
            // Content
            VStack(spacing: 4) {
                // X button
                HStack {
                    Spacer()
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(isPlaying ? .white.opacity(0.8) : .secondary.opacity(0.6))
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, 4)
                
                Spacer()
                
                // Chord symbol
                Text(chord.formattedSymbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isPlaying ? .white : .primary)
                
                Spacer()
            }
        }
        .frame(width: 60)
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
        .scaleEffect(x: isPlaying ? 1.05 : (isTapped ? 0.95 : 1.0))
        .opacity(isSelected ? 0.8 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isPlaying)
        .animation(.easeInOut(duration: 0.1), value: isTapped)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onTapGesture {
            // Play the chord when tapped (only if not selected)
            if !isSelected {
                // Set the visualized chord to highlight on piano
                theoryEngine.visualizedChord = chord
                
                // Also set as selected chord to update the display
                theoryEngine.selectedChord = chord
                
                // Play the chord
                audioEngine.playChord(chord, velocity: 60, duration: 0.8)
                
                withAnimation(.easeInOut(duration: 0.1)) {
                    isTapped = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isTapped = false
                    }
                }
                
                // Clear the visualized chord after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if theoryEngine.visualizedChord == chord {
                        withAnimation(.easeOut(duration: 0.3)) {
                            theoryEngine.visualizedChord = nil
                        }
                    }
                }
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            onLongPress()
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - Chord Timeline Item

struct ChordTimelineItem: View {
    let chord: Chord
    let index: Int
    let isPlaying: Bool
    let isSelected: Bool
    let onRemove: () -> Void
    let onLongPress: () -> Void
    
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(TheoryEngine.self) private var theoryEngine
    @State private var isTapped = false
    
    var body: some View {
        ZStack {
            // Center the chord symbol
            Text(chord.formattedSymbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isPlaying ? .white : .primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Position X button in top right
            VStack {
                HStack {
                    Spacer()
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(isPlaying ? .white.opacity(0.8) : .secondary)
                    }
                }
                Spacer()
            }
            .padding(6)
        }
        .frame(width: 60, height: 60)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isPlaying ? Color.appPrimary : (isTapped ? Color.appPrimary.opacity(0.8) : Color.appSecondaryBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isPlaying ? Color.clear : Color.appBorder, lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isSelected ? Color.green: Color.appBorder, lineWidth: isSelected ? 3 : 1)
                )
        )
        .scaleEffect(isPlaying ? 1.05 : (isTapped ? 0.95 : 1.0))
        .opacity(isSelected ? 0.8 : 1.0)  // Dim when selected
        .animation(.easeInOut(duration: 0.2), value: isPlaying)
        .animation(.easeInOut(duration: 0.1), value: isTapped)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onTapGesture {
            // Play the chord when tapped (only if not selected)
            if !isSelected {
                // Set the visualized chord to highlight on piano
                theoryEngine.visualizedChord = chord
                
                // Also set as selected chord to update the display
                theoryEngine.selectedChord = chord
                
                // Play the chord
                audioEngine.playChord(chord, velocity: 60, duration: 0.8)
                
                withAnimation(.easeInOut(duration: 0.1)) {
                    isTapped = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isTapped = false
                    }
                }
                
                // Clear the visualized chord after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if theoryEngine.visualizedChord == chord {
                        withAnimation(.easeOut(duration: 0.3)) {
                            theoryEngine.visualizedChord = nil
                        }
                    }
                }
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            onLongPress()
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - Preview

//#Preview("All Views") {
//    let theoryEngine = TheoryEngine()
//    
//    // Add some test chords
//    theoryEngine.addChordToProgression(Chord(.C, type: .major))
//    theoryEngine.addChordToProgression(Chord(.F, type: .major))
//    theoryEngine.addChordToProgression(Chord(.G, type: .major))
//    theoryEngine.addChordToProgression(Chord(.C, type: .major))
//    
//    return FloatingProgressionPlayer()
//        .environment(AudioEngine())
//        .environment(theoryEngine)
//}

#Preview("Intermediate View Mockup") {
    // Recreate just the intermediate view for preview purposes
    struct IntermediateViewMockup: View {
        @State private var theoryEngine = TheoryEngine()
        @State private var audioEngine = AudioEngine()
        @State private var isPlaying = false
        @State private var currentPlayIndex: Int? = nil
        @State private var selectedChordIndex: Int? = nil
        @State private var showArrows = false
        
        private var progression: [Chord] {
            theoryEngine.currentProgression.map { $0.chord }
        }
        
        var body: some View {
            ZStack {
                // Background to see the view better
                Color.gray.opacity(0.1)
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Text("Intermediate View Preview")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Recreated intermediate view
                    HStack(spacing: 0) {
                        // Play button - vertical rectangle
                        Button(action: { isPlaying.toggle() }) {
                            Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44)
                                .frame(maxHeight: .infinity)
                        }
                        .background(isPlaying ? Color.red : Color.appPrimary)
                        .cornerRadius(16, corners: [.topLeft, .bottomLeft])
                        
                        // Timeline
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                if progression.isEmpty {
                                    Text("Add chords below")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 40)
                                        .frame(minWidth: 200)
                                } else {
                                    ForEach(Array(progression.enumerated()), id: \.offset) { index, chord in
                                        MinimalChordTimelineItem(
                                            chord: chord,
                                            index: index,
                                            isPlaying: currentPlayIndex == index,
                                            isSelected: selectedChordIndex == index,
                                            onRemove: { 
                                                theoryEngine.removeFromProgression(at: index)
                                            },
                                            onLongPress: {
                                                selectedChordIndex = index
                                                showArrows = true
                                            }
                                        )
                                        .id(index)
                                    }
                                    
                                    // Spacer to ensure last chord is visible
                                    Color.clear
                                        .frame(width: 44, height: 1)
                                }
                            }
                            .padding(.horizontal, 12)
                        }
                        .background(Color.appTertiaryBackground.opacity(0.3))
                        
                        // Ellipsis menu
                        Menu {
                            Text("View Options")
                            Button("Minimized", action: {})
                            Button("Simple", action: {})
                            Button("Full", action: {})
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44)
                                .frame(maxHeight: .infinity)
                                .background(Color.gray.opacity(0.6))
                                .cornerRadius(16, corners: [.topRight, .bottomRight])
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appSecondaryBackground)
                            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                    )
                    .frame(maxWidth: UIScreen.main.bounds.width - 20)
                    .frame(height: 56)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Test controls
                    VStack(spacing: 16) {
                        Text("Test Controls")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            Button("Add Chord") {
                                let chords: [Chord] = [
                                    Chord(.D, type: .minor),
                                    Chord(.E, type: .minor),
                                    Chord(.A, type: .major),
                                    Chord(.B, type: .dim)
                                ]
                                if let randomChord = chords.randomElement() {
                                    theoryEngine.addChordToProgression(randomChord)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Clear All") {
                                theoryEngine.clearProgression()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Many Chords") {
                                theoryEngine.clearProgression()
                                // Add many chords to test scrolling
                                let progression: [Chord] = [
                                    Chord(.C, type: .major),
                                    Chord(.A, type: .minor),
                                    Chord(.F, type: .major),
                                    Chord(.G, type: .major),
                                    Chord(.E, type: .minor),
                                    Chord(.D, type: .minor),
                                    Chord(.G, type: .dom7),
                                    Chord(.C, type: .maj7)
                                ]
                                progression.forEach { chord in
                                    theoryEngine.addChordToProgression(chord)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                    .background(Color.appSecondaryBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .environment(theoryEngine)
            .environment(audioEngine)
            .onAppear {
                // Add initial test chords
                theoryEngine.addChordToProgression(Chord(.C, type: .major))
                theoryEngine.addChordToProgression(Chord(.A, type: .minor))
                theoryEngine.addChordToProgression(Chord(.F, type: .major))
                theoryEngine.addChordToProgression(Chord(.G, type: .major))
            }
        }
    }
    
    return IntermediateViewMockup()
}

#Preview("Minimal Chord Item") {
    HStack(spacing: 0) {
        MinimalChordTimelineItem(
            chord: Chord(.C, type: .major),
            index: 0,
            isPlaying: false,
            isSelected: false,
            onRemove: { print("Remove") },
            onLongPress: { print("Long press") }
        )
        
        MinimalChordTimelineItem(
            chord: Chord(.F, type: .major),
            index: 1,
            isPlaying: true,
            isSelected: false,
            onRemove: { print("Remove") },
            onLongPress: { print("Long press") }
        )
        
        MinimalChordTimelineItem(
            chord: Chord(.G, type: .dom7),
            index: 2,
            isPlaying: false,
            isSelected: true,
            onRemove: { print("Remove") },
            onLongPress: { print("Long press") }
        )
    }
    .frame(height: 60)
    .background(Color.appTertiaryBackground.opacity(0.3))
    .padding()
    .environment(TheoryEngine())
    .environment(AudioEngine())
}
