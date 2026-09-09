//
//  RaceStrategy.swift
//  On Trail
//
//  Created by On Trail Team.
//

import Foundation

/// Container for the complete race strategy derived from GPX analysis.
struct RaceStrategy: Codable, Identifiable {
    let id: UUID
    let courseName: String
    let locationName: String?
    let segments: [CourseSegment]
    let checkpoints: [Checkpoint]
    let allTrackPoints: [TrackPoint]
    let pacingZone: PacingZone
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        courseName: String,
        locationName: String? = nil,
        segments: [CourseSegment],
        checkpoints: [Checkpoint],
        allTrackPoints: [TrackPoint],
        pacingZone: PacingZone = PacingZone(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.courseName = courseName
        self.locationName = locationName
        self.segments = segments
        self.checkpoints = checkpoints
        self.allTrackPoints = allTrackPoints
        self.pacingZone = pacingZone
        self.createdAt = createdAt
    }
    
    // MARK: - Distance
    
    /// Total course distance in meters.
    var totalDistance: Double {
        allTrackPoints.last?.distanceFromStart ?? 0
    }
    
    /// Total course distance in kilometers.
    var totalDistanceKm: Double {
        totalDistance / 1000.0
    }
    
    /// Formatted total distance string.
    var totalDistanceFormatted: String {
        String(format: "%.1f km", totalDistanceKm)
    }
    
    // MARK: - Elevation
    
    /// Total elevation gain across the entire course.
    var totalElevationGain: Double {
        segments.reduce(0) { $0 + $1.elevationGain }
    }
    
    /// Total elevation loss across the entire course.
    var totalElevationLoss: Double {
        segments.reduce(0) { $0 + $1.elevationLoss }
    }
    
    /// Minimum elevation on the course.
    var minElevation: Double {
        allTrackPoints.map(\.elevation).min() ?? 0
    }
    
    /// Maximum elevation on the course.
    var maxElevation: Double {
        allTrackPoints.map(\.elevation).max() ?? 0
    }
    
    /// Formatted elevation gain string.
    var elevationGainFormatted: String {
        String(format: "+%.0f m", totalElevationGain)
    }
    
    /// Formatted elevation loss string.
    var elevationLossFormatted: String {
        String(format: "-%.0f m", totalElevationLoss)
    }
    
    // MARK: - Segments by Phase
    
    /// All climb segments.
    var climbSegments: [CourseSegment] {
        segments.filter { $0.phase == .climb }
    }
    
    /// All descent segments.
    var descentSegments: [CourseSegment] {
        segments.filter { $0.phase == .descent }
    }
    
    /// All flat segments.
    var flatSegments: [CourseSegment] {
        segments.filter { $0.phase == .flat }
    }
    
    /// Total climb distance in km.
    var totalClimbDistanceKm: Double {
        climbSegments.reduce(0) { $0 + $1.distanceKm }
    }
    
    /// Total descent distance in km.
    var totalDescentDistanceKm: Double {
        descentSegments.reduce(0) { $0 + $1.distanceKm }
    }
    
    /// Total flat distance in km.
    var totalFlatDistanceKm: Double {
        flatSegments.reduce(0) { $0 + $1.distanceKm }
    }
    
    // MARK: - Time Estimates
    
    /// Estimated total moving time in seconds (base pace).
    var estimatedFinishTimeSeconds: Double {
        segments.reduce(0) { $0 + $1.estimatedTimeSeconds }
    }
    
    /// Formatted estimated finish time.
    var estimatedFinishTimeFormatted: String {
        PacingZone.formatDuration(estimatedFinishTimeSeconds)
    }
    
    /// Dynamic target GAP (flat effort equivalent in seconds/km) scaled by effortFactor.
    /// effortFactor: 1.0 is neutral, <1.0 faster (challenging), >1.0 conservative (light).
    func dynamicTargetGAP(effortFactor: Double = 1.0) -> Double {
        pacingZone.basePaceSecondsPerKm * max(0.4, effortFactor)
    }
    
    /// Calculate total course moving time dynamically based on segment gradients and effort factor.
    func dynamicTotalMovingSeconds(effortFactor: Double = 1.0) -> Double {
        let currentGAP = dynamicTargetGAP(effortFactor: effortFactor)
        return segments.reduce(0.0) { accumulatedTime, segment in
            let segmentActualPace = pacingZone.actualPace(for: segment.averageGradient, targetGAP: currentGAP)
            return accumulatedTime + (segment.distanceKm * segmentActualPace)
        }
    }
    
    /// Formatted total dynamic moving time (HH:MM:SS).
    func dynamicTotalMovingFormatted(effortFactor: Double = 1.0) -> String {
        PacingZone.formatDuration(dynamicTotalMovingSeconds(effortFactor: effortFactor))
    }
    
    /// Total planned rest/pitstop duration across all water stations and checkpoints.
    var totalStationStopDurationSeconds: Double {
        checkpoints.reduce(0.0) { $0 + $1.plannedStopDurationSeconds }
    }
    
    /// Formatted total station stop duration (e.g., "25m" or "1h 10m").
    var totalStationStopDurationFormatted: String {
        PacingZone.formatDurationShort(totalStationStopDurationSeconds)
    }
    
    /// Dynamic goal finish time in seconds (moving time + station stops).
    func dynamicGoalFinishSeconds(effortFactor: Double = 1.0, pitstopSeconds: Double? = nil) -> Double {
        let stopSeconds = pitstopSeconds ?? totalStationStopDurationSeconds
        return dynamicTotalMovingSeconds(effortFactor: effortFactor) + max(0, stopSeconds)
    }
    
