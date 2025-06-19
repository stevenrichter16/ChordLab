//
//  TestPianoKeyboardView.swift
//  ChordLab
//
//  Test view to verify piano keyboard starts from root note
//

import SwiftUI

struct TestPianoKeyboardView: View {
    @State private var selectedKey = "D"
    @State private var selectedScale = "Major"
    @State private var theoryEngine = TheoryEngine()
    @State private var audioEngine = AudioEngine()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Key selector
                Picker("Key", selection: $selectedKey) {
                    ForEach(["C", "D", "E", "F", "G", "A", "B"], id: \.self) { key in
                        Text(key).tag(key)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Scale type selector
                Picker("Scale", selection: $selectedScale) {
                    Text("Major").tag("Major")
                    Text("Minor").tag("Minor")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                Divider()
                
                // Original piano (starting from C)
                VStack(alignment: .leading) {
                    Text("Original (starts from C):")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    GeometryReader { geometry in
                        let keyWidth = geometry.size.width / 7
                        PianoKeyboardView(
                            startOctave: 3,
                            octaveCount: 1,
                            keyWidth: keyWidth,
                            startFromRootNote: false
                        )
                    }
                    .frame(height: 120)
                    .padding(.horizontal)
                }
                
                Divider()
                
                // New piano (starting from root note)
                VStack(alignment: .leading) {
                    Text("New (starts from \(selectedKey), shows 8 keys with octave root):")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    GeometryReader { geometry in
                        let keyWidth = geometry.size.width / 8  // 8 keys instead of 7
                        PianoKeyboardView(
                            startOctave: 3,
                            octaveCount: 1,
                            keyWidth: keyWidth,
                            startFromRootNote: true
                        )
                    }
                    .frame(height: 120)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Piano Keyboard Test")
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
    TestPianoKeyboardView()
}