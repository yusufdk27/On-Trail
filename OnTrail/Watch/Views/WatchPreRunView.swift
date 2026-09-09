//
//  WatchPreRunView.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// Glanceable pre-race screen for Apple Watch.
/// Displays course title, key distance/elevation stats, and a big start button.
struct WatchPreRunView: View {
    let strategy: RaceStrategy
    var onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Course Badge & Title
            HStack(spacing: 4) {
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.neonOrange)
                
                Text(strategy.courseName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
            }
            .padding(.top, 4)
            
            // Key Metrics Pill
            HStack(spacing: 6) {
                VStack(spacing: 1) {
                    Text("DISTANCE")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                    Text(String(format: "%.1f km", strategy.totalDistanceKm))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Theme.borderGray)
                    .frame(width: 1, height: 24)
                
                VStack(spacing: 1) {
                    Text("ELEV. GAIN")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                    Text(String(format: "+%.0fm", strategy.totalElevationGain))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(SegmentPhase.climb.color)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 6)
            .background(Theme.slateGray)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // ETA & Checkpoints
            HStack {
                HStack(spacing: 3) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Theme.warningYellow)
                    Text("\(strategy.checkpoints.count) WS")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 3) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Theme.neonOrange)
                    Text(strategy.estimatedFinishTimeFormatted)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.neonOrange)
                }
            }
            .padding(.horizontal, 4)
            
            Spacer()
            
            // Big Start Strategy Run Button
            Button {
                onStart()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("START STRATEGY RUN")
                        .font(.system(size: 13, weight: .black))
                        .tracking(0.5)
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(Theme.neonOrange)
                .clipShape(Capsule())
                .shadow(color: Theme.neonOrange.opacity(0.6), radius: 6)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 4)
        }
        .padding(.horizontal, 8)
        .background(Color.black.ignoresSafeArea())
    }
}

#Preview {
    WatchPreRunView(
        strategy: RaceStrategy(
            courseName: "Mount Rinjani 25K",
            segments: [],
            checkpoints: [],
            allTrackPoints: []
        )
    ) {}
    .frame(width: 180, height: 220)
    .background(Color.black)
}
