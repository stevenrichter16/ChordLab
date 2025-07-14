//
//  KeySelector.swift
//  ChordLab
//
//  Key selection component for Piano Chord Visualizer
//

import SwiftUI
import Tonic

struct KeySelector: View {
    @Binding var selectedKey: String
    let keysContainingChord: Set<NoteClass>
    
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
                            isHighlighted: keysContainingChord.contains(NoteClass(key) ?? .C),
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
    let isHighlighted: Bool
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
                            isHighlighted ? Color.blue : (isSelected ? Color.clear : Color.gray.opacity(0.3)),
                            lineWidth: isHighlighted ? 2 : 1
                        )
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isHighlighted)
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
                KeySelector(selectedKey: .constant("C"), keysContainingChord: [])
            }
            
            // Selected different key
            VStack(alignment: .leading) {
                Text("Selected: G")
                    .font(.caption)
                    .foregroundColor(.secondary)
                KeySelector(selectedKey: .constant("G"), keysContainingChord: [])
            }
            
            // With highlighted keys (C major chord appears in C, F, G)
            VStack(alignment: .leading) {
                Text("C major chord - Keys highlighted: C, F, G")
                    .font(.caption)
                    .foregroundColor(.secondary)
                KeySelector(selectedKey: .constant("C"), keysContainingChord: [.C, .F, .G])
            }
        }
        .padding()
        
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.appBackground)
}
