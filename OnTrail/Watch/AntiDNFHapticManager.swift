//
//  AntiDNFHapticManager.swift
//  On Trail
//
//  Created by On Trail Team.
//

import Foundation
import SwiftUI
#if canImport(WatchKit)
import WatchKit
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Proactive Anti-DNF Haptic Trigger Engine for Apple Watch and iPhone companion.
/// Generates distinct sensory feedback to prevent overpacing and manage trail nutrition.
final class AntiDNFHapticManager {
    static let shared = AntiDNFHapticManager()
    
    private init() {}
    
    // MARK: - Haptic Patterns
    
    /// 2x sharp haptic alert when runner is overpacing on early climbs (HR Zone 4-5 spike).
    func playOverpacingAlert() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.failure)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            WKInterfaceDevice.current().play(.retry)
        }
        #elseif os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        }
        #endif
    }
    
    /// Rhythmic reminder to take hydration or energy gel (every 25m or +250m elevation gain).
    func playHydrationFuelAlert() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.directionUp)
        #elseif os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        #endif
    }
    
    /// Directional alert 150-200m before entering a steep climb (>15%) to remind power-hiking.
    func playUpcomingClimbAlert() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.notification)
        #elseif os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        #endif
    }
    
    /// Positive haptic feedback when maintaining target GAP pacing in Zone 2.
    func playPacingSuccessFeedback() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.success)
        #elseif os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }
    
    /// Cut-Off Time (COT) proximity warning when within 15 minutes of station cutoff.
    func playCutOffWarning() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.retry)
        #elseif os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .rigid)
        impact.impactOccurred()
        #endif
    }
}
