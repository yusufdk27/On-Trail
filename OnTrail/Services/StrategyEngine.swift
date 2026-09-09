//
//  StrategyEngine.swift
//  On Trail
//
//  Created by On Trail Team.
//

import Foundation

/// Segments the course into phases and computes pacing strategy.
struct StrategyEngine {
    
    /// Minimum segment distance in meters to avoid noise from micro-segments.
    static let minimumSegmentDistance: Double = 200
    
    /// Gradient threshold for classifying climb vs flat vs descent.
    static let gradientThreshold: Double = 3.0
    
    // MARK: - Main Pipeline
    
    /// Generate a complete race strategy from raw parsed GPX data.
    static func generateStrategy(
        from result: GPXParser.GPXResult,
        locationName: String? = nil,
        basePaceSecondsPerKm: Double = 360
    ) -> RaceStrategy {
        // 1. Smooth elevation data
        let smoothed = ElevationAnalyzer.smooth(result.trackPoints, windowSize: 5)
        
        // 2. Segment the course
        var segments = segmentCourse(smoothed)
        
        // 3. Merge small segments
        segments = mergeSmallSegments(segments, minDistance: minimumSegmentDistance)
        
        // 4. Apply GAP-based pacing
        let pacingZone = PacingZone(basePaceSecondsPerKm: basePaceSecondsPerKm)
        segments = applyPacing(segments, pacingZone: pacingZone)
        
        // 5. Re-index segments
        segments = segments.enumerated().map { index, seg in
            CourseSegment(
                id: seg.id,
                phase: seg.phase,
                trackPoints: seg.trackPoints,
                segmentIndex: index,
                targetPaceSecondsPerKm: seg.targetPaceSecondsPerKm,
                targetGAPSecondsPerKm: seg.targetGAPSecondsPerKm
            )
        }
        
        // 6. Compute checkpoint arrival times
        let checkpoints = computeCheckpointArrivals(
            result.waypoints,
            segments: segments,
            pacingZone: pacingZone
        )
        
        return RaceStrategy(
            courseName: result.trackName,
            locationName: locationName,
            segments: segments,
            checkpoints: checkpoints,
            allTrackPoints: smoothed,
            pacingZone: pacingZone
        )
    }
    
    /// Recalculate an existing race strategy with a new base pace.
    static func recalculatePacing(
        strategy: RaceStrategy,
        newBasePaceSecondsPerKm: Double
    ) -> RaceStrategy {
        let newPacingZone = PacingZone(basePaceSecondsPerKm: newBasePaceSecondsPerKm)
        let updatedSegments = applyPacing(strategy.segments, pacingZone: newPacingZone)
        let updatedCheckpoints = computeCheckpointArrivals(
            strategy.checkpoints,
            segments: updatedSegments,
            pacingZone: newPacingZone
        )
        
        return RaceStrategy(
            id: strategy.id,
            courseName: strategy.courseName,
            locationName: strategy.locationName,
            segments: updatedSegments,
            checkpoints: updatedCheckpoints,
            allTrackPoints: strategy.allTrackPoints,
            pacingZone: newPacingZone,
            createdAt: strategy.createdAt
        )
    }
    
    // MARK: - Segmentation
    
    /// Segment the course into contiguous climb/flat/descent sections.
    static func segmentCourse(_ points: [TrackPoint]) -> [CourseSegment] {
        guard points.count > 1 else { return [] }
        
        var segments: [CourseSegment] = []
        var currentSegmentPoints: [TrackPoint] = [points[0]]
        
        // Calculate rolling gradient with a window to reduce noise
        let windowSize = min(5, points.count - 1)
        
        func rollingGradient(at index: Int) -> Double {
            let start = max(0, index - windowSize / 2)
            let end = min(points.count - 1, index + windowSize / 2)
            guard start != end else { return 0 }
            
            let startPoint = points[start]
            let endPoint = points[end]
            let hDist = endPoint.distanceFromStart - startPoint.distanceFromStart
            guard hDist > 0 else { return 0 }
            
            return ((endPoint.elevation - startPoint.elevation) / hDist) * 100
        }
        
        var currentPhase = SegmentPhase.classify(gradient: rollingGradient(at: 0))
        
        for i in 1..<points.count {
            let gradient = rollingGradient(at: i)
            let phase = SegmentPhase.classify(gradient: gradient)
            
            if phase != currentPhase {
                // End current segment
                let segment = CourseSegment(
                    phase: currentPhase,
                    trackPoints: currentSegmentPoints,
                    segmentIndex: segments.count
                )
                segments.append(segment)
                
                // Start new segment (include the last point of previous as first of new)
                currentSegmentPoints = [points[i - 1], points[i]]
                currentPhase = phase
            } else {
                currentSegmentPoints.append(points[i])
            }
        }
        
        // Add final segment
        if !currentSegmentPoints.isEmpty {
            let segment = CourseSegment(
                phase: currentPhase,
                trackPoints: currentSegmentPoints,
                segmentIndex: segments.count
            )
            segments.append(segment)
        }
        
        return segments
    }
    
    // MARK: - Merge Small Segments
    
