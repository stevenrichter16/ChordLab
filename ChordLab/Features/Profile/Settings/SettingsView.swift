//
//  SettingsView.swift
//  ChordLab
//
//  Settings screen for the app
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
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
                Section("Sound") {
                    HStack {
                        Label("Haptic Feedback", systemImage: "waveform")
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .labelsHidden()
                    }
                    
                    HStack {
                        Label("Sound Effects", systemImage: "speaker.wave.2")
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .labelsHidden()
                    }
                }
                
                // About Section
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/yourusername/chordlab")!) {
                        HStack {
                            Label("GitHub", systemImage: "link")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
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
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}