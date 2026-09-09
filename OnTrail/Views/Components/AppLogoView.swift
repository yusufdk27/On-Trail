//
//  AppLogoView.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// Minimalist vector App Logo component for On Trail.
/// Features a geometric twin-mountain silhouette with glowing neon orange pacing waveform & summit beacon.
struct AppLogoView: View {
    var size: CGFloat = 84
    var showGlow: Bool = true
    
    @State private var pulseGlow = false
    @State private var lineProgress: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            // Container background
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.08, green: 0.08, blue: 0.09),
                            Theme.background
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.22)
                        .stroke(Theme.neonOrange.opacity(pulseGlow ? 0.35 : 0.15), lineWidth: 1)
                )
                .shadow(
                    color: showGlow ? Theme.neonOrange.opacity(pulseGlow ? 0.35 : 0.15) : .clear,
                    radius: pulseGlow ? 16 : 8,
                    x: 0,
                    y: 4
                )
            
            // Geometric Mountains & Pacing Wave
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                ZStack {
                    // Subtle Topographic Lines
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: h * 0.78))
                        path.addQuadCurve(to: CGPoint(x: w, y: h * 0.72), control: CGPoint(x: w * 0.45, y: h * 0.85))
                        
                        path.move(to: CGPoint(x: 0, y: h * 0.88))
                        path.addQuadCurve(to: CGPoint(x: w, y: h * 0.82), control: CGPoint(x: w * 0.55, y: h * 0.94))
                    }
                    .stroke(Theme.borderGray.opacity(0.35), lineWidth: 1)
                    
                    // Background Mountain (Dark Slate)
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.16, y: h * 0.75))
                        path.addLine(to: CGPoint(x: w * 0.36, y: h * 0.38))
                        path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.75))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [Theme.surfaceGray.opacity(0.9), Theme.slateGray],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Foreground Main Mountain - Left Facet
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.25, y: h * 0.78))
                        path.addLine(to: CGPoint(x: w * 0.60, y: h * 0.26))
                        path.addLine(to: CGPoint(x: w * 0.60, y: h * 0.78))
                        path.closeSubpath()
                    }
                    .fill(Color(red: 0.16, green: 0.16, blue: 0.18))
                    
                    // Foreground Main Mountain - Right Facet (Shadowed)
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.60, y: h * 0.26))
                        path.addLine(to: CGPoint(x: w * 0.86, y: h * 0.78))
                        path.addLine(to: CGPoint(x: w * 0.60, y: h * 0.78))
                        path.closeSubpath()
                    }
                    .fill(Color(red: 0.10, green: 0.10, blue: 0.12))
                    
                    // Glowing Neon Orange Trail Pacing Wave
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.12, y: h * 0.70))
                        path.addLine(to: CGPoint(x: w * 0.28, y: h * 0.60))
                        path.addLine(to: CGPoint(x: w * 0.44, y: h * 0.44))
                        path.addLine(to: CGPoint(x: w * 0.60, y: h * 0.26)) // Summit
                        path.addLine(to: CGPoint(x: w * 0.70, y: h * 0.46))
                        path.addLine(to: CGPoint(x: w * 0.78, y: h * 0.40)) // Pacing pulse
                        path.addLine(to: CGPoint(x: w * 0.84, y: h * 0.54))
                        path.addLine(to: CGPoint(x: w * 0.92, y: h * 0.50))
                    }
                    .trim(from: 0, to: lineProgress)
                    .stroke(
                        Theme.neonOrange,
                        style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: Theme.neonOrange.opacity(pulseGlow ? 0.8 : 0.4), radius: size * 0.08)
                    
                    // Summit Beacon Pin / Target Point
                    if lineProgress >= 0.6 {
                        Circle()
                            .fill(Theme.neonOrange)
                            .frame(width: size * 0.09, height: size * 0.09)
                            .position(x: w * 0.60, y: h * 0.26)
                            .shadow(color: Theme.neonOrange, radius: 4)
                            .overlay(
                                Circle()
                                    .fill(.white)
                                    .frame(width: size * 0.04, height: size * 0.04)
                                    .position(x: w * 0.60, y: h * 0.26)
                            )
                            .transition(.scale)
                    }
                }
            }
            .padding(size * 0.1)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                lineProgress = 1.0
            }
            withAnimation(
                .easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
                .delay(0.5)
            ) {
                pulseGlow = true
            }
        }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        
        VStack(spacing: 30) {
            AppLogoView(size: 120)
            AppLogoView(size: 80)
            AppLogoView(size: 48)
        }
    }
}
