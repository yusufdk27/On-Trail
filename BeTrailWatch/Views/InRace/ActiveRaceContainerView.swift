//
//  ActiveRaceContainerView.swift
//  BeTrailWatch
//
//  In-race root container conforming 100% to Apple Watch Workout app navigation architecture:
//  • 3-Screen Horizontal Paging (TabView with .tabViewStyle(.page)):
//    - Left (Tag 0): WorkoutControlsView (2x2 action grid: End, Pause/Resume, Lock, Settings)
//    - Center (Tag 1, DEFAULT): WorkoutMetricsContainerView (Vertical Digital Crown scroll snapping)
//    - Right (Tag 2): WorkoutMediaView (Native NowPlayingView media controls)
//  • Full immersion: hides navigation bar and back button
//  • Anti-DNF pacing alert overlay for real-time safety
//

import SwiftUI

enum WorkoutTab: Int, Hashable {
    case controls = 0
    case metrics = 1
    case media = 2
}

struct ActiveRaceContainerView: View {
    let strategy: RaceStrategy
    @Environment(WatchRaceCoordinator.self) private var coordinator

    var store: WatchStrategyStore = .shared
    var workout: WatchWorkoutManager = .shared

    /// Tab 1 (Metrics) selected by default upon entering active race.
    @State private var selectedTab: WorkoutTab = .metrics

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 0 (Left): Workout Controls (2x2 Grid)
            WorkoutControlsView(strategy: strategy, workout: workout)
                .tag(WorkoutTab.controls)

            // Tab 1 (Center, Default): Tactical HUD + Segment Profile (Vertical Paging)
            WorkoutMetricsContainerView(
                strategy: strategy,
                store: store,
                workout: workout,
                coordinator: coordinator
            )
            .tag(WorkoutTab.metrics)

            // Tab 2 (Right): Native Media Player (NowPlayingView)
            WorkoutMediaView()
                .tag(WorkoutTab.media)
        }
        .tabViewStyle(.page)
        .background(WatchTheme.background)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        // Anti-DNF alert overlay (appears when overpacing is detected)
        .overlay(alignment: .top) {
            if let alert = store.upcomingAlertMessage {
                alertBanner(message: alert)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(duration: 0.3), value: alert)
            }
        }
    }

    // MARK: - Anti-DNF Alert Banner

    private func alertBanner(message: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 9, weight: .bold))
            Text(message)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(WatchTheme.neonYellow)
        .clipShape(Capsule())
        .padding(.horizontal, 8)
        .padding(.top, 2)
    }
}

// MARK: - Previews

#Preview("Active Race Container — Center Metrics Tab") {
    let coordinator: WatchRaceCoordinator = {
        let c = WatchRaceCoordinator.shared
        c.appState = .activeRace(BeTrailMockData.slu2025Strategy)
        return c
    }()
    return ActiveRaceContainerView(strategy: BeTrailMockData.slu2025Strategy)
        .environment(coordinator)
        .frame(width: 176, height: 215)
        .background(Color.black)
}
