//
//  LessonDetailView.swift
//  ChordLab
//
//  Interactive lesson player: content pages -> quiz -> completion
//

import SwiftUI
import UIKit
import Tonic

struct LessonDetailView: View {
    let lesson: Lesson

    @Environment(DataManager.self) private var dataManager
    @Environment(\.dismiss) private var dismiss

    private enum Phase {
        case pages, quiz, completed
    }

    @State private var phase: Phase = .pages
    @State private var pageIndex = 0
    @State private var quizIndex = 0
    @State private var selectedAnswer: Int? = nil
    @State private var quizCorrect = 0

    private var totalSteps: Int {
        lesson.pages.count + lesson.quiz.count
    }

    private var currentStep: Int {
        switch phase {
        case .pages: return pageIndex + 1
        case .quiz: return lesson.pages.count + quizIndex + 1
        case .completed: return totalSteps
        }
    }

    private let slideTransition: AnyTransition = .asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )

    var body: some View {
        VStack(spacing: 0) {
            if phase != .completed {
                ProgressView(value: Double(currentStep), total: Double(totalSteps))
                    .tint(lesson.color)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            switch phase {
            case .pages:
                pagesView
            case .quiz:
                quizView
            case .completed:
                completedView
            }
        }
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.appBackground)
        .onAppear {
            try? dataManager.recordLessonViewed(lesson.id)
        }
    }

    // MARK: - Content pages

    private var pagesView: some View {
        let page = lesson.pages[pageIndex]

        return VStack(spacing: 0) {
            ZStack {
                LessonPageView(page: page, accentColor: lesson.color)
                    .id(page.id)
                    .transition(slideTransition)
            }

            HStack {
                if pageIndex > 0 {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            pageIndex -= 1
                        }
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        if pageIndex + 1 < lesson.pages.count {
                            pageIndex += 1
                        } else {
                            phase = .quiz
                        }
                    }
                } label: {
                    Label(
                        pageIndex + 1 < lesson.pages.count ? "Next" : "Start Quiz",
                        systemImage: "chevron.right"
                    )
                    .labelStyle(.titleAndIcon)
                    .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .tint(lesson.color)
            }
            .padding()
        }
    }

    // MARK: - Quiz

    private var quizView: some View {
        let question = lesson.quiz[quizIndex]

        return ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Question \(quizIndex + 1) of \(lesson.quiz.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 16)

                    Text(question.prompt)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    VStack(spacing: 10) {
                        ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                            AnswerOptionButton(
                                text: option,
                                state: answerState(for: index, in: question),
                                action: { selectQuizAnswer(index) }
                            )
                        }
                    }
                    .padding(.horizontal)

                    if let selected = selectedAnswer {
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
            .id(quizIndex)
            .transition(slideTransition)
        }
    }

    private func answerState(for index: Int, in question: PracticeQuestion) -> AnswerOptionButton.AnswerState {
        guard let selected = selectedAnswer else { return .idle }

        if index == question.correctIndex {
            return .correct
        } else if index == selected {
            return .wrong
        } else {
            return .dimmed
        }
    }

    private func selectQuizAnswer(_ index: Int) {
        guard selectedAnswer == nil else { return }

        let question = lesson.quiz[quizIndex]
        let isCorrect = index == question.correctIndex
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedAnswer = index
            if isCorrect {
                quizCorrect += 1
            }
        }

        if !isCorrect {
            try? dataManager.recordMissedQuestion(from: question, mode: .theoryQuiz)
        }

        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(isCorrect ? .success : .error)

        let answeredIndex = quizIndex
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            guard phase == .quiz, quizIndex == answeredIndex else { return }

            if quizIndex + 1 < lesson.quiz.count {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    quizIndex += 1
                    selectedAnswer = nil
                }
            } else {
                try? dataManager.markLessonCompleted(lesson.id)
                withAnimation(.easeInOut(duration: 0.3)) {
                    phase = .completed
                }
            }
        }
    }

    // MARK: - Completion

    private var nextLesson: Lesson? {
        guard let index = LessonLibrary.all.firstIndex(where: { $0.id == lesson.id }) else { return nil }
        let after = LessonLibrary.all.index(after: index)
        return after < LessonLibrary.all.endIndex ? LessonLibrary.all[after] : nil
    }

    private var completedView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 96, height: 96)
                .background(Circle().fill(lesson.color))

            VStack(spacing: 8) {
                Text("Lesson Complete!")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("You answered \(quizCorrect) of \(lesson.quiz.count) quiz questions correctly.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                if let next = nextLesson {
                    NavigationLink {
                        LessonDetailView(lesson: next)
                    } label: {
                        Text("Next: \(next.title)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(lesson.color)
                            .cornerRadius(12)
                    }
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
}

// MARK: - Lesson Page

struct LessonPageView: View {
    let page: LessonPage
    let accentColor: Color

    @Environment(AudioEngine.self) private var audioEngine
    @State private var demoSymbol: String? = nil
    @State private var demoChord: Chord? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(page.title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(page.body)
                    .font(.body)
                    .lineSpacing(4)

                if !page.demoChords.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Try it", systemImage: "hand.tap")
                            .font(.headline)
                            .foregroundColor(accentColor)

                        ChordPianoView(
                            highlightedChord: demoChord,
                            currentKey: page.keyName,
                            playingChordNotes: .constant([])
                        )

                        HStack(spacing: 10) {
                            ForEach(page.demoChords, id: \.self) { symbol in
                                DemoChordButton(
                                    symbol: symbol,
                                    accentColor: accentColor,
                                    isActive: demoSymbol == symbol,
                                    action: { playDemo(symbol) }
                                )
                            }
                        }
                    }
                    .padding()
                    .background(Color.appSecondaryBackground)
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }

    private func playDemo(_ symbol: String) {
        guard let chord = Chord.parse(symbol) else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            demoSymbol = symbol
            demoChord = chord
        }
        audioEngine.playChord(chord, velocity: 80, duration: 1.2)
    }
}

struct DemoChordButton: View {
    let symbol: String
    let accentColor: Color
    let isActive: Bool
    let action: () -> Void

    private var displaySymbol: String {
        Chord.parse(symbol)?.formattedSymbol ?? symbol
    }

    var body: some View {
        Button(action: action) {
            Text(displaySymbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isActive ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(isActive ? accentColor : Color.appTertiaryBackground)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Play \(displaySymbol)")
    }
}

#Preview {
    NavigationStack {
        LessonDetailView(lesson: LessonLibrary.all[1])
            .environment(DataManager(inMemory: true))
            .environment(TheoryEngine())
            .environment(AudioEngine())
    }
}
