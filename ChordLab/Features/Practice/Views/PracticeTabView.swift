//
//  PracticeTabView.swift
//  ChordLab
//
//  Main view for the Practice tab
//

import SwiftUI

struct PracticeTabView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(TheoryEngine.self) private var theoryEngine
    
    @State private var currentStreak = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Daily Streak Banner
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading) {
                        Text("\(currentStreak) Day Streak")
                            .font(.headline)
                        Text("Keep it going!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.appSecondaryBackground)
                .cornerRadius(12)
                
                // Practice Modes
                VStack(alignment: .leading, spacing: 12) {
                    Text("Practice Modes")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        PracticeModeCard(
                            title: "Ear Training",
                            subtitle: "Identify chords by ear",
                            icon: "ear.fill",
                            color: .blue
                        )
                        
                        PracticeModeCard(
                            title: "Chord Recognition",
                            subtitle: "Name the chord shown",
                            icon: "pianokeys.inverse",
                            color: .green
                        )
                        
                        PracticeModeCard(
                            title: "Progression Builder",
                            subtitle: "Create chord progressions",
                            icon: "square.stack.3d.up.fill",
                            color: .purple
                        )
                        
                        PracticeModeCard(
                            title: "Theory Quiz",
                            subtitle: "Test your knowledge",
                            icon: "questionmark.circle.fill",
                            color: .orange
                        )
                    }
                }
                
                // Recent Scores
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Scores")
                        .font(.headline)
                    
                    if currentStreak == 0 {
                        Text("Complete a practice session to see your scores")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.appTertiaryBackground)
                            .cornerRadius(8)
                    } else {
                        // Placeholder for recent scores
                        VStack(spacing: 8) {
                            ScoreRow(mode: "Ear Training", score: 85, date: Date())
                            ScoreRow(mode: "Theory Quiz", score: 92, date: Date())
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadPracticeStreak()
        }
    }
    
    private func loadPracticeStreak() {
        // TODO: Load actual streak from DataManager
        currentStreak = 3 // Placeholder
    }
}

struct PracticeModeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button {
            // TODO: Navigate to practice mode
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 50, height: 50)
                    .background(color.opacity(0.2))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.appSecondaryBackground)
            .cornerRadius(12)
        }
    }
}

struct ScoreRow: View {
    let mode: String
    let score: Int
    let date: Date
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(mode)
                    .font(.subheadline)
                Text(date, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(score)%")
                .font(.headline)
                .foregroundColor(scoreColor)
        }
        .padding()
        .background(Color.appTertiaryBackground)
        .cornerRadius(8)
    }
    
    private var scoreColor: Color {
        if score >= 90 {
            return .green
        } else if score >= 70 {
            return .orange
        } else {
            return .red
        }
    }
}

#Preview {
    NavigationStack {
        PracticeTabView()
            .environment(DataManager(inMemory: true))
            .environment(TheoryEngine())
    }
}