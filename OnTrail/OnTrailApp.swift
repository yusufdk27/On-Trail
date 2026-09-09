//
//  OnTrailApp.swift
//  On Trail
//
//  Created by Yusuf Dwi Kurniawan on 31/08/26.
//

import SwiftUI

@main
struct OnTrailApp: App {
    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let strategy = appState.currentStrategy {
                    CourseVisualizerView(strategy: strategy)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity
                        ))
                } else {
                    PaceStrategyListView()
                        .transition(.opacity)
                }
            }
            .environment(appState)
            .preferredColorScheme(appState.appearance.colorScheme)
            .animation(.easeInOut(duration: 0.4), value: appState.currentStrategy?.id)
            .onAppear {
                WatchConnectivityManager.shared.activate()
            }
        }
    }
}
