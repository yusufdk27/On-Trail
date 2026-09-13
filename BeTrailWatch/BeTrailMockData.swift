//
//  BeTrailMockData.swift
//  BeTrailWatch
//
//  Static mock data factory for Xcode Previews and simulator testing.
//  All routes are fully self-contained — no iPhone companion sync needed.
//

import Foundation

// MARK: - Mock Route Library

enum BeTrailMockData {

    // MARK: Route Collection (5 routes for HomeView)

    static let routes: [RaceStrategy] = [
        slu2025Strategy,
        merdeka25kStrategy,
        bromo42kStrategy,
        papandayan30kStrategy,
        salak10kStrategy
    ]

    // MARK: - SLU 2025 50 km (Primary Preview Route)
    // Salak-Lawu Ultra 2025 — Merapi foothills loop
    // 52.25 km | +3,379 m | -3,380 m | Est. 19h 45m

    static let slu2025Strategy: RaceStrategy = {
        let totalKm = 52.25
        let profile: [(km: Double, ele: Double)] = [
            (0.00, 550), (3.0, 680), (6.0, 920), (9.0, 1200),
            (12.0, 1560), (15.0, 1850), (17.5, 1620), (20.0, 1380),
            (22.5, 1580), (25.0, 1820), (27.0, 2150), (29.5, 1780),
            (32.0, 1580), (34.0, 1740), (36.5, 1900), (38.5, 2200),
            (40.0, 2400), (42.5, 2100), (44.5, 1800), (46.5, 1350),
            (48.5, 980),  (50.5, 680),  (52.25, 550)
        ]
        let points = buildTrackPoints(
            startLat: -7.5756, startLon: 110.4458, totalKm: totalKm, profile: profile
        )
        let segments = buildSegments(from: points)
        let checkpoints = [
            Checkpoint(name: "Start", type: .start, latitude: -7.5756, longitude: 110.4458,
                       distanceFromStart: 0, plannedStopDurationSeconds: 0),
            Checkpoint(name: "WS Kaliurang", type: .waterStation, latitude: -7.5832, longitude: 110.4321,
                       distanceFromStart: 10_000, plannedStopDurationSeconds: 300),
            Checkpoint(name: "WS Turgo", type: .aidStation, latitude: -7.5612, longitude: 110.4112,
                       distanceFromStart: 22_000, plannedStopDurationSeconds: 600),
            Checkpoint(name: "Summit Merapi", type: .summit, latitude: -7.5408, longitude: 110.4458,
                       distanceFromStart: 27_000, plannedStopDurationSeconds: 0),
            Checkpoint(name: "WS Boyong", type: .aidStation, latitude: -7.5510, longitude: 110.4701,
                       distanceFromStart: 34_000, plannedStopDurationSeconds: 600),
            Checkpoint(name: "WS Srowolan", type: .waterStation, latitude: -7.5680, longitude: 110.4558,
                       distanceFromStart: 44_000, plannedStopDurationSeconds: 300),
            Checkpoint(name: "Finish", type: .finish, latitude: -7.5756, longitude: 110.4458,
                       distanceFromStart: 52_250, plannedStopDurationSeconds: 0)
        ]
        return RaceStrategy(
            courseName: "SLU 2025 50 km",
            locationName: "Gunung Merapi, Yogyakarta",
            segments: segments,
            checkpoints: checkpoints,
            allTrackPoints: points,
            pacingZone: PacingZone(basePaceSecondsPerKm: 360)
        )
    }()

    // MARK: - Merdeka Trail Race 25 km
    // 25.35 km | +1,450 m | -1,450 m | Est. 2h 37m

    static let merdeka25kStrategy: RaceStrategy = {
        let totalKm = 25.35
        let profile: [(km: Double, ele: Double)] = [
            (0.0, 320), (3.0, 550), (6.0, 820), (9.0, 1100),
            (11.5, 1380), (13.0, 1200), (15.5, 980), (18.0, 750),
            (20.0, 900), (22.0, 680), (24.0, 480), (25.35, 320)
        ]
        let points = buildTrackPoints(
            startLat: -6.9175, startLon: 107.6191, totalKm: totalKm, profile: profile
        )
        let segments = buildSegments(from: points)
        let checkpoints = [
            Checkpoint(name: "Start", type: .start, latitude: -6.9175, longitude: 107.6191,
                       distanceFromStart: 0, plannedStopDurationSeconds: 0),
            Checkpoint(name: "WS Cihawuk", type: .waterStation, latitude: -6.9020, longitude: 107.6050,
                       distanceFromStart: 8_000, plannedStopDurationSeconds: 180),
            Checkpoint(name: "Puncak Mega", type: .summit, latitude: -6.8890, longitude: 107.5980,
                       distanceFromStart: 13_000, plannedStopDurationSeconds: 0),
            Checkpoint(name: "WS Batas", type: .waterStation, latitude: -6.9100, longitude: 107.6080,
                       distanceFromStart: 19_000, plannedStopDurationSeconds: 180),
            Checkpoint(name: "Finish", type: .finish, latitude: -6.9175, longitude: 107.6191,
                       distanceFromStart: 25_350, plannedStopDurationSeconds: 0)
        ]
        return RaceStrategy(
            courseName: "Merdeka Trail Race",
            locationName: "Gunung Papandayan, Garut",
            segments: segments,
            checkpoints: checkpoints,
            allTrackPoints: points,
            pacingZone: PacingZone(basePaceSecondsPerKm: 320)
        )
    }()

