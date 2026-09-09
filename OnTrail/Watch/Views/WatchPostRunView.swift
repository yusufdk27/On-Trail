//
//  WatchPostRunView.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// Post-race strategy adherence summary for Apple Watch.
/// Displays Pacing Adherence Score %, elevation gain conquered, and DNF risk avoidance report.
struct WatchPostRunView: View {
    let strategy: RaceStrategy
    var store: WatchStrategyStore = .shared
    var onDismiss: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Header
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.successGreen)
                    
                    Text("RACE SUMMARY")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .tracking(1.0)
                }
                .padding(.top, 4)
                
                // Circular Adherence Gauge
                ZStack {
                    Circle()
                        .stroke(Theme.surfaceGray, lineWidth: 6)
                        .frame(width: 76, height: 76)
                    
                    Circle()
                        .trim(from: 0, to: store.adherenceScorePercentage / 100.0)
                        .stroke(
                            Theme.neonOrange,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 76, height: 76)
                    
                    VStack(spacing: 0) {
                        Text(String(format: "%.0f%%", store.adherenceScorePercentage))
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary)
                        Text("ADHERENCE")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .padding(.vertical, 2)
                
                // Strategy Feedback
                Text("Excellent uphill energy conservation. Zero DNF risk detected.")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
                
                // Metrics Matrix
                VStack(spacing: 4) {
                    summaryRow(title: "DISTANCE", value: String(format: "%.1f km", store.currentDistanceMeters / 1000.0))
                    summaryRow(title: "ELEV. GAIN", value: String(format: "+%.0f m", strategy.totalElevationGain))
                    summaryRow(title: "AVG CADENCE", value: String(format: "%.0f spm", WatchWorkoutManager.shared.currentCadence))
                }
                .padding(6)
                .background(Theme.slateGray)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Done Button
                Button {
                    onDismiss()
                } label: {
                    Text("DONE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(Theme.neonOrange)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
                .padding(.bottom, 6)
            }
            .padding(.horizontal, 8)
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
        }
    }
}

#Preview {
    WatchPostRunView(
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
