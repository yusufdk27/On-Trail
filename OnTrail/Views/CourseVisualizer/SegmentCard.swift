//
//  SegmentCard.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// Individual segment detail card with phase-colored accent, metrics, and strategy tips.
struct SegmentCard: View {
    let segment: CourseSegment
    let segmentNumber: Int
    
    @State private var isExpanded = false
    @State private var appeared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: Theme.spacingM) {
                    // Phase accent bar
                    RoundedRectangle(cornerRadius: 2)
                        .fill(segment.phase.color)
                        .frame(width: 4)
                        .shadow(color: segment.phase.color.opacity(0.4), radius: 4)
                    
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        // Header row
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: segment.phase.icon)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(segment.phase.color)
                                
                                Text("Segment \(segmentNumber)")
                                    .font(Theme.heading)
                                    .foregroundStyle(Theme.textPrimary)
                                
                                Text("· \(segment.phase.displayName)")
                                    .font(Theme.caption)
                                    .foregroundStyle(segment.phase.color)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.textTertiary)
                                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        }
                        
                        // Metrics row
                        HStack(spacing: Theme.spacingL) {
                            metricItem(
                                icon: "ruler",
                                value: String(format: "%.1f", segment.distanceKm),
                                unit: "km"
                            )
                            
                            metricItem(
                                icon: "arrow.up.right",
                                value: String(format: "%+.0f", segment.endElevation - segment.startElevation),
                                unit: "m"
                            )
                            
                            metricItem(
                                icon: "percent",
                                value: String(format: "%.1f", segment.averageGradient),
                                unit: "avg"
                            )
                            
                            metricItem(
                                icon: "speedometer",
                                value: segment.targetPaceFormatted,
                                unit: "/km"
                            )
                        }
                    }
                }
                .padding(Theme.spacingL)
            }
            .buttonStyle(.plain)
            
            // Expandable detail section
            if isExpanded {
                GlowingDivider(color: segment.phase.color, opacity: 0.3)
                    .padding(.horizontal, Theme.spacingL)
                
                VStack(alignment: .leading, spacing: Theme.spacingM) {
                    // Detailed metrics
                    HStack(spacing: Theme.spacingS) {
                        detailMetric(title: "Elev. Gain", value: String(format: "+%.0fm", segment.elevationGain))
                        detailMetric(title: "Elev. Loss", value: String(format: "-%.0fm", segment.elevationLoss))
                        detailMetric(title: "Max Grade", value: String(format: "%.1f%%", segment.maxGradient))
                        detailMetric(title: "Est. Time", value: segment.estimatedTimeFormatted)
                    }
                    
                    // Strategy tips
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("STRATEGY TIPS")
                            .font(Theme.smallCaption)
                            .foregroundStyle(segment.phase.color)
                            .tracking(1.2)
                        
                        ForEach(segment.phase.strategyTips.prefix(3), id: \.self) { tip in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(segment.phase.color.opacity(0.6))
                                    .frame(width: 4, height: 4)
                                    .padding(.top, 6)
                                
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
        .neonGlow(color: segment.phase.color.opacity(0.3), radius: 4)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(Double(segmentNumber) * 0.05)) {
                appeared = true
            }
        }
    }
    
    // MARK: - Subviews
    
    private func metricItem(icon: String, value: String, unit: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
            
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
            
            Text(unit)
                .font(.system(size: 10))
                .foregroundStyle(Theme.textTertiary)
        }
    }
    
    private func detailMetric(title: String, value: String) -> some View {
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
    ScrollView {
        VStack(spacing: 12) {
            SegmentCard(
                segment: CourseSegment(
                    phase: .climb,
                    trackPoints: [],
                    segmentIndex: 0,
                    targetPaceSecondsPerKm: 420
                ),
                segmentNumber: 1
            )
            SegmentCard(
                segment: CourseSegment(
                    phase: .flat,
                    trackPoints: [],
                    segmentIndex: 1,
                    targetPaceSecondsPerKm: 360
                ),
                segmentNumber: 2
            )
            SegmentCard(
                segment: CourseSegment(
                    phase: .descent,
                    trackPoints: [],
                    segmentIndex: 2,
                    targetPaceSecondsPerKm: 330
                ),
                segmentNumber: 3
            )
        }
        .padding()
    }
    .background(Theme.background)
}
