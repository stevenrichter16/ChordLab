//
//  FloatingTabBar.swift
//  ChordLab
//
//  The app's custom material tab bar, pinned to the physical bottom
//  of the screen (ContentView reserves its measured height)
//

import SwiftUI
import UIKit

struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    @Namespace private var animation

    let tabs: [(icon: String, label: String)] = [
        ("book.fill", "Learn"),
        ("magnifyingglass", "Explore"),
        ("books.vertical.fill", "Library"),
        ("music.note.list", "Practice"),
        ("person.fill", "Profile")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Glass effect background with tab items
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    FloatingTabItem(
                        icon: tabs[index].icon,
                        label: tabs[index].label,
                        isSelected: selectedTab == index,
                        namespace: animation,
                        action: {
                            withAnimation(.appSpring) {
                                selectedTab = index

                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            .background(
                .ultraThinMaterial,
                in: Rectangle()
            )
        }
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.white.opacity(0.2)),
            alignment: .top
        )
        .shadow(color: .black.opacity(0.15), radius: 20, y: -5)
    }
}

struct FloatingTabItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    var namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                ZStack {
                    // Selection background
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appPrimary.opacity(0.2))
                            .matchedGeometryEffect(id: "floatingTab", in: namespace)
                    }

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(isSelected ? .appPrimary : .secondary)
                }
                .frame(width: 56, height: 36)

                Text(label)
                    .font(.system(size: 9, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .appPrimary : .secondary)
                    .opacity(isSelected ? 1.0 : 0.7)
            }
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview("Floating Tab Bar") {
    @State var selectedTab = 0

    return VStack {
        Spacer()
        FloatingTabBar(selectedTab: $selectedTab)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.appBackground)
}
