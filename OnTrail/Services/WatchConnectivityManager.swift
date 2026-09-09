//
//  WatchConnectivityManager.swift
//  On Trail
//
//  Created by On Trail Team.
//

import Foundation
import WatchConnectivity

/// Manages Watch Connectivity session for syncing race strategy to Apple Watch.
@Observable
final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    
    static let shared = WatchConnectivityManager()
    
    var isPaired: Bool = false
    var isReachable: Bool = false
    var lastSyncDate: Date?
    var syncError: String?
    var isSyncing: Bool = false
    
    private override init() {
        super.init()
    }
    
    // MARK: - Session Activation
    
    /// Activate the WCSession if supported.
    func activate() {
        guard WCSession.isSupported() else { return }
        
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
    
    // MARK: - Strategy Sync
    
    /// Send a race strategy to the paired Apple Watch.
    func sendStrategy(_ strategy: RaceStrategy) {
        guard WCSession.isSupported() else {
            syncError = "Watch Connectivity not supported on this device."
            return
        }
        
        let session = WCSession.default
        
        guard session.isPaired else {
            syncError = "No Apple Watch paired with this iPhone."
            return
        }
        
        isSyncing = true
        syncError = nil
        
        do {
            let data = try JSONEncoder().encode(strategy)
            let userInfo: [String: Any] = [
                "strategyData": data,
                "syncTimestamp": Date().timeIntervalSince1970
            ]
            session.transferUserInfo(userInfo)
            lastSyncDate = Date()
            isSyncing = false
        } catch {
            syncError = "Failed to encode strategy: \(error.localizedDescription)"
            isSyncing = false
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.isPaired = session.isPaired
            self.isReachable = session.isReachable
            
            if let error = error {
                self.syncError = error.localizedDescription
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session becoming inactive
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate session
        session.activate()
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
    }
}
