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
    // set it per-question and restore the user's key when leaving.
    // Captured at most once: on re-entry after a tab switch, the question
    // view's onAppear (which sets the question key) can fire before ours,
    // and re-capturing then would clobber the user's key with a question key.
    @State private var savedKey: String? = nil
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
            if savedKey == nil {
                savedKey = theoryEngine.currentKey
                savedScale = theoryEngine.currentScaleType
            }
        }
        .onDisappear {
            if let savedKey {
                theoryEngine.setKey(savedKey, scaleType: savedScale)
            }
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
