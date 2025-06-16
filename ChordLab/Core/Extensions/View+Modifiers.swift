//
//  View+Modifiers.swift
//  ChordLab
//
//  Custom view modifiers and extensions
//

import SwiftUI

// MARK: - Custom View Modifiers

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

struct PulseEffect: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .animation(
                Animation.easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

struct GlowEffect: ViewModifier {
    var color: Color = .blue
    var radius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius / 3)
            .shadow(color: color.opacity(0.3), radius: radius)
    }
}

// MARK: - View Extensions

extension View {
    /// Add a shake animation effect
    func shake(amount: CGFloat = 10, shakes: Int = 3, animating: Bool) -> some View {
        self.modifier(ShakeEffect(amount: amount, shakesPerUnit: shakes, animatableData: animating ? 1 : 0))
    }
    
    /// Add a pulse animation effect
    func pulse() -> some View {
        self.modifier(PulseEffect())
    }
    
    /// Add a glow effect
    func glow(color: Color = .blue, radius: CGFloat = 20) -> some View {
        self.modifier(GlowEffect(color: color, radius: radius))
    }
    
    /// Conditional modifier application
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Hide view conditionally
    func hidden(_ shouldHide: Bool) -> some View {
        self.opacity(shouldHide ? 0 : 1)
    }
    
    /// Disable with opacity
    func disabledWithOpacity(_ isDisabled: Bool, opacity: Double = 0.6) -> some View {
        self
            .disabled(isDisabled)
            .opacity(isDisabled ? opacity : 1.0)
    }
}

// MARK: - Animation Extensions

extension View {
    /// Standard spring animation
    func standardAnimation() -> some View {
        self.animation(.spring(response: 0.3, dampingFraction: 0.7), value: UUID())
    }
    
    /// Smooth animation
    func smoothAnimation() -> some View {
        self.animation(.easeInOut(duration: 0.3), value: UUID())
    }
    
    /// Bouncy animation
    func bouncyAnimation() -> some View {
        self.animation(.spring(response: 0.4, dampingFraction: 0.6), value: UUID())
    }
}

// MARK: - Layout Extensions

extension View {
    /// Center view in available space
    func centered() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Add consistent padding
    func standardPadding() -> some View {
        self.padding(16)
    }
    
    /// Add navigation bar styling
    func navigationBarStyle() -> some View {
        self
            .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Interaction Extensions

extension View {
    /// Add haptic feedback on tap
    func hapticTap(style: UIImpactFeedbackGenerator.FeedbackStyle = .light, action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            let impact = UIImpactFeedbackGenerator(style: style)
            impact.impactOccurred()
            action()
        }
    }
    
    /// Add success haptic feedback
    func successHaptic() -> some View {
        self.onAppear {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
    }
    
    /// Add error haptic feedback
    func errorHaptic() -> some View {
        self.onAppear {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.error)
        }
    }
}

// MARK: - Debug Extensions

#if DEBUG
extension View {
    /// Add debug border
    func debugBorder(_ color: Color = .red, width: CGFloat = 1) -> some View {
        self.border(color, width: width)
    }
    
    /// Print view updates
    func debugPrint(_ prefix: String = "") -> some View {
        self.onAppear {
            print("\(prefix) View appeared")
        }
    }
}
#endif