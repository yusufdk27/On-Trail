//
//  WaterStationCardView.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// Water Station Card component conforming to Apple HIG design specifications (Image 4).
/// Features blue water station badge and large digital clock.
struct WaterStationCardView: View {
    var pitstopSeconds: Double
    var onTapped: (() -> Void)? = nil
    
    var body: some View {
        Button {
            onTapped?()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.waterBlue)
                    
                    Text("Total time spent at Water Station")
                        .font(Theme.trailCardBadge)
                        .foregroundStyle(Theme.waterBlue)
                    
                    Spacer()
                }
                
                let stopSecs = Int(pitstopSeconds)
                let hours = stopSecs / 3600
                let minutes = (stopSecs % 3600) / 60
                let seconds = stopSecs % 60
                let timeStr = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
                
                Text(timeStr)
                    .font(Theme.trailClock)
                    .foregroundStyle(Theme.textPrimary)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Theme.slateGray)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusCard, style: .continuous)
                    .stroke(Theme.cardBorder, lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }
}
