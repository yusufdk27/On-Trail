//
//  WatchCompanionApp.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

#if os(watchOS)
@main
struct WatchCompanionApp: App {
    @State private var store = WatchStrategyStore.shared
    
    var body: some Scene {
        WindowGroup {
            if let strategy = store.strategy {
                switch store.raceState {
                case .preRace:
                    WatchPreRunView(strategy: strategy) {
                        store.startRace()
                    }
                case .active, .paused:
                    WatchActiveRaceView(strategy: strategy, store: store)
                case .postRace:
                    WatchPostRunView(strategy: strategy, store: store) {
                        store.raceState = .preRace
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "applewatch.radiowaves.left.and.right")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.neonOrange)
                    Text("Menunggu Rute")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Buka rute di iPhone untuk sync strategi.")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.black.ignoresSafeArea())
            }
        }
    }
}
#endif
