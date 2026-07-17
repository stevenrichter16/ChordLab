//
//  SaveProgressionSheet.swift
//  ChordLab
//
//  Sheet for saving a chord progression to the library
//

import SwiftUI
import Tonic
import SwiftData

struct SaveProgressionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(TheoryEngine.self) private var theoryEngine
    
    let playbackChords: [TheoryEngine.PlaybackChord]
    let currentKey: String
    let tempo: Int

    private var chords: [Chord] {
        playbackChords.map { $0.chord }
    }
    
    @State private var progressionName = ""
    @State private var selectedTags: Set<String> = []
    @State private var customTag = ""
    @State private var showingSaveError = false
    @State private var saveError: String?
    @FocusState private var nameFieldFocused: Bool

    private var scaleName: String {
        theoryEngine.currentScaleType.capitalized
    }
    
    // Predefined tags
    let suggestedTags = ["Jazz", "Pop", "Rock", "Classical", "Blues", "Practice", "Original", "Cover", "Beginner", "Advanced"]
    
    var body: some View {
        NavigationStack {
            Form {
                // Name Section
                Section {
                    TextField("Progression Name", text: $progressionName)
                        .focused($nameFieldFocused)
                        .onAppear {
                            // Auto-generate name if empty
                            if progressionName.isEmpty {
                                progressionName = generateDefaultName()
                            }
                            // Focusing synchronously in a sheet's onAppear is
                            // unreliable; defer until presentation settles
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                nameFieldFocused = true
                            }
                        }
                } header: {
                    Text("Name")
                } footer: {
                    Text("Give your progression a memorable name")
                }
                
                // Preview Section
                Section("Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("\(currentKey) \(scaleName)", systemImage: "key")
                            Spacer()
                            Label("\(tempo) BPM", systemImage: "metronome")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                        Text(chords.map { $0.formattedSymbol }.joined(separator: " - "))
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
                
                // Tags Section
                Section("Tags (Optional)") {
                    // Suggested tags
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                        ForEach(suggestedTags, id: \.self) { tag in
                            TagButton(
                                tag: tag,
                                isSelected: selectedTags.contains(tag),
                                action: { toggleTag(tag) }
                            )
                        }
                    }
                    
                    // Custom tag input
                    HStack {
                        TextField("Add custom tag", text: $customTag)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                addCustomTag()
                            }
                        
                        Button("Add", action: addCustomTag)
                            .disabled(customTag.isEmpty)
                    }
                }
            }
            .navigationTitle("Save Progression")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProgression()
                    }
                    .fontWeight(.semibold)
                    .disabled(progressionName.isEmpty)
                }
            }
            .alert("Save Error", isPresented: $showingSaveError) {
                Button("OK") { }
            } message: {
                Text(saveError ?? "Failed to save progression")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateDefaultName() -> String {
        let chordNames = chords.prefix(3).map { $0.formattedSymbol }.joined(separator: "-")
        return "\(currentKey) \(scaleName): \(chordNames)"
    }
    
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    private func addCustomTag() {
        let trimmed = customTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            selectedTags.insert(trimmed)
            customTag = ""
        }
    }
    
    private func saveProgression() {
        // Create the progression using TheoryEngine
        let progression = theoryEngine.createProgressionData(
            from: playbackChords,
            name: progressionName,
            tempo: tempo
        )
        
        // Add tags
        progression.tags = Array(selectedTags)
        
        // Save to SwiftData
        modelContext.insert(progression)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveError = error.localizedDescription
            showingSaveError = true
        }
    }
}

// MARK: - Tag Button

struct TagButton: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.appPrimary : Color.appSecondaryBackground)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .strokeBorder(isSelected ? Color.clear : Color.appBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SaveProgressionSheet(
        playbackChords: [
            TheoryEngine.PlaybackChord(chord: Chord(.C, type: .major)),
            TheoryEngine.PlaybackChord(chord: Chord(.F, type: .major), duration: 2.0),
            TheoryEngine.PlaybackChord(chord: Chord(.G, type: .major)),
            TheoryEngine.PlaybackChord(chord: Chord(.C, type: .major), duration: 4.0)
        ],
        currentKey: "C",
        tempo: 90
    )
    .environment(TheoryEngine())
    .environment(DataManager(inMemory: true))
}