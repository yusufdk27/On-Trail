//
//  CheckpointRow.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// Rich COROS-style Checkpoint Card with per-station time spent controls,
/// leg split summaries, arrival/departure timestamps, and COT safety status.
struct CheckpointRow: View {
    let checkpoint: Checkpoint
    var onAdjustStop: ((Int) -> Void)?
    var onTapCard: (() -> Void)?
    
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top Row: Station Type Icon, Name, Distance & COT Badge
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor.opacity(0.16))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: checkpoint.type.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(iconBackgroundColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(checkpoint.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    
                    HStack(spacing: 6) {
                        Text(String(format: "KM %.1f", checkpoint.distanceKm))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.secondary)
                        
                        if let elevation = checkpoint.elevation {
                            Text("·")
                                .foregroundStyle(Color.secondary)
                            Text(String(format: "%.0f m", elevation))
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // COT Safety Badge (if applicable)
                if let margin = checkpoint.cutOffMarginSeconds {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(cutOffColor)
                            .frame(width: 6, height: 6)
                        Text(formatMarginBadge(margin))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(cutOffColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(cutOffColor.opacity(0.14))
                    .clipShape(Capsule())
                }
            }
            
            // Leg Split Information Bar (from previous pos)
            if checkpoint.legDistanceKm > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                    
                    Text(String(format: "Sektor: %.1f km", checkpoint.legDistanceKm))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                    
                    Text("·")
                        .foregroundStyle(Color.secondary)
                    
                    Text(String(format: "+%.0fm", checkpoint.legElevationGain))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(SegmentPhase.climb.color)
                    
                    Text("·")
                        .foregroundStyle(Color.secondary)
                    
                    Text(checkpoint.legMovingDurationFormatted)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.surfaceGray)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            
            Divider()
                .background(Theme.borderGray)
            
            // Bottom Row: Arrival/Departure Timestamps & Stop Duration Stepper (COROS feature)
            HStack(alignment: .center) {
                // Timing Stack (ETA & Dep)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("TIBA:")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.secondary)
                        Text(checkpoint.estimatedArrivalFormatted)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary)
                        Text("(\(checkpoint.arrivalClockFormatted(raceStartTime: appState.raceStartTime)))")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                    }
                    
                    if checkpoint.plannedStopDurationSeconds > 0 {
                        HStack(spacing: 4) {
                            Text("BRGKT:")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.secondary)
                            Text(checkpoint.estimatedDepartureFormatted)
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Theme.textSecondary)
                            Text("(\(checkpoint.departureClockFormatted(raceStartTime: appState.raceStartTime)))")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color(uiColor: .secondaryLabel))
                        }
                    }
                }
                
                Spacer()
                
                // Time Spent Steppers (Only for aid/water stations)
                if checkpoint.type == .waterStation || checkpoint.type == .aidStation || checkpoint.type == .cutOff {
                    HStack(spacing: 6) {
                        Button {
                            onAdjustStop?(-1)
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.circle)
                        .controlSize(.mini)
                        .tint(Color.secondary)
                        .disabled(checkpoint.plannedStopDurationSeconds <= 0)
                        
                        // Stop Duration Pill (Tappable to edit)
                        Button {
                            onTapCard?()
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "timer")
                                    .font(.system(size: 9, weight: .semibold))
                                Text(checkpoint.plannedStopFormatted)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                            }
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .controlSize(.mini)
                        .tint(Theme.neonOrange)
                        
                        Button {
                            onAdjustStop?(1)
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.circle)
                        .controlSize(.mini)
                        .tint(Color.secondary)
                        
                        Button {
                            onAdjustStop?(5)
                        } label: {
                            Text("+5m")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .controlSize(.mini)
                        .tint(Theme.neonOrange)
                    }
                }
            }
        }
        .padding(14)
        .background(Theme.slateGray)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
    
    // MARK: - Computed
    
    private var iconBackgroundColor: Color {
        switch checkpoint.type {
        case .waterStation: return .blue
        case .aidStation: return Theme.successGreen
        case .cutOff: return Theme.warningYellow
        case .start: return Theme.successGreen
        case .finish: return Theme.neonOrange
        case .summit: return Theme.neonOrange
        }
    }
    
    private var cutOffColor: Color {
        guard let margin = checkpoint.cutOffMarginSeconds else { return Theme.textTertiary }
        if margin > 1800 { return Theme.successGreen }
        if margin > 0 { return Theme.warningYellow }
        return Theme.dangerRed
    }
    
    private func formatMarginBadge(_ seconds: Double) -> String {
        let mins = Int(abs(seconds)) / 60
        if seconds >= 0 {
            let hours = mins / 60
            let remainderMins = mins % 60
            if hours > 0 {
                return "+\(hours)h \(remainderMins)m aman"
            }
            return "+\(mins)m aman"
        } else {
            return "Riskan (-\(mins)m)"
        }
    }
}