    // MARK: - Bromo Tengger Semeru 42 km

    static let bromo42kStrategy: RaceStrategy = {
        let totalKm = 42.0
        let profile: [(km: Double, ele: Double)] = [
            (0.0, 2100), (4.0, 2400), (8.0, 2700), (12.0, 3000),
            (15.0, 2650), (18.0, 2350), (21.0, 2600), (24.0, 2900),
            (27.0, 2400), (30.0, 2150), (33.0, 2400), (36.0, 2200),
            (39.0, 2050), (42.0, 2100)
        ]
        let points = buildTrackPoints(
            startLat: -7.9425, startLon: 112.9530, totalKm: totalKm, profile: profile
        )
        let segments = buildSegments(from: points)
        let checkpoints = [
            Checkpoint(name: "Start — Tengger Caldera", type: .start, latitude: -7.9425, longitude: 112.9530,
                       distanceFromStart: 0, plannedStopDurationSeconds: 0),
            Checkpoint(name: "WS Penanjakan", type: .aidStation, latitude: -7.9200, longitude: 112.9350,
                       distanceFromStart: 12_000, plannedStopDurationSeconds: 480),
            Checkpoint(name: "WS Ranu Kumbolo", type: .aidStation, latitude: -8.0100, longitude: 112.9800,
                       distanceFromStart: 24_000, plannedStopDurationSeconds: 600),
            Checkpoint(name: "Finish", type: .finish, latitude: -7.9425, longitude: 112.9530,
                       distanceFromStart: 42_000, plannedStopDurationSeconds: 0)
        ]
        return RaceStrategy(
            courseName: "Bromo Sky Race 42 km",
            locationName: "Gunung Bromo, Jawa Timur",
            segments: segments,
            checkpoints: checkpoints,
            allTrackPoints: points,
            pacingZone: PacingZone(basePaceSecondsPerKm: 400)
        )
    }()

    // MARK: - Papandayan Sky Run 30 km

    static let papandayan30kStrategy: RaceStrategy = {
        let totalKm = 30.0
        let profile: [(km: Double, ele: Double)] = [
            (0.0, 1600), (4.0, 1950), (8.0, 2350), (12.0, 2750),
            (14.0, 2400), (17.0, 2100), (20.0, 2350), (23.0, 2600),
            (26.0, 2150), (28.5, 1800), (30.0, 1600)
        ]
        let points = buildTrackPoints(
            startLat: -7.3242, startLon: 107.7372, totalKm: totalKm, profile: profile
        )
        let segments = buildSegments(from: points)
        let checkpoints = [
            Checkpoint(name: "Start", type: .start, latitude: -7.3242, longitude: 107.7372,
                       distanceFromStart: 0, plannedStopDurationSeconds: 0),
            Checkpoint(name: "WS Pondok Salada", type: .waterStation, latitude: -7.3100, longitude: 107.7300,
                       distanceFromStart: 10_000, plannedStopDurationSeconds: 300),
            Checkpoint(name: "Puncak Papandayan", type: .summit, latitude: -7.3010, longitude: 107.7220,
                       distanceFromStart: 14_000, plannedStopDurationSeconds: 0),
            Checkpoint(name: "WS Kawah", type: .waterStation, latitude: -7.3080, longitude: 107.7280,
                       distanceFromStart: 22_000, plannedStopDurationSeconds: 240),
            Checkpoint(name: "Finish", type: .finish, latitude: -7.3242, longitude: 107.7372,
                       distanceFromStart: 30_000, plannedStopDurationSeconds: 0)
        ]
        return RaceStrategy(
            courseName: "Papandayan Sky Run 30 km",
            locationName: "Gunung Papandayan, Garut",
            segments: segments,
            checkpoints: checkpoints,
            allTrackPoints: points,
            pacingZone: PacingZone(basePaceSecondsPerKm: 380)
        )
    }()

    // MARK: - Salak Peak Sprint 10 km

    static let salak10kStrategy: RaceStrategy = {
        let totalKm = 10.0
        let profile: [(km: Double, ele: Double)] = [
            (0.0, 800), (2.0, 1100), (4.0, 1500), (6.0, 1900),
            (7.5, 2211), (8.5, 1800), (9.5, 1200), (10.0, 800)
        ]
        let points = buildTrackPoints(
            startLat: -6.7212, startLon: 106.7317, totalKm: totalKm, profile: profile
        )
        let segments = buildSegments(from: points)
        let checkpoints = [
            Checkpoint(name: "Start", type: .start, latitude: -6.7212, longitude: 106.7317,
                       distanceFromStart: 0, plannedStopDurationSeconds: 0),
            Checkpoint(name: "Puncak Salak I", type: .summit, latitude: -6.7180, longitude: 106.7280,
                       distanceFromStart: 7_500, plannedStopDurationSeconds: 0),
            Checkpoint(name: "Finish", type: .finish, latitude: -6.7212, longitude: 106.7317,
                       distanceFromStart: 10_000, plannedStopDurationSeconds: 0)
        ]
        return RaceStrategy(
            courseName: "Salak Peak Sprint 10 km",
            locationName: "Gunung Salak, Bogor",
            segments: segments,
            checkpoints: checkpoints,
            allTrackPoints: points,
            pacingZone: PacingZone(basePaceSecondsPerKm: 280)
        )
    }()

