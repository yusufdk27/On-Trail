//
//  CourseMapView.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI
import MapKit

/// MapKit view showing the course route colored by segment phase,
/// with live synchronized runner position scrubbing, tappable checkpoints,
/// and full-bleed Apple Maps layout with floating layer & recenter controls.
struct CourseMapView: View {
    let strategy: RaceStrategy
    var selectedDistance: Double? = nil
    var isFullScreen: Bool = true
    var isSheetExpanded: Bool = false
    var onCheckpointTapped: ((Checkpoint) -> Void)? = nil
    
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var isSatellite: Bool = false
    
    var body: some View {
        if isFullScreen {
            fullScreenMapView
        } else {
            cardMapView
        }
    }
    
    // MARK: - Full Screen Map View (Apple Maps Style)
    
    private var fullScreenMapView: some View {
        GeometryReader { geo in
            let bottomOffset = geo.size.height * 0.40 + 16
            ZStack(alignment: .bottomTrailing) {
                Map(position: $mapPosition) {
                    // Course route polylines
                    ForEach(strategy.segments) { segment in
                        let coords = segment.trackPoints.map { $0.coordinate }
                        MapPolyline(coordinates: coords)
                            .stroke(
                                segment.phase.color,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                            )
                    }
                    
                    // Start marker
                    if let first = strategy.allTrackPoints.first {
                        Annotation("Start", coordinate: first.coordinate) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.20, green: 0.85, blue: 0.35))
                                    .frame(width: 26, height: 26)
                                    .shadow(color: Color.black.opacity(0.4), radius: 4)
                                Image(systemName: "flag.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    
                    // Finish marker
                    if let last = strategy.allTrackPoints.last {
                        Annotation("Finish", coordinate: last.coordinate) {
                            ZStack {
                                Circle()
                                    .fill(Theme.neonOrange)
                                    .frame(width: 26, height: 26)
                                    .shadow(color: Color.black.opacity(0.4), radius: 4)
                                Image(systemName: "flag.checkered")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    
                    // Checkpoint / Water Station markers
                    ForEach(strategy.checkpoints) { checkpoint in
                        Annotation(checkpoint.name, coordinate: checkpoint.coordinate) {
                            Button {
                                onCheckpointTapped?(checkpoint)
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 0.12, green: 0.12, blue: 0.14))
                                        .frame(width: 26, height: 26)
                                        .overlay(
                                            Circle()
                                                .stroke(Theme.warningYellow, lineWidth: 1.8)
                                        )
                                        .shadow(color: Color.black.opacity(0.4), radius: 4)
                                    Image(systemName: checkpoint.type.icon)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Theme.warningYellow)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Live Synchronized Runner Scrubbing Pin
                    if let runnerCoord = currentScrubbingCoordinate {
                        Annotation("Runner", coordinate: runnerCoord) {
                            ZStack {
                                Circle()
                                    .fill(Theme.neonOrange.opacity(0.35))
                                    .frame(width: 32, height: 32)
                                
                                Circle()
                                    .fill(Theme.neonOrange)
                                    .frame(width: 18, height: 18)
                                    .overlay(
                                        Circle()
                                            .stroke(.white, lineWidth: 2)
                                    )
                                    .shadow(color: Theme.neonOrange, radius: 8)
                            }
                        }
                    }
                }
                .mapStyle(isSatellite ? .imagery(elevation: .realistic) : .standard(elevation: .realistic))
                .frame(width: geo.size.width, height: geo.size.height)
                .ignoresSafeArea()
                
            }
        }
    }
    
    // MARK: - Card Map View (for fallback/previews)
    
    private var cardMapView: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Text("COURSE MAP")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .tracking(1.5)
                
                Spacer()
                
                if let dist = selectedDistance {
                    Text(String(format: "KM %.1f", dist / 1000.0))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.neonOrange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.neonOrange.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            
            fullScreenMapView
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
        }
        .padding(Theme.spacingL)
        .background(Theme.slateGray)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge))
    }
    
    // MARK: - Helper
    
    private var currentScrubbingCoordinate: CLLocationCoordinate2D? {
        guard let dist = selectedDistance, !strategy.allTrackPoints.isEmpty else { return nil }
        let closest = strategy.allTrackPoints.min(by: {
            abs($0.distanceFromStart - dist) < abs($1.distanceFromStart - dist)
        })
        return closest?.coordinate
    }
}
