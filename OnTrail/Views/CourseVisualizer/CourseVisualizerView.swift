//
//  CourseVisualizerView.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI
import MapKit

/// Interactive Course Visualizer & Strategy Builder with Apple Maps Style Bottom Sheet.
/// Implements the 4-screen design flow:
/// 1. Preview GPX (Screen 1): Full map, floating frosted navbar, collapsed sheet with "Start - End" & `< >`.
/// 2. Detail (Screen 2): Expanded sheet with Goal Finish card, dotted blue Effort Slider, Water Station card, and Strategy table.
/// 3. Detail Strategy (Screen 3): Collapsed sheet for active segment (e.g. `Segment 1: Climb`).
/// 4. Detail detailnya strategy (Screen 4): Expanded sheet for active segment with sub-splits table.
struct CourseVisualizerView: View {
    let strategy: RaceStrategy
    @Environment(AppState.self) private var appState
    
    @State private var selectedDistance: Double? = nil
    @State private var selectedSegmentIndex: Int = -1 // -1 represents "Start - End" (Full course)
    @State private var showingWatchSimulator = false
    @State private var isSavedFeedback = false
    @State private var showingRaceStartTimePicker = false
    
    // Apple HIG Native Bottom Sheet Detent
    @State private var sheetDetent: PresentationDetent = .fraction(0.40)
    
    // Segment currently selected or nil for full route
    private var currentSegment: CourseSegment? {
        guard selectedSegmentIndex >= 0 && selectedSegmentIndex < strategy.segments.count else {
            return nil
        }
        return strategy.segments[selectedSegmentIndex]
    }
    
