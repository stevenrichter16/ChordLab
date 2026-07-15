//
//  ProgressionChallengeView.swift
//  ChordLab
//
//  Progression challenge practice: identify common progressions by ear
//

import SwiftUI
import Tonic

struct ProgressionChallengeView: View {
    @Environment(AudioEngine.self) private var audioEngine

    var body: some View {
        PracticeGameView(
            mode: .progressionChallenge,
            accentColor: .purple,
            instructions: "Listen to a four-chord progression and identify its Roman numeral pattern. Higher difficulties use more keys and seventh chords.",
            generator: PracticeQuestionGenerator.progressionQuestions,
            onQuestionShown: { question in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    playProgression(question.progression)
                }
            }
        ) { question in
            ReplayProgressionButton(progression: question.progression) {
                playProgression(question.progression)
            }
        }
        .onDisappear {
            audioEngine.stopPlayback()
        }
    }

    private func playProgression(_ chords: [Chord]) {
        guard !chords.isEmpty else { return }
        audioEngine.stopPlayback()
        audioEngine.setTempo(80)
        audioEngine.playProgression(chords.map { TheoryEngine.PlaybackChord(chord: $0) })
    }
}

struct ReplayProgressionButton: View {
    let progression: [Chord]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                HStack(spacing: 6) {
                    ForEach(0..<max(progression.count, 1), id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.purple.opacity(0.6))
                            .frame(width: 18, height: CGFloat(22 + (index % 2) * 10))
                    }
                }

                Label("Replay progression", systemImage: "speaker.wave.3.fill")
                    .font(.caption)
            }
            .foregroundColor(.purple)
            .frame(width: 180, height: 110)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.purple.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ProgressionChallengeView()
            .environment(DataManager(inMemory: true))
            .environment(AudioEngine())
    }
}
