//
//  WatchCompanionSimulatorView.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// An interactive Apple Watch Ultra chassis simulator built directly into the iOS app.
/// Allows runners and evaluators to preview the watchOS in-race glanceable experience,
/// simulate elevation progression, test proactive anti-DNF alerts, and review adherence scores.
struct WatchCompanionSimulatorView: View {
    let strategy: RaceStrategy
    @Environment(\.dismiss) private var dismiss
    
    @State private var store = WatchStrategyStore()
    @State private var isSimulatingRun = false
    @State private var simulationTimer: Timer?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: Theme.spacingL) {
                    // Header Description
                    VStack(spacing: 4) {
                        Text("APPLE WATCH ULTRA COMPANION")
                            .font(Theme.smallCaption)
                            .foregroundStyle(Theme.neonOrange)
                            .tracking(2.0)
                        
                        Text("Live In-Race Execution & Anti-DNF Engine")
                            .font(Theme.body)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.top, Theme.spacingM)
                    
                    // Apple Watch Chassis Frame
                    appleWatchChassis
                    
                    // Simulation Interactive Controls
                    simulationControlPanel
                    
                    Spacer()
                }
                .padding(.horizontal, Theme.spacingL)
            }
            .navigationTitle("Watch Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Selesai") {
                        stopSimulation()
                        dismiss()
                    }
                    .foregroundStyle(Theme.neonOrange)
                }
            }
            .onAppear {
                store.strategy = strategy
                if let firstPt = strategy.allTrackPoints.first {
                    store.currentElevation = firstPt.elevation
                }
            }
            .onDisappear {
                stopSimulation()
            }
        }
    }
    
    // MARK: - Apple Watch Ultra Chassis
    
    private var appleWatchChassis: some View {
        ZStack {
            // Titanium Case Outer Rim
            RoundedRectangle(cornerRadius: 38)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.28),
                            Color(white: 0.18),
                            Color(white: 0.24)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 252, height: 308)
                .overlay(
                    RoundedRectangle(cornerRadius: 38)
                        .stroke(Color(white: 0.38), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.8), radius: 20, x: 0, y: 10)
            
            // Bezel Screen Inset
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.black)
                .frame(width: 226, height: 280)
            
            // Watch Display Content
            ZStack {
                switch store.raceState {
                case .preRace:
                    WatchPreRunView(strategy: strategy) {
                        store.startRace()
                        startAutoSimulation()
                    }
                case .active, .paused:
                    WatchActiveRaceView(strategy: strategy, store: store)
                case .postRace:
                    WatchPostRunView(strategy: strategy, store: store) {
                        store.raceState = .preRace
                        store.currentDistanceMeters = 0
                    }
                }
            }
            .frame(width: 218, height: 272)
            .clipShape(RoundedRectangle(cornerRadius: 26))
            
            // Orange Ultra Action Button (Left side)
            Capsule()
                .fill(Theme.neonOrange)
                .frame(width: 4, height: 42)
                .offset(x: -128, y: -20)
            
            // Digital Crown (Right side)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(white: 0.35))
                .frame(width: 6, height: 50)
                .offset(x: 128, y: -30)
        }
        .padding(.vertical, Theme.spacingS)
    }
    
    // MARK: - Simulation Control Panel
    
    private var simulationControlPanel: some View {
        VStack(spacing: Theme.spacingM) {
            Text("SIMULATOR PLAYGROUND")
                .font(Theme.smallCaption)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)
            
            // Progress Scrubber
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Jarak Simulasi")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(String(format: "%.1f / %.1f km", store.currentDistanceMeters / 1000.0, strategy.totalDistanceKm))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.neonOrange)
                }
                
                Slider(
                    value: Binding(
                        get: { store.currentDistanceMeters },
                        set: { newDistance in
                            store.updateProgress(distanceMeters: newDistance)
                        }
                    ),
                    in: 0...max(1.0, strategy.totalDistanceKm * 1000.0),
                    step: 100
                )
                .tint(Theme.neonOrange)
            }
            
            // Action Buttons
            HStack(spacing: Theme.spacingM) {
                // Auto Play / Pause
                Button {
                    if isSimulatingRun {
                        stopSimulation()
                    } else {
                        if store.raceState == .preRace {
                            store.startRace()
                        }
                        startAutoSimulation()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isSimulatingRun ? "pause.fill" : "play.fill")
                        Text(isSimulatingRun ? "Pause Lari" : "Simulasi Lari")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(Theme.neonOrange)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                // Trigger Overpacing Test
                Button {
                    testOverpacingAlert()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Test Anti-DNF")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(Theme.surfaceGray)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Theme.warningYellow, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.spacingL)
        .background(Theme.slateGray)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge)
                .stroke(Theme.cardBorder, lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
    
    // MARK: - Simulation Actions
    
    private func startAutoSimulation() {
        isSimulatingRun = true
        simulationTimer?.invalidate()
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            let step = 150.0 // +150 meters per tick
            let nextDist = store.currentDistanceMeters + step
            let maxDist = strategy.totalDistanceKm * 1000.0
            
            if nextDist >= maxDist {
                store.updateProgress(distanceMeters: maxDist)
                stopSimulation()
            } else {
                store.updateProgress(distanceMeters: nextDist)
            }
        }
    }
    
    private func stopSimulation() {
        isSimulatingRun = false
        simulationTimer?.invalidate()
        simulationTimer = nil
    }
    
    private func testOverpacingAlert() {
        if store.raceState == .preRace {
            store.startRace()
        }
        WatchWorkoutManager.shared.heartRate = 176 // Zone 4-5 spike
        store.actualPaceSecondsPerKm = 280 // Faster than target
        store.isOverpacing = true
        store.upcomingAlertMessage = "OVERPACING! Slow down cadence!"
        AntiDNFHapticManager.shared.playOverpacingAlert()
    }
}

#Preview {
    WatchCompanionSimulatorView(
        strategy: RaceStrategy(
            courseName: "Mount Rinjani 25K",
            segments: [],
            checkpoints: [],
            allTrackPoints: []
        )
    )
}
