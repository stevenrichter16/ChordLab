//
//  LibraryTabView.swift
//  ChordLab
//
//  Main view for the Library tab showing saved progressions
//

import SwiftUI
import SwiftData

struct LibraryTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedProgression.dateModified, order: .reverse) private var progressions: [SavedProgression]
    
    @State private var searchText = ""
    @State private var selectedSortOption: SortOption = .dateModified
    @State private var showOnlyFavorites = false
    
    enum SortOption: String, CaseIterable {
        case dateModified = "Last Modified"
        case dateCreated = "Date Created"
        case name = "Name"
        case playCount = "Most Played"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if progressions.isEmpty && searchText.isEmpty {
                    LibraryEmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredProgressions) { progression in
                                LibraryProgressionCard(progression: progression)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Library")
            .searchable(text: $searchText, prompt: "Search progressions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Sort options
                        Section("Sort by") {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(action: { selectedSortOption = option }) {
                                    Label(
                                        option.rawValue,
                                        systemImage: selectedSortOption == option ? "checkmark" : ""
                                    )
                                }
                            }
                        }
                        
                        // Filter options
                        Section {
                            Button(action: { showOnlyFavorites.toggle() }) {
                                Label(
                                    "Favorites Only",
                                    systemImage: showOnlyFavorites ? "checkmark" : ""
                                )
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
    
    private var filteredProgressions: [SavedProgression] {
        var filtered = progressions
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { progression in
                progression.name.localizedCaseInsensitiveContains(searchText) ||
                progression.chords.joined(separator: " ").localizedCaseInsensitiveContains(searchText) ||
                progression.key.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply favorites filter
        if showOnlyFavorites {
            filtered = filtered.filter { $0.isFavorite }
        }
        
        // Apply sorting
        switch selectedSortOption {
        case .dateModified:
            filtered.sort { $0.dateModified > $1.dateModified }
        case .dateCreated:
            filtered.sort { $0.dateCreated > $1.dateCreated }
        case .name:
            filtered.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .playCount:
            filtered.sort { $0.playCount > $1.playCount }
        }
        
        return filtered
    }
}

// MARK: - Empty State View

struct LibraryEmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "music.note.list")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Progressions Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create chord progressions in the Explore tab\nand save them here for later")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

// MARK: - Progression Card

struct LibraryProgressionCard: View {
    let progression: SavedProgression
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "music.note")
                    .font(.caption)
                    .foregroundColor(.appPrimary)
                
                Text(progression.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Button(action: { toggleFavorite() }) {
                    Image(systemName: progression.isFavorite ? "star.fill" : "star")
                        .foregroundColor(progression.isFavorite ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
                
                Menu {
                    Button("Edit", systemImage: "pencil") {
                        // TODO: Edit functionality
                    }
                    
                    Button("Duplicate", systemImage: "doc.on.doc") {
                        // TODO: Duplicate functionality
                    }
                    
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        // TODO: Delete functionality
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
            
            // Divider
            Divider()
            
            // Key and tempo info
            HStack(spacing: 16) {
                Label("\(progression.key) \(progression.scale.capitalized)", systemImage: "key")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("\(progression.tempo) BPM", systemImage: "metronome")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Chord preview
            Text(chordPreview)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            // Footer stats
            HStack {
                if progression.chordCount > 0 {
                    Text("\(progression.chordCount) chords")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if progression.duration > 0 {
                    Text("• \(formatDuration(progression.duration))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if progression.playCount > 0 {
                    Text("• Played \(progression.playCount) times")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(progression.dateModified.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.appSecondaryBackground)
        .cornerRadius(12)
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            ProgressionDetailView(progression: progression)
        }
    }
    
    private var chordPreview: String {
        let chords = progression.progressionChords.prefix(4).map { $0.chordSymbol }
        let preview = chords.joined(separator: " - ")
        return chords.count < progression.chordCount ? preview + "..." : preview
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func toggleFavorite() {
        progression.isFavorite.toggle()
        progression.dateModified = Date()
    }
}

// MARK: - Preview

#Preview {
    LibraryTabView()
        .environment(DataManager(inMemory: true))
}
