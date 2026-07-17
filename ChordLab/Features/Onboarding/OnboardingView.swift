//
//  OnboardingView.swift
//  ChordLab
//
//  First-launch walkthrough of the app's core loop
//

import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var pageIndex = 0

    private struct OnboardingPage {
        let icon: String
        let color: Color
        let title: String
        let body: String
    }

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "pianokeys",
            color: .appPrimary,
            title: "Welcome to ChordLab",
            body: "Learn music theory the way it's meant to be learned — by seeing it and hearing it on a real piano."
        ),
        OnboardingPage(
            icon: "hand.tap.fill",
            color: .green,
            title: "Explore Chords",
            body: "Tap any chord to see its notes light up and hear it played. Touch and hold a chord to add it to a progression you can play, loop, and save."
        ),
        OnboardingPage(
            icon: "graduationcap.fill",
            color: .orange,
            title: "Learn & Practice",
            body: "Ten interactive lessons take you from notes to the circle of fifths, and four practice games train your eyes and ears at your own pace."
        ),
        OnboardingPage(
            icon: "flame.fill",
            color: .red,
            title: "Build a Streak",
            body: "Practice a little every day. ChordLab tracks your streaks, scores, and achievements — and remembers any question you miss so you can master it later."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Skip
            HStack {
                Spacer()
                Button("Skip") {
                    onFinish()
                }
                .foregroundColor(.secondary)
                .padding()
                .opacity(pageIndex < pages.count - 1 ? 1 : 0)
            }

            TabView(selection: $pageIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 28) {
                        Spacer()

                        Image(systemName: page.icon)
                            .font(.system(size: 56))
                            .foregroundColor(page.color)
                            .frame(width: 140, height: 140)
                            .background(Circle().fill(page.color.opacity(0.12)))

                        VStack(spacing: 12) {
                            Text(page.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)

                            Text(page.body)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 32)

                        Spacer()
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.25), value: pageIndex)

            // Page dots
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == pageIndex ? Color.appPrimary : Color.appBorder)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 24)

            Button {
                if pageIndex + 1 < pages.count {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        pageIndex += 1
                    }
                } else {
                    onFinish()
                }
            } label: {
                Text(pageIndex + 1 < pages.count ? "Continue" : "Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appPrimary)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.appBackground)
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
