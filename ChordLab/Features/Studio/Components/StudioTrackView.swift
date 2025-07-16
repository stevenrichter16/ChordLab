//
//  StudioTrackView.swift
//  ChordLab
//
//  Individual track view with drag and drop support
//

import SwiftUI
import Tonic

extension Notification.Name {
    static let playTrack = Notification.Name("playTrack")
}

struct StudioTrackView: View {
    @Bindable var track: Track
    let totalBeats: Int
    let currentBeat: Int
    let isSelected: Bool
    let onSelect: () -> Void
    @Binding var selectedBeat: Int?
    
    private let beatWidth: CGFloat = 40
    private let trackHeight: CGFloat = 60
    
    var body: some View {
        HStack(spacing: 0) {
            // Track header
            TrackHeader(
                track: track,
                isSelected: isSelected,
                onSelect: onSelect
            )
            .frame(width: 60)
            
            // Track content grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(0..<totalBeats, id: \.self) { beat in
                        BeatCell(
                            beat: beat,
                            content: track.contentAt(beat: beat),
                            isCurrentBeat: beat == currentBeat,
                            isSelectedBeat: isSelected && selectedBeat == beat,
                            trackType: track.type,
                            onDrop: { content in
                                track.setContent(content, at: beat)
                            },
                            onRemove: {
                                track.removeContent(at: beat)
                            },
                            onTap: {
                                // Select this track and beat
                                onSelect()
                                selectedBeat = beat
                            }
                        )
                        .frame(width: beatWidth, height: trackHeight)
                    }
                }
            }
        }
        .background(isSelected ? Color.appPrimary.opacity(0.1) : Color.clear)
        .overlay(
            Rectangle()
                .strokeBorder(isSelected ? Color.appPrimary : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Track Header

struct TrackHeader: View {
    @Bindable var track: Track
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Track icon
            Image(systemName: track.type.icon)
                .font(.title2)
                .foregroundColor(track.type.color)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onTapGesture(count: 2) {
            // Double tap to play just this track
            // This will be implemented in StudioTabView
            NotificationCenter.default.post(name: .playTrack, object: track.id)
        }
    }
}

// MARK: - Beat Cell

struct BeatCell: View {
    let beat: Int
    let content: MusicalContent?
    let isCurrentBeat: Bool
    let isSelectedBeat: Bool
    let trackType: TrackType
    let onDrop: (MusicalContent) -> Void
    let onRemove: () -> Void
    let onTap: () -> Void
    
    @State private var isTargeted = false
    
    @ViewBuilder
    var body: some View {
        let baseView = ZStack {
            // Background
            Rectangle()
                .fill(backgroundColor)
                .overlay(
                    Rectangle()
                        .strokeBorder(borderColor, lineWidth: isSelectedBeat ? 3 : (isTargeted ? 2 : 1))
                )
            
            // Content
            if let content = content {
                TrackContentView(content: content, trackType: trackType)
                    .onTapGesture(count: 2) {
                        onRemove()
                    }
            }
            
            // Drop indicator
            if isTargeted && content == nil {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.appPrimary)
                    .font(.title3)
                    .opacity(0.8)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        
        // Apply appropriate drop destination based on track type
        if trackType == .chords {
            baseView
                .dropDestination(for: DraggableChord.self) { items, _ in
                    guard let draggableChord = items.first,
                          let chord = draggableChord.chord else { return false }
                    
                    onDrop(.chord(chord))
                    return true
                } isTargeted: { isTargeted in
                    self.isTargeted = isTargeted
                }
        } else if trackType == .melody {
            baseView
                .dropDestination(for: DraggableNote.self) { items, _ in
                    guard let draggableNote = items.first else { return false }
                    
                    onDrop(.note(draggableNote.note, duration: draggableNote.duration))
                    return true
                } isTargeted: { isTargeted in
                    self.isTargeted = isTargeted
                }
        } else {
            baseView
        }
    }
    
    private var backgroundColor: Color {
        if isCurrentBeat {
            return Color.appPrimary.opacity(0.2)
        } else if beat % 4 == 0 {
            return Color.appSecondaryBackground
        } else {
            return Color.appSecondaryBackground.opacity(0.5)
        }
    }
    
    private var borderColor: Color {
        if isSelectedBeat {
            return Color.appPrimary
        } else if isTargeted {
            return Color.appPrimary.opacity(0.6)
        } else if beat % 4 == 0 {
            return Color.appBorder
        } else {
            return Color.appBorder.opacity(0.5)
        }
    }
}

// MARK: - Track Content View

struct TrackContentView: View {
    let content: MusicalContent
    let trackType: TrackType
    
    var body: some View {
        switch content {
        case .chord(let chord, _):
            ChordContentView(chord: chord)
        case .note(let note, let duration, _):
            NoteContentView(note: note, duration: duration)
        case .drumHit(let drumType, _):
            DrumContentView(drumType: drumType)
        }
    }
}

struct ChordContentView: View {
    let chord: Chord
    
    var body: some View {
        Text(chord.description)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color.blue)
            .cornerRadius(4)
    }
}

struct NoteContentView: View {
    let note: Note
    let duration: Duration
    
    var body: some View {
        VStack(spacing: 2) {
            Text(note.noteClass.description + "\(note.octave)")
                .font(.caption2)
                .fontWeight(.medium)
            Text(duration.symbol)
                .font(.caption)
        }
        .foregroundColor(.white)
        .padding(4)
        .background(Color.green)
        .cornerRadius(4)
    }
}

struct DrumContentView: View {
    let drumType: DrumType
    
    var body: some View {
        Image(systemName: drumType.icon)
            .font(.title3)
            .foregroundColor(.white)
            .frame(width: 30, height: 30)
            .background(Color.orange)
            .clipShape(Circle())
    }
}

// MARK: - Track Content (without ScrollView)

struct StudioTrackContent: View {
    @Bindable var track: Track
    let totalBeats: Int
    let currentBeat: Int
    let isSelected: Bool
    @Binding var selectedBeat: Int?
    let onSelect: () -> Void
    
    private let beatWidth: CGFloat = 40
    private let trackHeight: CGFloat = 60
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<totalBeats, id: \.self) { beat in
                BeatCell(
                    beat: beat,
                    content: track.contentAt(beat: beat),
                    isCurrentBeat: beat == currentBeat,
                    isSelectedBeat: isSelected && selectedBeat == beat,
                    trackType: track.type,
                    onDrop: { content in
                        track.setContent(content, at: beat)
                    },
                    onRemove: {
                        track.removeContent(at: beat)
                    },
                    onTap: {
                        // Select this track and beat
                        onSelect()
                        selectedBeat = beat
                    }
                )
                .frame(width: beatWidth, height: trackHeight)
            }
        }
        .frame(height: trackHeight)
    }
}

// MARK: - Add Track Button

struct AddTrackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Track")
            }
            .foregroundColor(.appPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.appSecondaryBackground.opacity(0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundColor(.appPrimary)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}
