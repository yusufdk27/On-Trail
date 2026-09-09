//
//  EffortSliderView.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// Effort Slider matching Screen 2 of the native design:
/// Flanked by Tortoise (easy) and Hare (challenging) icons, with a dotted step track,
/// Apple-blue active progress fill, and a white circular thumb knob.
struct EffortSliderView: View {
    @Binding var value: Double // 0.0 ... 1.0
    
    private let stepCount = 10
    
    var body: some View {
        HStack(spacing: 12) {
            // Left icon: Tortoise
            Image(systemName: "tortoise.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(uiColor: .systemGray))
            
            // Slider Track with Dots & Thumb
            GeometryReader { geo in
                let trackWidth = geo.size.width
                let trackHeight: CGFloat = 4
                let thumbWidth: CGFloat = 32
                let thumbHeight: CGFloat = 20
                let clampedValue = min(1.0, max(0.0, value))
                let thumbX = CGFloat(clampedValue) * max(1, trackWidth - thumbWidth)
                
                ZStack(alignment: .leading) {
                    // Base Inactive Track (Gray Line)
                    Capsule()
                        .fill(Color(uiColor: .systemGray5))
                        .frame(height: trackHeight)
                    
                    // Active Track Fill (Apple Blue)
                    Capsule()
                        .fill(Theme.waterBlue)
                        .frame(width: max(trackHeight, CGFloat(clampedValue) * trackWidth), height: trackHeight)
                    
                    // Dotted Step Markers Along the Track
                    HStack(spacing: 0) {
                        ForEach(0...stepCount, id: \.self) { step in
                            Circle()
                                .fill(Double(step) / Double(stepCount) <= clampedValue ? Color.white.opacity(0.9) : Color(uiColor: .systemGray4))
                                .frame(width: 3.5, height: 3.5)
                            
                            if step < stepCount {
                                Spacer()
                            }
                        }
                    }
                    .frame(height: trackHeight)
                    
                    // Draggable White Capsule Thumb Knob
                    Capsule()
                        .fill(Color.white)
                        .frame(width: thumbWidth, height: thumbHeight)
                        .overlay(
                            Capsule()
                                .stroke(Color.black.opacity(0.06), lineWidth: 0.8)
                        )
                        .shadow(color: Color.black.opacity(0.14), radius: 4, x: 0, y: 2)
                        .offset(x: thumbX)
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let fraction = gesture.location.x / max(1, trackWidth)
                            let raw = min(1.0, max(0.0, Double(fraction)))
                            // Smoothly snap or smoothly update value
                            value = (raw * 100).rounded() / 100.0
                        }
                )
            }
            .frame(height: 24)
            
            // Right icon: Hare / Cheetah (Race Effort)
            Image(systemName: "hare.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textSecondary.opacity(0.8))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ZStack {
        Color.white.ignoresSafeArea()
        EffortSliderView(value: .constant(0.4))
            .padding()
    }
}
