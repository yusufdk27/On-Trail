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
            // Section Header (Apple Fitness style)
            HStack(spacing: 6) {
                Text("Strategy")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.secondary.opacity(0.6))
                Spacer()
            }
            
            // Table Container Card
            VStack(spacing: 0) {
                // Table Header Row
                HStack(spacing: 8) {
                    Text("-")
                        .font(Theme.trailTableHeader)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 22, alignment: .leading)
                    
                    Text("Distance")
                        .font(Theme.trailTableHeader)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 85, alignment: .leading)
                    
                    Text("Average Pace")
                        .font(Theme.trailTableHeader)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 110, alignment: .leading)
                    
                    Spacer()
                    
                    Text("Elevation")
                        .font(Theme.trailTableHeader)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                    .background(Theme.borderGray.opacity(0.35))
                
                // Table Body Rows
                if let seg = focusedSegment {
                    // Screen 4: Sub-splits within the selected segment
                    let splits = seg.splits(intervalMeters: 1000, effortFactor: effortFactor)
                    ForEach(Array(splits.enumerated()), id: \.element.id) { index, split in
                        splitRow(split)
                        
                        if index < splits.count - 1 {
                            Divider()
                                .background(Theme.borderGray.opacity(0.35))
                        }
                    }
                } else {
                    // Screen 2: All course segments (Start - End overview)
                    ForEach(Array(strategy.segments.enumerated()), id: \.element.id) { index, segment in
                        Button {
                            onSelectSegment?(segment.segmentIndex)
                        } label: {
                            segmentRow(segment)
                        }
                        .buttonStyle(.plain)
                        
                        if index < strategy.segments.count - 1 {
                            Divider()
                                .background(Theme.borderGray.opacity(0.35))
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            .background(Theme.slateGray)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusCard, style: .continuous)
                    .stroke(Theme.cardBorder, lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
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
                .frame(width: 22, alignment: .leading)
            
            // Distance
            Text(distanceStr)
                .font(Theme.trailTableValue)
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
                .frame(width: 85, alignment: .leading)
            
            // Average Pace
            Text(paceStr)
                .font(Theme.trailTableValue)
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
                .frame(width: 110, alignment: .leading)
            
            Spacer()
            
            // Elevation
            Text(String(format: "%.0f m", elevM))
                .font(Theme.trailTableValue)
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
                .frame(alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
    
    // MARK: - Split Row (Screen 4)
    
    private func splitRow(_ split: SegmentSplit) -> some View {
        HStack(spacing: 8) {
            // Phase Arrow Icon
            phaseIcon(for: split.phase)
                .frame(width: 22, alignment: .leading)
            
            // Distance
            Text(split.distanceFormatted)
                .font(Theme.trailTableValue)
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
                .frame(width: 85, alignment: .leading)
            
            // Average Pace
            Text(split.paceFormatted)
                .font(Theme.trailTableValue)
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
                .frame(width: 110, alignment: .leading)
            
            Spacer()
            
            // Elevation
            Text(split.elevationFormatted)
                .font(Theme.trailTableValue)
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
                .frame(alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    // MARK: - Phase Arrow Icon
    
    private func phaseIcon(for phase: SegmentPhase) -> some View {
        Group {
            switch phase {
            case .climb:
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.phaseClimb)
            case .flat:
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.phaseFlat)
            case .descent:
                Image(systemName: "arrow.down.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.phaseDescent)
            }
        }
    }
}
