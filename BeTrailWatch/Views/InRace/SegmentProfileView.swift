//
//  SegmentProfileView.swift
//  BeTrailWatch
//
//  Phase 2 — Live Segment Profile View (Tab 2 of Digital Crown paging).
//  Matches "Activity 2" sketch.
//
//  Layout:
//  • Header  — Elapsed time (Neon Yellow large timer)
//  • Chart   — Active elevation curve: white (completed) + neon green (ahead) + red runner dot
//  • Metrics — 4/9 CLIMBS  |  3/8 DESCENTS  |  1231M CURRENT ELEVATION
//

import SwiftUI

struct SegmentProfileView: View {
    let strategy: RaceStrategy
    var store: WatchStrategyStore = .shared
    var workout: WatchWorkoutManager = .shared
    var coordinator: WatchRaceCoordinator = .shared

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            // MARK: Header — Elapsed Timer (Neon Yellow)
            Text(formatElapsed(workout.elapsedTimeSeconds))
                .font(WatchTheme.inRacePrimaryValue)
                .foregroundStyle(WatchTheme.neonYellow)
                .monospacedDigit()
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            // MARK: Active Elevation Profile Curve
            ElevationProfileCurve(
                trackPoints: strategy.allTrackPoints,
                runnerProgress: store.progressFraction,
                splitFraction: store.progressFraction
            )
            .frame(maxWidth: .infinity)
            .frame(height: 56)

            // MARK: Segment Counters + Current Elevation
            VStack(alignment: .leading, spacing: 4) {

                // 4/9 CLIMBS
                WatchMetricRow(
                    value: "\(coordinator.completedClimbs)/\(coordinator.totalClimbs)",
                    label: "CLIMBS",
                    valueColor: WatchTheme.textPrimary,
                    valueSize: 33
                )

                // 3/8 DESCENTS
                WatchMetricRow(
                    value: "\(coordinator.completedDescents)/\(coordinator.totalDescents)",
                    label: "DESCENTS",
                    valueColor: WatchTheme.textPrimary,
                    valueSize: 33
                )

                // 1231M CURRENT ELEVATION
                WatchMetricRow(
                    value: String(format: "%.0fM", store.currentElevation),
                    label: "CURRENT\nELEVATION",
                    valueColor: WatchTheme.textPrimary,
                    valueSize: 33
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(WatchTheme.background)
    }

    // MARK: - Timer Formatter

    private func formatElapsed(_ totalSeconds: Double) -> String {
        let total = Int(totalSeconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%02d:%02d,%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d,%02d", 0, minutes, seconds)
    }
}

// MARK: - Previews

#Preview("Segment Profile — 38% Progress") {
    let store: WatchStrategyStore = {
        let s = WatchStrategyStore(strategy: BeTrailMockData.slu2025Strategy)
        s.raceState = .active
        s.currentDistanceMeters = 52250 * 0.38   // ~38% of 52.25 km
        s.currentElevation = 1231
        s.actualPaceSecondsPerKm = 360
        return s
    }()
    let workout: WatchWorkoutManager = {
        let w = WatchWorkoutManager.shared
        w.elapsedTimeSeconds = 474   // 07:54
        w.heartRate = 104
        return w
    }()
    let coordinator: WatchRaceCoordinator = {
        let c = WatchRaceCoordinator.shared
        c.appState = .activeRace(BeTrailMockData.slu2025Strategy)
        return c
    }()

    SegmentProfileView(
        strategy: BeTrailMockData.slu2025Strategy,
        store: store,
        workout: workout,
        coordinator: coordinator
    )
    .frame(width: 176, height: 215)
    .background(Color.black)
}
