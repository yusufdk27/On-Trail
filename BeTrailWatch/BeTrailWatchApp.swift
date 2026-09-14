//
//  BeTrailWatchApp.swift
//  BeTrailWatch
//
//  @main entry point for the BeTrail standalone watchOS app.
//  Integrates WatchRaceCoordinator as the root state machine.
//  Navigation flow: Home → RouteDetail → ActiveRace → PostRace → Home
//

import SwiftUI

@main
struct BeTrailWatchApp: App {

    /// Shared race coordinator — drives all screen transitions.
    @State private var coordinator = WatchRaceCoordinator.shared

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(coordinator)
        }
    }
}

// MARK: - Root View (State-Driven Router)

/// Routes the app to the correct top-level view based on coordinator's AppState.
/// Uses a single NavigationStack to preserve the back-button/navigation hierarchy.
struct AppRootView: View {
    @Environment(WatchRaceCoordinator.self) private var coordinator

    var body: some View {
        Group {
            switch coordinator.appState {

            // MARK: Idle — Home
            case .home:
                NavigationStack {
                    HomeView()
                }

            // MARK: Pre-Race — Route Detail
            case .routeDetail(let strategy):
                NavigationStack {
                    HomeView()
                        .navigationDestination(isPresented: .constant(true)) {
                            RaceRouteListView()
                                .navigationDestination(isPresented: .constant(true)) {
                                    RouteDetailView(strategy: strategy)
                                }
                        }
                }

            // MARK: Pre-Race — 3-2-1 Countdown
            case .countdown(let strategy):
                WorkoutCountdownView(strategy: strategy)

            // MARK: Active Race — 3-Screen Horizontal TabView + Vertical Snapping Metrics
            case .activeRace(let strategy):
                ActiveRaceContainerView(strategy: strategy)

            // MARK: Paused Race — HUD (dimmed indicator)
            case .pausedRace(let strategy):
                ActiveRaceContainerView(strategy: strategy)
                    .overlay(
                        Text("PAUSED")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(WatchTheme.neonYellow)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(WatchTheme.neonYellow.opacity(0.2))
                            .clipShape(Capsule())
                            .padding(.top, 4),
                        alignment: .top
                    )

            // MARK: Post-Race — Summary
            case .postRace(let strategy):
                NavigationStack {
                    PostRaceSummaryView(strategy: strategy)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: coordinator.appState)
    }
}

// MARK: - Preview

#Preview("App Root — Home") {
    AppRootView()
        .environment(WatchRaceCoordinator.shared)
}

#Preview("App Root — Active Race") {
    let c = WatchRaceCoordinator.shared
    c.appState = .activeRace(BeTrailMockData.slu2025Strategy)
    return AppRootView()
        .environment(c)
}

#Preview("App Root — Post Race") {
    let c = WatchRaceCoordinator.shared
    c.appState = .postRace(BeTrailMockData.slu2025Strategy)
    return AppRootView()
        .environment(c)
}
