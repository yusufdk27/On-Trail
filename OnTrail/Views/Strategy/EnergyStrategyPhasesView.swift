//
//  EnergyStrategyPhasesView.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// 3-Phase Energy & Target Pacing Breakdown according to Trail Running Biomechanics:
/// 1. Climb Phase: Target GAP + Glycogen conservation & power hiking.
/// 2. Descent Phase: Cadence target + Quad preservation & eccentric braking control.
/// 3. Flat/Cruising Phase: Aerobic rhythm & active recovery on runnable trail.
struct EnergyStrategyPhasesView: View {
    let strategy: RaceStrategy
    var effortFactor: Double = 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Row (Apple Fitness Style)
            HStack(spacing: 6) {
                Image(systemName: "bolt.heart.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.neonOrange)
                
                Text("STRATEGI 3-FASE TRAIL")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.secondary)
                    .tracking(0.8)
                
                Spacer()
            }
            
            VStack(spacing: 10) {
                // 1. Climb Phase Card
                phaseCard(
                    phase: .climb,
                    title: "Climb Phase (Tanjakan)",
                    badge: "Hemat Glikogen",
                    primaryMetricTitle: "PACE RIIL (PENDAKIAN)",
                    primaryMetricValue: strategy.dynamicClimbPaceFormatted(effortFactor: effortFactor),
                    secondaryMetricTitle: "TARGET GAP (USAHA)",
                    secondaryMetricValue: strategy.dynamicAverageGAPFormatted(effortFactor: effortFactor),
                    subText: "\(String(format: "%.1f km", strategy.totalClimbDistanceKm)) · +\(String(format: "%.0f m", strategy.totalElevationGain))",
                    advice: "Power-hike pada kemiringan >12-15%. Walau kecepatan riil tampak lambat di 13:00–18:00 /km, beban kardiovaskular & glikogen Anda setara lari 6:00 /km di jalan datar."
                )
                
                // 2. Descent Phase Card
                phaseCard(
                    phase: .descent,
                    title: "Descent Phase (Turunan)",
                    badge: "Quad Preservation",
                    primaryMetricTitle: "PACE RIIL (TURUNAN)",
                    primaryMetricValue: strategy.dynamicDescentPaceFormatted(effortFactor: effortFactor),
                    secondaryMetricTitle: "TARGET CADENCE",
                    secondaryMetricValue: "175-185 SPM",
                    subText: "\(String(format: "%.1f km", strategy.totalDescentDistanceKm)) · -\(String(format: "%.0f m", strategy.totalElevationLoss))",
                    advice: "Turunan trail bukan jalan raya: jangan forsir sprint. Langkah pendek dan lentur di midfoot, kendalikan rem eksentrik paha depan (quads) agar tidak kehabisan otot sebelum finish."
                )
                
                // 3. Cruising / Flat Phase Card
                phaseCard(
                    phase: .flat,
                    title: "Cruising Phase (Datar / Rolling)",
                    badge: "Efisiensi Aerobik",
                    primaryMetricTitle: "TARGET PACE DATAR",
                    primaryMetricValue: strategy.dynamicFlatPaceFormatted(effortFactor: effortFactor),
                    secondaryMetricTitle: "RITME NAPAS",
                    secondaryMetricValue: "2:2 STABIL",
                    subText: "\(String(format: "%.1f km", strategy.totalFlatDistanceKm)) Bagian Datar",
                    advice: "Pertahankan ritme lari stabil dan manfaatkan bagian datar untuk memulihkan asam laktat, hidrasi elektrolit, dan asupan energi gel/makanan padat."
                )
            }
        }
    }
    
    private func phaseCard(
        phase: SegmentPhase,
        title: String,
        badge: String,
        primaryMetricTitle: String,
        primaryMetricValue: String,
        secondaryMetricTitle: String,
        secondaryMetricValue: String,
        subText: String,
        advice: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: phase.icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(phase.color)
                    
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                }
                
                Spacer()
                
                Text(badge)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(phase.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(phase.color.opacity(0.16))
                    .clipShape(Capsule())
            }
            
            // Dual Metric Display (Actual Pace vs GAP / Cadence)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(primaryMetricTitle)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.secondary)
                        .tracking(0.5)
                    
                    Text(primaryMetricValue)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(phase.color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(secondaryMetricTitle)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.secondary)
                        .tracking(0.5)
                    
                    Text(secondaryMetricValue)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("SEKTOR")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.secondary)
                        .tracking(0.5)
                    
                    Text(subText)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }
            }
            .padding(.vertical, 4)
            
            // Advice Micro-copy
            Text(advice)
                .font(.system(size: 12))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .lineSpacing(2)
        }
        .padding(14)
        .background(Theme.slateGray)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
}
