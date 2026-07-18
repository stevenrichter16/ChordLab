//
//  SettingsView.swift
//  ChordLab
//
//  Settings screen for the app
//

import SwiftUI

struct SettingsView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(\.dismiss) private var dismiss

    @State private var soundEnabled = true
    @State private var showingResetConfirmation = false
    @AppStorage("bassDoublingEnabled") private var bassDoublingEnabled = true

    var body: some View {
        NavigationStack {
            List {
                // Sound Section
                Section {
                    HStack {
                        Label("Sound", systemImage: "speaker.wave.2")
                        Spacer()
                        Toggle("", isOn: $soundEnabled)
                            .labelsHidden()
                    }

                    HStack {
                        Label("Bass in Progressions", systemImage: "waveform.path")
                        Spacer()
                        Toggle("", isOn: $bassDoublingEnabled)
                            .labelsHidden()
                    }

                    // Melodic voice for all chord/note playback; pushed as
                    // a categorized list rather than one 20-item menu
                    Picker(selection: Binding(
                        get: { audioEngine.currentInstrument },
                        set: { audioEngine.setInstrument($0) }
                    )) {
                        ForEach(AudioEngine.Instrument.Category.allCases, id: \.self) { category in
                            Section(category.rawValue) {
                                ForEach(AudioEngine.Instrument.allCases.filter { $0.category == category }) { instrument in
                                    Text(instrument.displayName).tag(instrument)
                                }
                            }
                        }
                    } label: {
                        Label("Instrument", systemImage: "pianokeys")
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text("Sound")
                } footer: {
                    Text("Doubles each chord's root an octave lower during progression playback. Instrument voices come from the bundled GeneralUser GS bank.")
                }

                // Data Section
                Section("Data") {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Label("Reset All Data", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }

                // About Section
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Piano Sound", systemImage: "pianokeys")
                        Spacer()
                        Text("GeneralUser GS")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com/stevenrichter16/ChordLab")!) {
                        HStack {
                            Label("GitHub", systemImage: "link")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("Piano samples from the GeneralUser GS SoundFont by S. Christian Collins.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                soundEnabled = (try? dataManager.getOrCreateUserData())?.soundEnabled ?? true
            }
            .onChange(of: soundEnabled) { _, isOn in
                audioEngine.setVolume(isOn ? 0.7 : 0)
                try? dataManager.updateUserData { userData in
                    userData.soundEnabled = isOn
                }
            }
            .confirmationDialog(
                "Reset all data?",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Everything", role: .destructive) {
                    try? dataManager.clearAllData()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This deletes all saved progressions, practice history, and achievement progress. This cannot be undone.")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
        .environment(DataManager(inMemory: true))
        .environment(AudioEngine())
}
