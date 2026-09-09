//
//  SegmentPhase.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// Classifies a course segment based on its gradient.
enum SegmentPhase: String, Codable, CaseIterable, Identifiable {
    case climb
    case descent
    case flat
    
    var id: String { rawValue }
    
    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .climb: return "Climb"
        case .descent: return "Descent"
        case .flat: return "Cruising"
        }
    }
    
    /// SF Symbol icon name for each phase.
    var icon: String {
        switch self {
        case .climb: return "arrow.up.right"
        case .descent: return "arrow.down.right"
        case .flat: return "arrow.right"
        }
    }
    
    /// The accent color for each phase.
    var color: Color {
        switch self {
        case .climb: return Color(red: 1.0, green: 0.37, blue: 0.0) // Neon Orange
        case .descent: return Color(red: 0.0, green: 0.8, blue: 0.9) // Cyan
        case .flat: return Color(red: 0.2, green: 0.84, blue: 0.29) // Green
        }
    }
    
    /// Secondary gradient color for chart visualization.
    var gradientEndColor: Color {
        switch self {
        case .climb: return Color(red: 0.9, green: 0.1, blue: 0.1) // Red
        case .descent: return Color(red: 0.1, green: 0.4, blue: 0.9) // Blue
        case .flat: return Color(red: 0.0, green: 0.7, blue: 0.6) // Teal
        }
    }
    
    /// Strategy tips for each phase.
    var strategyTips: [String] {
        switch self {
        case .climb:
            return [
                "Shorten stride length, increase cadence",
                "Target cadence: 170-180 spm",
                "Power hike steep sections (>15%)",
                "Conserve energy — don't surge",
                "Lean slightly forward into the hill"
            ]
        case .descent:
            return [
                "Control cadence, engage quads",
                "Quick, light footstrikes",
                "Watch footing on technical terrain",
                "Let gravity assist — don't brake too hard",
                "Relax upper body, arms for balance"
            ]
        case .flat:
            return [
                "Maintain steady rhythm",
                "Optimize energy efficiency",
                "Focus on consistent breathing",
                "Use this section to recover",
                "Hold target pace without surging"
            ]
        }
    }
    
    /// Classify a gradient percentage into a phase.
    static func classify(gradient: Double) -> SegmentPhase {
        if gradient > 3.0 {
            return .climb
        } else if gradient < -3.0 {
            return .descent
        } else {
            return .flat
        }
    }
}
