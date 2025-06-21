//
//  LearnTabView.swift
//  ChordLab
//
//  Main view for the Learn tab
//

import SwiftUI

struct LearnTabView: View {
    @Environment(TheoryEngine.self) private var theoryEngine
    @Environment(DataManager.self) private var dataManager
    @State private var useScrollablePiano = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Key and Scale Selector
                KeyScaleSelector()
                    .padding(.vertical, 8)
                
                // Scale Piano View
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Scale Visualization")
                            .font(.headline)
                        
                        Spacer()

                    }
                    .padding(.horizontal)
                    
                        ScrollablePianoView()
                            .padding(.horizontal)

                }
                
                // Today's Focus
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Focus")
                        .font(.headline)
                    
                    Text("Practice ii-V-I progressions in \(theoryEngine.currentKey) major")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Button {
                        // TODO: Navigate to lesson
                    } label: {
                        Text("Start Lesson")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .cornerRadius(12)
                
                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        QuickActionButton(
                            title: "Scale Practice",
                            icon: "music.note",
                            color: .blue
                        )
                        
                        QuickActionButton(
                            title: "Chord Review",
                            icon: "pianokeys",
                            color: .green
                        )
                        
                        QuickActionButton(
                            title: "Ear Training",
                            icon: "ear",
                            color: .orange
                        )
                        
                        QuickActionButton(
                            title: "Theory Quiz",
                            icon: "questionmark.circle",
                            color: .purple
                        )
                    }
                }
                .padding()
                
                // Theory Tip
                VStack(alignment: .leading, spacing: 8) {
                    Label("Theory Tip", systemImage: "lightbulb.fill")
                        .font(.headline)
                        .foregroundColor(.yellow)
                    
                    Text("The V7 chord creates tension that naturally resolves to the I chord due to the tritone between its 3rd and 7th degrees.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.appTertiaryBackground)
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Learn")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button {
            // TODO: Navigate to feature
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.appSecondaryBackground)
            .cornerRadius(12)
        }
    }
}

#Preview {
    NavigationStack {
        LearnTabView()
            .environment(TheoryEngine())
            .environment(AudioEngine())
            .environment(DataManager(inMemory: true))
    }
}
