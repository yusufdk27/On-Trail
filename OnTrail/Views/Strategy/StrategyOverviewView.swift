//
//  StrategyOverviewView.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// Full-screen strategy summary with pacing zone cards and energy timeline.
struct StrategyOverviewView: View {
    let strategy: RaceStrategy
    @Environment(\.dismiss) private var dismiss
    
    @State private var animateCards = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: Theme.spacingXL) {
                        // Finish time hero
                        finishTimeHero
                        
                        // Pacing zone cards
                        VStack(spacing: Theme.spacingM) {
                            Text("PACING ZONES")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.textSecondary)
                                .tracking(1.5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            PacingZoneCard(
                                phase: .climb,
                                segments: strategy.climbSegments,
                                totalDistanceKm: strategy.totalClimbDistanceKm,
                                totalElevationGain: strategy.totalElevationGain
                            )
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 20)
                            
                            PacingZoneCard(
                                phase: .flat,
                                segments: strategy.flatSegments,
                                totalDistanceKm: strategy.totalFlatDistanceKm,
                                totalElevationGain: 0
                            )
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 20)
                            
                            PacingZoneCard(
                                phase: .descent,
                                segments: strategy.descentSegments,
                                totalDistanceKm: strategy.totalDescentDistanceKm,
                                totalElevationGain: strategy.totalElevationLoss
                            )
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 20)
                        }
                        
                        // Energy management section
                        energyManagementSection
                        
                        // Race split timeline
                        splitTimelineSection
                        
                        Spacer()
                            .frame(height: Theme.spacingXL)
                    }
                    .padding(.horizontal, Theme.spacingL)
                    .padding(.top, Theme.spacingM)
                }
            }
            .navigationTitle("Race Strategy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.neonOrange)
                    .fontWeight(.semibold)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    animateCards = true
                }
            }
        }
        .presentationBackground(Theme.background)
    }
    
    // MARK: - Finish Time Hero
    
    private var finishTimeHero: some View {
        VStack(spacing: Theme.spacingM) {
            Text("ESTIMATED FINISH TIME")
                .font(Theme.caption)
                .foregroundStyle(Theme.textSecondary)
                .tracking(1.5)
            
            Text(strategy.estimatedFinishTimeFormatted)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
                .shadow(color: Theme.neonOrange.opacity(0.3), radius: 8)
            
            HStack(spacing: Theme.spacingXL) {
                VStack(spacing: 2) {
                    Text("Avg Pace")
                        .font(Theme.smallCaption)
                        .foregroundStyle(Theme.textTertiary)
                    Text(strategy.averagePaceFormatted)
                        .font(Theme.metricSmall)
                        .foregroundStyle(Theme.neonOrange)
                }
                
                Rectangle()
                    .fill(Theme.borderGray)
                    .frame(width: 1, height: 30)
                
                VStack(spacing: 2) {
                    Text("Distance")
                        .font(Theme.smallCaption)
                        .foregroundStyle(Theme.textTertiary)
                    Text(strategy.totalDistanceFormatted)
                        .font(Theme.metricSmall)
                        .foregroundStyle(Theme.textPrimary)
                }
                
                Rectangle()
                    .fill(Theme.borderGray)
                    .frame(width: 1, height: 30)
                
                VStack(spacing: 2) {
                    Text("Elev. Gain")
                        .font(Theme.smallCaption)
                        .foregroundStyle(Theme.textTertiary)
                    Text(strategy.elevationGainFormatted)
                        .font(Theme.metricSmall)
                        .foregroundStyle(SegmentPhase.climb.color)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.spacingXL)
        .background(Theme.slateGray)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge))
        .neonGlow()
    }
    
    // MARK: - Energy Management
    
    private var energyManagementSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("ENERGY MANAGEMENT")
                .font(Theme.caption)
                .foregroundStyle(Theme.textSecondary)
                .tracking(1.5)
            
            VStack(spacing: Theme.spacingS) {
                energyTip(
                    icon: "drop.fill",
                    color: Color.blue,
                    title: "Hydration",
                    detail: "Drink every 20-25 min or at each aid station"
                )
                energyTip(
                    icon: "bolt.fill",
                    color: Theme.warningYellow,
                    title: "Energy Gel",
                    detail: "Take gel every 45 min, preferably on flat sections"
                )
                energyTip(
                    icon: "heart.fill",
                    color: Theme.dangerRed,
                    title: "Heart Rate",
                    detail: "Stay in Zone 2-3 on climbs, avoid spiking above Zone 4"
                )
                energyTip(
                    icon: "figure.walk",
                    color: Theme.successGreen,
                    title: "Power Hiking",
                    detail: "Walk any climb steeper than 15% — it's more energy efficient"
                )
            }
        }
        .padding(Theme.spacingL)
        .background(Theme.slateGray)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
    }
    
    // MARK: - Split Timeline
    
    private var splitTimelineSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("SPLIT TIMELINE")
                .font(Theme.caption)
                .foregroundStyle(Theme.textSecondary)
                .tracking(1.5)
            
            ForEach(Array(strategy.segments.enumerated()), id: \.element.id) { index, segment in
                let cumulativeTime = strategy.segments.prefix(index + 1).reduce(0.0) { $0 + $1.estimatedTimeSeconds }
                
                HStack(spacing: Theme.spacingM) {
                    // Timeline dot
                    VStack(spacing: 0) {
                        Circle()
                            .fill(segment.phase.color)
                            .frame(width: 10, height: 10)
                        
                        if index < strategy.segments.count - 1 {
                            Rectangle()
                                .fill(Theme.borderGray)
                                .frame(width: 1, height: 24)
                        }
                    }
                    
                    // Segment info
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(segment.phase.displayName) \(index + 1)")
                                .font(Theme.caption)
                                .foregroundStyle(segment.phase.color)
                            
                            Text(String(format: "%.1f km · %@/km", segment.distanceKm, segment.targetPaceFormatted))
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        
                        Spacer()
                        
                        // Cumulative time
                        Text(PacingZone.formatDuration(cumulativeTime))
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
            }
        }
        .padding(Theme.spacingL)
        .background(Theme.slateGray)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
    }
    
    // MARK: - Helper
    
    private func energyTip(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(spacing: Theme.spacingM) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
            
            Spacer()
        }
        .padding(Theme.spacingM)
        .background(Theme.surfaceGray)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall))
    }
}

#Preview {
    StrategyOverviewView(
        strategy: RaceStrategy(
            courseName: "Preview",
            segments: [],
            checkpoints: [],
            allTrackPoints: []
        )
    )
}
