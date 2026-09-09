//
//  AppState.swift
//  On Trail
//
//  Created by On Trail Team.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import CoreLocation
import MapKit

/// Visual theme appearance preference
enum AppAppearance: String, CaseIterable, Identifiable {
    case system = "System"
    case dark = "Dark"
    case light = "Light"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "Auto (Sistem)"
        case .dark: return "Mode Gelap"
        case .light: return "Mode Terang"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}

/// Global app state managing the GPX import → analysis → strategy pipeline,
/// saved course library, effort level, and pitstop durations.
@Observable
final class AppState {
    
    /// Current appearance theme mode (system auto, forced dark, or forced light).
    var appearance: AppAppearance = {
        if let raw = UserDefaults.standard.string(forKey: "app_appearance_mode"),
           let app = AppAppearance(rawValue: raw) {
            return app
        }
        return .system
    }() {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: "app_appearance_mode")
        }
    }
    
    /// Toggle between appearance modes
    func toggleAppearance() {
        switch appearance {
        case .dark: appearance = .light
        case .light: appearance = .system
        case .system: appearance = .dark
        }
    }
    
    /// Stored list of all imported race strategies.
    var savedStrategies: [RaceStrategy] = []
    
    /// The currently active race strategy for the visualizer/strategy view.
    var currentStrategy: RaceStrategy?
    
    /// Effort slider value: 0.0 (Light) ... 0.5 (Neutral) ... 1.0 (Challenging)
    var effortSliderValue: Double = 0.5
    
    /// Planned race start time of day (used to predict clock arrival times at checkpoints).
    var raceStartTime: Date = {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 6
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    /// Total planned rest/stop duration across all water stations and checkpoints.
    var pitstopDurationSeconds: Double {
        currentStrategy?.totalStationStopDurationSeconds ?? 0
    }
    
    /// Whether a GPX file is currently being processed.
    var isProcessing: Bool = false
    
    /// Error message from import/parsing.
    var importError: String?
    
    /// Whether the file importer sheet is presented.
    var showingFileImporter: Bool = false
    
    /// Whether the paste XML sheet/modal is presented.
    var showingPasteSheet: Bool = false
    
    /// Selected checkpoint for editing COT / details.
    var selectedCheckpoint: Checkpoint?
    
    /// Whether the checkpoint editor sheet is presented.
    var showingCheckpointEditor: Bool = false
    
    /// User's base pace in seconds per km.
    var basePaceSecondsPerKm: Double = 360 // 6:00/km default
    
    /// Navigation path for drill-downs.
    var navigationPath = NavigationPath()
    
    /// Processing progress (0.0 to 1.0).
    var processingProgress: Double = 0
    
    /// Processing status message.
    var processingStatus: String = ""
    
    private let storageKey = "on_trail_saved_courses_v1"
    
    // MARK: - Computed Properties
    
    /// Multiplier derived from effortSliderValue (0.0 = Light / 1.25x time, 1.0 = Challenging / 0.78x time).
    var effortFactor: Double {
        1.25 - (effortSliderValue * 0.47)
    }
    
    // MARK: - Lifecycle & Persistence
    
    init() {
        loadSavedStrategies()
    }
    
    /// Load stored courses from UserDefaults.
    func loadSavedStrategies() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoder = JSONDecoder()
            savedStrategies = try decoder.decode([RaceStrategy].self, from: data)
        } catch {
            print("Failed to decode saved strategies: \(error.localizedDescription)")
        }
    }
    
    /// Persist courses to UserDefaults.
    func persistStrategies() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(savedStrategies)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save strategies: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Course Selection & Deletion
    
    /// Select a course from the list and activate the strategy view.
    func selectStrategy(_ strategy: RaceStrategy) {
        currentStrategy = strategy
        WatchConnectivityManager.shared.sendStrategy(strategy)
    }
    
    /// Delete a strategy from the saved list.
    func deleteStrategy(id: UUID) {
        savedStrategies.removeAll { $0.id == id }
        if currentStrategy?.id == id {
            currentStrategy = nil
        }
        persistStrategies()
    }
    
    /// Close the active course and return to the Pace Strategy course list.
    func clearCurrentCourse() {
        currentStrategy = nil
        navigationPath = NavigationPath()
    }
    
    // MARK: - Station Stop Duration Adjustments (COROS Style)
    
    /// Formatted total pitstop time across all stations.
    var pitstopFormatted: String {
        let total = Int(pitstopDurationSeconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    /// Adjust planned stop duration at a specific water station / checkpoint by delta minutes (COROS style).
    func adjustStationStopMinutes(checkpointId: UUID, deltaMinutes: Int) {
        guard let current = currentStrategy else { return }
        
        let updatedRawCheckpoints = current.checkpoints.map { cp -> Checkpoint in
            guard cp.id == checkpointId else { return cp }
            var mutableCP = cp
            let currentStop = cp.plannedStopDurationSeconds
            let newStop = max(0, currentStop + Double(deltaMinutes * 60))
            mutableCP.plannedStopDurationSeconds = newStop
            return mutableCP
        }
        
        let recomputed = StrategyEngine.computeCheckpointArrivals(
            updatedRawCheckpoints,
            segments: current.segments,
            pacingZone: current.pacingZone
        )
        
        let updatedStrategy = RaceStrategy(
            id: current.id,
            courseName: current.courseName,
            locationName: current.locationName,
            segments: current.segments,
            checkpoints: recomputed,
            allTrackPoints: current.allTrackPoints,
            pacingZone: current.pacingZone,
            createdAt: current.createdAt
        )
        
        currentStrategy = updatedStrategy
        if let idx = savedStrategies.firstIndex(where: { $0.id == updatedStrategy.id }) {
            savedStrategies[idx] = updatedStrategy
            persistStrategies()
        }
        WatchConnectivityManager.shared.sendStrategy(updatedStrategy)
    }
    
    /// Set planned stop duration at a specific water station / checkpoint in seconds.
    func setStationStopSeconds(checkpointId: UUID, seconds: Double) {
        guard let current = currentStrategy else { return }
        
        let updatedRawCheckpoints = current.checkpoints.map { cp -> Checkpoint in
            guard cp.id == checkpointId else { return cp }
            var mutableCP = cp
            mutableCP.plannedStopDurationSeconds = max(0, seconds)
            return mutableCP
        }
        
        let recomputed = StrategyEngine.computeCheckpointArrivals(
            updatedRawCheckpoints,
            segments: current.segments,
            pacingZone: current.pacingZone
        )
        
        let updatedStrategy = RaceStrategy(
            id: current.id,
            courseName: current.courseName,
            locationName: current.locationName,
            segments: current.segments,
            checkpoints: recomputed,
            allTrackPoints: current.allTrackPoints,
            pacingZone: current.pacingZone,
            createdAt: current.createdAt
        )
        
        currentStrategy = updatedStrategy
        if let idx = savedStrategies.firstIndex(where: { $0.id == updatedStrategy.id }) {
            savedStrategies[idx] = updatedStrategy
            persistStrategies()
        }
        WatchConnectivityManager.shared.sendStrategy(updatedStrategy)
    }
    
    /// Apply a uniform stop duration to all water/aid stations (e.g. 5 minutes).
    func applyUniformStationStop(minutes: Int) {
        guard let current = currentStrategy else { return }
        let stopSeconds = Double(max(0, minutes * 60))
        
        let updatedRaw = current.checkpoints.map { cp -> Checkpoint in
            var mutable = cp
            if cp.type == .waterStation || cp.type == .aidStation || cp.type == .cutOff {
                mutable.plannedStopDurationSeconds = stopSeconds
            }
            return mutable
        }
        
        let recomputed = StrategyEngine.computeCheckpointArrivals(
            updatedRaw,
            segments: current.segments,
            pacingZone: current.pacingZone
        )
        
        let updatedStrategy = RaceStrategy(
            id: current.id,
            courseName: current.courseName,
            locationName: current.locationName,
            segments: current.segments,
            checkpoints: recomputed,
            allTrackPoints: current.allTrackPoints,
            pacingZone: current.pacingZone,
            createdAt: current.createdAt
        )
        
        currentStrategy = updatedStrategy
        if let idx = savedStrategies.firstIndex(where: { $0.id == updatedStrategy.id }) {
            savedStrategies[idx] = updatedStrategy
            persistStrategies()
        }
        WatchConnectivityManager.shared.sendStrategy(updatedStrategy)
    }
    
    /// Reset all station stops to 0 minutes.
    func resetAllStationStops() {
        applyUniformStationStop(minutes: 0)
    }
    
    /// Backward-compatible alias for resetting pitstops.
    func resetPitstop() {
        resetAllStationStops()
    }
    
    /// Backward-compatible uniform adjustment of pitstops across stations.
    func adjustPitstopMinutes(_ deltaMinutes: Int) {
        guard let current = currentStrategy, !current.checkpoints.isEmpty else { return }
        let currentTotalMin = Int(pitstopDurationSeconds / 60)
        let count = max(1, current.checkpoints.count)
        let newPerStationMin = max(0, (currentTotalMin / count) + deltaMinutes)
        applyUniformStationStop(minutes: newPerStationMin)
    }
    
    // MARK: - GPX Import from File URL
    
    /// Import and process a GPX file directly from iOS Files picker.
    func importGPX(from url: URL) {
        isProcessing = true
        importError = nil
        processingProgress = 0
        processingStatus = "Membuka file GPX..."
        
        Task { @MainActor in
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                // Step 1: Read Data safely
                processingProgress = 0.15
                processingStatus = "Membaca data file..."
                
                var fileData: Data?
                var coordinateError: NSError?
                let coordinator = NSFileCoordinator()
                
                coordinator.coordinate(readingItemAt: url, options: .withoutChanges, error: &coordinateError) { readURL in
                    fileData = try? Data(contentsOf: readURL)
                }
                
                if let coordinateError {
                    print("Coordination warning: \(coordinateError.localizedDescription)")
                }
                
                guard let data = fileData ?? (try? Data(contentsOf: url)), !data.isEmpty else {
                    throw GPXImportError.fileAccessDenied
                }
                
                // Step 2: Parse GPX
                processingProgress = 0.35
                processingStatus = "Mem-parsing titik elevasi & koordinat..."
                
                let parser = GPXParser()
                let result = try parser.parse(data: data)
                
                guard !result.trackPoints.isEmpty else {
                    throw GPXImportError.noTrackPoints
                }
                
                // Fallback track name from file name if generic
                let fileName = url.deletingPathExtension().lastPathComponent
                let resolvedCourseName = (result.trackName == "Trail Course" || result.trackName.isEmpty) ? fileName : result.trackName
                
                // Step 3: Reverse Geocode first coordinate to find Regency/Region
                processingProgress = 0.55
                processingStatus = "Menemukan lokasi geografis rute..."
                
                var detectedLocation: String? = nil
                if let firstPoint = result.trackPoints.first {
                    detectedLocation = await reverseGeocode(latitude: firstPoint.latitude, longitude: firstPoint.longitude)
                }
                
                // Step 4: Analyze & Generate Strategy
                processingProgress = 0.75
                processingStatus = "Menganalisis profil elevasi & GAP..."
                
                try await Task.sleep(for: .milliseconds(250))
                
                let modifiedResult = GPXParser.GPXResult(
                    trackName: resolvedCourseName,
                    trackPoints: result.trackPoints,
                    waypoints: result.waypoints
                )
                
                let strategy = StrategyEngine.generateStrategy(
                    from: modifiedResult,
                    locationName: detectedLocation,
                    basePaceSecondsPerKm: basePaceSecondsPerKm
                )
                
                processingProgress = 1.0
                processingStatus = "Strategi On Trail siap!"
                
                try await Task.sleep(for: .milliseconds(150))
                
                // Add to saved list (avoid duplicate ids)
                savedStrategies.removeAll { $0.courseName == strategy.courseName }
                savedStrategies.insert(strategy, at: 0)
                persistStrategies()
                
                currentStrategy = strategy
                isProcessing = false
                
                // Sync to Apple Watch
                WatchConnectivityManager.shared.sendStrategy(strategy)
                
            } catch {
                importError = error.localizedDescription
                isProcessing = false
            }
        }
    }
    
    // MARK: - Reverse Geocode Helper
    
    private func reverseGeocode(latitude: Double, longitude: Double) async -> String? {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        if #available(iOS 26.0, *) {
            guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
            do {
                let items = try await request.mapItems
                if let item = items.first {
                    if let locality = item.addressRepresentations?.cityName, !locality.isEmpty {
                        return locality
                    } else if let cityContext = item.addressRepresentations?.cityWithContext, !cityContext.isEmpty {
                        return cityContext
                    } else if let name = item.name, !name.isEmpty {
                        return name
                    }
                }
            } catch {
                return nil
            }
            return nil
        } else {
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = "Trail"
            searchRequest.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                latitudinalMeters: 5000,
                longitudinalMeters: 5000
            )
            let search = MKLocalSearch(request: searchRequest)
            let response = try? await search.start()
            return response?.mapItems.first?.name
        }
    }
    
    // MARK: - GPX Import from Raw String
    
    /// Import and process raw GPX XML string (e.g. from Clipboard / Paste).
    func importGPXString(_ rawXML: String) {
        let trimmed = rawXML.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            importError = "Teks XML kosong."
            return
        }
        
        isProcessing = true
        importError = nil
        processingProgress = 0.2
        processingStatus = "Mem-parsing teks XML GPX..."
        
        Task { @MainActor in
            do {
                let parser = GPXParser()
                let result = try parser.parse(xmlString: trimmed)
                
                guard !result.trackPoints.isEmpty else {
                    throw GPXImportError.noTrackPoints
                }
                
                processingProgress = 0.6
                processingStatus = "Menganalisis profil elevasi..."
                
                var detectedLocation: String? = nil
                if let firstPoint = result.trackPoints.first {
                    detectedLocation = await reverseGeocode(latitude: firstPoint.latitude, longitude: firstPoint.longitude)
                }
                
                try await Task.sleep(for: .milliseconds(250))
                
                let strategy = StrategyEngine.generateStrategy(
                    from: result,
                    locationName: detectedLocation,
                    basePaceSecondsPerKm: basePaceSecondsPerKm
                )
                
                processingProgress = 1.0
                processingStatus = "Strategi rute siap!"
                
                savedStrategies.removeAll { $0.courseName == strategy.courseName }
                savedStrategies.insert(strategy, at: 0)
                persistStrategies()
                
                currentStrategy = strategy
                isProcessing = false
                showingPasteSheet = false
                
                WatchConnectivityManager.shared.sendStrategy(strategy)
                
            } catch {
                importError = error.localizedDescription
                isProcessing = false
            }
        }
    }
    
    // MARK: - Sample Course Helper
    
    /// Load bundled sample GPX course (if requested).
    func loadSampleCourse() {
        isProcessing = true
        importError = nil
        processingProgress = 0.3
        processingStatus = "Memuat rute contoh..."
        
        Task { @MainActor in
            do {
                let parser = GPXParser()
                let result = try parser.parseBundledFile(named: "sample_trail")
                
                let strategy = StrategyEngine.generateStrategy(
                    from: result,
                    locationName: "Karanganyar Regency",
                    basePaceSecondsPerKm: basePaceSecondsPerKm
                )
                
                savedStrategies.removeAll { $0.courseName == strategy.courseName }
                savedStrategies.insert(strategy, at: 0)
                persistStrategies()
                
                currentStrategy = strategy
                isProcessing = false
                WatchConnectivityManager.shared.sendStrategy(strategy)
            } catch {
                importError = error.localizedDescription
                isProcessing = false
            }
        }
    }
    
    // MARK: - Update Base Pace
    
    /// Update base flat pace and instantly recalculate all segment GAP paces and arrival times.
    func updateBasePace(_ newPace: Double) {
        basePaceSecondsPerKm = newPace
        guard let current = currentStrategy else { return }
        let updated = StrategyEngine.recalculatePacing(strategy: current, newBasePaceSecondsPerKm: newPace)
        currentStrategy = updated
        
        if let idx = savedStrategies.firstIndex(where: { $0.id == updated.id }) {
            savedStrategies[idx] = updated
            persistStrategies()
        }
    }
    
    /// Update a checkpoint with custom cut-off times, planned stop durations, or details.
    func updateCheckpoint(_ updated: Checkpoint) {
        guard let current = currentStrategy else { return }
        let updatedRawCheckpoints = current.checkpoints.map { cp in
            cp.id == updated.id ? updated : cp
        }
        let recomputed = StrategyEngine.computeCheckpointArrivals(
            updatedRawCheckpoints,
            segments: current.segments,
            pacingZone: current.pacingZone
        )
        let updatedStrategy = RaceStrategy(
            id: current.id,
            courseName: current.courseName,
            locationName: current.locationName,
            segments: current.segments,
            checkpoints: recomputed,
            allTrackPoints: current.allTrackPoints,
            pacingZone: current.pacingZone,
            createdAt: current.createdAt
        )
        currentStrategy = updatedStrategy
        
        if let idx = savedStrategies.firstIndex(where: { $0.id == updatedStrategy.id }) {
            savedStrategies[idx] = updatedStrategy
            persistStrategies()
        }
        WatchConnectivityManager.shared.sendStrategy(updatedStrategy)
    }
    
    /// Dismiss error.
    func dismissError() {
        importError = nil
    }
}

// MARK: - Errors

enum GPXImportError: LocalizedError {
    case noTrackPoints
    case fileAccessDenied
    
    var errorDescription: String? {
        switch self {
        case .noTrackPoints:
            return "Tidak ditemukan titik rute (track/route points) dalam file GPX ini. Pastikan file memiliki tag <trkpt> atau <rtept>."
        case .fileAccessDenied:
            return "Tidak dapat mengakses file yang dipilih dari sistem iOS Files. Silakan coba lagi atau salin teks XML GPX."
        }
    }
}

// MARK: - GPX UTTypes

extension UTType {
    /// Supported GPX UTTypes to ensure files in iOS Files app are never grayed out.
    static let gpxTypes: [UTType] = {
        var types: [UTType] = [
            .xml,
            .plainText,
            .data,
            .item,
            .content
        ]
        if let gpxCustom = UTType(filenameExtension: "gpx") {
            types.insert(gpxCustom, at: 0)
        }
        if let gpxStandard = UTType("com.topografix.gpx") {
            types.insert(gpxStandard, at: 0)
        }
        return types
    }()
}
