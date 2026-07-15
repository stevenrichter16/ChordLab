//
//  ChordRecognitionView.swift
//  ChordLab
//
//  Chord recognition practice: name the chord highlighted on the piano
//

import SwiftUI
import Tonic

struct ChordRecognitionView: View {
    @Environment(TheoryEngine.self) private var theoryEngine
    @Environment(AudioEngine.self) private var audioEngine

    // The piano's enharmonic spelling follows the global engine key, so we
    // set it per-question and restore the user's key when leaving
    @State private var savedKey: String = "C"
    @State private var savedScale: String = "major"

    var body: some View {
        PracticeGameView(
            mode: .chordRecognition,
            accentColor: .green,
            instructions: "A chord is highlighted on the piano — name it. Root, third, fifth and seventh are color-coded just like in Explore.",
            generator: PracticeQuestionGenerator.chordRecognitionQuestions,
            onQuestionShown: { question in
                theoryEngine.setKey(question.keyName, scaleType: "major")
            },
            stimulus: { question in
                VStack(spacing: 12) {
                    ChordPianoView(
                        highlightedChord: question.chord,
                        currentKey: question.keyName,
                        playingChordNotes: .constant([])
                    )
                    .padding(.horizontal)

                    ReplayChordButton(chord: question.chord, tint: .green)
                }
            }
        )
        .onAppear {
            savedKey = theoryEngine.currentKey
            savedScale = theoryEngine.currentScaleType
        }
        .onDisappear {
            theoryEngine.setKey(savedKey, scaleType: savedScale)
        }
    }
}

#Preview {
    NavigationStack {
        ChordRecognitionView()
            .environment(DataManager(inMemory: true))
            .environment(TheoryEngine())
            .environment(AudioEngine())
    }
}
