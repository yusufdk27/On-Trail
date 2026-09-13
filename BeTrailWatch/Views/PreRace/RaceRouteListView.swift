//
//  RaceRouteListView.swift
//  BeTrailWatch
//
//  Scrollable list of available race routes.
//  Each card shows a mini GPX map outline, route name, distance, and estimated time.
//  Matches the UI sketch: teal route thumbnail + bold white title + cyan subtitle.
//

import SwiftUI

struct RaceRouteListView: View {
    @Environment(WatchRaceCoordinator.self) private var coordinator

    var body: some View {
        List(coordinator.availableRoutes) { strategy in
            NavigationLink {
                RouteDetailView(strategy: strategy)
            } label: {
                RouteCardRow(strategy: strategy)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
        }
        .listStyle(.plain)
        .background(WatchTheme.background)
        .navigationTitle("Race Route")
    }
}

// MARK: - Route Card Row

struct RouteCardRow: View {
    let strategy: RaceStrategy

    var body: some View {
        ZStack(alignment: .topTrailing) {
            WatchCard(background: WatchTheme.cardGreen) {
                VStack(alignment: .leading, spacing: 6) {
                    // Mini GPX Map Outline Thumbnail
                    GPXMapOutline(trackPoints: strategy.allTrackPoints, color: WatchTheme.cyan)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    // Route Name
                    Text(strategy.courseName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(WatchTheme.textPrimary)
                        .lineLimit(1)

                    // Distance · Estimated Time
                    HStack(spacing: 4) {
                        Text(String(format: "%.2f km", strategy.totalDistanceKm))
                        Text("•")
                        Text(strategy.estimatedFinishTimeFormatted)
                    }
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(WatchTheme.cyan)
                }
            }

            // More Button (top-right overlay)
            WatchMoreButton()
                .padding(10)
        }
    }
}

// MARK: - GPX Map Outline

/// Renders a normalized vector path of the GPS track inside any bounding rect.
/// Uses lat/lon min-max normalization so the shape always fills the view.
struct GPXMapOutline: View {
    let trackPoints: [TrackPoint]
    var color: Color = WatchTheme.cyan
    var lineWidth: CGFloat = 2.0

    var body: some View {
        GeometryReader { geo in
            if trackPoints.count > 1 {
                let (minLat, maxLat, minLon, maxLon) = bounds(of: trackPoints)
                let latRange = max(0.0001, maxLat - minLat)
                let lonRange = max(0.0001, maxLon - minLon)
                let padding: CGFloat = 4

                let w = geo.size.width  - padding * 2
                let h = geo.size.height - padding * 2

                Path { path in
                    for (idx, pt) in trackPoints.enumerated() {
                        // Normalize: lon → X, lat → Y (flip lat so north is up)
                        let x = padding + CGFloat((pt.longitude - minLon) / lonRange) * w
                        let y = padding + CGFloat(1.0 - (pt.latitude - minLat) / latRange) * h

                        if idx == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            } else {
                // Fallback placeholder when no points available
                RoundedRectangle(cornerRadius: 6)
                    .fill(WatchTheme.cardSurface)
                    .overlay(
                        Image(systemName: "map")
                            .font(.system(size: 18))
                            .foregroundStyle(WatchTheme.textTertiary)
                    )
            }
        }
    }

    private func bounds(of points: [TrackPoint]) -> (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) {
        let lats = points.map(\.latitude)
        let lons = points.map(\.longitude)
        return (
            minLat: lats.min() ?? 0,
            maxLat: lats.max() ?? 1,
            minLon: lons.min() ?? 0,
            maxLon: lons.max() ?? 1
        )
    }
}

// MARK: - Previews

#Preview("Route List") {
    NavigationStack {
        RaceRouteListView()
            .environment(WatchRaceCoordinator.shared)
    }
}

#Preview("Route Card Row") {
    RouteCardRow(strategy: BeTrailMockData.slu2025Strategy)
        .padding()
        .background(WatchTheme.background)
}

#Preview("GPX Map Outline") {
    GPXMapOutline(trackPoints: BeTrailMockData.slu2025Strategy.allTrackPoints)
        .frame(width: 160, height: 60)
        .background(WatchTheme.cardGreen)
}
