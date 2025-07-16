//
//  StudioEngine.swift
//  ChordLab
//
//  Engine for Studio DAW playback and sequencing
//

import Foundation
import SwiftUI
import Tonic

@Observable
class StudioEngine {
    private let audioEngine: AudioEngine
    private var playbackTimer: Timer?
    
    // Playback state
    var isPlaying = false
    var currentBeat = 0
    var tempo = 120
    
    // Look-ahead scheduling
    private var audioBeat = 0  // Beat position for audio (ahead of visual)
    private let lookAheadBeats = 3  // Play audio 3 beats ahead of visual
    
    // Session reference
    weak var session: StudioSession?
    
    init(audioEngine: AudioEngine) {
        self.audioEngine = audioEngine
    }
    
    // MARK: - Playback Control
    
    func play() {
        guard let session = session else { return }
        
        isPlaying = true
        session.isPlaying = true  // Sync with session
        currentBeat = 0
        audioBeat = lookAheadBeats  // Start audio ahead
        
        // Calculate beat duration (assuming 16th note grid)
        let beatDuration = 60.0 / Double(tempo) / 4.0
        
        // Pre-play the first few beats of audio
        for i in 0..<lookAheadBeats {
            playAudioAtBeat(i)
        }
        
        // Start playback timer
        playbackTimer = Timer.scheduledTimer(withTimeInterval: beatDuration, repeats: true) { [weak self] _ in
            self?.tickBeat()
        }
    }
    
    func stop() {
        isPlaying = false
        session?.isPlaying = false  // Sync with session
        playbackTimer?.invalidate()
        playbackTimer = nil
        currentBeat = 0
        audioBeat = 0
        session?.currentBeat = 0
    }
    
    func pause() {
        isPlaying = false
        session?.isPlaying = false  // Sync with session
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func tickBeat() {
        guard let session = session else { return }
        
        // Update visual position
        currentBeat += 1
        if currentBeat >= session.totalBeats {
            currentBeat = 0
        }
        session.currentBeat = currentBeat
        
        // Play audio for the beat that's lookAheadBeats ahead
        playAudioAtBeat(audioBeat)
        
        // Advance audio beat
        audioBeat += 1
        if audioBeat >= session.totalBeats {
            audioBeat = 0
        }
    }
    
    private func playAudioAtBeat(_ beat: Int) {
        guard let session = session else { return }
        
        // Play content from all unmuted tracks at the specified beat
        for track in session.tracks {
            guard !track.isMuted else { continue }
            
            // Check if this track is solo'd or no tracks are solo'd
            let hasSoloTracks = session.tracks.contains { $0.isSolo }
            if hasSoloTracks && !track.isSolo { continue }
            
            // Play content at the specified beat
            if let content = track.contentAt(beat: beat) {
                playContent(content, volume: track.volume)
            }
        }
    }
    
    private func playContent(_ content: MusicalContent, volume: Double) {
        let velocity = UInt8(volume * 127)
        
        switch content {
        case .chord(let chord, _):
            audioEngine.playChord(chord, velocity: UInt8(Int(velocity)), duration: 0.8)
            
        case .note(let note, let duration, _):
            audioEngine.playNote(note, velocity: UInt8(Int(velocity)))
            // TODO: Handle note duration properly
            
        case .drumHit(let drumType, _):
            // TODO: Implement drum sounds
            playDrumSound(drumType, velocity: Int(velocity))
        }
    }
    
    private func playDrumSound(_ drumType: DrumType, velocity: Int) {
        // Placeholder - use different notes to simulate drum sounds
        switch drumType {
        case .kick:
            audioEngine.playNote(Note(.C, octave: 1), velocity: UInt8(velocity))
        case .snare:
            audioEngine.playNote(Note(.D, octave: 2), velocity: UInt8(velocity))
        case .hihat:
            audioEngine.playNote(Note(.F, accidental: .sharp, octave: 3), velocity: UInt8(velocity))
        case .crash:
            audioEngine.playNote(Note(.A, octave: 4), velocity: UInt8(velocity))
        }
    }
    
    // MARK: - Single Track Playback
    
    func playTrack(trackId: UUID) {
        guard let session = session,
              let track = session.tracks.first(where: { $0.id == trackId }) else { return }
        
        stop() // Stop any current playback
        
        isPlaying = true
        session.isPlaying = true
        currentBeat = 0
        audioBeat = lookAheadBeats
        
        // Calculate beat duration
        let beatDuration = 60.0 / Double(tempo) / 4.0
        
        // Pre-play audio for look-ahead beats
        for i in 0..<lookAheadBeats {
            if let content = track.contentAt(beat: i) {
                playContent(content, volume: track.volume)
            }
        }
        
        // Start playback timer for single track
        playbackTimer = Timer.scheduledTimer(withTimeInterval: beatDuration, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Update visual
            self.currentBeat += 1
            if self.currentBeat >= session.totalBeats {
                self.currentBeat = 0
            }
            session.currentBeat = self.currentBeat
            
            // Play audio ahead
            if let content = track.contentAt(beat: self.audioBeat) {
                self.playContent(content, volume: track.volume)
            }
            
            // Advance audio beat
            self.audioBeat += 1
            if self.audioBeat >= session.totalBeats {
                self.audioBeat = 0
            }
        }
    }
    
    // MARK: - Tempo Control
    
    func setTempo(_ newTempo: Int) {
        tempo = newTempo
        
        // If playing, restart with new tempo
        if isPlaying {
            pause()
            play()
        }
    }
}
