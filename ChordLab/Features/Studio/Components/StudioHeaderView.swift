//
//  StudioHeaderView.swift
//  ChordLab
//
//  Transport controls and header for Studio
//

import SwiftUI

struct StudioHeaderView: View {
    @Binding var isPlaying: Bool
    @Binding var tempo: Int
    let currentBeat: Int
    let onPlay: () -> Void
    let onStop: () -> Void
    let onClear: () -> Void
    
    var body: some View {
        HStack(spacing: 5) {
            // Title
            Text("Studio")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            // Transport controls
            HStack(spacing: 12) {
                // Play/Stop button
                Button(action: {
                    if isPlaying {
                        onStop()
                    } else {
                        onPlay()
                    }
                }) {
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(isPlaying ? Color.red : Color.appPrimary)
                        .clipShape(Circle())
                }
                
                // Beat indicator
                VStack(spacing: 4) {
                    Text("Beat")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(currentBeat + 1)")
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.medium)
                }
                .frame(width: 60)
                
                Divider()
                    .frame(height: 30)
                
                // Tempo control
                HStack(spacing: 4) {
                    Image(systemName: "metronome")
                        .foregroundColor(.secondary)
                    
                    Text("\(tempo)")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 40)
                    
                    Stepper("", value: $tempo, in: 60...200, step: 5)
                        .labelsHidden()
                }
                
                Divider()
                    .frame(height: 30)
                
                // Clear button
                Button(action: onClear) {
                    Label("Clear", systemImage: "trash")
                        .foregroundColor(.red)
                }
                .frame(width: 40, height: 40)
                .buttonStyle(.bordered)
            }
        }
        .frame(height: 50)
        .padding()
    }
}

// MARK: - Preview

#Preview {
    StudioHeaderView(
        isPlaying: .constant(false),
        tempo: .constant(120),
        currentBeat: 0,
        onPlay: {},
        onStop: {},
        onClear: {}
    )
    .background(Color.appBackground)
}
