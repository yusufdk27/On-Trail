//
//  WorkoutCountdownView.swift
//  BeTrailWatch
//
//  Pre-race 3-2-1 countdown screen matching native watchOS Workout app UX.
//  Features:
//  • Full screen True Black background
//  • Animated thick Neon Green progress ring with rounded line caps
//  • Large bold numbers (3 -> 2 -> 1) with haptic feedback on each tick
//  • Tap anywhere to skip countdown directly into active race
//  • Seamless transition to HKWorkoutSession and ActiveRaceContainerView
//

import SwiftUI
#if os(watchOS)
import WatchKit
#endif

struct WorkoutCountdownView: View {
    let strategy: RaceStrategy
    @Environment(WatchRaceCoordinator.self) private var coordinator

    @State private var countRemaining: Int = 3
    @State private var ringProgress: Double = 1.0
    @State private var timerTask: Task<Void, Never>? = nil

    private let totalCountdown: Double = 3.0

    var body: some View {
        ZStack {
            // True Black background
            WatchTheme.background
                .ignoresSafeArea()

            // Central Progress Ring + Big Number
            ZStack {
                // Background track ring
                Circle()
                    .stroke(
                        WatchTheme.neonGreen.opacity(0.2),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )

                // Active countdown progress ring (animates counter-clockwise or clockwise)
                Circle()
                    .trim(from: 0.0, to: max(0.0, ringProgress))
                    .stroke(
                        WatchTheme.neonGreen,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: ringProgress)

                // Countdown Number (3 -> 2 -> 1)
                Text("\(countRemaining)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .id(countRemaining)
            }
            .frame(width: 130, height: 130)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            skipAndStartRace()
        }
        .onAppear {
            startCountdownSequence()
        }
        .onDisappear {
            timerTask?.cancel()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Countdown Logic

    private func startCountdownSequence() {
        playHaptic()
        timerTask?.cancel()

        timerTask = Task { @MainActor in
            // Tick 3 -> 2
            ringProgress = 2.0 / totalCountdown
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if Task.isCancelled { return }

            countRemaining = 2
            playHaptic()
            ringProgress = 1.0 / totalCountdown

            // Tick 2 -> 1
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if Task.isCancelled { return }

            countRemaining = 1
            playHaptic()
            ringProgress = 0.0

            // Tick 1 -> 0 (Start Race)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if Task.isCancelled { return }

            finishCountdown()
        }
    }

    private func skipAndStartRace() {
        timerTask?.cancel()
        finishCountdown()
    }

    private func finishCountdown() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.start)
        #endif
        coordinator.startRace(with: strategy)
    }

    private func playHaptic() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.start)
        #endif
    }
}

// MARK: - Previews

#Preview("Countdown") {
    WorkoutCountdownView(strategy: BeTrailMockData.slu2025Strategy)
        .environment(WatchRaceCoordinator.shared)
}
