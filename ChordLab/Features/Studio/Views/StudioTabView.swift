//
//  StudioTabView.swift
//  ChordLab
//
//  Main view for the Studio DAW tab
//

import SwiftUI
import Tonic

struct StudioTabView: View {
    @State private var studioSession = StudioSession()
    @State private var studioEngine: StudioEngine?
    @State private var selectedDuration: Duration = .quarter
    @State private var showingTrackTypeSelection = false
    @State private var verticalScrollOffset: CGFloat = 0
    
    @Environment(TheoryEngine.self) private var theoryEngine
    @Environment(AudioEngine.self) private var audioEngine
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with transport controls
            StudioHeaderView(
                isPlaying: $studioSession.isPlaying,
                tempo: $studioSession.tempo,
                currentBeat: studioSession.currentBeat,
                onPlay: startPlayback,
                onStop: stopPlayback,
                onClear: clearAll
            )
            .background(Color.appBackground)
            
            Divider()
            
            // Tracks area with synchronized scrolling
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 2) {
                    // Timeline and tracks container
                    HStack(spacing: 0) {
                        // Fixed headers column
                        VStack(spacing: 0) {
                            // Timeline header spacer
                            Color.clear
                                .frame(width: 60, height: 30)
                                .background(Color.appSecondaryBackground)
                            
                            // Track headers
                            VStack(spacing: 2) {
                                ForEach(studioSession.tracks) { track in
                                    TrackHeader(
                                        track: track,
                                        isSelected: track.id == studioSession.selectedTrackId,
                                        onSelect: { studioSession.selectedTrackId = track.id }
                                    )
                                    .frame(width: 60, height: 60)
                                    .background(track.id == studioSession.selectedTrackId ? Color.appPrimary.opacity(0.1) : Color.clear)
                                }
                            }
                        }
                        
                        // Horizontally scrollable content (timeline + track beats)
                        ScrollView(.horizontal, showsIndicators: true) {
                            VStack(spacing: 0) {
                                // Timeline ruler
                                TimelineRulerContent(
                                    totalBeats: studioSession.totalBeats,
                                    currentBeat: studioSession.currentBeat,
                                    beatsPerMeasure: studioSession.beatsPerMeasure
                                )
                                .background(Color.appSecondaryBackground)
                                
                                // Track content
                                VStack(spacing: 2) {
                                    ForEach(studioSession.tracks) { track in
                                        StudioTrackContent(
                                            track: track,
                                            totalBeats: studioSession.totalBeats,
                                            currentBeat: studioSession.currentBeat,
                                            isSelected: track.id == studioSession.selectedTrackId,
                                            selectedBeat: $studioSession.selectedBeat,
                                            onSelect: { studioSession.selectedTrackId = track.id }
                                        )
                                        .background(track.id == studioSession.selectedTrackId ? Color.appPrimary.opacity(0.1) : Color.clear)
                                        .overlay(
                                            Rectangle()
                                                .strokeBorder(track.id == studioSession.selectedTrackId ? Color.appPrimary : Color.clear, lineWidth: 2)
                                        )
                                    }
                                }
                            }
                        }
                    }
                    
                    // Add track button
                    AddTrackButton {
                        showingTrackTypeSelection = true
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }
            .background(Color.appBackground.opacity(0.5))
            
            Divider()
            
            // Bottom panel - Chord/Note palette based on selected track
            if let selectedTrack = studioSession.tracks.first(where: { $0.id == studioSession.selectedTrackId }) {
                StudioBottomPanel(
                    trackType: selectedTrack.type,
                    selectedDuration: $selectedDuration,
                    studioSession: studioSession,
                    selectedTrack: selectedTrack
                )
                .frame(height: 150)
                .background(Color.appSecondaryBackground)
            }
        }
        .ignoresSafeArea(.keyboard) // Ignore keyboard safe area
        .safeAreaInset(edge: .bottom) {
            // Add space for tab bar
            Color.clear.frame(height: 100) // Standard tab bar height
        }
        .onAppear {
            // Initialize studio engine
            let engine = StudioEngine(audioEngine: audioEngine)
            engine.session = studioSession
            self.studioEngine = engine
            
            // Select first track by default
            if let firstTrack = studioSession.tracks.first {
                studioSession.selectedTrackId = firstTrack.id
            }
            
            // Listen for track play notifications
            NotificationCenter.default.addObserver(
                forName: .playTrack,
                object: nil,
                queue: .main
            ) { notification in
                if let trackId = notification.object as? UUID {
                    playTrack(trackId: trackId)
                }
            }
        }
        .onDisappear {
            stopPlayback()
        }
        .confirmationDialog("Choose Track Type", isPresented: $showingTrackTypeSelection) {
            Button("Chord Track") {
                studioSession.addTrack(
                    name: "Chords \(studioSession.tracks.filter { $0.type == .chords }.count + 1)",
                    type: .chords
                )
            }
            Button("Melody Track") {
                studioSession.addTrack(
                    name: "Melody \(studioSession.tracks.filter { $0.type == .melody }.count + 1)",
                    type: .melody
                )
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("What type of track would you like to add?")
        }
    }
    
    // MARK: - Playback Control
    
    private func startPlayback() {
        studioEngine?.tempo = studioSession.tempo
        studioEngine?.play()
        // Note: isPlaying state is now synchronized in StudioEngine
    }
    
    private func stopPlayback() {
        studioEngine?.stop()
        // Note: isPlaying state is now synchronized in StudioEngine
    }
    
    private func clearAll() {
        studioSession.clearAll()
    }
    
    private func playTrack(trackId: UUID) {
        studioEngine?.playTrack(trackId: trackId)
    }
}
