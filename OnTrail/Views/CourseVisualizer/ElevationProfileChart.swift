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
        VStack(alignment: .leading, spacing: 6) {
            // Interactive scrub readout when scrubbing
            if selectedDistance != nil {
                chartHeader
            }
            
            // Chart Canvas
            Chart {
                // Main Elevation Area Fill (Lime-Green Gradient)
                ForEach(displayPoints) { point in
                    AreaMark(
                        x: .value("Distance", point.distanceFromStart),
                        y: .value("Elevation", point.elevation)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Theme.trailLime.opacity(0.35),
                                Theme.trailLime.opacity(0.12),
                                Theme.trailLime.opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.monotone)
                    
                    LineMark(
                        x: .value("Distance", point.distanceFromStart),
                        y: .value("Elevation", point.elevation)
                    )
                    .foregroundStyle(Theme.trailLime)
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                }
                
                // Key Course Landmark Points (as seen in Image 1)
                ForEach(displayPoints.enumerated().filter { $0.offset % max(1, displayPoints.count / 4) == 0 }.map(\.element)) { pt in
                    PointMark(
                        x: .value("Distance", pt.distanceFromStart),
                        y: .value("Elevation", pt.elevation)
                    )
                    .symbol {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 6, height: 6)
                            .overlay(Circle().stroke(Theme.trailLime, lineWidth: 2))
                    }
                }
                
                // Interactive Scrub Rule Marker
                if let selected = selectedDistance {
                    RuleMark(x: .value("Selected", selected))
                        .foregroundStyle(Theme.targetOrange)
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    
                    if let pt = nearestPoint(to: selected) {
                        PointMark(
                            x: .value("Selected", selected),
                            y: .value("Elevation", pt.elevation)
                        )
                        .foregroundStyle(Theme.targetOrange)
                        .symbolSize(36)
                    }
                }
            }
            .chartXScale(domain: xDomain)
            .chartYScale(domain: yDomain)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                    AxisValueLabel {
                        if let dist = value.as(Double.self) {
                            Text(String(format: "%.0fkm", dist / 1000.0))
                                .font(Theme.trailAxisLabel)
                                .foregroundStyle(Color.secondary.opacity(0.8))
                        }
                    }
                }
            }
            .chartYAxis {
                // Left Y-Axis: Pace Reference Labels (matching Image 1: 20'00", 15'00", 10'00", etc.)
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisValueLabel {
                        if let ele = value.as(Double.self) {
                            let ratio = max(0.0, min(1.0, (ele - yDomain.lowerBound) / max(1.0, (yDomain.upperBound - yDomain.lowerBound))))
                            let paceMin = Int((1.0 - ratio) * 20.0)
                            Text(String(format: "%02d'00\"", paceMin))
                                .font(Theme.trailAxisLabel)
                                .foregroundStyle(Color.secondary.opacity(0.8))
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Theme.gridLine)
                }
                
                // Right Y-Axis: Elevation Labels (matching Image 1: 800m, 600m, 400m, etc.)
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) { value in
                    AxisValueLabel {
                        if let ele = value.as(Double.self) {
                            Text(String(format: "%.0fm", ele))
                                .font(Theme.trailAxisLabel)
                                .foregroundStyle(Color.secondary.opacity(0.8))
                        }
                    }
                }
            }
            .chartXSelection(value: $selectedDistance)
            .frame(height: 145)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Theme.slateGray)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusCard, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private var chartHeader: some View {
        if let selected = selectedDistance, let pt = nearestPoint(to: selected) {
            HStack(spacing: 8) {
                Text(String(format: "%.1f km", selected / 1000.0))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.neonOrange)
                
                Text("·")
                    .foregroundStyle(Theme.textTertiary)
                
                Text(String(format: "%.0f m", pt.elevation))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                
                if let seg = strategy.segment(at: selected) {
                    Text("(\(seg.phase.displayName))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(seg.phase.color)
                }
                
                Spacer()
            }
            .padding(.bottom, 2)
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
