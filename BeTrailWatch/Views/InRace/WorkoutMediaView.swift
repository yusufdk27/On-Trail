//
//  WorkoutMediaView.swift
//  BeTrailWatch
//
//  Right-hand tab of in-race 3-screen navigation.
//  Integrates native watchOS NowPlayingView from WatchKit for music & podcast playback control.
//

import SwiftUI
#if os(watchOS)
import WatchKit
#endif

struct WorkoutMediaView: View {
    var body: some View {
        #if os(watchOS)
        NowPlayingView()
            .background(WatchTheme.background)
        #else
        VStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(WatchTheme.neonGreen)

            Text("Now Playing")
                .font(WatchTheme.preRacePrimary)
                .foregroundStyle(WatchTheme.textPrimary)

            Text("Control audio during race")
                .font(WatchTheme.inRaceSecondaryLabel)
                .foregroundStyle(WatchTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WatchTheme.background)
        #endif
    }
}

// MARK: - Preview

#Preview("Media View") {
    WorkoutMediaView()
}
