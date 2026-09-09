//
//  GlowingDivider.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// A horizontal divider with a subtle neon glow effect.
struct GlowingDivider: View {
    var color: Color = Theme.neonOrange
    var opacity: Double = 0.4
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        color.opacity(0),
                        color.opacity(opacity),
                        color.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .shadow(color: color.opacity(opacity * 0.5), radius: 4, x: 0, y: 0)
    }
}

#Preview {
    VStack(spacing: 30) {
        GlowingDivider()
        GlowingDivider(color: Theme.cyan)
        GlowingDivider(color: Theme.successGreen)
    }
    .padding()
    .background(Theme.background)
}
