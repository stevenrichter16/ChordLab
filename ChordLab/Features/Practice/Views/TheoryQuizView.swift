//
//  TheoryQuizView.swift
//  ChordLab
//
//  Theory quiz practice: Roman numerals, chord functions, and chord tones
//

import SwiftUI

struct TheoryQuizView: View {
    var body: some View {
        PracticeGameView(
            mode: .theoryQuiz,
            accentColor: .orange,
            instructions: "Answer questions about Roman numerals, chord functions, and chord tones. Higher difficulties use more keys and seventh chords.",
            generator: PracticeQuestionGenerator.theoryQuizQuestions
        ) { question in
            HStack(spacing: 8) {
                Image(systemName: "key.fill")
                Text("Key of \(question.keyName) major")
                    .fontWeight(.medium)
            }
            .font(.subheadline)
            .foregroundColor(.orange)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.orange.opacity(0.12)))
        }
    }
}

#Preview {
    NavigationStack {
        TheoryQuizView()
            .environment(DataManager(inMemory: true))
    }
}
