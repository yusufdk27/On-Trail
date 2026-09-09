//
//  PacingZone.swift
//  On Trail
//
//  Created by On Trail Team.
//

import Foundation

/// Pacing configuration and Trail Running Metabolic Cost & GAP Engine.
///
/// In Trail Running:
/// - **Target GAP (Grade Adjusted Pace)** represents the runner's baseline effort equivalent on flat road.
/// - **Actual Pace** represents the real moving speed over mountain terrain, which slows down dramatically
///   on climbs (power hiking at +10% to +35%) and adapts on technical descents (quad preservation, braking).
struct PacingZone: Codable {
    
    /// User's base flat pace / target GAP in seconds per kilometer (default: 6:00/km = 360s).
    var basePaceSecondsPerKm: Double = 360
    
    // MARK: - Trail Slope Cost Multiplier
    
    /// Computes the multiplier from flat GAP effort to real trail actual pace for a given gradient percentage.
    ///
    /// Based on Minetti's metabolic energy cost equation adapted for mountain trail surfaces:
    /// - Flat (0%): ~1.04x (dirt/single-track surface coefficient)
    /// - Moderate Climb (+5% to +9%): 1.30x - 1.65x (cadence increases, stride shortens)
    /// - Steep Trail Climb (+10% to +20%): 1.70x - 2.95x (transition to power hiking)
    /// - Severe Alpine Climb (+20% to +35%): 3.00x - 4.50x (steep scrambles / switchbacks)
    /// - Gentle Descent (-3% to -7%): 0.84x - 0.88x (optimal gravity assist)
    /// - Steep / Technical Descent (-8% to -25%): 0.95x - 1.45x (braking forces, quad fatigue, rock hopping)
    static func trailCostMultiplier(for gradient: Double) -> Double {
        if gradient >= 0 {
            // Uphill: non-linear metabolic cost growth
            if gradient <= 4.0 {
                return 1.04 + (gradient * 0.05) // 0% -> 1.04, 4% -> 1.24
            } else if gradient <= 10.0 {
                // 4% -> 1.24, 10% -> 1.72
                let base4 = 1.24
                return base4 + ((gradient - 4.0) * 0.08)
            } else if gradient <= 20.0 {
                // 10% -> 1.72, 20% -> 2.92 (power-hiking territory)
                let base10 = 1.72
                return base10 + ((gradient - 10.0) * 0.12)
            } else {
                // > 20% extreme climb (e.g. 25% -> 3.67, 30% -> 4.42)
                let base20 = 2.92
                return min(base20 + ((gradient - 20.0) * 0.15), 5.0)
            }
        } else {
            // Downhill
            let absGrad = abs(gradient)
            if absGrad <= 6.0 {
                // Optimal runnable downhill: speed up to ~16% faster
                return max(0.84, 1.04 - (absGrad * 0.033))
            } else if absGrad <= 12.0 {
                // Moderate descent: braking begins to neutralize gravity advantage
                let base6 = 0.84
                return base6 + ((absGrad - 6.0) * 0.025) // -12% -> 0.99
            } else if absGrad <= 22.0 {
                // Steep technical descent: quad preservation & hazard avoidance slows runner
                let base12 = 0.99
                return base12 + ((absGrad - 12.0) * 0.035) // -20% -> 1.27
            } else {
                // Severe technical descent: careful step placement
                let base22 = 1.34
                return min(base22 + ((absGrad - 22.0) * 0.04), 2.2)
            }
        }
    }
    
    // MARK: - Actual Pace Calculation
    
    /// Calculate the realistic actual trail running pace (seconds/km) for a given gradient
    /// based on a target flat GAP.
    func actualPace(for gradient: Double, targetGAP: Double? = nil) -> Double {
        let gap = targetGAP ?? basePaceSecondsPerKm
        let multiplier = Self.trailCostMultiplier(for: gradient)
        return gap * multiplier
    }
    
    /// Calculate the equivalent Grade Adjusted Pace (flat effort equivalent)
    /// given an actual observed pace on a slope.
    static func gap(from actualPaceSecondsPerKm: Double, gradient: Double) -> Double {
        let multiplier = trailCostMultiplier(for: gradient)
        return actualPaceSecondsPerKm / max(0.4, multiplier)
    }
    
    // MARK: - Legacy Compatibility
    
    /// Grade-adjusted pace wrapper returning actual segment pace.
    func gradeAdjustedPace(for gradient: Double) -> Double {
        actualPace(for: gradient)
    }
    
    // MARK: - Formatting Helpers
    
    /// Format a pace value in seconds/km to a readable string (e.g., "6:30 /km" or "12:45 /km").
    static func formatPace(_ secondsPerKm: Double, showUnit: Bool = true) -> String {
        guard secondsPerKm > 0 && !secondsPerKm.isNaN && !secondsPerKm.isInfinite else {
            return showUnit ? "--:-- /km" : "--:--"
        }
        let totalSeconds = Int(secondsPerKm.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if showUnit {
            return String(format: "%d:%02d /km", minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    /// Format a duration in seconds to a readable string.
    static func formatDuration(_ totalSeconds: Double) -> String {
        guard totalSeconds > 0 && !totalSeconds.isNaN && !totalSeconds.isInfinite else {
            return "00:00:00"
        }
        let total = Int(totalSeconds.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
    
    /// Short duration string (e.g., "3h 45m" or "42m").
    static func formatDurationShort(_ totalSeconds: Double) -> String {
        guard totalSeconds > 0 else { return "0m" }
        let total = Int(totalSeconds.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
