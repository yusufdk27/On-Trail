//
//  MetricCard.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// A reusable metric display card with title, large monospaced value, and secondary unit.
/// Built with strict line limits and scaling factors to ensure flawless mobile layouts.
struct MetricCard: View {
    let title: String
    let value: String
    var unit: String = ""
    var icon: String? = nil
    var accentColor: Color = Theme.neonOrange
    var trend: TrendDirection? = nil
    var isCompact: Bool = false
    
    enum TrendDirection {
        case up, down, neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "arrow.right"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return Theme.dangerRed
            case .down: return Theme.successGreen
            case .neutral: return Theme.textSecondary
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title row
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
                
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .tracking(1.0)
                    .lineLimit(1)
                
                Spacer()
                
                if let trend {
                    Image(systemName: trend.icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(trend.color)
                }
            }
            
            // Value + Unit row
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.slateGray)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .stroke(Theme.borderGray.opacity(0.35), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        HStack {
            MetricCard(
                title: "DISTANCE",
                value: "29.4",
                unit: "km",
                icon: "figure.run",
                accentColor: Theme.neonOrange
            )
            
            MetricCard(
                title: "ELEV. GAIN",
                value: "+1,958",
                unit: "m",
                icon: "arrow.up.right",
                accentColor: Color.orange
            )
        }
        
        HStack {
            MetricCard(
                title: "EST. FINISH",
                value: "3h 20m",
                unit: "total",
                icon: "clock.fill",
                accentColor: Theme.warningYellow
            )
            
            MetricCard(
                title: "AVG PACE",
                value: "6:48",
                unit: "/km",
                icon: "speedometer",
                accentColor: Color.blue
            )
        }
    }
    .padding()
    .background(Theme.background)
}
