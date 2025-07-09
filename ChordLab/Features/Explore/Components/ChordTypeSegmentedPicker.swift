//
//  ChordTypeSegmentedPicker.swift
//  ChordLab
//
//  Segmented picker for chord types with room for expansion
//

import SwiftUI

struct ChordTypeSegmentedPicker: View {
    @Binding var selectedChordType: ChordTypeSelector.ChordType
    
    // Future expansion: add .ninths, .thirteenths
    let availableTypes: [(ChordTypeSelector.ChordType, String)] = [
        (.triads, "Triads"),
        (.sevenths, "7ths")
        // Future: (.ninths, "9ths"), (.thirteenths, "13ths")
    ]
    
    var body: some View {
        Picker("Chord Type", selection: $selectedChordType) {
            ForEach(availableTypes, id: \.0) { type, label in
                Text(label).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 200)
    }
}

// Compact version with just symbols
struct CompactChordTypePicker: View {
    @Binding var selectedChordType: ChordTypeSelector.ChordType
    
    let compactLabels: [(ChordTypeSelector.ChordType, String)] = [
        (.triads, "III"),
        (.sevenths, "7")
        // Future: (.ninths, "9"), (.thirteenths, "13")
    ]
    
    var body: some View {
        Picker("", selection: $selectedChordType) {
            ForEach(compactLabels, id: \.0) { type, label in
                Text(label)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .tag(type)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 100)
    }
}

// MARK: - Compact Color Legend

struct CompactColorLegend: View {
    let showSeventh: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            LegendDot(color: .blue, label: "Root")
            LegendDot(color: .green, label: "3rd")
            LegendDot(color: .orange, label: "5th")
            if showSeventh {
                LegendDot(color: .purple, label: "7th")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.appSecondaryBackground.opacity(0.8))
        .cornerRadius(8)
    }
}

struct LegendDot: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        Text("Chord Type Selectors")
            .font(.title2)
            .fontWeight(.bold)
        
        VStack(alignment: .leading, spacing: 20) {
            // Standard segmented picker
            VStack(alignment: .leading) {
                Text("Standard Segmented Picker")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ChordTypeSegmentedPicker(selectedChordType: .constant(.triads))
            }
            
            // Compact version
            VStack(alignment: .leading) {
                Text("Compact Segmented Picker")
                    .font(.caption)
                    .foregroundColor(.secondary)
                CompactChordTypePicker(selectedChordType: .constant(.sevenths))
            }
            
            Divider()
            
            // Color legends
            VStack(alignment: .leading, spacing: 15) {
                Text("Compact Color Legends")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                CompactColorLegend(showSeventh: false)
                CompactColorLegend(showSeventh: true)
            }
        }
        .padding()
        
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.appBackground)
}
