//
//  ElevationProfileChart.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI
import Charts

/// Interactive elevation profile chart built with Swift Charts.
/// Styled with vibrant lime-green gradient fill and clean grid markings matching Apple HIG reference.
struct ElevationProfileChart: View {
    let strategy: RaceStrategy
    var focusedSegment: CourseSegment? = nil
    @Binding var selectedDistance: Double?
    
    init(
        strategy: RaceStrategy,
        focusedSegment: CourseSegment? = nil,
        selectedDistance: Binding<Double?> = .constant(nil)
    ) {
        self.strategy = strategy
        self.focusedSegment = focusedSegment
        self._selectedDistance = selectedDistance
    }
    
    private var displayPoints: [TrackPoint] {
        if let segment = focusedSegment, !segment.trackPoints.isEmpty {
            return segment.trackPoints
        }
        return strategy.allTrackPoints
    }
    
    private var xDomain: ClosedRange<Double> {
        if let segment = focusedSegment {
            return segment.startDistance...max(segment.startDistance + 100, segment.endDistance)
        }
        return 0...max(1000, strategy.totalDistance)
    }
    
    private var yDomain: ClosedRange<Double> {
        let eleValues = displayPoints.map(\.elevation)
        let minEle = eleValues.min() ?? 0
        let maxEle = eleValues.max() ?? 100
        let padding = max(30.0, (maxEle - minEle) * 0.15)
        return max(0, minEle - padding)...(maxEle + padding)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with interactive scrub readout
            chartHeader
            
            // Chart Canvas
            Chart {
                // Main Elevation Area Fill (Lime-Green Gradient)
                ForEach(displayPoints) { point in
                    AreaMark(
                        x: .value("Distance", point.distanceFromStart),
                        y: .value("Elevation", point.elevation)
                    )
                    .foregroundStyle(Theme.chartLimeGradient)
                    .interpolationMethod(.monotone)
                    
                    LineMark(
                        x: .value("Distance", point.distanceFromStart),
                        y: .value("Elevation", point.elevation)
                    )
                    .foregroundStyle(Theme.chartLimeColor)
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                }
                
                // Checkpoints / Aid Stations Pins along elevation line
                ForEach(strategy.checkpoints) { cp in
                    if (focusedSegment == nil || (cp.distanceFromStart >= (focusedSegment?.startDistance ?? 0) && cp.distanceFromStart <= (focusedSegment?.endDistance ?? 0))),
                       let ele = cp.elevation {
                        PointMark(
                            x: .value("Distance", cp.distanceFromStart),
                            y: .value("Elevation", ele)
                        )
                        .foregroundStyle(Theme.warningYellow)
                        .symbolSize(28)
                        .annotation(position: .top, spacing: 4) {
                            Text(shortCode(cp.name))
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(Theme.warningYellow)
                                .padding(.horizontal, 3)
                                .padding(.vertical, 1)
                                .background(Color.black.opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }
                }
                
                // Interactive Scrub Rule Marker
                if let selected = selectedDistance {
                    RuleMark(x: .value("Selected", selected))
                        .foregroundStyle(Theme.neonOrange)
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    
                    if let pt = nearestPoint(to: selected) {
                        PointMark(
                            x: .value("Selected", selected),
                            y: .value("Elevation", pt.elevation)
                        )
                        .foregroundStyle(Theme.neonOrange)
                        .symbolSize(42)
                    }
                }
            }
            .chartXScale(domain: xDomain)
            .chartYScale(domain: yDomain)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisValueLabel {
                        if let dist = value.as(Double.self) {
                            Text(String(format: "%.0fkm", dist / 1000.0))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Theme.borderGray.opacity(0.4))
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
                    AxisValueLabel {
                        if let ele = value.as(Double.self) {
                            Text(String(format: "%.0fm", ele))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Theme.borderGray.opacity(0.3))
                }
            }
            .chartXSelection(value: $selectedDistance)
            .frame(height: 175)
        }
        .padding(12)
        .background(Theme.slateGray)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
    
    // MARK: - Header
    
    private var chartHeader: some View {
        HStack {
            if let selected = selectedDistance, let pt = nearestPoint(to: selected) {
                HStack(spacing: 8) {
                    Text(String(format: "%.1f km", selected / 1000.0))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.neonOrange)
                    
                    Text("·")
                        .foregroundStyle(Theme.textTertiary)
                    
                    Text(String(format: "%.0f m", pt.elevation))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary)
                    
                    if let seg = strategy.segment(at: selected) {
                        Text("(\(seg.phase.displayName))")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(seg.phase.color)
                    }
                }
            } else {
                Text("ELEVATION PROFILE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .tracking(1.0)
            }
            
            Spacer()
            
            // Min / Max stats
            HStack(spacing: 4) {
                Text(String(format: "%.0fm", yDomain.lowerBound))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.textTertiary)
                Text("–")
                    .foregroundStyle(Theme.textTertiary)
                Text(String(format: "%.0fm", yDomain.upperBound))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func nearestPoint(to distance: Double) -> TrackPoint? {
        displayPoints.min(by: {
            abs($0.distanceFromStart - distance) < abs($1.distanceFromStart - distance)
        })
    }
    
    private func shortCode(_ name: String) -> String {
        if let match = name.range(of: #"WS\s*0?(\d+)"#, options: .regularExpression) {
            return String(name[match]).replacingOccurrences(of: " ", with: "")
        }
        if name.lowercased().contains("start") { return "START" }
        if name.lowercased().contains("finish") { return "FIN" }
        return String(name.prefix(4)).uppercased()
    }
}
