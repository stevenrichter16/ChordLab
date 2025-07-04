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
                .frame(width: 50, height: 50)
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

//#Preview {
//    VStack {
//        KeySelector(selectedKey: .constant("C"))
//            .padding()
//        
//        KeySelector(selectedKey: .constant("G"))
//            .padding()
//    }
//    .background(Color.appBac
