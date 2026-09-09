//
//  MetricsSummaryRowView.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// 3-Column Summary Metrics row conforming to Apple HIG design specifications (Image 2).
/// Displays Distance with the signature `/:\` trail path icon, Total Ascent with dark `↗`,
/// and Total Descent with dark `↘`.
struct MetricsSummaryRowView: View {
    let strategy: RaceStrategy
    var focusedSegment: CourseSegment? = nil
    var effortFactor: Double = 1.0
    
    var body: some View {
        HStack(spacing: 0) {
            if let seg = focusedSegment {
                // Segment Mode (Screens 3 & 4)
                // 1. Distance
                VStack(alignment: .leading, spacing: 3) {
                    Text("Distance")
                        .font(Theme.trailMetricLabel)
                        .foregroundStyle(Color.secondary)
                    
                    HStack(spacing: 5) {
                        TrailPathIcon(size: 18)
                        Text(formatMeters(seg.distance))
                            .font(Theme.trailMetricValue)
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 2. Average Pace
                VStack(alignment: .leading, spacing: 3) {
                    Text("Average Pace")
                        .font(Theme.trailMetricLabel)
                        .foregroundStyle(Color.secondary)
                    
                    let adjPace = seg.targetPaceSecondsPerKm * effortFactor
                    Text(PacingZone.formatPace(adjPace, showUnit: false) + " /km")
                        .font(Theme.trailMetricValue)
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                // 3. Elevation
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Elevation")
                        .font(Theme.trailMetricLabel)
                        .foregroundStyle(Color.secondary)
                    
                    let elevM = seg.phase == .climb ? seg.elevationGain : (seg.phase == .descent ? seg.elevationLoss : seg.elevationGain)
                    Text(String(format: "%.0f m", elevM))
                        .font(Theme.trailMetricValue)
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                // Full Course Mode (Screens 1 & 2 - Image 2)
                // 1. Distance
                VStack(alignment: .leading, spacing: 3) {
                    Text("Distance")
                        .font(Theme.trailMetricLabel)
                        .foregroundStyle(Color.secondary)
                    
                    HStack(spacing: 5) {
                        TrailPathIcon(size: 18)
                        Text(String(format: "%.2f km", strategy.totalDistanceKm))
                            .font(Theme.trailMetricValue)
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 2. Total Ascent
                VStack(alignment: .leading, spacing: 3) {
                    Text("Total Ascent")
                        .font(Theme.trailMetricLabel)
                        .foregroundStyle(Color.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(String(format: "%.0f m", strategy.totalElevationGain))
                            .font(Theme.trailMetricValue)
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                // 3. Total Descent
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Total Descent")
                        .font(Theme.trailMetricLabel)
                        .foregroundStyle(Color.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.right")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(String(format: "%.0f m", strategy.totalElevationLoss))
                            .font(Theme.trailMetricValue)
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 4)
    }
    
    private func formatMeters(_ meters: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        f.maximumFractionDigits = 0
        let str = f.string(from: NSNumber(value: meters)) ?? String(format: "%.0f", meters)
        return "\(str) m"
    }
}
