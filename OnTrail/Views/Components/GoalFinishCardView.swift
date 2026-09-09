//
//  GoalFinishCardView.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// Goal Finish Card component conforming to Apple HIG design specifications (Image 3).
/// Features Target Time badge, large digital clock, custom EffortSlider, and 3-column sub-metrics.
struct GoalFinishCardView: View {
    let strategy: RaceStrategy
    var effortFactor: Double
    var pitstopSeconds: Double
    @Binding var effortSliderValue: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Target Time Badge
            HStack(spacing: 6) {
                Image(systemName: "target")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.targetOrange)
                
                Text("Target Time")
                    .font(Theme.trailCardBadge)
                    .foregroundStyle(Theme.targetOrange)
                
                Spacer()
            }
            
            // Big Digital Clock
            let dynamicFinish = strategy.dynamicGoalFinishFormatted(
                effortFactor: effortFactor,
                pitstopSeconds: pitstopSeconds
            )
            Text(dynamicFinish)
                .font(Theme.trailClock)
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
            
            // Custom Effort Slider (Tortoise - Dotted Track - Hare)
            EffortSliderView(value: $effortSliderValue)
                .padding(.vertical, 4)
            
            // 3-Column Summary Sub-Metrics
            HStack(spacing: 8) {
                // Average Pace
                VStack(alignment: .leading, spacing: 3) {
                    Text(strategy.dynamicAveragePaceFormatted(effortFactor: effortFactor))
                        .font(Theme.trailSubmetricValue)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Average Pace")
                        .font(Theme.trailSubmetricLabel)
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Average GAP
                VStack(alignment: .leading, spacing: 3) {
                    Text(strategy.dynamicAverageGAPFormatted(effortFactor: effortFactor))
                        .font(Theme.trailSubmetricValue)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Average GAP")
                        .font(Theme.trailSubmetricLabel)
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                // Elevation
                VStack(alignment: .trailing, spacing: 3) {
                    Text(String(format: "%.0f m", strategy.totalElevationGain))
                        .font(Theme.trailSubmetricValue)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Elevation")
                        .font(Theme.trailSubmetricLabel)
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.top, 2)
        }
        .padding(18)
        .background(Theme.slateGray)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusCard, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
}
