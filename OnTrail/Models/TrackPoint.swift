//
//  TrackPoint.swift
//  On Trail
//
//  Created by On Trail Team.
//

import Foundation
import CoreLocation

/// Represents a single GPS track point parsed from a GPX file.
struct TrackPoint: Identifiable, Codable, Equatable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let elevation: Double // meters
    let timestamp: Date?
    
    /// Cumulative distance from the start of the track, in meters.
    var distanceFromStart: Double = 0
    
    init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        elevation: Double,
        timestamp: Date? = nil,
        distanceFromStart: Double = 0
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.timestamp = timestamp
        self.distanceFromStart = distanceFromStart
    }
    
    /// The coordinate as a CLLocationCoordinate2D for MapKit usage.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Distance from start in kilometers.
    var distanceKm: Double {
        distanceFromStart / 1000.0
    }
    
    /// Calculate the Haversine distance to another track point, in meters.
    func distance(to other: TrackPoint) -> Double {
        let earthRadius: Double = 6371000 // meters
        
        let lat1 = latitude * .pi / 180
        let lat2 = other.latitude * .pi / 180
        let dLat = (other.latitude - latitude) * .pi / 180
        let dLon = (other.longitude - longitude) * .pi / 180
        
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1) * cos(lat2) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
    
    /// Calculate the gradient percentage to another track point.
    func gradient(to other: TrackPoint) -> Double {
        let horizontalDistance = distance(to: other)
        guard horizontalDistance > 0 else { return 0 }
        let elevationChange = other.elevation - elevation
        return (elevationChange / horizontalDistance) * 100
    }
}
