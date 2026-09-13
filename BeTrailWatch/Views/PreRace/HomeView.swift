//
//  HomeView.swift
//  BeTrailWatch
//
//  Root navigation screen for BeTrail Watch app.
//  Displayed as idle/home state before any race is started.
//  Matches the UI sketch: BeTrail title + two large navigation cards.
//

import SwiftUI

struct HomeView: View {
    @Environment(WatchRaceCoordinator.self) private var coordinator

    var body: some View {
        NavigationStack {
            List {
                // MARK: Race Route Card
                NavigationLink {
                    RaceRouteListView()
                } label: {
                    raceRouteCard
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))

                // MARK: Record Activity Card
                NavigationLink {
                    // Free-record activity (future feature placeholder)
                    recordActivityCard
                } label: {
                    recordActivityCardLabel
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
            }
            .listStyle(.plain)
            .background(WatchTheme.background)
            .navigationTitle("BeTrail")
            .navigationBarTitleDisplayMode(.automatic)
        }
    }

    // MARK: - Race Route Card

    private var raceRouteCard: some View {
        WatchCard(background: WatchTheme.cardGreen) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .top) {
                    // Neon route icon
                    Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(WatchTheme.neonGreen)

                    Spacer()

                    WatchMoreButton()
                }

                Spacer().frame(height: 6)

                Text("Race Route")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(WatchTheme.textPrimary)

                Text("\(coordinator.availableRoutes.count) routes")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(WatchTheme.textSecondary)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Record Activity Card Label

    private var recordActivityCardLabel: some View {
        WatchCard(background: WatchTheme.cardGreen) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .top) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(WatchTheme.neonGreen)

                    Spacer()

                    WatchMoreButton()
                }

                Spacer().frame(height: 6)

                Text("Record Activity")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(WatchTheme.textPrimary)

                Text("Free run mode")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(WatchTheme.textSecondary)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Record Activity Destination (Placeholder)

    private var recordActivityCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(WatchTheme.neonGreen)

            Text("Free Run")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(WatchTheme.textPrimary)

            Text("Record without a preset strategy")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(WatchTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                let freeRunStrategy = RaceStrategy(
                    courseName: "Free Run",
                    segments: [],
                    checkpoints: [],
                    allTrackPoints: []
                )
                coordinator.startRace(with: freeRunStrategy)
            } label: {
                Text("Start")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(WatchTheme.neonGreen)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(WatchTheme.background)
    }
}

// MARK: - Preview

#Preview("Home") {
    HomeView()
        .environment(WatchRaceCoordinator.shared)
}
