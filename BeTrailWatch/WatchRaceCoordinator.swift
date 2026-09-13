//
//  WatchRaceCoordinator.swift
//  BeTrailWatch
//
//  Unified state machine for the BeTrail watchOS app.
//  Integrates with WatchStrategyStore + WatchWorkoutManager.
//  Drives the navigation flow: Home → RouteDetail → Active Race → Post-Race.
//

import SwiftUI

// MARK: - App Navigation State

/// Top-level navigation state for the BeTrail Watch app.
@Observable
final class WatchRaceCoordinator {
    static let shared = WatchRaceCoordinator()

    enum AppState: Equatable {
        /// Idle home screen — route library browser.
        case home
        /// Pre-race route detail / confirmation.
        case routeDetail(RaceStrategy)
        /// Live race in progress.
        case activeRace(RaceStrategy)
        /// Race paused.
        case pausedRace(RaceStrategy)
        /// Post-race summary.
        case postRace(RaceStrategy)

        static func == (lhs: AppState, rhs: AppState) -> Bool {
            switch (lhs, rhs) {
            case (.home, .home): return true
            case (.routeDetail(let a), .routeDetail(let b)): return a.id == b.id
            case (.activeRace(let a), .activeRace(let b)): return a.id == b.id
            case (.pausedRace(let a), .pausedRace(let b)): return a.id == b.id
            case (.postRace(let a), .postRace(let b)): return a.id == b.id
            default: return false
            }
        }
    }

    // MARK: - State

    var appState: AppState = .home

    /// Routes available for selection. Populated from WatchConnectivity or mock data.
    var availableRoutes: [RaceStrategy] = BeTrailMockData.routes

    // MARK: - Derived Convenience

    var currentStrategy: RaceStrategy? {
        switch appState {
        case .routeDetail(let s), .activeRace(let s), .pausedRace(let s), .postRace(let s):
            return s
        case .home:
            return nil
        }
    }

    var isRaceActive: Bool {
        switch appState {
        case .activeRace, .pausedRace: return true
        default: return false
        }
    }

    // MARK: - Transitions

    /// User taps a route card — open RouteDetail.
    func selectRoute(_ strategy: RaceStrategy) {
        appState = .routeDetail(strategy)
    }

    /// User confirms Start Race in RouteDetailView.
    func startRace(with strategy: RaceStrategy) {
        // Sync strategy to the existing store/workout managers
        WatchStrategyStore.shared.strategy = strategy
        WatchStrategyStore.shared.startRace()
        AntiDNFHapticManager.shared.playPacingSuccessFeedback()
        appState = .activeRace(strategy)
    }

    /// Pause from within TacticalHUD / digital crown long press.
    func pauseRace() {
        guard case .activeRace(let s) = appState else { return }
        WatchStrategyStore.shared.pauseRace()
        appState = .pausedRace(s)
    }

    /// Resume a paused race.
    func resumeRace() {
        guard case .pausedRace(let s) = appState else { return }
        WatchStrategyStore.shared.resumeRace()
        appState = .activeRace(s)
    }

    /// End race — transition to post-race summary.
    func endRace() {
        guard let s = currentStrategy else { return }
        WatchStrategyStore.shared.finishRace()
        appState = .postRace(s)
    }

    /// Return to home from post-race or route detail.
    func returnHome() {
        appState = .home
    }

    // MARK: - Computed Pacing State

    /// Real-time pacing state based on actual vs. target pace.
    var currentPacingState: PacingState {
        let store = WatchStrategyStore.shared
        return PacingState.evaluate(
            actual: store.actualPaceSecondsPerKm,
            target: store.targetPace
        )
    }

    /// Remaining ascent in the current + upcoming segments (meters).
    var remainingAscentMeters: Double {
        guard let strategy = currentStrategy else { return 0 }
        let currentDist = WatchStrategyStore.shared.currentDistanceMeters
        return strategy.segments
            .filter { $0.phase == .climb && $0.endDistance > currentDist }
            .reduce(0) { $0 + max(0, $1.elevationGain) }
    }

    /// Segments of `.climb` type that have been completed.
    var completedClimbs: Int {
        guard let strategy = currentStrategy else { return 0 }
        let currentDist = WatchStrategyStore.shared.currentDistanceMeters
        return strategy.climbSegments.filter { $0.endDistance <= currentDist }.count
    }

    /// Total climb segments in course.
    var totalClimbs: Int {
        currentStrategy?.climbSegments.count ?? 0
    }

    /// Segments of `.descent` type that have been completed.
    var completedDescents: Int {
        guard let strategy = currentStrategy else { return 0 }
        let currentDist = WatchStrategyStore.shared.currentDistanceMeters
        return strategy.descentSegments.filter { $0.endDistance <= currentDist }.count
    }

    /// Total descent segments in course.
    var totalDescents: Int {
        currentStrategy?.descentSegments.count ?? 0
    }
}
