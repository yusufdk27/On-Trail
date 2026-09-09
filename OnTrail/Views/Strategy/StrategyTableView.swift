//
//  StrategyTableView.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// Tabular strategy presentation matching Screens 2 & 4 of the native design.
/// In "Start - End" mode: Lists all CourseSegments. Tapping a row drills down to that segment.
/// In "Segment" mode: Lists the kilometer / sub-splits of the selected segment.
struct StrategyTableView: View {
    let strategy: RaceStrategy
    let focusedSegment: CourseSegment?
    var effortFactor: Double = 1.0
    var onSelectSegment: ((Int) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section Header
            Text("Strategy")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            
            // Table Container Card
            VStack(spacing: 0) {
                // Table Header Row
                HStack(spacing: 8) {
                    Text("-")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                        .frame(width: 20, alignment: .leading)
                    
                    Text("Distance")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.secondary)
                        .frame(width: 75, alignment: .leading)
                    
                    Text("Average Pace")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.secondary)
                        .frame(width: 95, alignment: .leading)
                    
                    Spacer()
                    
                    Text("Elevation")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.secondary)
                        .frame(alignment: .trailing)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                
                Divider()
                    .background(Theme.borderGray.opacity(0.4))
                
                // Table Body Rows
                if let seg = focusedSegment {
                    // Screen 4: Sub-splits within the selected segment
                    let splits = seg.splits(intervalMeters: 1000, effortFactor: effortFactor)
                    ForEach(splits) { split in
                        splitRow(split)
                    }
                } else {
                    // Screen 2: All course segments (Start - End overview)
                    ForEach(strategy.segments) { segment in
                        Button {
                            onSelectSegment?(segment.segmentIndex)
                        } label: {
                            segmentRow(segment)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.bottom, 6)
            .background(Theme.slateGray)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.cardBorder, lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 5, y: 1.5)
        }
    }
    
    // MARK: - Course Segment Row (Screen 2)
    
    private func segmentRow(_ segment: CourseSegment) -> some View {
        let adjustedPaceSecs = segment.targetPaceSecondsPerKm * effortFactor
        let paceStr = PacingZone.formatPace(adjustedPaceSecs, showUnit: false) + " /km"
        let elevM = segment.phase == .climb ? segment.elevationGain : (segment.phase == .descent ? segment.elevationLoss : segment.elevationGain)
        
        let distanceStr: String = {
            let f = NumberFormatter()
            f.numberStyle = .decimal
            f.groupingSeparator = "."
            f.maximumFractionDigits = 0
            let meters = segment.distanceKm >= 1.0 ? segment.distanceKm * 1000 : segment.distance
            let str = f.string(from: NSNumber(value: meters)) ?? String(format: "%.0f", meters)
            return "\(str) m"
        }()
        
        return HStack(spacing: 8) {
            // Phase Arrow Icon
            phaseIcon(for: segment.phase)
                .frame(width: 20, alignment: .leading)
            
            // Distance
            Text(distanceStr)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
                .frame(width: 75, alignment: .leading)
            
            // Average Pace
            Text(paceStr)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
                .frame(width: 95, alignment: .leading)
            
            Spacer()
            
            // Elevation
            Text(String(format: "%.0f m", elevM))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
                .frame(alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .contentShape(Rectangle())
    }
    
    // MARK: - Split Row (Screen 4)
    
    private func splitRow(_ split: SegmentSplit) -> some View {
        HStack(spacing: 8) {
            // Phase Arrow Icon
            phaseIcon(for: split.phase)
                .frame(width: 20, alignment: .leading)
            
            // Distance
            Text(split.distanceFormatted)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
                .frame(width: 75, alignment: .leading)
            
            // Average Pace
            Text(split.paceFormatted)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
                .frame(width: 95, alignment: .leading)
            
            Spacer()
            
            // Elevation
            Text(split.elevationFormatted)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
                .frame(alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
    }
    
    // MARK: - Phase Arrow Icon
    
    private func phaseIcon(for phase: SegmentPhase) -> some View {
        Group {
            switch phase {
            case .climb:
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.32, blue: 0.32)) // Red/Coral Climb
            case .flat:
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(red: 0.22, green: 0.78, blue: 0.42)) // Green Flat
            case .descent:
                Image(systemName: "arrow.down.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(red: 0.28, green: 0.60, blue: 0.98)) // Blue Descent
            }
        }
    }
}
