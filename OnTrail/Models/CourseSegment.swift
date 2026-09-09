//
//  CourseSegment.swift
//  On Trail
//
//  Created by On Trail Team.
//

import Foundation

/// Represents a contiguous section of the course with a consistent phase (climb/flat/descent).
struct CourseSegment: Identifiable, Codable {
    let id: UUID
    let phase: SegmentPhase
    let trackPoints: [TrackPoint]
    let segmentIndex: Int
    
    /// Real moving pace on this terrain/grade (seconds per km).
    var targetPaceSecondsPerKm: Double = 360 // actual trail pace
    
    /// Target Grade Adjusted Pace (flat equivalent effort in seconds per km).
    var targetGAPSecondsPerKm: Double = 360
    
    init(
        id: UUID = UUID(),
        phase: SegmentPhase,
        trackPoints: [TrackPoint],
        segmentIndex: Int,
        targetPaceSecondsPerKm: Double = 360,
        targetGAPSecondsPerKm: Double = 360
    ) {
        self.id = id
        self.phase = phase
        self.trackPoints = trackPoints
        self.segmentIndex = segmentIndex
        self.targetPaceSecondsPerKm = targetPaceSecondsPerKm
        self.targetGAPSecondsPerKm = targetGAPSecondsPerKm
    }
    
    // MARK: - Computed Properties
    
    /// Distance from start where this segment begins (meters).
    var startDistance: Double {
        trackPoints.first?.distanceFromStart ?? 0
    }
    
    /// Distance from start where this segment ends (meters).
    var endDistance: Double {
        trackPoints.last?.distanceFromStart ?? 0
    }
    
    /// Length of this segment in meters.
    var distance: Double {
        endDistance - startDistance
    }
    
    /// Length of this segment in kilometers.
    var distanceKm: Double {
        distance / 1000.0
    }
    
    /// Start elevation in meters.
    var startElevation: Double {
        trackPoints.first?.elevation ?? 0
    }
    
    /// End elevation in meters.
    var endElevation: Double {
        trackPoints.last?.elevation ?? 0
    }
    
    /// Minimum elevation within this segment.
    var minElevation: Double {
        trackPoints.map(\.elevation).min() ?? 0
    }
    
    /// Maximum elevation within this segment.
    var maxElevation: Double {
        trackPoints.map(\.elevation).max() ?? 0
    }
    
    /// Total elevation gain within this segment (only counting uphill changes).
    var elevationGain: Double {
        var gain: Double = 0
        for i in 1..<trackPoints.count {
            let diff = trackPoints[i].elevation - trackPoints[i - 1].elevation
            if diff > 0 { gain += diff }
        }
        return gain
    }
    
    /// Total elevation loss within this segment (only counting downhill changes).
    var elevationLoss: Double {
        var loss: Double = 0
        for i in 1..<trackPoints.count {
            let diff = trackPoints[i].elevation - trackPoints[i - 1].elevation
            if diff < 0 { loss += abs(diff) }
        }
        return loss
    }
    
    /// Average gradient percentage across the segment.
    var averageGradient: Double {
        guard distance > 0 else { return 0 }
        let elevChange = endElevation - startElevation
        return (elevChange / distance) * 100
    }
    
    /// Maximum gradient found between any two consecutive points.
    var maxGradient: Double {
        guard trackPoints.count > 1 else { return 0 }
        var maxGrad: Double = 0
        for i in 1..<trackPoints.count {
            let grad = abs(trackPoints[i - 1].gradient(to: trackPoints[i]))
            if grad > maxGrad { maxGrad = grad }
        }
        return maxGrad
    }
    
    /// Formatted actual target pace string (e.g., "12:30 /km").
    var targetPaceFormatted: String {
        PacingZone.formatPace(targetPaceSecondsPerKm, showUnit: false)
    }
    
    /// Formatted GAP string (e.g., "6:05 /km").
    var gapFormatted: String {
        PacingZone.formatPace(targetGAPSecondsPerKm, showUnit: false)
    }
    
    /// Estimated time to complete this segment in seconds (based on actual terrain pace).
    var estimatedTimeSeconds: Double {
        distanceKm * targetPaceSecondsPerKm
    }
    
    /// Formatted estimated time string.
    var estimatedTimeFormatted: String {
        let totalSeconds = Int(estimatedTimeSeconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Short description of the segment.
    var summary: String {
        let dist = String(format: "%.1f", distanceKm)
        let elev = String(format: "%+.0f", endElevation - startElevation)
        let grad = String(format: "%.1f", averageGradient)
        return "\(phase.displayName) · \(dist) km · \(elev)m · \(grad)%"
    }
}
