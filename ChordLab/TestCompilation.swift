//
//  TestCompilation.swift
//  ChordLab
//
//  Test to verify Library functionality compiles
//

import SwiftUI
import SwiftData

struct TestCompilationView: View {
    var body: some View {
        VStack {
            Text("Testing Library Compilation")
            
            // Test that our types work
            Button("Test Types") {
                testTypes()
            }
        }
    }
    
    func testTypes() {
        // Test ProgressionChord
        let progressionChord = ProgressionChord(
            chordSymbol: "Cmaj7",
            romanNumeral: "I",
            noteNames: ["C", "E", "G", "B"],
            function: "Tonic"
        )
        
        // Test SavedProgression
        let savedProgression = SavedProgression(
            name: "Test",
            progressionChords: [progressionChord],
            key: "C",
            tempo: 120
        )
        
        print("Types compile correctly!")
        print("Progression has \(savedProgression.chordCount) chords")
    }
}

#Preview {
    TestCompilationView()
}