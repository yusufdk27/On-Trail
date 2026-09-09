//
//  NeonButton.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// A high-visibility CTA button with neon orange gradient and glow effect.
struct NeonButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var glowPulse = false
    
    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.spacingS) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Theme.orangeGradient
                    .opacity(isPressed ? 0.8 : 1.0)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge))
            .shadow(
                color: Theme.neonOrange.opacity(glowPulse ? 0.5 : 0.25),
                radius: glowPulse ? 16 : 8,
                x: 0,
                y: 4
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                glowPulse = true
            }
        }
    }
}

/// A secondary style button with outlined border.
struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.spacingS) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(Theme.neonOrange)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Theme.neonOrange.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(Theme.neonOrange.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
                }
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        NeonButton(title: "Import GPX File", icon: "doc.badge.plus") {}
        NeonButton(title: "Sync to Watch", icon: "applewatch.radiowaves.left.and.right") {}
        SecondaryButton(title: "Try Sample Course", icon: "map") {}
    }
    .padding()
    .background(Theme.background)
}
