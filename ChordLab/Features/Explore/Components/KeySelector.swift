//
//  KeySelector.swift
//  ChordLab
//
//  Key selection component for Piano Chord Visualizer
//

import SwiftUI

struct KeySelector: View {
    @Binding var selectedKey: String
    
    // White keys only for initial implementation
    private let keys = ["C", "D", "E", "F", "G", "A", "B"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Key")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(keys, id: \.self) { key in
                        PianoKeyButton(
                            key: key,
                            isSelected: selectedKey == key,
                            action: {
                                selectedKey = key
                            }
                        )
                        .accessibilityIdentifier("key-\(key)")
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct PianoKeyButton: View {
    let key: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(key)
                .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.appPrimary : Color.appSecondaryBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isSelected ? Color.clear : Color.gray.opacity(0.3),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        Text("KeySelector Preview")
            .font(.title2)
            .fontWeight(.bold)
        
        VStack(alignment: .leading, spacing: 20) {
            // Default size
            VStack(alignment: .leading) {
                Text("Default Size (50x50)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                KeySelector(selectedKey: .constant("C"))
            }
            
            // Selected different key
            VStack(alignment: .leading) {
                Text("Selected: G")
                    .font(.caption)
                    .foregroundColor(.secondary)
                KeySelector(selectedKey: .constant("G"))
            }
            
            // Selected B (end of scroll)
            VStack(alignment: .leading) {
                Text("Selected: B (should be fully visible)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                KeySelector(selectedKey: .constant("B"))
            }
        }
        .padding()
        
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.appBackground)
}
