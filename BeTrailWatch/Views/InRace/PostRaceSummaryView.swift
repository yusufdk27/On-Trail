//
//  PostRaceSummaryView.swift
//  BeTrailWatch
//
//  Post-race strategy adherence summary for BeTrail Watch.
//  Shows pacing adherence score, elevation gain conquered, and return-home action.
//

import SwiftUI

struct PostRaceSummaryView: View {
    let strategy: RaceStrategy
    var store: WatchStrategyStore = .shared
    var workout: WatchWorkoutManager = .shared
    @Environment(WatchRaceCoordinator.self) private var coordinator

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {

                // MARK: - Adherence Ring + Score
                ZStack {
                    Circle()
                        .stroke(WatchTheme.cardSurface, lineWidth: 6)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: store.adherenceScorePercentage / 100.0)
                        .stroke(
                            WatchTheme.neonGreen,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 80, height: 80)
                        .animation(.easeOut(duration: 1.2), value: store.adherenceScorePercentage)

                    VStack(spacing: 1) {
                        Text(String(format: "%.0f%%", store.adherenceScorePercentage))
                            .font(WatchTheme.metricFont(size: 20, weight: .black))
                            .foregroundStyle(WatchTheme.textPrimary)
                        Text("ADHERENCE")
                            .font(WatchTheme.labelFont(size: 8))
                            .foregroundStyle(WatchTheme.textTertiary)
                    }
                }
                .padding(.top, 6)

                // MARK: - Feedback Text
                Text("Great pacing — energy conservation on climbs!")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(WatchTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                // MARK: - Key Metrics
                VStack(spacing: 4) {
                    summaryRow(
                        label: "DISTANCE",
                        value: String(format: "%.2f km", store.currentDistanceMeters / 1000.0)
                    )
                    Divider().background(WatchTheme.separator)
                    summaryRow(
                        label: "ELEV. GAIN",
                        value: String(format: "+%.0f m", strategy.totalElevationGain)
                    )
                    Divider().background(WatchTheme.separator)
                    summaryRow(
                        label: "ELAPSED",
                        value: formatElapsed(workout.elapsedTimeSeconds)
                    )
                    Divider().background(WatchTheme.separator)
                    summaryRow(
                        label: "AVG PACE",
                        value: PaceStateRow.formatWatchPace(store.actualPaceSecondsPerKm)
                    )
                }
                .padding(8)
                .background(WatchTheme.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                // MARK: - Done Button
                Button {
                    coordinator.returnHome()
                } label: {
                    Text("Done")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(WatchTheme.neonGreen)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 10)
        }
        .background(WatchTheme.background)
        .navigationTitle("Summary")
    }

    // MARK: - Helpers

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(WatchTheme.labelFont(size: 10))
                .foregroundStyle(WatchTheme.textTertiary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(WatchTheme.textPrimary)
        }
    }

    private func formatElapsed(_ totalSeconds: Double) -> String {
        let total = Int(totalSeconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - Preview

#Preview("Post Race Summary") {
    NavigationStack {
        PostRaceSummaryView(
            strategy: BeTrailMockData.slu2025Strategy
        )
        .environment(WatchRaceCoordinator.shared)
    }
    .frame(width: 176, height: 215)
    .background(Color.black)
}
