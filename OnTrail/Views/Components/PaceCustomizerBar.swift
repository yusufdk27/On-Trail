//
//  PaceCustomizerBar.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// A component allowing runners to customize their flat base pace,
/// dynamically recalculating Grade Adjusted Pace (GAP), segment targets, and total finish time.
struct PaceCustomizerBar: View {
    @Binding var basePaceSecondsPerKm: Double
    var onPaceChanged: ((Double) -> Void)?
    
    @State private var isExpanded: Bool = false
    
    private let presetPaces: [(label: String, seconds: Double)] = [
        ("4:30", 270),
        ("5:00", 300),
        ("5:30", 330),
        ("6:00", 360),
        ("6:30", 390),
        ("7:00", 420),
        ("7:30", 450),
        ("8:00", 480)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            // Header Button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: Theme.spacingM) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Theme.neonOrange.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.neonOrange)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BASE FLAT PACE")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.textSecondary)
                            .tracking(1.2)
                        
                        Text(PacingZone.formatPace(basePaceSecondsPerKm))
                            .font(Theme.heading)
                            .foregroundStyle(Theme.textPrimary)
                    }
                    
                    Spacer()
                    
                    Text(isExpanded ? "Tutup" : "Sesuaikan")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.neonOrange)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)
            
            // Expanded Controls
            if isExpanded {
                VStack(alignment: .leading, spacing: Theme.spacingM) {
                    GlowingDivider(opacity: 0.25)
                    
                    // Preset Pills
                    Text("PRESET PACE")
                        .font(Theme.smallCaption)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1.0)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.spacingS) {
                            ForEach(presetPaces, id: \.seconds) { preset in
                                let isSelected = abs(basePaceSecondsPerKm - preset.seconds) < 5
                                
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        basePaceSecondsPerKm = preset.seconds
                                        onPaceChanged?(preset.seconds)
                                    }
                                } label: {
                                    Text("\(preset.label)/km")
                                        .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .monospaced))
                                        .foregroundStyle(isSelected ? .white : Theme.textSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(isSelected ? Theme.neonOrange : Theme.surfaceGray)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(isSelected ? Theme.neonOrange : Color.clear, lineWidth: 1)
                                        )
                                        .shadow(color: isSelected ? Theme.neonOrange.opacity(0.4) : .clear, radius: 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Fine-Tuning Slider
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("FINE TUNING")
                                .font(Theme.smallCaption)
                                .foregroundStyle(Theme.textTertiary)
                                .tracking(1.0)
                            
                            Spacer()
                            
                            Text(PacingZone.formatPace(basePaceSecondsPerKm))
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(Theme.neonOrange)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { basePaceSecondsPerKm },
                                set: { newValue in
                                    basePaceSecondsPerKm = newValue
                                    onPaceChanged?(newValue)
                                }
                            ),
                            in: 240...540, // 4:00/km to 9:00/km
                            step: 5
                        )
                        .tint(Theme.neonOrange)
                        
                        HStack {
                            Text("4:00/km (Elit)")
                                .font(Theme.smallCaption)
                                .foregroundStyle(Theme.textTertiary)
                            Spacer()
                            Text("9:00/km (Ultra Hike)")
                                .font(Theme.smallCaption)
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Theme.spacingL)
        .background(Theme.slateGray)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge))
        .neonGlow(color: Theme.neonOrange, radius: isExpanded ? 8 : 4)
    }
}

#Preview {
    PaceCustomizerBar(basePaceSecondsPerKm: .constant(360))
        .padding()
        .background(Theme.background)
}
