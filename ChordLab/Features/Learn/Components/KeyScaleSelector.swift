//
//  KeyScaleSelector.swift
//  ChordLab
//
//  Horizontal pill selector for key and scale selection
//

import SwiftUI
import Tonic

struct KeyScaleSelector: View {
    @Environment(TheoryEngine.self) private var theoryEngine
    @Environment(DataManager.self) private var dataManager
    
    
    // All available keys
    private let allKeys = [
        "C", "C♯", "D♭", "D", "D♯", "E♭", "E", "F",
        "F♯", "G♭", "G", "G♯", "A♭", "A", "A♯", "B♭", "B"
    ]
    
    // Display keys (avoiding duplicate enharmonics for UI)
    private let displayKeys = [
        "C", "C♯/D♭", "D", "D♯/E♭", "E", "F",
        "F♯/G♭", "G", "G♯/A♭", "A", "A♯/B♭", "B"
    ]
    
    // Available scale types
    private let scaleTypes = ["major", "minor"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Key selector
            VStack(alignment: .leading, spacing: 4) {
                Text("Key")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(displayKeys, id: \.self) { keyLabel in
                            KeyPillButton(
                                label: keyLabel,
                                isSelected: isKeySelected(keyLabel),
                                action: {
                                    selectKey(from: keyLabel)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
            }
            
            // Scale type selector
            VStack(alignment: .leading, spacing: 4) {
                Text("Scale")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                HStack(spacing: 8) {
                    ForEach(scaleTypes, id: \.self) { scaleType in
                        ScalePillButton(
                            label: scaleType.capitalized,
                            isSelected: theoryEngine.currentScaleType == scaleType,
                            action: {
                                selectScale(scaleType)
                            }
                        )
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func isKeySelected(_ keyLabel: String) -> Bool {
        if keyLabel.contains("/") {
            // Handle enharmonic display
            let parts = keyLabel.split(separator: "/").map(String.init)
            return parts.contains(theoryEngine.currentKey)
        }
        return theoryEngine.currentKey == keyLabel
    }
    
    private func selectKey(from keyLabel: String) {
        print("Key selected: \(keyLabel)")
        print("Current scale: \(theoryEngine.currentScaleType)")
        let key: String
        if keyLabel.contains("/") {
            // For enharmonics, prefer sharps by default
            key = String(keyLabel.split(separator: "/")[0])
        } else {
            key = keyLabel
        }
        
        // Update engine
        theoryEngine.setKey(key, scaleType: theoryEngine.currentScaleType)
        
        // Persist change
        Task {
            do {
                try dataManager.updateUserData { userData in
                    userData.currentKey = key
                }
            } catch {
                print("Failed to save key selection: \(error)")
            }
        }
    }
    
    private func selectScale(_ scaleType: String) {
        // Update engine
        print("in select scale: \(scaleType)")
        print("in select sclae current key: \(theoryEngine.currentKey)")
        theoryEngine.setKey(theoryEngine.currentKey, scaleType: scaleType)
        
        // Persist change
        Task {
            do {
                try dataManager.updateUserData { userData in
                    userData.currentScale = scaleType
                }
            } catch {
                print("Failed to save scale selection: \(error)")
            }
        }
    }
}

// MARK: - Key Pill Button

struct KeyPillButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(.body, design: .rounded))
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.appPrimary : Color.appSecondaryBackground)
                )
                .foregroundColor(isSelected ? .white : .primary)
                .overlay(
                    Capsule()
                        .strokeBorder(Color.appPrimary.opacity(0.3), lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scale Pill Button

struct ScalePillButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(.body, design: .rounded))
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.appPrimary : Color.appSecondaryBackground)
                )
                .foregroundColor(isSelected ? .white : .primary)
                .overlay(
                    Capsule()
                        .strokeBorder(Color.appPrimary.opacity(0.3), lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        KeyScaleSelector()
            .environment(TheoryEngine())
            .environment(DataManager(inMemory: true))
        
        Spacer()
    }
    .padding()
}
