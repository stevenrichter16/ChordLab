//
//  PracticeGameView.swift
//  ChordLab
//
//  Reusable practice session container: difficulty setup -> questions -> results
//

import SwiftUI
import UIKit

struct PracticeGameView<Stimulus: View>: View {
    let mode: PracticeSession.PracticeMode
    let accentColor: Color
    let instructions: String
    let difficultyDetails: [PracticeSession.PracticeDifficulty: String]
    let showsDifficultyPicker: Bool
    let generator: (Int, PracticeSession.PracticeDifficulty) -> [PracticeQuestion]
    let onQuestionShown: ((PracticeQuestion) -> Void)?
    let onAnswered: ((PracticeQuestion, Bool) -> Void)?
    let stimulus: (PracticeQuestion) -> Stimulus

    @Environment(DataManager.self) private var dataManager
    @Environment(\.dismiss) private var dismiss

    @State private var phase: GamePhase = .setup
    @State private var difficulty: PracticeSession.PracticeDifficulty = .beginner
    @State private var questions: [PracticeQuestion] = []
    @State private var currentIndex = 0
    @State private var selectedAnswerIndex: Int? = nil
    @State private var correctCount = 0
    @State private var startedAt = Date()
    @State private var elapsedDuration: TimeInterval = 0
    @State private var displayedRingProgress: Double = 0

    private let questionCount = 10

    enum GamePhase {
        case setup, playing, results
    }

    init(
        mode: PracticeSession.PracticeMode,
        accentColor: Color,
        instructions: String,
        difficultyDetails: [PracticeSession.PracticeDifficulty: String] = [:],
        showsDifficultyPicker: Bool = true,
        generator: @escaping (Int, PracticeSession.PracticeDifficulty) -> [PracticeQuestion],
        onQuestionShown: ((PracticeQuestion) -> Void)? = nil,
        onAnswered: ((PracticeQuestion, Bool) -> Void)? = nil,
        @ViewBuilder stimulus: @escaping (PracticeQuestion) -> Stimulus
    ) {
        self.mode = mode
        self.accentColor = accentColor
        self.instructions = instructions
        self.difficultyDetails = difficultyDetails
        self.showsDifficultyPicker = showsDifficultyPicker
        self.generator = generator
        self.onQuestionShown = onQuestionShown
        self.onAnswered = onAnswered
        self.stimulus = stimulus
    }

    var body: some View {
        Group {
            switch phase {
            case .setup:
                setupView
            case .playing:
                playingView
            case .results:
                resultsView
            }
        }
        .navigationTitle(mode.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.appBackground)
    }

    // MARK: - Setup

