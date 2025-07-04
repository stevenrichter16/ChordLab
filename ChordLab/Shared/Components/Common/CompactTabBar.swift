//
//  CompactTabBar.swift
//  ChordLab
//
//  Custom compact and sleek tab bar
//

import SwiftUI
import UIKit

struct CompactTabBar: View {
    @Binding var selectedTab: Int
    @State private var selectedTabFrame: CGRect = .zero
    @Namespace private var animation
    
    // Tab items configuration
    let tabs: [(icon: String, label: String)] = [
        ("book.fill", "Learn"),
        ("magnifyingglass", "Explore"), 
        ("books.vertical.fill", "Library"),
        ("music.note.list", "Practice"),
        ("person.fill", "Profile")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab bar content
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    CompactTabItem(
                        icon: tabs[index].icon,
                        label: tabs[index].label,
                        isSelected: selectedTab == index,
                        namespace: animation,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedTab = index
                                
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Safe area extension
            GeometryReader { geometry in
                Color.clear
                    .frame(height: geometry.safeAreaInsets.bottom)
            }
            .frame(height: 0)
        }
        .background(Color.appSecondaryBackground)
        .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
    }
}

struct CompactTabItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    var namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.appPrimary.opacity(0.15))
                            .frame(width: 50, height: 32)
                            .matchedGeometryEffect(id: "tabSelection", in: namespace)
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: isSelected ? 22 : 20, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(isSelected ? .appPrimary : .secondary)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                
                if isSelected {
                    Text(label)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.appPrimary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Alternative ultra-compact design with just icons
struct UltraCompactTabBar: View {
    @Binding var selectedTab: Int
    
    let tabs: [(icon: String, label: String)] = [
        ("book.fill", "Learn"),
        ("magnifyingglass", "Explore"),
        ("books.vertical.fill", "Library"),
        ("music.note.list", "Practice"),
        ("person.fill", "Profile")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    UltraCompactTabItem(
                        icon: tabs[index].icon,
                        isSelected: selectedTab == index,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedTab = index
                                
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.appSecondaryBackground)
        }
        .background(Color.appSecondaryBackground)
        .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
    }
}

struct UltraCompactTabItem: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Selection indicator
                if isSelected {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.15))
                        .frame(width: 40, height: 40)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(isSelected ? .appPrimary : .secondary)
                    .scaleEffect(isSelected ? 1.15 : 1.0)
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview("Compact Tab Bar") {
    @State var selectedTab = 0
    
    return VStack {
        Spacer()
        CompactTabBar(selectedTab: $selectedTab)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.appBackground)
}

// Modern glass effect tab bar (attached to bottom)
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
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
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
    }
}

#Preview("Compact Tab Bar") {
    @State var selectedTab = 0
    
    return VStack {
        Spacer()
        CompactTabBar(selectedTab: $selectedTab)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.appBackground)
}

#Preview("Ultra Compact Tab Bar") {
    @State var selectedTab = 0
    
    return VStack {
        Spacer()
        UltraCompactTabBar(selectedTab: $selectedTab)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.appBackground)
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