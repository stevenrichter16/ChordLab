//
//  ScalePianoView.swift
//  ChordLab
//
//  Piano keyboard visualization that highlights scale notes
//  This is a wrapper around PianoKeyboardView for backward compatibility
//

import SwiftUI
import Tonic

struct ScalePianoView: View {
    @Environment(TheoryEngine.self) private var theoryEngine
    @Environment(AudioEngine.self) private var audioEngine
    
    var body: some View {
        GeometryReader { geometry in
            let keyWidth = geometry.size.width / 8 // 8 white keys (7 scale notes + octave root)
            let _ = print("ScalePianoView - geometry width: \(geometry.size.width), keyWidth: \(keyWidth)")
            
            PianoKeyboardView(startOctave: 3, octaveCount: 1, keyWidth: keyWidth, startFromRootNote: true)
                .environment(theoryEngine)
                .environment(audioEngine)
        }
        .frame(height: 190) // Slightly taller for better visibility
    }
}

// MARK: - Preview

#Preview {
    ScalePianoView()
        .environment(TheoryEngine())
        .environment(AudioEngine())
        .padding()
}
