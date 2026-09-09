//
//  GPXParser.swift
//  On Trail
//
//  Created by On Trail Team.
//

import Foundation

/// Parses GPX (GPS Exchange Format) XML files into TrackPoint and Checkpoint arrays.
/// Supports GPX 1.0, 1.1, Garmin extensions, route points (<rtept>), track points (<trkpt>), and waypoints (<wpt>).
final class GPXParser: NSObject, XMLParserDelegate {
    
    // MARK: - Types
    
    enum GPXParserError: LocalizedError {
        case fileNotFound
        case invalidData
        case emptyFile
        case noTrackPoints
        case parsingFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "File GPX tidak ditemukan."
            case .invalidData:
                return "Format data GPX tidak valid atau rusak."
            case .emptyFile:
                return "File GPX kosong."
            case .noTrackPoints:
                return "Tidak ditemukan titik koordinat (track points) dalam file GPX ini."
            case .parsingFailed(let msg):
                return "Gagal memproses GPX: \(msg)"
            }
        }
    }
    
    struct GPXResult {
        let trackName: String
        let trackPoints: [TrackPoint]
        let waypoints: [Checkpoint]
    }
    
    // MARK: - Parser State
    
    private var trackPoints: [TrackPoint] = []
    private var waypoints: [Checkpoint] = []
    private var trackName: String = "Trail Course"
    
    private var currentElement: String = ""
    private var currentCharacters: String = ""
    
    // Track point / route point state
    private var currentLatitude: Double?
    private var currentLongitude: Double?
    private var currentElevation: Double?
    private var currentTimestamp: Date?
    private var isInsideTrackPoint = false
    
    // Waypoint state
    private var isParsingWaypoint = false
    private var waypointName: String = ""
    private var waypointLatitude: Double?
    private var waypointLongitude: Double?
    private var waypointElevation: Double?
    
    // Track & Route hierarchy
    private var insideTrack = false
    private var insideRoute = false
    
    private var parseError: Error?
    
    // MARK: - Date Formatters
    
    private let isoDateFormatterFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private let isoDateFormatterBasic: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    private let fallbackDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
    
    // MARK: - Public API
    
    /// Parse GPX from a URL (handles security scoped URLs and file coordination).
    func parse(fileURL: URL) throws -> GPXResult {
        var fileData: Data?
        var coordinateError: NSError?
        
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(readingItemAt: fileURL, options: .withoutChanges, error: &coordinateError) { readURL in
            fileData = try? Data(contentsOf: readURL)
        }
        
        if let coordinateError = coordinateError {
            // Fallback to direct read
            if let fallback = try? Data(contentsOf: fileURL) {
                fileData = fallback
            } else {
                throw GPXParserError.parsingFailed(coordinateError.localizedDescription)
            }
        }
        
        guard let rawData = fileData ?? (try? Data(contentsOf: fileURL)) else {
            throw GPXParserError.invalidData
        }
        
        return try parse(data: rawData)
    }
    
    /// Parse GPX string directly.
    func parse(xmlString: String) throws -> GPXResult {
        guard let data = xmlString.data(using: .utf8) else {
            throw GPXParserError.invalidData
        }
        return try parse(data: data)
    }
    
    /// Parse raw GPX Data.
    func parse(data: Data) throws -> GPXResult {
        guard !data.isEmpty else {
            throw GPXParserError.emptyFile
        }
        
        // Clean & sanitize data: strip UTF-8 BOM if present
        let cleanedData = sanitizeXMLData(data)
        
        resetState()
        
        let parser = XMLParser(data: cleanedData)
        parser.delegate = self
        parser.shouldProcessNamespaces = false
        parser.shouldReportNamespacePrefixes = false
        parser.shouldResolveExternalEntities = false
        
        let success = parser.parse()
        
        if !success {
            if let error = parseError {
                throw GPXParserError.parsingFailed(error.localizedDescription)
            }
            if let parserErr = parser.parserError {
                throw GPXParserError.parsingFailed(parserErr.localizedDescription)
            }
            throw GPXParserError.parsingFailed("Format XML tidak terbaca.")
        }
        
        guard !trackPoints.isEmpty else {
            throw GPXParserError.noTrackPoints
        }
        
        // Calculate cumulative distances
        let pointsWithDistance = calculateCumulativeDistances(trackPoints)
        
        // Assign distances & nearest elevations to waypoints
        let waypointsWithDistance = assignWaypointDistances(waypoints, trackPoints: pointsWithDistance)
        
        return GPXResult(
            trackName: trackName,
            trackPoints: pointsWithDistance,
            waypoints: waypointsWithDistance
        )
    }
    
    /// Parse a bundled GPX file.
    func parseBundledFile(named fileName: String) throws -> GPXResult {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "gpx") else {
            throw GPXParserError.fileNotFound
        }
        return try parse(fileURL: url)
    }
    
    // MARK: - Sanitization & Helpers
    
    private func sanitizeXMLData(_ data: Data) -> Data {
        var bytes = [UInt8](data)
        
        // Check and strip UTF-8 BOM (0xEF, 0xBB, 0xBF)
        if bytes.count >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF {
            bytes.removeFirst(3)
            return Data(bytes)
        }
        
        // Check if string can be decoded as UTF-8 or Latin-1
        if let utf8String = String(data: data, encoding: .utf8) {
            return Data(utf8String.utf8)
        } else if let latin1String = String(data: data, encoding: .isoLatin1) {
            return Data(latin1String.utf8)
        }
        
        return data
    }
    
    private func resetState() {
        trackPoints = []
        waypoints = []
        trackName = "Trail Course"
        currentElement = ""
        currentCharacters = ""
        currentLatitude = nil
        currentLongitude = nil
        currentElevation = nil
        currentTimestamp = nil
        isInsideTrackPoint = false
        isParsingWaypoint = false
        waypointName = ""
        waypointLatitude = nil
        waypointLongitude = nil
        waypointElevation = nil
        insideTrack = false
        insideRoute = false
        parseError = nil
    }
    
    private func calculateCumulativeDistances(_ points: [TrackPoint]) -> [TrackPoint] {
        guard !points.isEmpty else { return [] }
        
        var result: [TrackPoint] = []
        result.reserveCapacity(points.count)
        var cumulativeDistance: Double = 0
        
        var firstPoint = points[0]
        firstPoint.distanceFromStart = 0
        result.append(firstPoint)
        
        for i in 1..<points.count {
            let dist = points[i - 1].distance(to: points[i])
            cumulativeDistance += dist
            
            var point = points[i]
            point.distanceFromStart = cumulativeDistance
            result.append(point)
        }
        
        return result
    }
    
    private func assignWaypointDistances(_ wpts: [Checkpoint], trackPoints: [TrackPoint]) -> [Checkpoint] {
        guard !trackPoints.isEmpty else { return wpts }
        
        return wpts.map { wpt in
            var closest = trackPoints[0]
            var minDist = Double.greatestFiniteMagnitude
            
            let wptPoint = TrackPoint(latitude: wpt.latitude, longitude: wpt.longitude, elevation: 0)
            
            for tp in trackPoints {
                let d = wptPoint.distance(to: tp)
                if d < minDist {
                    minDist = d
                    closest = tp
                }
            }
            
            let finalElevation = wpt.elevation ?? closest.elevation
            
            return Checkpoint(
                id: wpt.id,
                name: wpt.name,
                type: wpt.type,
                latitude: wpt.latitude,
                longitude: wpt.longitude,
                distanceFromStart: closest.distanceFromStart,
                cutOffTimeSeconds: wpt.cutOffTimeSeconds,
                elevation: finalElevation,
                estimatedArrivalSeconds: wpt.estimatedArrivalSeconds
            )
        }.sorted { $0.distanceFromStart < $1.distanceFromStart }
    }
    
    private func parseDate(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if let d = isoDateFormatterFractional.date(from: trimmed) { return d }
        if let d = isoDateFormatterBasic.date(from: trimmed) { return d }
        if let d = fallbackDateFormatter.date(from: trimmed) { return d }
        return nil
    }
    
    private func parseDouble(_ string: String) -> Double? {
        let clean = string.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        return Double(clean)
    }
    
    private func classifyWaypoint(name: String) -> CheckpointType {
        let lower = name.lowercased()
        if lower.contains("water") || lower.contains("hydra") || lower.contains("ws") {
            return .waterStation
        } else if lower.contains("aid") || lower.contains("supply") || lower.contains("feed") || lower.contains("pos") {
            return .aidStation
        } else if lower.contains("cut") || lower.contains("cot") {
            return .cutOff
        } else if lower.contains("start") {
            return .start
        } else if lower.contains("finish") || lower.contains("end") || lower.contains("goal") {
            return .finish
        } else if lower.contains("summit") || lower.contains("peak") || lower.contains("top") || lower.contains("puncak") {
            return .summit
        }
        return .aidStation
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String]
    ) {
        let nameLower = elementName.lowercased()
        currentElement = nameLower
        currentCharacters = ""
        
        switch nameLower {
        case "trk":
            insideTrack = true
            
        case "rte":
            insideRoute = true
            
        case "trkpt", "rtept":
            isInsideTrackPoint = true
            // Support both standard and case-insensitive lat/lon attributes
            let latStr = attributeDict["lat"] ?? attributeDict["Lat"] ?? attributeDict["LAT"] ?? attributeDict["latitude"]
            let lonStr = attributeDict["lon"] ?? attributeDict["Lon"] ?? attributeDict["LON"] ?? attributeDict["longitude"] ?? attributeDict["lng"]
            
            if let latStr, let lonStr, let lat = parseDouble(latStr), let lon = parseDouble(lonStr) {
                currentLatitude = lat
                currentLongitude = lon
            }
            currentElevation = nil
            currentTimestamp = nil
            
        case "wpt":
            isParsingWaypoint = true
            let latStr = attributeDict["lat"] ?? attributeDict["Lat"] ?? attributeDict["LAT"] ?? attributeDict["latitude"]
            let lonStr = attributeDict["lon"] ?? attributeDict["Lon"] ?? attributeDict["LON"] ?? attributeDict["longitude"] ?? attributeDict["lng"]
            
            if let latStr, let lonStr, let lat = parseDouble(latStr), let lon = parseDouble(lonStr) {
                waypointLatitude = lat
                waypointLongitude = lon
            }
            waypointName = ""
            waypointElevation = nil
            
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentCharacters += string
    }
    
    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let nameLower = elementName.lowercased()
        let trimmed = currentCharacters.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch nameLower {
        case "ele":
            if let ele = parseDouble(trimmed) {
                if isParsingWaypoint {
                    waypointElevation = ele
                } else if isInsideTrackPoint {
                    currentElevation = ele
                }
            }
            
        case "time":
            if isInsideTrackPoint {
                currentTimestamp = parseDate(trimmed)
            }
            
        case "name":
            if isParsingWaypoint && !trimmed.isEmpty && waypointName.isEmpty {
                waypointName = trimmed
            } else if (insideTrack || insideRoute) && !trimmed.isEmpty && trackName == "Trail Course" {
                trackName = trimmed
            }
            
        case "trkpt", "rtept":
            if let lat = currentLatitude, let lon = currentLongitude {
                let point = TrackPoint(
                    latitude: lat,
                    longitude: lon,
                    elevation: currentElevation ?? 0.0,
                    timestamp: currentTimestamp
                )
                trackPoints.append(point)
            }
            currentLatitude = nil
            currentLongitude = nil
            currentElevation = nil
            currentTimestamp = nil
            isInsideTrackPoint = false
            
        case "wpt":
            if let lat = waypointLatitude, let lon = waypointLongitude {
                let finalName = waypointName.isEmpty ? "Checkpoint \(waypoints.count + 1)" : waypointName
                let checkpoint = Checkpoint(
                    name: finalName,
                    type: classifyWaypoint(name: finalName),
                    latitude: lat,
                    longitude: lon,
                    distanceFromStart: 0,
                    elevation: waypointElevation
                )
                waypoints.append(checkpoint)
            }
            isParsingWaypoint = false
            waypointLatitude = nil
            waypointLongitude = nil
            waypointName = ""
            waypointElevation = nil
            
        case "trk":
            insideTrack = false
            
        case "rte":
            insideRoute = false
            
        default:
            break
        }
        
        currentCharacters = ""
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred error: Error) {
        // If we already parsed track points, ignore minor trailing tag errors
        if trackPoints.isEmpty {
            parseError = error
        }
    }
}
