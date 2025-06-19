//
//  KeyPickerView.swift
//  ChordLab
//
//  Sheet view for selecting musical key and scale type
//

import SwiftUI
import Tonic

struct KeyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TheoryEngine.self) private var theoryEngine
    @Environment(DataManager.self) private var dataManager
    
    // Local state for selection
    @State private var selectedKey: String = ""
    @State private var selectedScaleType: String = ""
    
    // Grid layout for keys
    private let keyColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // All 12 keys with enharmonic pairs
    private let keyRows: [[String]] = [
        ["C", "C♯/D♭", "D"],
        ["D♯/E♭", "E", "F"],
        ["F♯/G♭", "G", "G♯/A♭"],
        ["A", "A♯/B♭", "B"]
    ]
    
    // Available scale types
    // TODO: Add modes (dorian, phrygian, lydian, mixolydian, locrian) after initial testing
    private let scaleTypes = ["major", "minor"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Key Selection Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select Key")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: keyColumns, spacing: 12) {
                        ForEach(keyRows, id: \.self) { row in
                            ForEach(row, id: \.self) { keyLabel in
                                KeyButton(
                                    label: keyLabel,
                                    selectedKey: $selectedKey
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Scale Type Selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select Scale Type")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Picker("Scale Type", selection: $selectedScaleType) {
                        ForEach(scaleTypes, id: \.self) { scaleType in
                            Text(scaleType.capitalized)
                                .tag(scaleType)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("Key & Scale")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Initialize with current values from TheoryEngine
                selectedKey = theoryEngine.currentKey
                selectedScaleType = theoryEngine.currentScaleType
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveAndDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveAndDismiss() {
        // Update TheoryEngine
        theoryEngine.setKey(selectedKey, scaleType: selectedScaleType)
        
        // Persist to DataManager
        Task {
            do {
                let userData = try dataManager.getOrCreateUserData()
                userData.currentKey = selectedKey
                userData.currentScale = selectedScaleType
                userData.modifiedAt = Date()
                try dataManager.context.save()
            } catch {
                print("Failed to save key selection: \(error)")
            }
        }
        
        dismiss()
    }
}

// MARK: - Key Button Component

struct KeyButton: View {
    let label: String
    @Binding var selectedKey: String
    
    // Parse the actual key from the label (handles enharmonics)
    private var actualKey: String {
        // For enharmonic pairs, we need to pick one
        if label.contains("/") {
            // Default to sharp for selection
            return String(label.split(separator: "/")[0])
        }
        return label
    }
    
    private var isSelected: Bool {
        if label.contains("/") {
            // Check both enharmonic options
            let parts = label.split(separator: "/").map(String.init)
            return parts.contains(selectedKey)
        }
        return selectedKey == label
    }
    
    var body: some View {
        Button {
            selectedKey = actualKey
        } label: {
            VStack(spacing: 4) {
                if label.contains("/") {
                    // Enharmonic display
                    let parts = label.split(separator: "/")
                    Text(String(parts[0]))
                        .font(.headline)
                    Text(String(parts[1]))
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    // Single note display
                    Text(label)
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.appPrimary : Color.appSecondaryBackground)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.appPrimary, lineWidth: isSelected ? 2 : 0)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    KeyPickerView()
        .environment(TheoryEngine())
        .environment(DataManager(inMemory: true))
}