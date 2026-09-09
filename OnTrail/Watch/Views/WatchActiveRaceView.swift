//
//  WatchActiveRaceView.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// Dual-Zone Glanceable In-Race Layout for Apple Watch (1-2 Second Rule).
/// Top Zone: Real-time Mini Elevation Profile with tracking runner dot.
/// Bottom Zone: Target GAP Pace vs Actual, Heart Rate Zone, and Proactive Anti-DNF Alerts.
struct WatchActiveRaceView: View {
    let strategy: RaceStrategy
    var store: WatchStrategyStore = .shared
    var workout: WatchWorkoutManager = .shared
    
    @State private var pulseRunnerDot = false
    @State private var showingControls = false
    
    var body: some View {
        VStack(spacing: 4) {
            // MARK: - Top Zone: Mini Elevation Profile Canvas
            topElevationZone
                .frame(height: 52)
                .background(Theme.slateGray.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.borderGray.opacity(0.5), lineWidth: 1)
                )
            
            // MARK: - Bottom Zone: Target GAP vs Actual Pace & Alerts
            bottomMetricsZone
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseRunnerDot = true
            }
        }
        .sheet(isPresented: $showingControls) {
            workoutControlsSheet
        }
    }
    
    // MARK: - Top Zone (Mini Elevation Graph)
    
    private var topElevationZone: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let points = strategy.allTrackPoints
            
            if points.count > 1 {
                let minEle = points.map(\.elevation).min() ?? 0
                let maxEle = points.map(\.elevation).max() ?? 1
                let eleRange = max(1.0, maxEle - minEle)
                let totalDist = max(1.0, points.last?.distanceFromStart ?? 1.0)
                
                ZStack(alignment: .topLeading) {
                    // Course Elevation Path
                    Path { path in
                        for (index, pt) in points.enumerated() {
                            let x = (pt.distanceFromStart / totalDist) * w
                            let normY = (pt.elevation - minEle) / eleRange
                            let y = h - 6 - (normY * (h - 12))
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Theme.neonOrange, lineWidth: 2)
                    
                    // Live Runner Dot on Profile
                    let runnerX = min(w - 6, max(6, CGFloat(store.progressFraction) * w))
                    let currentNormY = (store.currentElevation - minEle) / eleRange
                    let runnerY = h - 6 - (CGFloat(max(0, min(1, currentNormY))) * (h - 12))
                    
                    Circle()
                        .fill(Theme.neonOrange)
                        .frame(width: pulseRunnerDot ? 10 : 8, height: pulseRunnerDot ? 10 : 8)
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: 1.5)
                        )
                        .shadow(color: Theme.neonOrange, radius: 4)
                        .position(x: runnerX, y: runnerY)
                    
                    // Segment Indicator Pill
                    HStack(spacing: 2) {
                        Text(store.currentSegment?.phase.displayName.uppercased() ?? "TRAIL")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(store.currentSegment?.phase.color ?? Theme.neonOrange)
                        
                        Text(String(format: "%.0fm", store.currentElevation))
                            .font(.system(size: 7, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.black.opacity(0.8))
                    .clipShape(Capsule())
                    .padding(3)
                }
            }
        }
    }
    
    // MARK: - Bottom Zone (Glanceable Pacing & Anti-DNF Alerts)
    
    private var bottomMetricsZone: some View {
        VStack(spacing: 3) {
            // Proactive Anti-DNF Alert Pill (When Active)
            if let alert = store.upcomingAlertMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text(alert)
                        .font(.system(size: 9, weight: .bold))
                        .lineLimit(1)
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity)
                .background(Theme.warningYellow)
                .clipShape(Capsule())
                .transition(.scale.combined(with: .opacity))
            }
            
            // Primary Metric: Target GAP vs Actual Pace
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("TARGET GAP")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(0.5)
                    
                    Text(PacingZone.formatPace(store.targetPace))
                        .font(.system(size: 26, weight: .black, design: .monospaced))
                        .foregroundStyle(store.isOverpacing ? Theme.neonOrange : Theme.successGreen)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 0) {
                    Text("ACTUAL")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                    
                    Text(PacingZone.formatPace(store.actualPaceSecondsPerKm))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary)
                }
            }
            .padding(.horizontal, 4)
            
            // Secondary Strip: Heart Rate Zone & Distance
            HStack {
                // Heart Rate
                HStack(spacing: 3) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(workout.currentHeartRateZone.color)
                    
                    Text(String(format: "%.0f", workout.heartRate))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(workout.currentHeartRateZone.color)
                    
                    Text(workout.currentHeartRateZone.name)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
                
                Spacer()
                
                // Distance Done
                Text(String(format: "%.1f km", store.currentDistanceMeters / 1000.0))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.horizontal, 4)
            .padding(.top, 1)
            
            // Tap for Controls
            Button {
                showingControls = true
            } label: {
                HStack(spacing: 2) {
                    Circle().fill(Theme.borderGray).frame(width: 3, height: 3)
                    Circle().fill(Theme.borderGray).frame(width: 3, height: 3)
                    Circle().fill(Theme.borderGray).frame(width: 3, height: 3)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 10)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Workout Controls Sheet
    
    private var workoutControlsSheet: some View {
        VStack(spacing: 12) {
            Text("SESSION CONTROLS")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Theme.textSecondary)
            
            Button {
                showingControls = false
                if workout.isRunning {
                    store.pauseRace()
                } else {
                    store.resumeRace()
                }
            } label: {
                HStack {
                    Image(systemName: workout.isRunning ? "pause.fill" : "play.fill")
                    Text(workout.isRunning ? "Pause" : "Resume")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(workout.isRunning ? Theme.warningYellow : Theme.successGreen)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            Button {
                showingControls = false
                store.finishRace()
            } label: {
                HStack {
                    Image(systemName: "flag.checkered")
                    Text("End Run")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(Theme.dangerRed)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
    }
}

#Preview {
    WatchActiveRaceView(
        strategy: RaceStrategy(
            courseName: "Mount Rinjani 25K",
            segments: [],
            checkpoints: [],
            allTrackPoints: []
        )
    )
    .frame(width: 180, height: 220)
    .background(Color.black)
}
