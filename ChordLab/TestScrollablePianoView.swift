//
//  TestScrollablePianoView.swift
//  ChordLab
//
//  Test view to compare piano keyboard implementations
//

import SwiftUI

struct TestScrollablePianoView: View {
    @State private var selectedKey = "C"
    @State private var selectedScale = "Major"
    @State private var theoryEngine = TheoryEngine()
    @State private var audioEngine = AudioEngine()
    @State private var showScrollable = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Toggle between piano views
                Picker("Piano Type", selection: $showScrollable) {
                    Text("Scrollable").tag(true)
                    Text("Original").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Key and scale selectors
                HStack {
                    Picker("Key", selection: $selectedKey) {
                        ForEach(["C", "D", "E", "F", "G", "A", "B"], id: \.self) { key in
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
                
                Divider()
                
                // Piano view
                if showScrollable {
                    VStack(alignment: .leading) {
                        Text("Scrollable Piano (5 octaves, C2-C6)")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollablePianoView()
                            .padding(.horizontal)
                    }
                } else {
                    VStack(alignment: .leading) {
                        Text("Original Scale Piano (1 octave from root)")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScalePianoView()
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Info panel
                VStack(spacing: 8) {
                    Text("Current Key: \(selectedKey) \(selectedScale)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 20) {
                        Label("Root", systemImage: "circle.fill")
                            .foregroundColor(.blue)
                        Label("Scale", systemImage: "circle")
                            .foregroundColor(.green)
                    }
                    .font(.caption)
                }
                .padding()
                .background(Color.appSecondaryBackground)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .navigationTitle("Piano Comparison")
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
    TestScrollablePianoView()
}