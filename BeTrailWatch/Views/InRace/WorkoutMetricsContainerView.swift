//
//  WorkoutMetricsContainerView.swift
//  BeTrailWatch
//
//  Center tab of in-race 3-screen navigation.
//  Uses vertical paged scrolling (Digital Crown / vertical swipe snapping)
//  to switch between:
//  • Screen 1 (Top): TacticalHUDView (Elapsed time, Pace vs Strategy, Ascent, HR, Distance)
//  • Screen 2 (Bottom): SegmentProfileView (Elevation curve, Climbs/Descents, Current Elevation)
//

import SwiftUI

struct WorkoutMetricsContainerView: View {
    let strategy: RaceStrategy
    var store: WatchStrategyStore = .shared
    var workout: WatchWorkoutManager = .shared
    var coordinator: WatchRaceCoordinator = .shared

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // Top Screen: Tactical Live HUD
                TacticalHUDView(
                    strategy: strategy,
                    store: store,
                    workout: workout,
                    coordinator: coordinator
                )
                .containerRelativeFrame(.vertical)

                // Bottom Screen: Segment Profile & Elevation Curve
                SegmentProfileView(
                    strategy: strategy,
                    store: store,
                    workout: workout,
                    coordinator: coordinator
                )
                .containerRelativeFrame(.vertical)
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .background(WatchTheme.background)
    }
}

// MARK: - Preview

#Preview("Metrics Container") {
    let coordinator: WatchRaceCoordinator = {
        let c = WatchRaceCoordinator.shared
        c.appState = .activeRace(BeTrailMockData.slu2025Strategy)
        return c
    }()
    return WorkoutMetricsContainerView(
        strategy: BeTrailMockData.slu2025Strategy,
        coordinator: coordinator
    )
    .frame(width: 176, height: 215)
    .background(Color.black)
}
