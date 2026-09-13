//
//  WatchTheme.swift
//  BeTrailWatch
//
//  BeTrail watchOS Design System.
//  Uses pure Color values (no UIColor) for OLED True Black efficiency.
//

import SwiftUI

// MARK: - Design Tokens

/// watchOS-specific design tokens for BeTrail.
/// All colors chosen for maximum legibility on OLED Apple Watch displays
/// under sunlight and mid-run glancing (1–2 second read rule).
enum WatchTheme {

    // MARK: Backgrounds
    /// True Black — maximizes OLED pixel-off efficiency.
    static let background = Color.black
    /// Deep green-tinted card surface (Home screen action cards).
    static let cardGreen = Color(red: 0.048, green: 0.118, blue: 0.040)
    /// Neutral dark card surface.
    static let cardSurface = Color(white: 0.10)
    /// Subtle separator.
    static let separator = Color(white: 0.20)

    // MARK: Accents
    /// Neon Green #30D158 — "Ahead of pace", "Start Race" CTA, primary accent.
    static let neonGreen = Color(red: 0.188, green: 0.820, blue: 0.345)
    /// Neon Yellow #FFD60A — Elapsed time, workout timer.
    static let neonYellow = Color(red: 1.0, green: 0.839, blue: 0.039)
    /// Danger Red #FF453A — "Behind pace" alert state.
    static let dangerRed = Color(red: 1.0, green: 0.271, blue: 0.227)
    /// Cyan — Route card subtitle (distance · time).
    static let cyan = Color(red: 0.247, green: 0.780, blue: 1.0)
    /// Orange — Heart rate icon accent.
    static let heartRed = Color(red: 1.0, green: 0.271, blue: 0.227)

    // MARK: Text
    static let textPrimary   = Color.white
    static let textSecondary = Color(white: 0.60)
    static let textTertiary  = Color(white: 0.40)

    // MARK: Typography Tokens (In-Race & Pre-Race)
    
    // In-Race: SF Compact Rounded, High Glanceability
    /// In-Race Primary Value — 33pt, weight .medium, design .rounded
    static let inRacePrimaryValue: Font = .system(size: 33, weight: .medium, design: .rounded)
    /// In-Race Secondary Label — 12pt, weight .medium, design .rounded
    static let inRaceSecondaryLabel: Font = .system(size: 12, weight: .medium, design: .rounded)

    // Pre-Race: SF Compact Default (.design: .default)
    /// Pre-Race Primary — 17pt, weight .bold, design .default
    static let preRacePrimary: Font = .system(size: 17, weight: .bold, design: .default)
    /// Pre-Race Secondary — 17pt, weight .regular, design .default
    static let preRaceSecondary: Font = .system(size: 17, weight: .regular, design: .default)

    // MARK: Legacy & Dynamic Font Helpers
    static func metricFont(size: CGFloat = 33, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func labelFont(size: CGFloat = 12, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func timerFont(size: CGFloat = 33, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Typography View Modifiers & Extensions

struct InRacePrimaryValueModifier: ViewModifier {
    var color: Color = .white

    func body(content: Content) -> some View {
        content
            .font(WatchTheme.inRacePrimaryValue)
            .monospacedDigit()
            .foregroundStyle(color)
            .minimumScaleFactor(0.75)
            .lineLimit(1)
    }
}

struct InRaceSecondaryLabelModifier: ViewModifier {
    var color: Color = WatchTheme.textSecondary

    func body(content: Content) -> some View {
        content
            .font(WatchTheme.inRaceSecondaryLabel)
            .foregroundStyle(color)
    }
}

struct PreRacePrimaryModifier: ViewModifier {
    var color: Color = WatchTheme.textPrimary

    func body(content: Content) -> some View {
        content
            .font(WatchTheme.preRacePrimary)
            .foregroundStyle(color)
    }
}

struct PreRaceSecondaryModifier: ViewModifier {
    var color: Color = WatchTheme.textSecondary

    func body(content: Content) -> some View {
        content
            .font(WatchTheme.preRaceSecondary)
            .foregroundStyle(color)
    }
}

extension View {
    /// In-Race Primary Value: 33pt, .medium, .rounded, monospacedDigit
    func inRacePrimaryValue(color: Color = .white) -> some View {
        modifier(InRacePrimaryValueModifier(color: color))
    }

    /// In-Race Secondary Label: 12pt, .medium, .rounded
    func inRaceSecondaryLabel(color: Color = WatchTheme.textSecondary) -> some View {
        modifier(InRaceSecondaryLabelModifier(color: color))
    }

    /// Pre-Race Primary: 17pt, .bold, .default
    func preRacePrimary(color: Color = WatchTheme.textPrimary) -> some View {
        modifier(PreRacePrimaryModifier(color: color))
    }

    /// Pre-Race Secondary: 17pt, .regular, .default
    func preRaceSecondary(color: Color = WatchTheme.textSecondary) -> some View {
        modifier(PreRaceSecondaryModifier(color: color))
    }
}

extension Font {
    static let inRacePrimaryValue = WatchTheme.inRacePrimaryValue
    static let inRaceSecondaryLabel = WatchTheme.inRaceSecondaryLabel
    static let preRacePrimary = WatchTheme.preRacePrimary
    static let preRaceSecondary = WatchTheme.preRaceSecondary
}

// MARK: - Pacing State

/// Real-time pacing state relative to the GPX strategy.
enum PacingState: Equatable {
    case onTarget
    case behind
    case ahead

    /// Color applied to the large numeric pace value.
    var valueColor: Color {
        switch self {
        case .onTarget: return .white
        case .behind:   return WatchTheme.dangerRed
        case .ahead:    return WatchTheme.neonGreen
        }
    }

    /// Short ALL-CAPS status string (top line of right label).
    var statusLabel: String {
        switch self {
        case .onTarget: return "ON TARGET"
        case .behind:   return "BEHIND"
        case .ahead:    return "AHEAD"
        }
    }

    /// Derive state from actual vs. target pace (seconds/km).
    /// Within ±15 s/km is considered on-target.
    static func evaluate(actual: Double, target: Double) -> PacingState {
        let delta = actual - target
        if delta > 15  { return .behind }
        if delta < -15 { return .ahead }
        return .onTarget
    }
}

// MARK: - Reusable MetricRow

/// Apple Watch Workout–style metric row:
/// large value on the left, 2-line uppercase label on the right.
struct WatchMetricRow: View {
    let value: String
    let label: String
    var valueColor: Color = .white
    var valueSize: CGFloat = 33

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Text(value)
                .font(.system(size: valueSize, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(valueColor)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(label)
                .font(WatchTheme.inRaceSecondaryLabel)
                .foregroundStyle(WatchTheme.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Watch Card

/// Rounded card container matching watchOS navigation list style.
struct WatchCard<Content: View>: View {
    var background: Color = WatchTheme.cardGreen
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - More Button (•••)

struct WatchMoreButton: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(WatchTheme.neonGreen.opacity(0.25))
                .frame(width: 28, height: 28)
            HStack(spacing: 2.5) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(WatchTheme.neonGreen)
                        .frame(width: 3.5, height: 3.5)
                }
            }
        }
    }
}
