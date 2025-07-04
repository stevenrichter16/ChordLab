//
//  MinimalistChordToggle.swift
//  ChordLab
//
//  Ultra-compact chord type selector
//

import SwiftUI

struct MinimalistChordToggle: View {
    @Binding var selectedChordType: ChordTypeSelector.ChordType
    
    var body: some View {
        HStack(spacing: 0) {
            // III side
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedChordType = .triads
                }
            }) {
                Text("III")
                    .font(.system(size: 14, weight: selectedChordType == .triads ? .bold : .regular, design: .rounded))
                    .foregroundColor(selectedChordType == .triads ? .white : .secondary)
                    .frame(width: 28)
                    .padding(.vertical, 6)
                    .background(
                        selectedChordType == .triads ? Color.appPrimary : Color.clear
                    )
            }
            .buttonStyle(.plain)
            
            // Divider
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 1)
                .padding(.vertical, 4)
            
            // 7 side
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedChordType = .sevenths
                }
            }) {
                Text("7")
                    .font(.system(size: 14, weight: selectedChordType == .sevenths ? .bold : .regular, design: .rounded))
                    .foregroundColor(selectedChordType == .sevenths ? .white : .secondary)
                    .frame(width: 28)
                    .padding(.vertical, 6)
                    .background(
                        selectedChordType == .sevenths ? Color.appPrimary : Color.clear
                    )
            }
            .buttonStyle(.plain)
        }
        .background(Color.appSecondaryBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.appBorder, lineWidth: 1)
        )
    }
}

// Alternative even more minimal design
struct UltraMinimalChordToggle: View {
    @Binding var selectedChordType: ChordTypeSelector.ChordType
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedChordType = selectedChordType == .triads ? .sevenths : .triads
            }
        }) {
            HStack(spacing: 2) {
                Text(selectedChordType == .triads ? "III" : "7")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.appSecondaryBackground)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.appBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        MinimalistChordToggle(selectedChordType: .constant(.triads))
        MinimalistChordToggle(selectedChordType: .constant(.sevenths))
        
        Divider()
        
        UltraMinimalChordToggle(selectedChordType: .constant(.triads))
        UltraMinimalChordToggle(selectedChordType: .constant(.sevenths))
    }
    .padding()
    .background(Color.appBackground)
}