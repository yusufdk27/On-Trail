//
//  Theme.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// Design system tokens for On Trail.
/// Minimalist, high-contrast, OLED-optimized dark theme.
enum Theme {
    
    // MARK: - Colors
    
    /// Adaptive background:
    /// Pure black (#000000) in Dark Mode, Apple System Grouped Background (#F2F2F7) in Light Mode.
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? .black : .systemGroupedBackground
    })
    
    /// Neon Orange accent — high visibility trail running target.
    static let neonOrange = Color(red: 1.0, green: 0.369, blue: 0.0) // #FF5E00
    
    /// Apple System Blue for action buttons (e.g. Save pill).
    static let systemBlue = Color(red: 0.0, green: 0.48, blue: 1.0)
    
    /// Slate Gray — secondary grouped background for data cards:
    /// #1C1C1E in Dark Mode, pure crisp white in Light Mode.
    static let slateGray = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
            : .secondarySystemGroupedBackground
    })
    
    /// Surface Gray — tertiary elevated surfaces:
    /// #2C2C2E in Dark Mode, #EBEBF0 in Light Mode.
    static let surfaceGray = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.173, green: 0.173, blue: 0.18, alpha: 1.0)
            : .tertiarySystemGroupedBackground
    })
    
    /// Subtle separator / border:
    static let borderGray = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.12)
            : UIColor.separator
    })
    
    /// Subtle card border for crisp card definition in both modes:
    static let cardBorder = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.10)
            : UIColor(white: 0.0, alpha: 0.06)
    })
    
    /// Primary text — high contrast (White in Dark, Black in Light).
    static let textPrimary = Color(uiColor: .label)
    
    /// Secondary text — dimmed.
    static let textSecondary = Color(uiColor: .secondaryLabel)
    
    /// Tertiary text — subtle caption.
    static let textTertiary = Color(uiColor: .tertiaryLabel)
    
    /// Success green.
    static let successGreen = Color(red: 0.196, green: 0.843, blue: 0.294) // #32D74B
    
    /// Warning yellow.
    static let warningYellow = Color(red: 1.0, green: 0.839, blue: 0.039) // #FFD60A
    
    /// Danger red.
    static let dangerRed = Color(red: 1.0, green: 0.271, blue: 0.227) // #FF453A
    
    /// Cyan for descent phases.
    static let cyan = Color(red: 0.0, green: 0.8, blue: 0.9)
    
    // MARK: - Gradients
    
    /// Neon orange gradient for CTA buttons.
    static let orangeGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.42, blue: 0.0),
            Color(red: 0.95, green: 0.25, blue: 0.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Climb phase gradient (orange → red).
    static let climbGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.45, blue: 0.0),
            Color(red: 0.9, green: 0.15, blue: 0.1)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Descent phase gradient (cyan → blue).
    static let descentGradient = LinearGradient(
        colors: [
            Color(red: 0.0, green: 0.8, blue: 0.9),
            Color(red: 0.1, green: 0.4, blue: 0.9)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Flat phase gradient (green → teal).
    static let flatGradient = LinearGradient(
        colors: [
            Color(red: 0.2, green: 0.84, blue: 0.29),
            Color(red: 0.0, green: 0.7, blue: 0.6)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Subtle background ambient gradient.
    static let ambientGradient = RadialGradient(
        colors: [
            Color(red: 1.0, green: 0.369, blue: 0.0).opacity(0.06),
            Color.clear
        ],
        center: .topTrailing,
        startRadius: 50,
        endRadius: 400
    )
    
    /// Vibrant Lime Green for Elevation Chart fill & line (matching HIG design reference).
    static let chartLimeColor = Color(red: 0.65, green: 0.95, blue: 0.15) // #A6F226
    
    static let chartLimeGradient = LinearGradient(
        colors: [
            Color(red: 0.65, green: 0.95, blue: 0.15).opacity(0.55),
            Color(red: 0.65, green: 0.95, blue: 0.15).opacity(0.12),
            Color.clear
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Multi-spectrum Effort Gradient for Goal Finish slider (Light Green → Yellow → Orange → Crimson).
    static let effortGradient = LinearGradient(
        colors: [
            Color(red: 0.20, green: 0.85, blue: 0.35), // Green (Light)
            Color(red: 0.95, green: 0.85, blue: 0.10), // Yellow
            Color(red: 1.0, green: 0.45, blue: 0.0),   // Orange
            Color(red: 0.95, green: 0.15, blue: 0.30)  // Crimson (Challenging)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Apple HIG Design Tokens for Trail & Navigation
    
    /// Accent Lime for Elevation Profile
    static let trailLime = Color(red: 0.68, green: 0.93, blue: 0.15) // #AEEB26
    
    /// Target Time Bright Orange (#FF7A00)
    static let targetOrange = Color(red: 1.0, green: 0.48, blue: 0.0)
    
    /// Water Station & Active Track Blue (#007AFF)
    static let waterBlue = Color(red: 0.0, green: 0.48, blue: 1.0)
    
    /// Phase Arrow Colors (matching Apple HIG System Colors)
    static let phaseClimb = Color(red: 1.0, green: 0.23, blue: 0.19) // #FF3B30
    static let phaseFlat = Color(red: 0.20, green: 0.78, blue: 0.35)  // #34C759
    static let phaseDescent = Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF
    
    /// Solid subtle hairline grid for elevation chart
    static let gridLine = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.10)
            : UIColor(red: 0.90, green: 0.90, blue: 0.92, alpha: 0.8)
    })
    
    // MARK: - Typography (Apple HIG Scales)
    
    /// Digital Clock (Goal finish & Water Station)
    static let trailClock = Font.system(size: 36, weight: .bold, design: .rounded)
    
    /// Summary Metric Values (Distance, Ascent, Descent)
    static let trailMetricValue = Font.system(size: 21, weight: .bold, design: .rounded)
    
    /// Summary Metric Labels (Distance, Total Ascent, etc.)
    static let trailMetricLabel = Font.system(size: 13, weight: .medium, design: .default)
    
    /// Strategy Table Data Row Values
    static let trailTableValue = Font.system(size: 17, weight: .bold, design: .rounded)
    
    /// Strategy Table Header Labels
    static let trailTableHeader = Font.system(size: 13, weight: .medium, design: .default)
    
    /// Sub-metric Value (Average Pace, GAP, Elevation)
    static let trailSubmetricValue = Font.system(size: 17, weight: .bold, design: .rounded)
    
    /// Sub-metric Caption (Average Pace, GAP, Elevation)
    static let trailSubmetricLabel = Font.system(size: 13, weight: .regular, design: .default)
    
    /// Card Title Badges (Target Time, Water Station)
    static let trailCardBadge = Font.system(size: 13, weight: .bold, design: .rounded)
    
    /// Section Heading outside cards (Goal Finish, Strategy)
    static let trailSectionHeading = Font.system(size: 17, weight: .bold, design: .rounded)
    
    /// Chart Axis Labels
    static let trailAxisLabel = Font.system(size: 11, weight: .regular, design: .default)
    
    /// Large title (e.g., course name).
    static let largeTitle = Font.system(size: 28, weight: .bold, design: .default)
    
    /// Title.
    static let title = Font.system(size: 22, weight: .bold, design: .default)
    
    /// Section heading.
    static let heading = Font.system(size: 18, weight: .semibold, design: .default)
    
    /// Body text.
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    
    /// Caption / label.
    static let caption = Font.system(size: 13, weight: .medium, design: .default)
    
    /// Small caption.
    static let smallCaption = Font.system(size: 11, weight: .medium, design: .default)
    
    /// Metric value (large, monospaced).
    static let metricLarge = Font.system(size: 32, weight: .bold, design: .monospaced)
    
    /// Metric value (medium, monospaced).
    static let metricMedium = Font.system(size: 22, weight: .bold, design: .monospaced)
    
    /// Metric value (small, monospaced).
    static let metricSmall = Font.system(size: 16, weight: .semibold, design: .monospaced)
    
    // MARK: - Corner Radii
    
    /// Card corner radius matching Apple HIG mockups (22pt)
    static let cornerRadiusCard: CGFloat = 22
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusXL: CGFloat = 20
    
    // MARK: - Spacing
    
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 12
    static let spacingL: CGFloat = 16
    static let spacingXL: CGFloat = 24
    static let spacingXXL: CGFloat = 32
    
    // MARK: - Shadows
    
    /// Neon glow shadow for accented elements.
    static func neonGlow(radius: CGFloat = 12, opacity: Double = 0.4) -> some View {
        Color.clear
            .shadow(color: neonOrange.opacity(opacity), radius: radius, x: 0, y: 0)
    }
    
    // MARK: - Phase Gradient
    
    /// Get gradient for a specific segment phase.
    static func gradient(for phase: SegmentPhase) -> LinearGradient {
        switch phase {
        case .climb: return climbGradient
        case .descent: return descentGradient
        case .flat: return flatGradient
        }
    }
}

// MARK: - View Modifiers

/// Card style modifier (slate gray container with rounded corners).
struct CardModifier: ViewModifier {
    var padding: CGFloat = Theme.spacingL
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.slateGray)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(Theme.cardBorder, lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
}

/// Neon glow border modifier.
struct NeonGlowBorder: ViewModifier {
    var color: Color = Theme.neonOrange
    var radius: CGFloat = 8
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.15), radius: radius, x: 0, y: 0)
    }
}

extension View {
    /// Apply card styling.
    func cardStyle(padding: CGFloat = Theme.spacingL) -> some View {
        modifier(CardModifier(padding: padding))
    }
    
    /// Apply neon glow border.
    func neonGlow(color: Color = Theme.neonOrange, radius: CGFloat = 8) -> some View {
        modifier(NeonGlowBorder(color: color, radius: radius))
    }
}
