//
//  ExploreTabView.swift
//  ChordLab
//
//  Main view for the Explore tab
//

import SwiftUI
import Tonic

struct ExploreTabView: View {
    @Environment(TheoryEngine.self) private var theoryEngine
    @Environment(AudioEngine.self) private var audioEngine
    
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    
    let categories = ["All", "Major", "Minor", "Seventh", "Extended", "Altered"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search chords...", text: $searchText)
            }
            .padding()
            .background(Color.appSecondaryBackground)
            .cornerRadius(10)
            .padding()
            
            // Category Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        CategoryPill(
                            title: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
            
            // Chord Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    // Placeholder chords
                    ForEach(getSampleChords(), id: \.description) { chord in
                        ChordCard(chord: chord) {
                            audioEngine.playChord(chord)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func getSampleChords() -> [Chord] {
        // Return sample chords based on category
        let allChords = [
            Chord(.C, type: .major),
            Chord(.A, type: .minor),
            Chord(.G, type: .maj7),
            Chord(.D, type: .min7),
            Chord(.F, type: .dom7),
            Chord(.E, type: .dim)
        ]
        
        if selectedCategory == "All" {
            return allChords
        }
        
        // Filter based on category (simplified for placeholder)
        return allChords.filter { chord in
            switch selectedCategory {
            case "Major":
                return chord.type == .major
            case "Minor":
                return chord.type == .minor
            case "Seventh":
                return [ChordType.maj7, .min7, .dom7].contains(chord.type)
            default:
                return true
            }
        }
    }
}

struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.appPrimary : Color.appSecondaryBackground)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct ChordCard: View {
    let chord: Chord
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(chord.description)
                    .font(.title2)
                    .bold()
                
                Text("Tap to play")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
        ExploreTabView()
            .environment(TheoryEngine())
            .environment(AudioEngine())
    }
}