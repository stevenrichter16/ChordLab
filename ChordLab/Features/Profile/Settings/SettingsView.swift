//
//  SettingsView.swift
//  ChordLab
//
//  Settings screen for the app
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(DataManager.self) private var dataManager
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(\.dismiss) private var dismiss

    @State private var soundEnabled = true
    @State private var showingResetConfirmation = false
    @AppStorage("bassDoublingEnabled") private var bassDoublingEnabled = true

    var body: some View {
        @Bindable var appState = appState

        NavigationStack {
            List {
                // Appearance Section
                Section("Appearance") {
                    // Tab Bar Style Picker
                    HStack {
                        Label("Tab Bar Style", systemImage: "rectangle.bottomthird.inset.filled")
                        Spacer()
                        Picker("Tab Bar Style", selection: $appState.tabBarStyle) {
                            ForEach(TabBarStyle.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }

                    // Tab Bar Preview
                    VStack(spacing: 8) {
                        Text("Preview")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appTertiaryBackground)
                                .frame(height: 80)

                            switch appState.tabBarStyle {
                            case .compact:
                                CompactTabBar(selectedTab: .constant(2))
                                    .scaleEffect(0.8)
                                    .disabled(true)
                            case .ultraCompact:
                                UltraCompactTabBar(selectedTab: .constant(2))
                                    .scaleEffect(0.8)
                                    .disabled(true)
                            case .floating:
                                FloatingTabBar(selectedTab: .constant(2))
                                    .scaleEffect(0.8)
                                    .disabled(true)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                }

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

                    // Melodic voice for all chord/note playback
                    Picker(selection: Binding(
                        get: { audioEngine.currentInstrument },
                        set: { audioEngine.setInstrument($0) }
                    )) {
                        ForEach(AudioEngine.Instrument.allCases) { instrument in
                            Text(instrument.displayName).tag(instrument)
                        }
                    } label: {
                        Label("Instrument", systemImage: "pianokeys")
                    }
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