    // MARK: - Live Race Preview Mock

    /// Pre-configured store state for in-race view previews.
    static var liveRaceStore: WatchStrategyStore {
        let store = WatchStrategyStore(strategy: slu2025Strategy)
        store.raceState = .active
        store.currentDistanceMeters = 1_560
        store.currentElevation = 850
        store.actualPaceSecondsPerKm = 360
        return store
    }

    static var liveRaceWorkout: WatchWorkoutManager {
        let w = WatchWorkoutManager.shared
        w.heartRate = 104
        w.elapsedTimeSeconds = 474     // 7:54
        w.distanceMeters = 1_560
        return w
    }

    // MARK: - Private Track Builders

    /// Generates a smooth loop GPX track from an elevation profile.
    /// Uses a Lissajous-like parametric curve for realistic non-circular loop shapes.
    static func buildTrackPoints(
        startLat: Double,
        startLon: Double,
        totalKm: Double,
        profile: [(km: Double, ele: Double)]
    ) -> [TrackPoint] {
        let pointCount = max(200, Int(totalKm * 20))
        var points: [TrackPoint] = []

        // Scale factor: 1 degree ≈ 111 km
        let latRadius = (totalKm / (2 * .pi)) / 111.0
        let lonRadius = latRadius * 1.25  // slightly wider than tall

        for i in 0...pointCount {
            let t = Double(i) / Double(pointCount)
            let angle = t * 2 * .pi

            // Lissajous variation: figure-8-like loop for realism
            let lat = startLat + latRadius * sin(angle)
            let lon = startLon + lonRadius * sin(angle * 2) * 0.5 + lonRadius * cos(angle) * 0.5

            let kmProgress = t * totalKm
            let elevation = smoothInterpolate(at: kmProgress, profile: profile)
            let distanceFromStart = t * totalKm * 1000.0

            points.append(TrackPoint(
                latitude: lat,
                longitude: lon,
                elevation: elevation,
                distanceFromStart: distanceFromStart
            ))
        }
        return points
    }

    /// Cosine-smooth elevation interpolation between profile keyframes.
    private static func smoothInterpolate(
        at km: Double,
        profile: [(km: Double, ele: Double)]
    ) -> Double {
        guard profile.count > 1 else { return profile.first?.ele ?? 0 }
        for i in 0..<(profile.count - 1) {
            let p0 = profile[i], p1 = profile[i + 1]
            guard km >= p0.km && km <= p1.km else { continue }
            let t = (km - p0.km) / max(0.001, p1.km - p0.km)
            let smoothT = (1 - cos(t * .pi)) / 2  // cosine ease
            return p0.ele + (p1.ele - p0.ele) * smoothT
        }
        return profile.last?.ele ?? 0
    }

    /// Splits a track point array into CourseSegments based on gradient.
    private static func buildSegments(from points: [TrackPoint]) -> [CourseSegment] {
        guard points.count > 2 else { return [] }

        var result: [CourseSegment] = []
        var segBuffer: [TrackPoint] = [points[0]]
        var currentPhase: SegmentPhase = .flat
        var segIdx = 0

        for i in 1..<points.count {
            let grad = points[i - 1].gradient(to: points[i])
            let phase = SegmentPhase.classify(gradient: grad)

            if phase == currentPhase || segBuffer.count < 4 {
                segBuffer.append(points[i])
            } else {
                // Flush current segment
                let pace = typicalPace(for: currentPhase)
                result.append(CourseSegment(
                    phase: currentPhase,
                    trackPoints: segBuffer,
                    segmentIndex: segIdx,
                    targetPaceSecondsPerKm: pace,
                    targetGAPSecondsPerKm: 360
                ))
                segIdx += 1
                segBuffer = [points[i - 1], points[i]]
                currentPhase = phase
            }
        }

        // Flush last segment
        if !segBuffer.isEmpty {
            let pace = typicalPace(for: currentPhase)
            result.append(CourseSegment(
                phase: currentPhase,
                trackPoints: segBuffer,
                segmentIndex: segIdx,
                targetPaceSecondsPerKm: pace,
                targetGAPSecondsPerKm: 360
            ))
        }
        return result
    }

    private static func typicalPace(for phase: SegmentPhase) -> Double {
        switch phase {
        case .climb:   return 900.0  // ~15:00 /km power-hiking
        case .descent: return 380.0  // ~6:20 /km technical descent
        case .flat:    return 420.0  // ~7:00 /km cruising
        }
    }
}
