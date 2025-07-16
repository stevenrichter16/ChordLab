//
//  TimelineRuler.swift
//  ChordLab
//
//  Timeline ruler showing measures and beats
//

import SwiftUI

struct TimelineRuler: View {
    let totalBeats: Int
    let currentBeat: Int
    let beatsPerMeasure: Int
    
    private let beatWidth: CGFloat = 40
    
    var body: some View {
        HStack(spacing: 0) {
            // Track header spacer
            Color.clear
                .frame(width: 120)
            
            // Ruler
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(0..<totalBeats, id: \.self) { beat in
                        VStack(spacing: 0) {
                            // Measure number at start of each measure
                            if beat % 4 == 0 {
                                Text("\(beat / 4 + 1)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("")
                                    .font(.caption2)
                            }
                            
                            // Beat tick
                            Rectangle()
                                .fill(beat % 4 == 0 ? Color.primary : Color.secondary)
                                .frame(width: 1, height: beat % 4 == 0 ? 10 : 6)
                            
                            Spacer()
                        }
                        .frame(width: beatWidth)
                        .background(beat == currentBeat ? Color.appPrimary.opacity(0.3) : Color.clear)
                    }
                }
            }
        }
    }
}

// Timeline ruler content without ScrollView for synchronized scrolling
struct TimelineRulerContent: View {
    let totalBeats: Int
    let currentBeat: Int
    let beatsPerMeasure: Int
    
    private let beatWidth: CGFloat = 40
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<totalBeats, id: \.self) { beat in
                VStack(spacing: 0) {
                    // Measure number at start of each measure
                    if beat % 4 == 0 {
                        Text("\(beat / 4 + 1)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("")
                            .font(.caption2)
                    }
                    
                    // Beat tick
                    Rectangle()
                        .fill(beat % 4 == 0 ? Color.primary : Color.secondary)
                        .frame(width: 1, height: beat % 4 == 0 ? 10 : 6)
                    
                    Spacer()
                }
                .frame(width: beatWidth)
                .background(beat == currentBeat ? Color.appPrimary.opacity(0.3) : Color.clear)
            }
        }
        .frame(height: 30)
    }
}

// MARK: - Preview

#Preview {
    TimelineRuler(
        totalBeats: 32,
        currentBeat: 5,
        beatsPerMeasure: 16
    )
    .frame(height: 30)
    .background(Color.appSecondaryBackground)
}