    private var formattedRaceStart: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: appState.raceStartTime)
    }
    
    private var segmentTitle: String {
        if let seg = currentSegment {
            return "Segment \(seg.segmentIndex + 1): \(seg.phase.displayName)"
        }
        return "Start - End"
    }
    
    private var segmentSubtitle: String {
        if let seg = currentSegment {
            let startKm = seg.startDistance / 1000.0
            let endKm = seg.endDistance / 1000.0
            return String(format: "%.1f km – %.1f km • %@", startKm, endKm, seg.phase.displayName)
        }
        return "Course Overview"
    }
    
    var body: some View {
        NavigationStack {
            CourseMapView(
                strategy: strategy,
                selectedDistance: selectedDistance,
                isFullScreen: true,
                isSheetExpanded: sheetDetent == .large,
                onCheckpointTapped: { checkpoint in
                    appState.selectedCheckpoint = checkpoint
                    appState.showingCheckpointEditor = true
                }
            )
            .ignoresSafeArea()
            .navigationBarBackButtonHidden(true)
            .toolbar {
                // Leading: Circular Frosted Glass Back Button (Matching 44pt target from screenshot)
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        appState.clearCurrentCourse()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 0.8))
                            .shadow(color: Color.black.opacity(0.10), radius: 6, y: 2)
                    }
                    .buttonStyle(.plain)
                }
                
                // Center: Course Name (Clean bold title directly on map, matching screenshot)
                ToolbarItem(placement: .principal) {
                    Text(strategy.courseName)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                // Trailing: Vibrant Blue Capsule Save Button (Matching screenshot)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            isSavedFeedback = true
                        }
                        WatchConnectivityManager.shared.sendStrategy(strategy)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                isSavedFeedback = false
                            }
                        }
                    } label: {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color(red: 0.0, green: 0.48, blue: 1.0), in: Capsule())
                            .shadow(color: Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.35), radius: 6, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: .constant(true)) {
                sheetContentView
                    .presentationDetents([.fraction(0.40), .large], selection: $sheetDetent)
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.40)))
                    .interactiveDismissDisabled()
                    .presentationBackground {
                        Group {
                            if sheetDetent == .large {
                                Theme.background
                            } else {
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                            }
                        }
                        .animation(.easeInOut(duration: 0.28), value: sheetDetent)
                    }
            }
            .overlay(alignment: .top) {
                if isSavedFeedback {
                    savedNotificationBadge
                        .padding(.top, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }
    
    // MARK: - Native Bottom Sheet Content
    
    private var sheetContentView: some View {
        ScrollView(.vertical, showsIndicators: sheetDetent == .large) {
            VStack(spacing: 16) {
                // Segment Switcher Header (< Start - End >)
                segmentSwitcherHeader
                
                // Summary Metrics Row: Distance, Total Ascent / Pace, Total Descent / Elevation
                MetricsSummaryRowView(
                    strategy: strategy,
                    focusedSegment: currentSegment,
                    effortFactor: appState.effortFactor
                )
                
                // Swift Charts Elevation Profile (Lime-Green Gradient)
                ElevationProfileChart(
                    strategy: strategy,
                    focusedSegment: currentSegment,
                    selectedDistance: $selectedDistance
                )
                
                if currentSegment == nil {
                    // SCREEN 2 (Start - End): Goal Finish + Water Station + Course Strategy
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Text("Goal Finish")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.secondary.opacity(0.6))
                            Spacer()
                        }
                        
                        GoalFinishCardView(
                            strategy: strategy,
                            effortFactor: appState.effortFactor,
                            pitstopSeconds: appState.pitstopDurationSeconds,
                            effortSliderValue: Binding(
                                get: { appState.effortSliderValue },
                                set: { appState.effortSliderValue = $0 }
                            )
                        )
                    }
                    
                    WaterStationCardView(pitstopSeconds: appState.pitstopDurationSeconds) {
                        showingRaceStartTimePicker = true
                    }
                    
                    StrategyTableView(
                        strategy: strategy,
                        focusedSegment: nil,
                        effortFactor: appState.effortFactor,
                        onSelectSegment: { index in
                            withAnimation(.easeInOut(duration: 0.25)) {
                                selectedSegmentIndex = index
                            }
                        }
                    )
                } else {
                    // SCREENS 3 & 4 (Segment X: Phase): Segment Splits Strategy
                    StrategyTableView(
                        strategy: strategy,
                        focusedSegment: currentSegment,
                        effortFactor: appState.effortFactor
                    )
                }
                
                Spacer()
                    .frame(height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .sheet(isPresented: $showingWatchSimulator) {
            WatchCompanionSimulatorView(strategy: strategy)
        }
        .sheet(
            isPresented: Binding(
                get: { appState.showingCheckpointEditor && appState.selectedCheckpoint != nil },
                set: { appState.showingCheckpointEditor = $0 }
            )
        ) {
            if let cp = appState.selectedCheckpoint {
                CheckpointEditorSheet(checkpoint: cp) { updated in
                    appState.updateCheckpoint(updated)
                }
            }
        }
        .sheet(isPresented: $showingRaceStartTimePicker) {
            raceStartTimeSheet
        }
    }
    
    // MARK: - Segment Switcher Header (Apple Maps Native Header Style)
    
    private var segmentSwitcherHeader: some View {
        Group {
            if selectedSegmentIndex == -1 && sheetDetent == .fraction(0.40) {
                // Screen 1: Preview GPX (Collapsed)
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(segmentTitle)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        
                        Text(segmentSubtitle)
                            .font(.system(size: 13, weight: .medium, design: .default))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        circularHeaderButton(systemName: "chevron.left") {
                            navigateSegment(delta: -1)
                        }
                        
                        circularHeaderButton(systemName: "chevron.right") {
                            navigateSegment(delta: 1)
                        }
                    }
                }
            } else {
                // Screens 2, 3, 4:
                HStack(alignment: .center) {
                    circularHeaderButton(systemName: "chevron.left") {
                        navigateSegment(delta: -1)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text(segmentTitle)
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        
                        Text(segmentSubtitle)
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    circularHeaderButton(systemName: "chevron.right") {
                        navigateSegment(delta: 1)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private func circularHeaderButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color(uiColor: .systemGray5).opacity(0.85))
                )
                .overlay(
                    Circle()
                        .stroke(Theme.cardBorder, lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 1.5)
        }
        .buttonStyle(.plain)
    }
    
    private func navigateSegment(delta: Int) {
        withAnimation(.easeInOut(duration: 0.22)) {
            if delta > 0 {
                if selectedSegmentIndex >= strategy.segments.count - 1 {
                    selectedSegmentIndex = -1
                } else {
                    selectedSegmentIndex += 1
                }
            } else {
                if selectedSegmentIndex <= -1 {
                    selectedSegmentIndex = strategy.segments.count - 1
                } else if selectedSegmentIndex == 0 {
                    selectedSegmentIndex = -1
                } else {
                    selectedSegmentIndex -= 1
                }
            }
        }
    }
    

    
    // MARK: - Race Start Time Picker Sheet
    
    private var raceStartTimeSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.checkmark.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.neonOrange)
                        .padding(.top, 16)
                    
                    Text("Jam Flag-Off Lomba")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    
                    Text("Tentukan waktu start lomba untuk menghitung estimasi jam tiba & jam keluar di setiap pos air serta jam finish riil Anda.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                DatePicker(
                    "Waktu Start",
                    selection: Binding(
                        get: { appState.raceStartTime },
                        set: { appState.raceStartTime = $0 }
                    ),
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxHeight: 180)
                .padding()
                .background(Theme.surfaceGray)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("Jadwal Race")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Selesai") {
                        showingRaceStartTimePicker = false
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.small)
                    .tint(Theme.neonOrange)
                    .foregroundStyle(.black)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .presentationDetents([.height(380)])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Sync to Watch CTA
    
    private var watchSyncButton: some View {
        Button {
            WatchConnectivityManager.shared.sendStrategy(strategy)
            showingWatchSimulator = true
        } label: {
            Label("Sync to Apple Watch", systemImage: "applewatch.radiowaves.left.and.right")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 38)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .tint(Theme.neonOrange)
        .foregroundStyle(.black)
        .padding(.top, 4)
    }
    
    // MARK: - Feedback Badge
    
    private var savedNotificationBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.successGreen)
            Text("Strategi rute berhasil disimpan & disinkronkan!")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Theme.successGreen.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 8)
    }
}
