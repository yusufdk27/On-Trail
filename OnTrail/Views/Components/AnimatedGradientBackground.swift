//
//  AnimatedGradientBackground.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// An animated radial gradient background with subtle neon orange ambient glow.
struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Base pure black
            Theme.background
            
            // Animated ambient glow — top right
            RadialGradient(
                colors: [
                    Theme.neonOrange.opacity(0.05),
                    Color.clear
                ],
                center: animateGradient ? .topTrailing : UnitPoint(x: 0.8, y: 0.1),
                startRadius: 50,
                endRadius: animateGradient ? 450 : 350
            )
            
            // Secondary subtle glow — bottom left
            RadialGradient(
                colors: [
                    Theme.neonOrange.opacity(0.02),
                    Color.clear
                ],
                center: animateGradient ? UnitPoint(x: 0.2, y: 0.9) : .bottomLeading,
                startRadius: 30,
                endRadius: animateGradient ? 300 : 200
            )
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .easeInOut(duration: 6.0)
                .repeatForever(autoreverses: true)
            ) {
                animateGradient = true
            }
        }
    }
}

/// A compact version for use within cards or smaller areas.
struct SubtleGlow: View {
    var color: Color = Theme.neonOrange
    var opacity: Double = 0.08
    
    var body: some View {
        RadialGradient(
            colors: [
                color.opacity(opacity),
                Color.clear
            ],
            center: .topLeading,
            startRadius: 0,
            endRadius: 200
        )
    }
}

#Preview {
    AnimatedGradientBackground()
}
