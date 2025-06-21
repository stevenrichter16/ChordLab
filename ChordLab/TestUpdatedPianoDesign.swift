//
//  TestUpdatedPianoDesign.swift
//  ChordLab
//
//  Test view to verify the updated piano design matches HTML
//

import SwiftUI

struct TestUpdatedPianoDesign: View {
    @State private var theoryEngine = TheoryEngine()
    @State private var audioEngine = AudioEngine()
    @State private var selectedKey = "C"
    @State private var selectedScale = "Major"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Key selector
                HStack {
                    Text("Key:")
                        .font(.headline)
                    
                    Picker("Key", selection: $selectedKey) {
                        ForEach(["C", "D", "E", "F", "G", "A", "B", "C#", "D♭", "E♭", "F#", "G♭", "A♭", "B♭"], id: \.self) { key in
                            Text(key).tag(key)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker("Scale", selection: $selectedScale) {
                        Text("Major").tag("Major")
                        Text("Minor").tag("Minor")
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)
                
                // Scrollable Piano
                VStack(alignment: .leading, spacing: 12) {
                    Text("Updated Design (Matching HTML)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollablePianoView()
                }
                
                // Legend
                VStack(spacing: 12) {
                    Text("Visual Guide")
                        .font(.headline)
                    
                    HStack(spacing: 30) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 12)
                            Text("Root Note")
                                .font(.caption)
                        }
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(red: 52/255, green: 199/255, blue: 89/255).opacity(0.15))
                                .overlay(
                                    Circle()
                                        .stroke(Color(red: 52/255, green: 199/255, blue: 89/255), lineWidth: 2)
                                )
                                .frame(width: 12, height: 12)
                            Text("Scale Note")
                                .font(.caption)
                        }
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 12, height: 12)
                            Text("Playing")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color.appSecondaryBackground)
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Updated Piano Design")
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: selectedKey) { _, newValue in
                theoryEngine.setKey(newValue, scaleType: selectedScale)
            }
            .onChange(of: selectedScale) { _, newValue in
                theoryEngine.setKey(selectedKey, scaleType: newValue)
            }
            .onAppear {
                theoryEngine.setKey(selectedKey, scaleType: selectedScale)
            }
        }
        .environment(theoryEngine)
        .environment(audioEngine)
    }
}

#Preview {
    TestUpdatedPianoDesign()
}