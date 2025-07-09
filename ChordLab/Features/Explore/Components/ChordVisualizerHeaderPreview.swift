//
//  ChordVisualizerHeaderPreview.swift
//  ChordLab
//
//  Preview showing improved layout for chord visualizer header
//

import SwiftUI

struct ChordVisualizerHeaderPreview: View {
    @State private var selectedKey = "C"
    @State private var selectedChordType: ChordTypeSelector.ChordType = .triads
    
    var body: some View {
        VStack(spacing: 0) {
            // Header section with key and chord type selection
            VStack(spacing: 12) {
                // Key selector on its own line
                KeySelector(selectedKey: $selectedKey)
                
                // Chord type picker and color legend on same line
                HStack {
                    CompactChordTypePicker(selectedChordType: $selectedChordType)
                    
                    Spacer()
                    
                    CompactColorLegend(showSeventh: selectedChordType == .sevenths)
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 12)
            .background(Color.appBackground)
            
            Divider()
            
            // Rest of the content would go here
            VStack {
                Text("Piano visualization and chord grid would appear here")
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
            }
            .frame(maxHeight: .infinity)
            .background(Color.appSecondaryBackground.opacity(0.3))
        }
    }
}

// Alternative layout with everything on one line
struct CompactChordVisualizerHeader: View {
    @State private var selectedKey = "C"
    @State private var selectedChordType: ChordTypeSelector.ChordType = .triads
    
    var body: some View {
        VStack(spacing: 0) {
            // Single line header
            HStack(spacing: 16) {
                // Key label
                Text("Key")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Compact key buttons (smaller)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(["C", "D", "E", "F", "G", "A", "B"], id: \.self) { key in
                            Button(action: { selectedKey = key }) {
                                Text(key)
                                    .font(.system(size: 16, weight: selectedKey == key ? .semibold : .regular))
                                    .foregroundColor(selectedKey == key ? .white : .primary)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedKey == key ? Color.appPrimary : Color.appSecondaryBackground)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(
                                                selectedKey == key ? Color.clear : Color.gray.opacity(0.3),
                                                lineWidth: 1
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxWidth: 280)
                
                Divider()
                    .frame(height: 20)
                
                // Chord type
                CompactChordTypePicker(selectedChordType: $selectedChordType)
                
                Spacer()
                
                // Color legend
                CompactColorLegend(showSeventh: selectedChordType == .sevenths)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.appBackground)
            
            Divider()
            
            // Content area
            VStack {
                Text("Content area")
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            }
            .frame(maxHeight: .infinity)
            .background(Color.appSecondaryBackground.opacity(0.3))
        }
    }
}

#Preview("Two Line Layout") {
    ChordVisualizerHeaderPreview()
        .frame(maxHeight: 400)
}

#Preview("Single Line Compact") {
    CompactChordVisualizerHeader()
        .frame(maxHeight: 400)
}