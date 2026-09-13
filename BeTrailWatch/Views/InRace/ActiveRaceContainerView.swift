//
//  ActiveRaceContainerView.swift
//  BeTrailWatch
//
//  In-race container using TabView(.page) for Digital Crown paging.
//  Tab 1 — TacticalHUDView (primary glanceable HUD)
//  Tab 2 — SegmentProfileView (elevation profile + segment counters)
//
//  Long press anywhere or swipe up → workout control sheet (Pause / End Run).
//

import SwiftUI

struct ActiveRaceContainerView: View {
    let strategy: RaceStrategy
    @Environment(WatchRaceCoordinator.self) private var coordinator

    var store: WatchStrategyStore = .shared
    var workout: WatchWorkoutManager = .shared

    @State private var selectedTab = 0
    @State private var showControls = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1 — Tactical HUD
            TacticalHUDView(
                strategy: strategy,
                store: store,
                workout: workout,
                coordinator: coordinator
            )
            .tag(0)
            .toolbar {
                // Workout controls accessible via Digital Crown press
                ToolbarItem(placement: .topBarLeading) {
                    workoutIndicatorButton
                }
            }

            // Tab 2 — Segment Profile
            SegmentProfileView(
                strategy: strategy,
                store: store,
                workout: workout,
                coordinator: coordinator
            )
            .tag(1)
        }
        .tabViewStyle(.page)
        .background(WatchTheme.background)
        .sheet(isPresented: $showControls) {
            workoutControlSheet
        }
        // Anti-DNF alert overlay (appears when overpacing detected)
        .overlay(alignment: .top) {
            if let alert = store.upcomingAlertMessage {
                alertBanner(message: alert)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(duration: 0.3), value: alert)
            }
        }
    }

    // MARK: - Workout Indicator Button (top-left chevron circle)

    private var workoutIndicatorButton: some View {
        Button {
            showControls = true
        } label: {
            ZStack {
                // Activity ring (partial — represents progress)
                Circle()
                    .stroke(WatchTheme.neonYellow.opacity(0.3), lineWidth: 3)
                    .frame(width: 32, height: 32)

                Circle()
                    .trim(from: 0, to: store.progressFraction)
                    .stroke(
                        WatchTheme.neonYellow,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 32, height: 32)

                // Double chevron icon
                Image(systemName: "chevron.up.2")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(WatchTheme.neonYellow)
            }
        }
        .buttonStyle(.plain)
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

    // MARK: - Workout Control Sheet

    private var workoutControlSheet: some View {
        VStack(spacing: 12) {
            Text("CONTROLS")
                .font(WatchTheme.labelFont(size: 11))
                .foregroundStyle(WatchTheme.textSecondary)
                .padding(.top, 4)

            // Pause / Resume
            Button {
                showControls = false
                if workout.isRunning {
                    coordinator.pauseRace()
                } else {
                    coordinator.resumeRace()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: workout.isRunning ? "pause.fill" : "play.fill")
                    Text(workout.isRunning ? "Pause" : "Resume")
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(workout.isRunning ? WatchTheme.neonYellow : WatchTheme.neonGreen)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            // End Run
            Button {
                showControls = false
                coordinator.endRace()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "flag.checkered")
                    Text("End Run")
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(WatchTheme.dangerRed)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .background(WatchTheme.background)
    }
}

// MARK: - Previews

#Preview("Active Race Container") {
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
