//
//  TacticalHUDView.swift
//  BeTrailWatch
//
//  Phase 2 — Live Race Tactical HUD (Tab 1 of Digital Crown paging).
//  5-row glanceable layout — readable in 1–2 seconds at race pace.
//
//  Row 1: Elapsed time       — Neon Yellow "00:07,54"
//  Row 2: Pace vs Strategy   — PaceStateRow (on-target/behind/ahead)
//  Row 3: Remaining Ascent   — "400M  REMAINING↵ASCENT"
//  Row 4: Heart Rate         — "104 ❤" (no background bar)
//  Row 5: Distance           — "1,56KM"
//
//  Matches Activity / Activity Copy / Activity Copy 2 sketches.
//

import SwiftUI

struct TacticalHUDView: View {
    let strategy: RaceStrategy
    var store: WatchStrategyStore = .shared
    var workout: WatchWorkoutManager = .shared
    var coordinator: WatchRaceCoordinator = .shared

    @State private var heartPulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            // Row 1 — Elapsed Duration (Neon Yellow)
            Text(formatElapsed(workout.elapsedTimeSeconds))
                .font(WatchTheme.inRacePrimaryValue)
                .foregroundStyle(WatchTheme.neonYellow)
                .monospacedDigit()
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            // Row 2 — Live Pace vs Strategy (PaceStateRow)
            PaceStateRow(
                paceFormatted: PaceStateRow.formatWatchPace(store.actualPaceSecondsPerKm),
                targetPaceFormatted: PaceStateRow.formatTargetLabel(store.targetPace),
                state: coordinator.currentPacingState
            )

            // Row 3 — Remaining Ascent
            WatchMetricRow(
                value: remainingAscentFormatted,
                label: "REMAINING\nASCENT",
                valueColor: WatchTheme.textPrimary,
                valueSize: 33
            )

            // Row 4 — Heart Rate (bare, no background bar)
            HStack(spacing: 5) {
                Text(String(format: "%.0f", workout.heartRate))
                    .font(WatchTheme.inRacePrimaryValue)
                    .foregroundStyle(WatchTheme.textPrimary)
                    .monospacedDigit()
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)

                Image(systemName: "heart.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(WatchTheme.heartRed)
                    .scaleEffect(heartPulse ? 1.12 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                        value: heartPulse
                    )

                Spacer(minLength: 0)
            }

            // Row 5 — Distance
            Text(distanceFormatted)
                .font(WatchTheme.inRacePrimaryValue)
                .foregroundStyle(WatchTheme.textPrimary)
                .monospacedDigit()
                .minimumScaleFactor(0.75)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(WatchTheme.background)
        .onAppear {
            heartPulse = true
        }
    }

    // MARK: - Formatters

    /// Elapsed time in Apple Watch format: "00:07,54" (HH:MM,SS).
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

    /// Remaining ascent rounded to nearest 10m, formatted as "400M".
    private var remainingAscentFormatted: String {
        let ascent = coordinator.remainingAscentMeters
        let rounded = (Int(ascent) / 10) * 10
        return "\(rounded)M"
    }

    /// Distance formatted as "1,56KM" (Indonesian decimal comma style).
    private var distanceFormatted: String {
        let km = store.currentDistanceMeters / 1000.0
        let str = String(format: "%.2f", km).replacingOccurrences(of: ".", with: ",")
        return "\(str)KM"
    }
}

// MARK: - Previews (All 3 Pacing States)

private func makePreviewStore(actualPace: Double, elapsed: Double, dist: Double) -> WatchStrategyStore {
    let s = WatchStrategyStore(strategy: BeTrailMockData.slu2025Strategy)
    s.raceState = .active
    s.actualPaceSecondsPerKm = actualPace
    s.currentDistanceMeters = dist
    return s
}

private func makePreviewWorkout(elapsed: Double, hr: Double, dist: Double) -> WatchWorkoutManager {
    let w = WatchWorkoutManager.shared
    w.elapsedTimeSeconds = elapsed
    w.heartRate = hr
    w.distanceMeters = dist
    return w
}

#Preview("On Target — 6'00\"") {
    let store = makePreviewStore(actualPace: 360, elapsed: 474, dist: 1560)
    let workout = makePreviewWorkout(elapsed: 474, hr: 104, dist: 1560)
    TacticalHUDView(
        strategy: BeTrailMockData.slu2025Strategy,
        store: store,
        workout: workout,
        coordinator: {
            let c = WatchRaceCoordinator.shared
            c.appState = .activeRace(BeTrailMockData.slu2025Strategy)
            return c
        }()
    )
    .frame(width: 176, height: 215)
    .background(Color.black)
}

#Preview("Behind — 7'00\"") {
    let store = makePreviewStore(actualPace: 420, elapsed: 474, dist: 1560)
    let workout = makePreviewWorkout(elapsed: 474, hr: 104, dist: 1560)
    TacticalHUDView(
        strategy: BeTrailMockData.slu2025Strategy,
        store: store,
        workout: workout,
        coordinator: {
            let c = WatchRaceCoordinator.shared
            c.appState = .activeRace(BeTrailMockData.slu2025Strategy)
            return c
        }()
    )
    .frame(width: 176, height: 215)
    .background(Color.black)
}

#Preview("Ahead — 5'43\"") {
    let store = makePreviewStore(actualPace: 343, elapsed: 474, dist: 1560)
    let workout = makePreviewWorkout(elapsed: 474, hr: 104, dist: 1560)
    TacticalHUDView(
        strategy: BeTrailMockData.slu2025Strategy,
        store: store,
        workout: workout,
        coordinator: {
            let c = WatchRaceCoordinator.shared
            c.appState = .activeRace(BeTrailMockData.slu2025Strategy)
            return c
        }()
    )
    .frame(width: 176, height: 215)
    .background(Color.black)
}
