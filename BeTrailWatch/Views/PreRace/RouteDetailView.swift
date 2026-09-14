//
//  RouteDetailView.swift
//  BeTrailWatch
//
//  Vertical paged detail view for a selected race route.
//  Page 1 — GPX map outline + Time & Distance metrics
//  Page 2 — Elevation Gain & Loss + Elevation Profile chart
//  Page 3 — "Start Race" CTA (neon green capsule, triggers HKWorkoutSession)
//
//  Matches the UI sketch: Route Detail / Route Detail 2 / Route Detail 3.
//

import SwiftUI

struct RouteDetailView: View {
    let strategy: RaceStrategy
    @Environment(WatchRaceCoordinator.self) private var coordinator

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 0) {
                // Page 1 — Map + Key Stats
                page1
                    .frame(minHeight: pageHeight)
            }
        }
        .background(WatchTheme.background)
        .navigationTitle(strategy.courseName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Dynamic page height

    private var pageHeight: CGFloat {
        // On 45mm/49mm watch, content area ≈ 195pt
        // Use a comfortable height that shows next page peeking
        WKInterfaceDeviceHelper.screenHeight - 30
    }

    // MARK: - Page 1: GPX Map + Time & Distance

    private var page1: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Large GPX Route Outline
            GPXMapOutline(
                trackPoints: strategy.allTrackPoints,
                color: WatchTheme.neonGreen,
                lineWidth: 2.5
            )
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .padding(.horizontal, 8)
            .padding(.top, 8)

            Divider().background(WatchTheme.separator).padding(.horizontal, 12)

            // Time
            metricStatRow(
                value: strategy.estimatedFinishTimeFormatted,
                label: "Time",
                icon: "clock",
                iconColor: WatchTheme.textSecondary
            )

            Divider().background(WatchTheme.separator).padding(.horizontal, 12)

            // Distance
            metricStatRow(
                value: String(format: "%.2f km", strategy.totalDistanceKm),
                label: "Distance",
                icon: "arrow.left.and.right",
                iconColor: WatchTheme.textSecondary
            )
            
            Divider().background(WatchTheme.separator).padding(.horizontal, 12)
            
            // Elevation Gain
            metricStatRow(
                value: String(format: "%.0f m", strategy.totalElevationGain),
                label: "Elevation Gain",
                icon: "arrow.up.right",
                iconColor: WatchTheme.textSecondary
            )

            Divider().background(WatchTheme.separator).padding(.horizontal, 12)

            // Elevation Loss
            metricStatRow(
                value: String(format: "%.0f m", strategy.totalElevationLoss),
                label: "Elevation Loss",
                icon: "arrow.down.right",
                iconColor: WatchTheme.textSecondary
            )

            Divider().background(WatchTheme.separator).padding(.horizontal, 12)
            
            // Elevation Profile chart (full view)
            ElevationProfileCurve(
                trackPoints: strategy.allTrackPoints,
                curveColor: WatchTheme.neonGreen,
                fillGradient: true
            )
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            Text("Elevation Profile")
                .font(WatchTheme.preRaceSecondary)
                .foregroundStyle(WatchTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)

            Spacer()

            // Start Race CTA — neon green capsule (triggers 3-2-1 countdown)
            Button {
                coordinator.startCountdown(for: strategy)
            } label: {
                Text("Start Race")
                    .font(.system(size: 17, weight: .bold, design: .default))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(WatchTheme.neonGreen)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Shared Stat Row

    private func metricStatRow(
        value: String,
        label: String,
        icon: String,
        iconColor: Color
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(WatchTheme.preRacePrimary)
                    .foregroundStyle(WatchTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(label)
                    .font(WatchTheme.preRaceSecondary)
                    .foregroundStyle(WatchTheme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(iconColor)
        }
        .padding(.horizontal, 12)
    }
}

// MARK: - Elevation Profile Curve

/// Renders a smooth neon green elevation curve from track point data.
/// Optionally fills the area below the curve with a gradient.
struct ElevationProfileCurve: View {
    let trackPoints: [TrackPoint]
    var curveColor: Color = WatchTheme.neonGreen
    var fillGradient: Bool = false

    // Optional runner position (0...1) and split point (0...1)
    var runnerProgress: Double? = nil   // nil = no dot
    var splitFraction: Double? = nil    // fraction where completed/remaining splits

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            if trackPoints.count > 1 {
                let minEle = trackPoints.map(\.elevation).min() ?? 0
                let maxEle = trackPoints.map(\.elevation).max() ?? 1
                let eleRange = max(1.0, maxEle - minEle)
                let totalDist = max(1.0, trackPoints.last?.distanceFromStart ?? 1.0)

                // Compute normalized curve points
                let pts: [CGPoint] = trackPoints.map { pt in
                    let x = CGFloat(pt.distanceFromStart / totalDist) * w
                    let normY = CGFloat((pt.elevation - minEle) / eleRange)
                    let y = h - 2 - normY * (h - 4)
                    return CGPoint(x: x, y: y)
                }

                ZStack {
                    // Optional fill gradient below curve
                    if fillGradient {
                        Path { path in
                            guard let first = pts.first, let last = pts.last else { return }
                            path.move(to: CGPoint(x: first.x, y: h))
                            for pt in pts { path.addLine(to: pt) }
                            path.addLine(to: CGPoint(x: last.x, y: h))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [curveColor.opacity(0.25), curveColor.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }

                    // Completed portion (white) vs remaining (neon green)
                    if let split = splitFraction {
                        let splitIdx = Int(split * Double(pts.count))
                        let completed = Array(pts.prefix(splitIdx + 1))
                        let remaining = Array(pts.suffix(pts.count - splitIdx))

                        // White: completed
                        smoothPath(pts: completed)
                            .stroke(.white, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                        // Neon Green: remaining
                        smoothPath(pts: remaining)
                            .stroke(curveColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    } else {
                        // Full neon green curve
                        smoothPath(pts: pts)
                            .stroke(curveColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    }

                    // Optional runner dot
                    if let progress = runnerProgress {
                        let dotIdx = min(pts.count - 1, Int(progress * Double(pts.count)))
                        let dotPt = pts[dotIdx]
                        Circle()
                            .fill(Color.red)
                            .frame(width: 9, height: 9)
                            .overlay(Circle().stroke(.white, lineWidth: 1.5))
                            .shadow(color: .red.opacity(0.8), radius: 4)
                            .position(x: dotPt.x, y: dotPt.y)
                    }
                }
            } else {
                // Fallback placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(WatchTheme.cardSurface)
            }
        }
    }

    /// Build a smooth path through the points using Catmull-Rom-style quadratic bezier approximation.
    private func smoothPath(pts: [CGPoint]) -> Path {
        Path { path in
            guard pts.count > 1 else { return }
            path.move(to: pts[0])
            for i in 1..<pts.count {
                let prev = pts[i - 1]
                let curr = pts[i]
                let mid = CGPoint(x: (prev.x + curr.x) / 2, y: (prev.y + curr.y) / 2)
                path.addQuadCurve(to: mid, control: prev)
            }
            if let last = pts.last { path.addLine(to: last) }
        }
    }
}

// MARK: - Device Height Helper

private enum WKInterfaceDeviceHelper {
    /// Approximate usable screen height for Apple Watch (45mm ≈ 198pt, 49mm Ultra ≈ 215pt).
    static var screenHeight: CGFloat {
        // We can't import WatchKit in previews; use a reasonable default.
        #if os(watchOS)
        return WKInterfaceDevice.current().screenBounds.height
        #else
        return 195
        #endif
    }
}

// MARK: - Previews

#Preview("Route Detail — Page 1") {
    NavigationStack {
        RouteDetailView(strategy: BeTrailMockData.slu2025Strategy)
            .environment(WatchRaceCoordinator.shared)
    }
    .frame(width: 180, height: 224)
    .background(WatchTheme.background)
}

#Preview("Elevation Profile Curve") {
    ElevationProfileCurve(
        trackPoints: BeTrailMockData.slu2025Strategy.allTrackPoints,
        fillGradient: true,
        runnerProgress: 0.38
    )
    .frame(width: 160, height: 56)
    .background(Color.black)
}

#Preview("Elevation Profile — Split") {
    ElevationProfileCurve(
        trackPoints: BeTrailMockData.slu2025Strategy.allTrackPoints,
        runnerProgress: 0.38,
        splitFraction: 0.38
    )
    .frame(width: 160, height: 56)
    .background(Color.black)
}
