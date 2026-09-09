//
//  LocationManager.swift
//  On Trail
//
//  Created by On Trail Team.
//

import Foundation
import CoreLocation

/// CoreLocation wrapper for current location tracking.
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    
    private let manager = CLLocationManager()
    
    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var locationError: String?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
    }
    
    // MARK: - Public API
    
    /// Request location authorization.
    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
    
    /// Start receiving location updates.
    func startUpdating() {
        manager.startUpdatingLocation()
    }
    
    /// Stop receiving location updates.
    func stopUpdating() {
        manager.stopUpdatingLocation()
    }
    
    /// Find the nearest track point to the current location.
    func nearestTrackPoint(in trackPoints: [TrackPoint]) -> (point: TrackPoint, index: Int)? {
        guard let location = currentLocation else { return nil }
        
        var nearestIndex = 0
        var nearestDistance = Double.greatestFiniteMagnitude
        
        for (index, tp) in trackPoints.enumerated() {
            let tpLocation = CLLocation(latitude: tp.latitude, longitude: tp.longitude)
            let distance = location.distance(from: tpLocation)
            if distance < nearestDistance {
                nearestDistance = distance
                nearestIndex = index
            }
        }
        
        guard nearestDistance < 500 else { return nil } // Must be within 500m of track
        return (point: trackPoints[nearestIndex], index: nearestIndex)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error.localizedDescription
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}