    /// Dynamic goal finish time formatted as HH:MM:SS.
    func dynamicGoalFinishFormatted(effortFactor: Double = 1.0, pitstopSeconds: Double? = nil) -> String {
        let total = Int(dynamicGoalFinishSeconds(effortFactor: effortFactor, pitstopSeconds: pitstopSeconds).rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    /// Predicted clock time of finish based on race start time (e.g. "10:18").
    func dynamicGoalFinishClock(raceStartTime: Date, effortFactor: Double = 1.0) -> String {
        let finishSeconds = dynamicGoalFinishSeconds(effortFactor: effortFactor)
        let finishDate = raceStartTime.addingTimeInterval(finishSeconds)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: finishDate)
    }
    
    /// Baseline Average Actual Pace across the entire course (seconds per km).
    var averagePaceSecondsPerKm: Double {
        guard totalDistanceKm > 0 else { return 0 }
        return estimatedFinishTimeSeconds / totalDistanceKm
    }
    
    /// Dynamic Average Actual Pace across terrain (seconds per km).
    func dynamicAveragePaceSecondsPerKm(effortFactor: Double = 1.0) -> Double {
        guard totalDistanceKm > 0 else { return 0 }
        return dynamicTotalMovingSeconds(effortFactor: effortFactor) / totalDistanceKm
    }
    
    /// Dynamic Average Actual Pace formatted (e.g. "10:45 /km").
    func dynamicAveragePaceFormatted(effortFactor: Double = 1.0) -> String {
        PacingZone.formatPace(dynamicAveragePaceSecondsPerKm(effortFactor: effortFactor))
    }
    
    /// Dynamic Average GAP (flat effort equivalent) formatted (e.g. "6:05 /km").
    func dynamicAverageGAPFormatted(effortFactor: Double = 1.0) -> String {
        PacingZone.formatPace(dynamicTargetGAP(effortFactor: effortFactor))
    }
    
    /// Dynamic Actual Pace for Climb segments (power-hiking / steep uphill).
    func dynamicClimbPaceFormatted(effortFactor: Double = 1.0) -> String {
        let climbs = climbSegments
        guard !climbs.isEmpty else { return dynamicAveragePaceFormatted(effortFactor: effortFactor) }
        let currentGAP = dynamicTargetGAP(effortFactor: effortFactor)
        let totalClimbDist = climbs.reduce(0.0) { $0 + $1.distanceKm }
        guard totalClimbDist > 0 else { return dynamicAveragePaceFormatted(effortFactor: effortFactor) }
        let totalClimbTime = climbs.reduce(0.0) { acc, seg in
            acc + (seg.distanceKm * pacingZone.actualPace(for: seg.averageGradient, targetGAP: currentGAP))
        }
        return PacingZone.formatPace(totalClimbTime / totalClimbDist)
    }
    
    /// Dynamic Actual Pace for Descent segments (technical downhill).
    func dynamicDescentPaceFormatted(effortFactor: Double = 1.0) -> String {
        let descents = descentSegments
        guard !descents.isEmpty else { return dynamicAveragePaceFormatted(effortFactor: effortFactor) }
        let currentGAP = dynamicTargetGAP(effortFactor: effortFactor)
        let totalDescentDist = descents.reduce(0.0) { $0 + $1.distanceKm }
        guard totalDescentDist > 0 else { return dynamicAveragePaceFormatted(effortFactor: effortFactor) }
        let totalDescentTime = descents.reduce(0.0) { acc, seg in
            acc + (seg.distanceKm * pacingZone.actualPace(for: seg.averageGradient, targetGAP: currentGAP))
        }
        return PacingZone.formatPace(totalDescentTime / totalDescentDist)
    }
    
    /// Dynamic Actual Pace for Flat/Rolling segments.
    func dynamicFlatPaceFormatted(effortFactor: Double = 1.0) -> String {
        let flats = flatSegments
        guard !flats.isEmpty else { return dynamicAverageGAPFormatted(effortFactor: effortFactor) }
        let currentGAP = dynamicTargetGAP(effortFactor: effortFactor)
        let totalFlatDist = flats.reduce(0.0) { $0 + $1.distanceKm }
        guard totalFlatDist > 0 else { return dynamicAverageGAPFormatted(effortFactor: effortFactor) }
        let totalFlatTime = flats.reduce(0.0) { acc, seg in
            acc + (seg.distanceKm * pacingZone.actualPace(for: seg.averageGradient, targetGAP: currentGAP))
        }
        return PacingZone.formatPace(totalFlatTime / totalFlatDist)
    }
    
    /// Formatted average pace.
    var averagePaceFormatted: String {
        PacingZone.formatPace(averagePaceSecondsPerKm)
    }
    
    /// Formatted location or fallback
    var locationFormatted: String {
        locationName ?? "Trail Course"
    }
    
    // MARK: - Cumulative Data
    
    /// Calculate cumulative elevation gain at each trackpoint for charting.
    var cumulativeElevationGain: [(distance: Double, gain: Double)] {
        var result: [(distance: Double, gain: Double)] = []
        var totalGain: Double = 0
        
        result.append((distance: 0, gain: 0))
        
        for i in 1..<allTrackPoints.count {
            let diff = allTrackPoints[i].elevation - allTrackPoints[i - 1].elevation
            if diff > 0 { totalGain += diff }
            result.append((distance: allTrackPoints[i].distanceFromStart, gain: totalGain))
        }
        
        return result
    }
    
    /// Get the segment for a given distance from start.
    func segment(at distance: Double) -> CourseSegment? {
        segments.first { distance >= $0.startDistance && distance <= $0.endDistance }
    }
}
