//
//  TestWhiteKeyView.swift
//  ChordLab
//
//  Isolated test for white key text rendering

import SwiftUI
import Tonic

struct TestWhiteKeyView: View {
    @State private var audioEngine = AudioEngine()
    
    var body: some View {
        VStack(spacing: 40) {
            Text("White Key Text Rendering Test")
                .font(.title2)
            
            // Test 1: Most basic implementation
            VStack {
                Text("Test 1: Most Basic")
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 50, height: 200)
                    .border(Color.black, width: 1)
                    .overlay(
                        Text("C")
                            .foregroundColor(.black)
                            .offset(y: 80)
                    )
            }
            
            // Test 2: Using actual PianoKeyView with large width
            VStack {
                Text("Test 2: PianoKeyView (50pt width)")
                PianoKeyView(
                    note: "D",
                    noteClass: .D,
                    octave: 4,
                    isHighlighted: false,
                    isRoot: false,
                    keyWidth: 50,
                    audioEngine: audioEngine
                )
                .frame(width: 50, height: 200)
            }
            
            // Test 3: Same but highlighted
            VStack {
                Text("Test 3: Highlighted Key")
                PianoKeyView(
                    note: "E",
                    noteClass: .E,
                    octave: 4,
                    isHighlighted: true,
                    isRoot: false,
                    keyWidth: 50,
                    audioEngine: audioEngine
                )
                .frame(width: 50, height: 200)
            }
            
            // Test 4: Root note
            VStack {
                Text("Test 4: Root Note")
                PianoKeyView(
                    note: "F",
                    noteClass: .F,
                    octave: 4,
                    isHighlighted: false,
                    isRoot: true,
                    keyWidth: 50,
                    audioEngine: audioEngine
                )
                .frame(width: 50, height: 200)
            }
            
            // Test 5: Small width like in the actual app
            VStack {
                Text("Test 5: Small Width (15pt)")
                PianoKeyView(
                    note: "G",
                    noteClass: .G,
                    octave: 4,
                    isHighlighted: false,
                    isRoot: false,
                    keyWidth: 15,
                    audioEngine: audioEngine
                )
                .frame(width: 15, height: 60)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    TestWhiteKeyView()
}
