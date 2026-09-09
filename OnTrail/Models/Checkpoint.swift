//
//  Checkpoint.swift
//  On Trail
//
//  Created by On Trail Team.
//

import Foundation
import CoreLocation

/// Represents a notable point along the course (aid station, water point, cut-off).
/// Matches professional trail race planning (COROS / UTMB style) with split times,
/// terrain metrics from the previous station, and customizable rest/stop duration per station.
struct Checkpoint: Identifiable, Codable {
    let id: UUID
    let name: String
    let type: CheckpointType
    let latitude: Double
    let longitude: Double
    let distanceFromStart: Double // meters
    
    /// Optional cut-off time in seconds from race start.
    var cutOffTimeSeconds: Double?
    
    /// Optional elevation at this checkpoint in meters.
    var elevation: Double?
    
    /// Estimated arrival time in seconds from race start (computed by strategy engine).
    var estimatedArrivalSeconds: Double?
    
    /// Planned rest / pitstop duration spent AT this specific water station (in seconds).
    /// Default: 300s (5 min) for aid/water stations; 0s for start/finish/summit.
    var plannedStopDurationSeconds: Double = 0
    
    // MARK: - Leg / Split Metrics (From previous checkpoint to this checkpoint)
    
    /// Distance of this leg in meters.
    var legDistanceMeters: Double = 0
    
    /// Elevation gain on this leg in meters.
    var legElevationGain: Double = 0
    
    /// Elevation loss on this leg in meters.
    var legElevationLoss: Double = 0
    
    /// Estimated moving time for this leg in seconds.
    var legMovingTimeSeconds: Double = 0
    
    /// Estimated actual pace for this leg in seconds per km.
    var legPaceSecondsPerKm: Double = 0
    
    init(
        id: UUID = UUID(),
        name: String,
        type: CheckpointType,
        latitude: Double,
        longitude: Double,
        distanceFromStart: Double,
        cutOffTimeSeconds: Double? = nil,
        elevation: Double? = nil,
        estimatedArrivalSeconds: Double? = nil,
        plannedStopDurationSeconds: Double? = nil,
        legDistanceMeters: Double = 0,
        legElevationGain: Double = 0,
        legElevationLoss: Double = 0,
        legMovingTimeSeconds: Double = 0,
        legPaceSecondsPerKm: Double = 0
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.latitude = latitude
        self.longitude = longitude
        self.distanceFromStart = distanceFromStart
        self.cutOffTimeSeconds = cutOffTimeSeconds
        self.elevation = elevation
        self.estimatedArrivalSeconds = estimatedArrivalSeconds
        
        // Default stop duration: 5 min (300s) for water & aid stations, 0 for start/finish/summit
        if let customStop = plannedStopDurationSeconds {
            self.plannedStopDurationSeconds = customStop
        } else {
            switch type {
            case .waterStation, .aidStation, .cutOff:
                self.plannedStopDurationSeconds = 300 // 5 minutes
            default:
                self.plannedStopDurationSeconds = 0
            }
        }
        
        self.legDistanceMeters = legDistanceMeters
        self.legElevationGain = legElevationGain
        self.legElevationLoss = legElevationLoss
        self.legMovingTimeSeconds = legMovingTimeSeconds
        self.legPaceSecondsPerKm = legPaceSecondsPerKm
    }
    
    // MARK: - Coordinates & Distances
    
    /// The coordinate for MapKit usage.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Distance from start in kilometers.
    var distanceKm: Double {
        distanceFromStart / 1000.0
    }
    
    /// Leg distance in kilometers.
    var legDistanceKm: Double {
        legDistanceMeters / 1000.0
    }
    
    // MARK: - Departures & Durations
    
    /// Estimated departure time in seconds from race start (arrival + stop duration).
    var estimatedDepartureSeconds: Double? {
        guard let arrival = estimatedArrivalSeconds else { return nil }
        return arrival + plannedStopDurationSeconds
    }
    
    /// Formatted estimated arrival time.
    var estimatedArrivalFormatted: String {
        guard let seconds = estimatedArrivalSeconds else { return "--:--" }
        return PacingZone.formatDuration(seconds)
    }
    
    /// Formatted estimated departure time.
    var estimatedDepartureFormatted: String {
        guard let seconds = estimatedDepartureSeconds else { return "--:--" }
        return PacingZone.formatDuration(seconds)
    }
    
    /// Formatted planned stop duration string (e.g., "5m", "10m", "0m").
    var plannedStopFormatted: String {
        let mins = Int(plannedStopDurationSeconds.rounded()) / 60
        if mins == 0 { return "0m" }
        return "\(mins)m"
    }
    
    /// Formatted leg moving duration (e.g., "1h 12m" or "48m").
    var legMovingDurationFormatted: String {
        guard legMovingTimeSeconds > 0 else { return "--:--" }
        return PacingZone.formatDurationShort(legMovingTimeSeconds)
    }
    
    /// Formatted leg actual pace.
    var legPaceFormatted: String {
        guard legPaceSecondsPerKm > 0 else { return "--:--" }
        return PacingZone.formatPace(legPaceSecondsPerKm)
    }
    
    /// Formatted cut-off time.
    var cutOffTimeFormatted: String? {
        guard let seconds = cutOffTimeSeconds else { return nil }
        return PacingZone.formatDuration(seconds)
    }
    
    /// Time margin before cut-off (positive = safe, negative = over).
    var cutOffMarginSeconds: Double? {
        guard let cutOff = cutOffTimeSeconds, let arrival = estimatedArrivalSeconds else { return nil }
        return cutOff - arrival
    }
    
    // MARK: - Real-World Clock Time Helpers
    
    /// Formatted arrival clock time of day given a race start date (e.g., "07:15 AM").
    func arrivalClockFormatted(raceStartTime: Date) -> String {
        guard let seconds = estimatedArrivalSeconds else { return "--:--" }
        let date = raceStartTime.addingTimeInterval(seconds)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    /// Formatted departure clock time of day given a race start date (e.g., "07:20 AM").
    func departureClockFormatted(raceStartTime: Date) -> String {
        guard let seconds = estimatedDepartureSeconds else { return "--:--" }
        let date = raceStartTime.addingTimeInterval(seconds)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

/// Types of checkpoints along the course.
enum CheckpointType: String, Codable, CaseIterable {
    case waterStation
    case aidStation
    case cutOff
    case start
    case finish
    case summit
    
    /// SF Symbol icon for this checkpoint type.
    var icon: String {
        switch self {
        case .waterStation: return "drop.fill"
        case .aidStation: return "cross.case.fill"
        case .cutOff: return "clock.badge.exclamationmark"
        case .start: return "flag.fill"
        case .finish: return "flag.checkered"
        case .summit: return "mountain.2.fill"
        }
    }
    
    /// Display name for this checkpoint type.
    var displayName: String {
        switch self {
        case .waterStation: return "Water Station"
        case .aidStation: return "Aid Station"
        case .cutOff: return "Cut-Off"
        case .start: return "Start"
        case .finish: return "Finish"
        case .summit: return "Summit"
        }
    }
}
