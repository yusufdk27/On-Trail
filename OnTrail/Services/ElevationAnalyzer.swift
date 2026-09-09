//
//  ElevationAnalyzer.swift
//  On Trail
//
//  Created by On Trail Team.
//

import Foundation

/// Analyzes elevation data from track points to compute gain, loss, gradients, and smoothed profiles.
struct ElevationAnalyzer {
    
    // MARK: - Smoothing
    
    /// Apply a moving average to smooth elevation data (reduces GPS noise).
    /// - Parameters:
    ///   - points: Raw track points
    ///   - windowSize: Number of points to average (default: 5)
    /// - Returns: Track points with smoothed elevation values
    static func smooth(_ points: [TrackPoint], windowSize: Int = 5) -> [TrackPoint] {
        guard points.count > windowSize else { return points }
        
        let halfWindow = windowSize / 2
        var smoothed = points
        
        for i in halfWindow..<(points.count - halfWindow) {
            var elevSum: Double = 0
            for j in (i - halfWindow)...(i + halfWindow) {
                elevSum += points[j].elevation
            }
            let avgElevation = elevSum / Double(windowSize)
            
            smoothed[i] = TrackPoint(
                id: points[i].id,
                latitude: points[i].latitude,
                longitude: points[i].longitude,
                elevation: avgElevation,
                timestamp: points[i].timestamp,
                distanceFromStart: points[i].distanceFromStart
            )
        }
        
        return smoothed
    }
    
    // MARK: - Elevation Statistics
    
    /// Calculate total elevation gain (sum of all positive elevation changes).
    static func totalGain(_ points: [TrackPoint]) -> Double {
        var gain: Double = 0
        for i in 1..<points.count {
            let diff = points[i].elevation - points[i - 1].elevation
            if diff > 0 { gain += diff }
        }
        return gain
    }
    
    /// Calculate total elevation loss (sum of all negative elevation changes, returned as positive).
    static func totalLoss(_ points: [TrackPoint]) -> Double {
        var loss: Double = 0
        for i in 1..<points.count {
            let diff = points[i].elevation - points[i - 1].elevation
            if diff < 0 { loss += abs(diff) }
        }
        return loss
    }
    
    /// Find the minimum elevation point.
    static func minElevationPoint(_ points: [TrackPoint]) -> TrackPoint? {
        points.min(by: { $0.elevation < $1.elevation })
    }
    
    /// Find the maximum elevation point.
    static func maxElevationPoint(_ points: [TrackPoint]) -> TrackPoint? {
        points.max(by: { $0.elevation < $1.elevation })
    }
    
    // MARK: - Gradient Analysis
    
    /// Calculate gradient at each point (gradient to the next point).
    /// Returns array of (distance, gradient%) tuples.
    static func gradientProfile(_ points: [TrackPoint]) -> [(distance: Double, gradient: Double)] {
        guard points.count > 1 else { return [] }
        
        var profile: [(distance: Double, gradient: Double)] = []
        
        for i in 0..<(points.count - 1) {
            let grad = points[i].gradient(to: points[i + 1])
            profile.append((distance: points[i].distanceFromStart, gradient: grad))
        }
        
        // Add last point with same gradient as previous
        if let last = profile.last {
            profile.append((distance: points.last!.distanceFromStart, gradient: last.gradient))
        }
        
        return profile
    }
    
    /// Find the steepest climb section (highest positive gradient over a minimum distance).
    static func steepestClimb(_ points: [TrackPoint], minDistanceMeters: Double = 100) -> (gradient: Double, startIndex: Int, endIndex: Int)? {
        guard points.count > 1 else { return nil }
        
        var steepest: (gradient: Double, startIndex: Int, endIndex: Int)?
        
        for i in 0..<points.count {
            for j in (i + 1)..<points.count {
                let dist = points[j].distanceFromStart - points[i].distanceFromStart
                guard dist >= minDistanceMeters else { continue }
                
                let grad = points[i].gradient(to: points[j])
                if grad > 0, steepest == nil || grad > steepest!.gradient {
                    steepest = (gradient: grad, startIndex: i, endIndex: j)
                }
            }
        }
        
        return steepest
    }
    
    /// Classify the difficulty of a gradient value.
    static func gradientDifficulty(_ gradient: Double) -> GradientDifficulty {
        let absGrad = abs(gradient)
        if absGrad < 3 { return .easy }
        if absGrad < 8 { return .moderate }
        if absGrad < 15 { return .hard }
        return .extreme
    }
}

/// Difficulty classification for gradients.
enum GradientDifficulty: String {
    case easy = "Easy"
    case moderate = "Moderate"
    case hard = "Hard"
    case extreme = "Extreme"
    
    var color: String {
        switch self {
        case .easy: return "green"
        case .moderate: return "orange"
        case .hard: return "red"
        case .extreme: return "purple"
        }
    }
}
