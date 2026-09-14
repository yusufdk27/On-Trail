//
//  WorkoutControlsView.swift
//  BeTrailWatch
//
//  Left-hand tab of in-race 3-screen navigation (Native watchOS Workout Controls pattern).
//  2x2 Action Grid:
//  • End Run (Dark Red pill + Finish Flag icon)
//  • Pause / Resume (Dark Amber pill + Pause/Play icon)
//  • Settings (Dark Gray pill + Gear icon)
//  • Water Lock (Teal/Dark Cyan pill + Water Drop icon)
//

import SwiftUI
#if os(watchOS)
import WatchKit
#endif

struct WorkoutControlsView: View {
    let strategy: RaceStrategy
    @Environment(WatchRaceCoordinator.self) private var coordinator

    var workout: WatchWorkoutManager = .shared

    @State private var showEndConfirmation: Bool = false
    @State private var showSettingsSheet: Bool = false

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 12) {
                // 2x2 Grid of Workout Control Buttons
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ],
                    spacing: 12
                ) {
                    // 1. Finish / End Run
                    workoutControlButton(
                        title: "End",
                        icon: "xmark",
                        iconColor: .white,
                        bgColor: Color(red: 0.45, green: 0.10, blue: 0.10)
                    ) {
                        showEndConfirmation = true
                    }

                    // 2. Pause / Resume
                    workoutControlButton(
                        title: workout.isRunning ? "Pause" : "Resume",
                        icon: workout.isRunning ? "pause.fill" : "play.fill",
                        iconColor: .black,
                        bgColor: workout.isRunning
                            ? Color(red: 0.95, green: 0.75, blue: 0.10)
                            : WatchTheme.neonGreen
                    ) {
                        if workout.isRunning {
                            coordinator.pauseRace()
                        } else {
                            coordinator.resumeRace()
                        }
                    }

                    // 3. Water Lock
                    workoutControlButton(
                        title: "Lock",
                        icon: "drop.fill",
                        iconColor: .white,
                        bgColor: Color(red: 0.08, green: 0.32, blue: 0.45)
                    ) {
                        #if os(watchOS)
                        WKInterfaceDevice.current().enableWaterLock()
                        #endif
                    }

                    // 4. Settings
                    workoutControlButton(
                        title: "Settings",
                        icon: "gearshape.fill",
                        iconColor: .white,
                        bgColor: Color(white: 0.22)
                    ) {
                        showSettingsSheet = true
                    }
                }
                .padding(.horizontal, 6)
                .padding(.top, 4)
            }
        }
        .background(WatchTheme.background)
        .confirmationDialog(
            "End Workout?",
            isPresented: $showEndConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Run", role: .destructive) {
                coordinator.endRace()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to finish this race?")
        }
        .sheet(isPresented: $showSettingsSheet) {
            settingsSheetView
        }
    }

    // MARK: - Action Button Component

    private func workoutControlButton(
        title: String,
        icon: String,
        iconColor: Color,
        bgColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(bgColor)
                        .frame(height: 54)

                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundStyle(WatchTheme.textPrimary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Settings Sheet

    private var settingsSheetView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Workout Settings")
                    .font(WatchTheme.preRacePrimary)
                    .foregroundStyle(WatchTheme.textPrimary)
                    .padding(.top, 4)

                Divider().background(WatchTheme.separator)

                Toggle("Pacing Haptics", isOn: .constant(true))
                    .font(WatchTheme.preRaceSecondary)
                    .tint(WatchTheme.neonGreen)

                Toggle("Voice Prompts", isOn: .constant(false))
                    .font(WatchTheme.preRaceSecondary)
                    .tint(WatchTheme.neonGreen)

                Button {
                    showSettingsSheet = false
                } label: {
                    Text("Done")
                        .font(.system(size: 15, weight: .bold, design: .default))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(WatchTheme.neonGreen)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
            .padding(.horizontal, 10)
        }
        .background(WatchTheme.background)
    }
}

// MARK: - Preview

#Preview("Workout Controls") {
    WorkoutControlsView(strategy: BeTrailMockData.slu2025Strategy)
        .environment(WatchRaceCoordinator.shared)
}
