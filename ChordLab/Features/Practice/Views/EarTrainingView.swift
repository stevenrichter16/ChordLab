//
//  EarTrainingView.swift
//  ChordLab
//
//  Ear training practice: identify chord qualities by ear
//

import SwiftUI
import Tonic

struct EarTrainingView: View {
    @Environment(AudioEngine.self) private var audioEngine

    var body: some View {
        PracticeGameView(
            mode: .earTraining,
            accentColor: .blue,
            instructions: "Listen to each chord and identify its quality. Higher difficulties add seventh chords and trickier qualities.",
            generator: PracticeQuestionGenerator.earTrainingQuestions,
            onQuestionShown: { question in
                guard let chord = question.chord else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    audioEngine.playChord(chord, velocity: 80, duration: 1.2)
                }
            },
            stimulus: { question in
                ReplayChordButton(chord: question.chord, tint: .blue)
            }
        )
    }
}

/// Large tappable button to (re)play the current question's chord
struct ReplayChordButton: View {
    let chord: Chord?
    let tint: Color

    @Environment(AudioEngine.self) private var audioEngine
    @State private var isPulsing = false

    var body: some View {
        Button(action: play) {
            VStack(spacing: 12) {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 40))
                    .scaleEffect(isPulsing ? 1.1 : 1.0)

                Text("Tap to replay")
                    .font(.caption)
            }
            .foregroundColor(tint)
            .frame(width: 140, height: 110)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(tint.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
    }

    private func play() {
        guard let chord else { return }
        audioEngine.playChord(chord, velocity: 80, duration: 1.2)

        withAnimation(.easeInOut(duration: 0.15)) {
            isPulsing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.15)) {
                isPulsing = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        EarTrainingView()
            .environment(DataManager(inMemory: true))
            .environment(AudioEngine())
    }
}
