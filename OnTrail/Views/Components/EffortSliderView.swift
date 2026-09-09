//
//  EffortSliderView.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// Apple Native styled continuous effort slider.
/// Gradient: Activity Green (Konservatif) → Sun Yellow (Moderate) → Flame Orange → Crimson (Challenging).
struct EffortSliderView: View {
    @Binding var value: Double // 0.0 ... 1.0
    
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let trackWidth = geo.size.width
                let trackHeight: CGFloat = 14
                let thumbWidth: CGFloat = 16
                let thumbHeight: CGFloat = 26
                
                ZStack(alignment: .leading) {
                    // Continuous Apple Fitness Activity Gradient Track
                    RoundedRectangle(cornerRadius: trackHeight / 2, style: .continuous)
                        .fill(Theme.effortGradient)
                        .frame(height: trackHeight)
                        .overlay(
                            RoundedRectangle(cornerRadius: trackHeight / 2, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                        )
                    
                    // Subtle tick marks
                    HStack {
                        ForEach(0..<7) { _ in
                            Spacer()
                            Rectangle()
                                .fill(Color.black.opacity(0.3))
                                .frame(width: 1, height: 6)
                        }
                        Spacer()
                    }
                    .frame(height: trackHeight)
                    
                    // Draggable Apple-style Thumb Indicator
                    let thumbX = CGFloat(value) * max(1, trackWidth - thumbWidth)
                    
                    ZStack {
                        // Outer thumb capsule
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(white: 0.16))
                            .frame(width: thumbWidth, height: thumbHeight)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .shadow(color: Color.black.opacity(0.6), radius: 4, y: 2)
                        
                        // Center indicator line
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 2, height: 12)
                    }
                    .offset(x: thumbX)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let clampedX = min(max(0, gesture.location.x), trackWidth)
                                let fraction = Double(clampedX / max(1, trackWidth))
                                value = min(1.0, max(0.0, fraction))
                            }
                    )
                }
                .frame(height: thumbHeight)
            }
            .frame(height: 26)
            
            // Labels below slider matching Apple Fitness standards & reference
            HStack {
                Text("Light")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.secondary)
                
                Spacer()
                
                Text("Target GAP")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.neonOrange)
                
                Spacer()
                
                Text("Challenging")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        EffortSliderView(value: .constant(0.5))
            .padding()
    }
}
