//
//  ProfileTabView.swift
//  ChordLab
//
//  Main view for the Profile tab
//

import SwiftUI

struct ProfileTabView: View {
    @Environment(DataManager.self) private var dataManager
    
    @State private var totalPracticeSessions = 0
    @State private var favoriteKey = "C major"
    @State private var achievementCount = 0
    @State private var showingSettings = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.appPrimary)
                    
                    Text("Music Student")
                        .font(.title2)
                        .bold()
                    
                    Text("Learning since today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Statistics
                VStack(alignment: .leading, spacing: 16) {
                    Text("Statistics")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(
                            title: "Sessions",
                            value: "\(totalPracticeSessions)",
                            icon: "music.note.list"
                        )
                        
                        StatCard(
                            title: "Favorite Key",
                            value: favoriteKey,
                            icon: "key.fill"
                        )
                        
                        StatCard(
                            title: "Achievements",
                            value: "\(achievementCount)",
                            icon: "trophy.fill"
                        )
                        
                        StatCard(
                            title: "Time Practiced",
                            value: "0h",
                            icon: "clock.fill"
                        )
                    }
                }
                .padding()
                
                // Achievements Preview
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recent Achievements")
                            .font(.headline)
                        Spacer()
                        Button("See All") {
                            // TODO: Navigate to achievements
                        }
                        .font(.caption)
                    }
                    
                    if achievementCount == 0 {
                        Text("Complete practice sessions to unlock achievements")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.appTertiaryBackground)
                            .cornerRadius(8)
                    } else {
                        // Placeholder achievements
                        HStack(spacing: 12) {
                            AchievementBadge(
                                icon: "star.fill",
                                title: "First Steps",
                                isUnlocked: true
                            )
                            
                            AchievementBadge(
                                icon: "flame.fill",
                                title: "On Fire",
                                isUnlocked: false
                            )
                            
                            AchievementBadge(
                                icon: "crown.fill",
                                title: "Theory Master",
                                isUnlocked: false
                            )
                        }
                    }
                }
                .padding()
                
                // Settings Button
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding()
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadProfileData()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    private func loadProfileData() {
        // TODO: Load actual data from DataManager
        totalPracticeSessions = 0
        achievementCount = 0
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.appPrimary)
            
            Text(value)
                .font(.headline)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.appSecondaryBackground)
        .cornerRadius(12)
    }
}

struct AchievementBadge: View {
    let icon: String
    let title: String
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(isUnlocked ? .yellow : .gray)
            
            Text(title)
                .font(.caption2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80, height: 80)
        .background(isUnlocked ? Color.appSecondaryBackground : Color.gray.opacity(0.2))
        .cornerRadius(12)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

#Preview {
    NavigationStack {
        ProfileTabView()
            .environment(DataManager(inMemory: true))
    }
}