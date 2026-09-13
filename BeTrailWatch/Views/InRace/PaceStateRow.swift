//
//  PaceStateRow.swift
//  BeTrailWatch
//
//  Reusable Apple Watch Workout–style pacing metric row.
//  Large pace value on the LEFT, 2-line uppercase status label on the RIGHT.
//  Color-coded by PacingState: white / red / neon-green.
//
//  Matches Activity, Activity Copy, Activity Copy 2 in the UI sketch.
//

import SwiftUI

// MARK: - Pace State Row

struct PaceStateRow: View {
    /// Current formatted pace string (e.g., "6'00''", "7'00''", "5'43''").
    let paceFormatted: String
    /// Target pace string shown in the right-hand label (e.g., "6'00\" / KM").
    let targetPaceFormatted: String
    /// Current pacing state — drives color and status label.
    let state: PacingState

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // LEFT: Large pace value (33pt, .medium, .rounded, monospacedDigit)
            Text(paceFormatted)
                .font(WatchTheme.inRacePrimaryValue)
                .monospacedDigit()
                .foregroundStyle(state.valueColor)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            // RIGHT: 2-line uppercase label (12pt, .medium, .rounded)
            VStack(alignment: .leading, spacing: 1) {
                Text(state.statusLabel)
                    .font(WatchTheme.inRaceSecondaryLabel)
                    .foregroundStyle(state.valueColor)

                Text(targetPaceFormatted)
                    .font(WatchTheme.inRaceSecondaryLabel)
                    .foregroundStyle(state.valueColor.opacity(0.75))
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Formatted Pace Helper

extension PaceStateRow {
    /// Build the display pace string in Watch format (e.g., "6'00''" for 360s/km).
    static func formatWatchPace(_ secondsPerKm: Double) -> String {
        guard secondsPerKm > 0 && !secondsPerKm.isNaN && !secondsPerKm.isInfinite else {
            return "--'--''"
        }
        let total = Int(secondsPerKm.rounded())
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d'%02d''", minutes, seconds)
    }

    /// Format target pace label line (e.g., "6'00\" / KM").
    static func formatTargetLabel(_ secondsPerKm: Double) -> String {
        guard secondsPerKm > 0 else { return "--'--\" / KM" }
        let total = Int(secondsPerKm.rounded())
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d'%02d\" / KM", minutes, seconds)
    }
}

// MARK: - Previews (All 3 States)

#Preview("On Target") {
    PaceStateRow(
        paceFormatted: "6'00''",
        targetPaceFormatted: "6'00\" / KM",
        state: .onTarget
    )
    .padding()
    .background(Color.black)
}

#Preview("Behind") {
    PaceStateRow(
        paceFormatted: "7'00''",
        targetPaceFormatted: "6'00\" / KM",
        state: .behind
    )
    .padding()
    .background(Color.black)
}

#Preview("Ahead") {
    PaceStateRow(
        paceFormatted: "5'43''",
        targetPaceFormatted: "6'00\" / KM",
        state: .ahead
    )
    .padding()
    .background(Color.black)
}