    private var setupView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: iconName)
                    .font(.system(size: 44))
                    .foregroundColor(accentColor)
                    .frame(width: 96, height: 96)
                    .background(Circle().fill(accentColor.opacity(0.12)))
                    .padding(.top, 24)

                Text(instructions)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if showsDifficultyPicker {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Difficulty")
                        .font(.headline)

                    ForEach(PracticeSession.PracticeDifficulty.allCases, id: \.self) { level in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                difficulty = level
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(level.rawValue)
                                        .fontWeight(difficulty == level ? .semibold : .regular)

                                    if let detail = difficultyDetails[level] {
                                        Text(detail)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                if difficulty == level {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(accentColor)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(difficulty == level ? accentColor.opacity(0.15) : Color.appSecondaryBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(
                                        difficulty == level ? accentColor : Color.appBorder,
                                        lineWidth: difficulty == level ? 2 : 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)
                }

                Button(action: start) {
                    Text("Start")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(accentColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Playing

    @ViewBuilder
    private var playingView: some View {
        if currentIndex < questions.count {
            let question = questions[currentIndex]

            VStack(spacing: 20) {
                // Progress header
                VStack(spacing: 8) {
                    HStack {
                        Text("Question \(currentIndex + 1) of \(questions.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Label("\(correctCount)", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }

                    ProgressView(value: Double(currentIndex + 1), total: Double(questions.count))
                        .tint(accentColor)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // ZStack so the outgoing and incoming question views overlap
                // during the slide transition instead of stacking vertically
                ZStack {
                    ScrollView {
                        VStack(spacing: 20) {
                            Text(question.prompt)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            stimulus(question)

                            VStack(spacing: 10) {
                                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                                    AnswerOptionButton(
                                        text: option,
                                        state: answerState(for: index, in: question),
                                        action: { selectAnswer(index) }
                                    )
                                }
                            }
                            .padding(.horizontal)

                            if let selected = selectedAnswerIndex {
                                let isCorrect = selected == question.correctIndex
                                HStack(spacing: 6) {
                                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    Text(isCorrect ? "Correct!" : "Correct answer: \(question.correctAnswer)")
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(isCorrect ? .green : .red)
                                .padding(.horizontal)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                        .padding(.vertical)
                    }
                    .id(question.id)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .onAppear {
                        onQuestionShown?(question)
                    }
                }
            }
        }
    }

    private func answerState(for index: Int, in question: PracticeQuestion) -> AnswerOptionButton.AnswerState {
        guard let selected = selectedAnswerIndex else { return .idle }

        if index == question.correctIndex {
            return .correct
        } else if index == selected {
            return .wrong
        } else {
            return .dimmed
        }
    }

    // MARK: - Results

    private var resultsView: some View {
        let total = max(questions.count, 1)
        let percentage = Int((Double(correctCount) / Double(total) * 100).rounded())

        return VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.appTertiaryBackground, lineWidth: 14)

                Circle()
                    .trim(from: 0, to: displayedRingProgress)
                    .stroke(scoreColor(percentage), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(percentage)%")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                    Text("\(correctCount) of \(total)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 180, height: 180)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Score \(percentage) percent, \(correctCount) of \(total) correct")
            .onAppear {
                displayedRingProgress = 0
                withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                    displayedRingProgress = Double(correctCount) / Double(total)
                }
            }

            Text(resultMessage(percentage))
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text(difficulty.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Difficulty")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 4) {
                    Text(formattedDuration)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.appSecondaryBackground)
            .cornerRadius(12)
            .padding(.horizontal, 32)

            VStack(spacing: 12) {
                Button {
                    phase = .setup
                } label: {
                    Text("Play Again")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(accentColor)
                        .cornerRadius(12)
                }

                Button("Done") {
                    dismiss()
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Game flow

    private func start() {
        questions = generator(questionCount, difficulty)
        guard !questions.isEmpty else { return }

        currentIndex = 0
        selectedAnswerIndex = nil
        correctCount = 0
        displayedRingProgress = 0
        startedAt = Date()
        withAnimation(.easeInOut(duration: 0.25)) {
            phase = .playing
        }
    }

    private func selectAnswer(_ index: Int) {
        guard selectedAnswerIndex == nil, currentIndex < questions.count else { return }

        let question = questions[currentIndex]
        let isCorrect = index == question.correctIndex
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedAnswerIndex = index
            if isCorrect {
                correctCount += 1
            }
        }

        // Wrong answers feed the review queue; repeats just bump the counter
        if !isCorrect {
            try? dataManager.recordMissedQuestion(from: question, mode: mode)
        }
        onAnswered?(question, isCorrect)

        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(isCorrect ? .success : .error)

        let answeredIndex = currentIndex
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            advance(from: answeredIndex)
        }
    }

    private func advance(from index: Int) {
        guard phase == .playing, currentIndex == index else { return }

        if currentIndex + 1 < questions.count {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                currentIndex += 1
                selectedAnswerIndex = nil
            }
        } else {
            finish()
        }
    }

    private func finish() {
        let total = max(questions.count, 1)
        let percentage = Int((Double(correctCount) / Double(total) * 100).rounded())
        elapsedDuration = Date().timeIntervalSince(startedAt)

        do {
            try dataManager.recordPracticeSession(
                mode: mode,
                score: percentage,
                totalQuestions: questions.count,
                correctAnswers: correctCount,
                difficulty: difficulty,
                duration: elapsedDuration
            )
        } catch {
            // Non-fatal: results still display, only history is lost
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            phase = .results
        }
    }

    // MARK: - Helpers

    private var iconName: String {
        switch mode {
        case .earTraining: return "ear.fill"
        case .chordRecognition: return "pianokeys.inverse"
        case .progressionChallenge: return "square.stack.3d.up.fill"
        case .theoryQuiz: return "questionmark.circle.fill"
        case .review: return "arrow.counterclockwise.circle.fill"
        }
    }

    private var formattedDuration: String {
        let seconds = Int(elapsedDuration)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func scoreColor(_ percentage: Int) -> Color {
        if percentage >= 90 { return .green }
        if percentage >= 70 { return .orange }
        return .red
    }

    private func resultMessage(_ percentage: Int) -> String {
        switch percentage {
        case 100: return "Perfect score! Outstanding!"
        case 90...: return "Excellent work — your ear is sharp!"
        case 70...: return "Good job! Keep practicing to level up."
        case 50...: return "Getting there — repetition builds recognition."
        default: return "Tough round. Try an easier difficulty and build up!"
        }
    }
}

// MARK: - Answer Option Button

struct AnswerOptionButton: View {
    let text: String
    let state: AnswerState
    let action: () -> Void

    enum AnswerState {
        case idle, correct, wrong, dimmed
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.body)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)

                Spacer()

                switch state {
                case .correct:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                case .wrong:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                default:
                    EmptyView()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
            .foregroundColor(foregroundColor)
            .opacity(state == .dimmed ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(state != .idle)
        .animation(.easeInOut(duration: 0.2), value: state)
    }

    private var backgroundColor: Color {
        switch state {
        case .correct: return .green
        case .wrong: return .red
        default: return .appSecondaryBackground
        }
    }

    private var borderColor: Color {
        switch state {
        case .correct, .wrong: return .clear
        default: return .appBorder
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .correct, .wrong: return .white
        default: return .primary
        }
    }
}
