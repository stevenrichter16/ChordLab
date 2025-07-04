//
//  ChordTypeSelector.swift
//  ChordLab
//
//  Selector for switching between triads and 7th chords
//

import SwiftUI

struct ChordTypeSelector: View {
    @Binding var selectedChordType: ChordType
    
    enum ChordType: String, CaseIterable {
        case triads = "Triads"
        case sevenths = "7ths"
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(ChordType.allCases, id: \.self) { type in
                ChordTypeButton(
                    title: type.rawValue,
                    isSelected: selectedChordType == type,
                    action: { selectedChordType = type }
                )
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(Color.appSecondaryBackground)
        .cornerRadius(10)
    }
}

struct ChordTypeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.appPrimary : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ChordTypeSelector(selectedChordType: .constant(.triads))
        ChordTypeSelector(selectedChordType: .constant(.sevenths))
    }
    .padding()
    .background(Color.appBackground)
}