    /// Merge segments shorter than minDistance into adjacent segments to reduce noise.
    static func mergeSmallSegments(_ segments: [CourseSegment], minDistance: Double) -> [CourseSegment] {
        guard segments.count > 1 else { return segments }
        
        var merged: [CourseSegment] = []
        var i = 0
        
        while i < segments.count {
            let seg = segments[i]
            
            if seg.distance < minDistance && !merged.isEmpty {
                // Merge into previous segment
                let prev = merged.removeLast()
                let combinedPoints = prev.trackPoints + seg.trackPoints.dropFirst()
                let mergedSegment = CourseSegment(
                    id: prev.id,
                    phase: prev.phase,
                    trackPoints: combinedPoints,
                    segmentIndex: prev.segmentIndex,
                    targetPaceSecondsPerKm: prev.targetPaceSecondsPerKm,
                    targetGAPSecondsPerKm: prev.targetGAPSecondsPerKm
                )
                merged.append(mergedSegment)
            } else if seg.distance < minDistance && merged.isEmpty && i + 1 < segments.count {
                // Merge into next segment
                let next = segments[i + 1]
                let combinedPoints = seg.trackPoints + next.trackPoints.dropFirst()
                let mergedSegment = CourseSegment(
                    id: next.id,
                    phase: next.phase,
                    trackPoints: combinedPoints,
                    segmentIndex: next.segmentIndex,
                    targetPaceSecondsPerKm: next.targetPaceSecondsPerKm,
                    targetGAPSecondsPerKm: next.targetGAPSecondsPerKm
                )
                merged.append(mergedSegment)
                i += 1 // skip next since we merged it
            } else {
                merged.append(seg)
            }
            
            i += 1
        }
        
        return merged
    }
    
    // MARK: - Pacing
    
    /// Calculate realistic actual trail moving pace and target GAP for each segment.
    static func applyPacing(_ segments: [CourseSegment], pacingZone: PacingZone) -> [CourseSegment] {
        segments.map { segment in
            let targetGAP = pacingZone.basePaceSecondsPerKm
            let actualPace = pacingZone.actualPace(for: segment.averageGradient, targetGAP: targetGAP)
            return CourseSegment(
                id: segment.id,
                phase: segment.phase,
                trackPoints: segment.trackPoints,
                segmentIndex: segment.segmentIndex,
                targetPaceSecondsPerKm: actualPace,
                targetGAPSecondsPerKm: targetGAP
            )
        }
    }
    
    // MARK: - Checkpoint Arrivals & Leg Splits
    
    /// Compute estimated arrival and departure times at each checkpoint, incorporating
    /// time spent at previous water stations and calculating terrain splits (COROS style).
    static func computeCheckpointArrivals(
        _ checkpoints: [Checkpoint],
        segments: [CourseSegment],
        pacingZone: PacingZone
    ) -> [Checkpoint] {
        guard !checkpoints.isEmpty else { return [] }
        
        let sorted = checkpoints.sorted { $0.distanceFromStart < $1.distanceFromStart }
        var result: [Checkpoint] = []
        var previousDepartureSeconds: Double = 0
        var previousDistance: Double = 0
        
        for (index, checkpoint) in sorted.enumerated() {
            let legDistMeters = max(0, checkpoint.distanceFromStart - previousDistance)
            let legDistKm = legDistMeters / 1000.0
            
            // Calculate leg moving time and elevation within [previousDistance, checkpoint.distanceFromStart]
            var legMovingSeconds: Double = 0
            var legGain: Double = 0
            var legLoss: Double = 0
            
            for segment in segments {
                let segStart = segment.startDistance
                let segEnd = segment.endDistance
                
                let overlapStart = max(previousDistance, segStart)
                let overlapEnd = min(checkpoint.distanceFromStart, segEnd)
                
                if overlapEnd > overlapStart {
                    let overlapDist = overlapEnd - overlapStart
                    let fraction = overlapDist / max(segment.distance, 1.0)
                    legMovingSeconds += segment.estimatedTimeSeconds * fraction
                    legGain += segment.elevationGain * fraction
                    legLoss += segment.elevationLoss * fraction
                }
            }
            
            if legMovingSeconds == 0 && legDistKm > 0 {
                legMovingSeconds = legDistKm * pacingZone.basePaceSecondsPerKm
            }
            
            let legPace = legDistKm > 0 ? (legMovingSeconds / legDistKm) : 0
            let arrivalSeconds = (index == 0 && checkpoint.distanceFromStart <= 50) ? 0.0 : (previousDepartureSeconds + legMovingSeconds)
            
            let updated = Checkpoint(
                id: checkpoint.id,
                name: checkpoint.name,
                type: checkpoint.type,
                latitude: checkpoint.latitude,
                longitude: checkpoint.longitude,
                distanceFromStart: checkpoint.distanceFromStart,
                cutOffTimeSeconds: checkpoint.cutOffTimeSeconds,
                elevation: checkpoint.elevation,
                estimatedArrivalSeconds: arrivalSeconds,
                plannedStopDurationSeconds: checkpoint.plannedStopDurationSeconds,
                legDistanceMeters: legDistMeters,
                legElevationGain: legGain,
                legElevationLoss: legLoss,
                legMovingTimeSeconds: legMovingSeconds,
                legPaceSecondsPerKm: legPace
            )
            
            result.append(updated)
            previousDepartureSeconds = updated.estimatedDepartureSeconds ?? arrivalSeconds
            previousDistance = checkpoint.distanceFromStart
        }
        
        return result
    }
}
