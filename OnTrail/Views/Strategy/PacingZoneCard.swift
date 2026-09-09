//
//  PacingZoneCard.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// Card summarizing a pacing zone (climb/flat/descent) with metrics and tips.
struct PacingZoneCard: View {
    let phase: SegmentPhase
    let segments: [CourseSegment]
    let totalDistanceKm: Double
    let totalElevationGain: Double
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    // Phase icon and title
                    HStack(spacing: Theme.spacingS) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(phase.color.opacity(0.15))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: phase.icon)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(phase.color)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(phase.displayName) Phase")
                                .font(Theme.heading)
                                .foregroundStyle(Theme.textPrimary)
                            
                            Text("\(segments.count) segments · \(String(format: "%.1f", totalDistanceKm)) km")
                                .font(Theme.smallCaption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Average pace
                    if !segments.isEmpty {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Avg Pace")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(Theme.textTertiary)
                            Text(averagePaceFormatted)
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundStyle(phase.color)
                        }
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .padding(.leading, 4)
                }
                .padding(Theme.spacingL)
            }
            .buttonStyle(.plain)
            
            // Expanded detail
            if isExpanded {
                GlowingDivider(color: phase.color, opacity: 0.3)
                    .padding(.horizontal, Theme.spacingL)
                
                VStack(alignment: .leading, spacing: Theme.spacingM) {
                    // Metrics
                    HStack(spacing: Theme.spacingS) {
                        zoneMetric(
                            title: "Total Dist.",
                            value: String(format: "%.1f km", totalDistanceKm)
                        )
                        zoneMetric(
                            title: phase == .descent ? "Elev. Loss" : "Elev. Gain",
                            value: String(format: "%.0f m", totalElevationGain)
                        )
                        zoneMetric(
                            title: "Est. Time",
                            value: totalEstimatedTime
                        )
                    }
                    
                    // Strategy tips
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("STRATEGY")
                            .font(Theme.smallCaption)
                            .foregroundStyle(phase.color)
                            .tracking(1.2)
                        
                        ForEach(phase.strategyTips.prefix(3), id: \.self) { tip in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(phase.color.opacity(0.7))
                                    .padding(.top, 2)
                                
                                Text(tip)
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                }
                .padding(Theme.spacingL)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Theme.slateGray)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .stroke(phase.color.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Computed
    
    private var averagePaceFormatted: String {
        guard !segments.isEmpty else { return "--:--" }
        let totalPace = segments.reduce(0.0) { $0 + $1.targetPaceSecondsPerKm }
        let avg = totalPace / Double(segments.count)
        return PacingZone.formatPace(avg)
    }
    
    private var totalEstimatedTime: String {
        let total = segments.reduce(0.0) { $0 + $1.estimatedTimeSeconds }
        return PacingZone.formatDuration(total)
    }
    
    private func zoneMetric(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spacingS)
        .background(Theme.surfaceGray)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall))
    }
}

#Preview {
    VStack(spacing: 12) {
        PacingZoneCard(
            phase: .climb,
            segments: [],
            totalDistanceKm: 8.2,
            totalElevationGain: 842
        )
        PacingZoneCard(
            phase: .flat,
            segments: [],
            totalDistanceKm: 10.5,
            totalElevationGain: 0
        )
        PacingZoneCard(
            phase: .descent,
            segments: [],
            totalDistanceKm: 6.7,
            totalElevationGain: 756
        )
    }
    .padding()
    .background(Theme.background)
}
