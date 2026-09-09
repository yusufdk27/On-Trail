//
//  TrailPathIcon.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// Vector recreation of the native Trail Path icon `/:\` matching HIG specifications.
/// Represents a mountain trail ascending and descending with center path dashes.
struct TrailPathIcon: View {
    var size: CGFloat = 17
    var color: Color = Theme.textPrimary
    
    var body: some View {
        HStack(spacing: 1.5) {
            // Left ascending slope
            Text("/")
                .font(.system(size: size, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            
            // Center path dashed dots
            VStack(spacing: 2.2) {
                Circle().fill(color).frame(width: size * 0.12, height: size * 0.12)
                Circle().fill(color).frame(width: size * 0.12, height: size * 0.12)
                Circle().fill(color).frame(width: size * 0.12, height: size * 0.12)
            }
            .padding(.horizontal, 1)
            
            // Right descending slope
            Text("\\")
                .font(.system(size: size, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .alignmentGuide(.firstTextBaseline) { d in d[.bottom] }
    }
}

#Preview {
    HStack {
        TrailPathIcon(size: 20)
        Text("50.24 km")
            .font(.system(size: 21, weight: .bold, design: .rounded))
    }
    .padding()
}
