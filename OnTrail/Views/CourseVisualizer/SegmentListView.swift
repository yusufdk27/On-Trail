//
//  SegmentListView.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// Scrollable list of course segments with summary header.
struct SegmentListView: View {
    let strategy: RaceStrategy
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            // Section header
            HStack {
                Text("SEGMENT BREAKDOWN")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .tracking(1.5)
                
                Spacer()
                
                Text("\(strategy.segments.count) segments")
                    .font(Theme.smallCaption)
                    .foregroundStyle(Theme.textTertiary)
            }
            
            // Phase summary bar
            phaseSummaryBar
            
            // Segment cards
            LazyVStack(spacing: Theme.spacingS) {
                ForEach(Array(strategy.segments.enumerated()), id: \.element.id) { index, segment in
                    SegmentCard(
                        segment: segment,
                        segmentNumber: index + 1
                    )
                }
            }
        }
    }
    
    // MARK: - Phase Summary Bar
    
    private var phaseSummaryBar: some View {
        GeometryReader { geo in
            let totalDistance = max(strategy.totalDistance, 1)
            
            HStack(spacing: 2) {
                ForEach(strategy.segments) { segment in
                    let fraction = segment.distance / totalDistance
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(segment.phase.color)
                        .frame(width: max(geo.size.width * fraction - 2, 4))
                }
            }
        }
        .frame(height: 6)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .padding(.bottom, Theme.spacingS)
    }
}

#Preview {
    ScrollView {
        SegmentListView(
            strategy: RaceStrategy(
                courseName: "Preview",
                segments: [],
                checkpoints: [],
                allTrackPoints: []
            )
        )
        .padding()
    }
    .background(Theme.background)
}
