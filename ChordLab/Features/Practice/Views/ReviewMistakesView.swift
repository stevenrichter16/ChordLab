//
//  ReviewMistakesView.swift
//  ChordLab
//
//  Replays questions the user previously missed. Answering one correctly
//  removes it from the queue; missing it again pushes it back for later.
//

import SwiftUI
import Tonic

struct ReviewMistakesView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(AudioEngine.self) private var audioEngine

    @State private var hasMistakes = true
    @State private var savedTempo = 120

    var body: some View {
        Group {
            if hasMistakes {
                PracticeGameView(
                    mode: .review,
                    accentColor: .indigo,
                    instructions: "Retry the questions you've missed. Answer one correctly and it leaves the queue — miss it and it comes back later.",
                    showsDifficultyPicker: false,
                    generator: { count, _ in
                        reviewQuestions(count: count)
                    },
                    onQuestionShown: { question in
                        autoplayStimulus(for: question)
                    },
                    onAnswered: { question, isCorrect in
                        if isCorrect {
                            try? dataManager.resolveMissedQuestion(
                                prompt: question.prompt,
                                correctAnswer: question.correctAnswer
                            )
                        }
                    },
                    stimulus: { question in
                        reviewStimulus(for: question)
                    }
                )
            } else {
                emptyState
            }
        }
        .onAppear {
            hasMistakes = ((try? dataManager.missedQuestionCount()) ?? 0) > 0
            savedTempo = audioEngine.currentTempo
        }
        .onDisappear {
            audioEngine.stopPlayback()
            audioEngine.setTempo(savedTempo)
        }
    }

    // MARK: - Question reconstruction

    private func reviewQuestions(count: Int) -> [PracticeQuestion] {
        let missed = (try? dataManager.getMissedQuestions(limit: count)) ?? []

        return missed.map { item in
            PracticeQuestion(
                prompt: item.prompt,
                keyName: item.keyName,
                chord: item.chordSymbol.flatMap { Chord.parse($0) },
                progression: item.progressionSymbols.compactMap { Chord.parse($0) },
                options: item.options,
                correctIndex: item.correctIndex,
                sourceMode: item.mode
            )
        }
    }

    // MARK: - Stimulus

    @ViewBuilder
    private func reviewStimulus(for question: PracticeQuestion) -> some View {
        switch question.sourceMode {
        case .earTraining:
            ReplayChordButton(chord: question.chord, tint: .indigo)

        case .chordRecognition:
            VStack(spacing: 12) {
                ChordPianoView(
                    highlightedChord: question.chord,
                    currentKey: question.keyName,
                    playingChordNotes: .constant([])
                )
                .padding(.horizontal)

                ReplayChordButton(chord: question.chord, tint: .indigo)
            }

        case .progressionChallenge:
            ReplayProgressionButton(progression: question.progression) {
                playProgression(question.progression)
            }

        default:
            // Theory questions carry their key context in the prompt
            EmptyView()
        }
    }

    private func autoplayStimulus(for question: PracticeQuestion) {
        switch question.sourceMode {
        case .earTraining:
            guard let chord = question.chord else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                audioEngine.playChord(chord, velocity: 80, duration: 1.2)
            }
        case .progressionChallenge:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                playProgression(question.progression)
            }
        default:
            break
        }
    }

    private func playProgression(_ chords: [Chord]) {
        guard !chords.isEmpty else { return }
        audioEngine.stopPlayback()
        audioEngine.setTempo(80)
        audioEngine.playProgression(chords.map { TheoryEngine.PlaybackChord(chord: $0) })
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundColor(.green)
                .frame(width: 120, height: 120)
                .background(Circle().fill(Color.green.opacity(0.12)))

            VStack(spacing: 8) {
                Text("Nothing to Review")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Missed questions from practice games and\nlesson quizzes will collect here.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

#Preview {
    NavigationStack {
        ReviewMistakesView()
            .environment(DataManager(inMemory: true))
            .environment(TheoryEngine())
            .environment(AudioEngine())
    }
}
