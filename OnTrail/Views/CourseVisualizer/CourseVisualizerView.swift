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
                // Leading: Circular Frosted Glass Back Button
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        appState.clearCurrentCourse()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 0.8))
                            .shadow(color: Color.black.opacity(0.12), radius: 6, y: 2)
                    }
                }
                
                // Center: Floating Frosted Capsule Course Name Pill
                ToolbarItem(placement: .principal) {
                    Text(strategy.courseName)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(Theme.cardBorder, lineWidth: 0.8))
                        .shadow(color: Color.black.opacity(0.12), radius: 6, y: 2)
                }
                
                // Trailing: Blue Capsule Save Button
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        withAnimation {
                            isSavedFeedback = true
                        }
                        WatchConnectivityManager.shared.sendStrategy(strategy)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                isSavedFeedback = false
                            }
                        }
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.small)
                    .tint(Color.blue)
                    .shadow(color: Color.blue.opacity(0.3), radius: 6, y: 2)
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
                metricsSummaryRow
                
                // Swift Charts Elevation Profile (Lime-Green Gradient)
                ElevationProfileChart(
                    strategy: strategy,
                    focusedSegment: currentSegment,
                    selectedDistance: $selectedDistance
                )
                
                if currentSegment == nil {
                    // SCREEN 2 (Start - End): Goal Finish + Water Station + Course Strategy
                    goalFinishSection
                    
                    waterStationSummaryCard
                    
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
    
    // MARK: - Segment Switcher Header (Responsive between Screen 1 vs 2, 3, 4)
    
    private var segmentSwitcherHeader: some View {
        Group {
            if selectedSegmentIndex == -1 && sheetDetent == .fraction(0.40) {
                // Screen 1: Preview GPX (Collapsed)
                // Left: "Start - End" title
                // Right: `<` and `>` buttons grouped together
                HStack {
                    Text(segmentTitle)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Button {
                            navigateSegment(delta: -1)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                                .frame(width: 28, height: 28)
                                .background(Color(uiColor: .systemGray6), in: Circle())
                                .overlay(Circle().stroke(Color.black.opacity(0.06), lineWidth: 0.8))
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            navigateSegment(delta: 1)
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                                .frame(width: 28, height: 28)
                                .background(Color(uiColor: .systemGray6), in: Circle())
                                .overlay(Circle().stroke(Color.black.opacity(0.06), lineWidth: 0.8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                // Screens 2, 3, 4:
                // Left: `<` button
                // Center: Title
                // Right: `>` button
                HStack {
                    Button {
                        navigateSegment(delta: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(width: 28, height: 28)
                            .background(Color(uiColor: .systemGray6), in: Circle())
                            .overlay(Circle().stroke(Color.black.opacity(0.06), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text(segmentTitle)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    
                    Spacer()
                    
                    Button {
                        navigateSegment(delta: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(width: 28, height: 28)
                            .background(Color(uiColor: .systemGray6), in: Circle())
                            .overlay(Circle().stroke(Color.black.opacity(0.06), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
    
    // MARK: - Metrics Summary Row
    
    private var metricsSummaryRow: some View {
        HStack(spacing: 0) {
            if let seg = currentSegment {
                // Segment-Specific Metrics (Screens 3 & 4)
                // Distance
                VStack(alignment: .leading, spacing: 2) {
                    Text("Distance")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.secondary)
                    
                    HStack(spacing: 4) {
                        Text("/\\")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary)
                        Text(formatMeters(seg.distance))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Average Pace
                VStack(alignment: .leading, spacing: 2) {
                    Text("Average Pace")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.secondary)
                    
                    let adjPace = seg.targetPaceSecondsPerKm * appState.effortFactor
                    Text(PacingZone.formatPace(adjPace, showUnit: false) + " /km")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Elevation
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Elevation")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.secondary)
                    
                    let elevM = seg.phase == .climb ? seg.elevationGain : (seg.phase == .descent ? seg.elevationLoss : seg.elevationGain)
                    Text(String(format: "%.0f m", elevM))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                // Course Overview Metrics (Screens 1 & 2)
                // Distance
                VStack(alignment: .leading, spacing: 2) {
                    Text("Distance")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.secondary)
                    
                    HStack(spacing: 4) {
                        Text("/\\")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary)
                        Text(String(format: "%.2f km", strategy.totalDistanceKm))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Total Ascent
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Ascent")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.secondary)
                    
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(String(format: "%.0f m", strategy.totalElevationGain))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Total Descent
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total Descent")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.secondary)
                    
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.down.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(String(format: "%.0f m", strategy.totalElevationLoss))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
    
    // MARK: - Goal Finish Section (Screen 2)
    
    private var goalFinishSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Goal Finish")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            
            VStack(alignment: .leading, spacing: 10) {
                // Target Time Badge
                HStack(spacing: 5) {
                    Image(systemName: "target")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(red: 1.0, green: 0.58, blue: 0.0))
                    
                    Text("Target Time")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.58, blue: 0.0))
                    
                    Spacer()
                }
                
                // Big Digital Clock
                let dynamicFinish = strategy.dynamicGoalFinishFormatted(
                    effortFactor: appState.effortFactor,
                    pitstopSeconds: appState.pitstopDurationSeconds
                )
                Text(dynamicFinish)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .monospacedDigit()
                
                // Custom Effort Slider (Tortoise - Dotted Track - Hare)
                EffortSliderView(value: Binding(
                    get: { appState.effortSliderValue },
                    set: { appState.effortSliderValue = $0 }
                ))
                .padding(.top, 2)
                
                // 3-Column Summary Metrics
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(strategy.dynamicAveragePaceFormatted(effortFactor: appState.effortFactor))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Average Pace")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(strategy.dynamicAverageGAPFormatted(effortFactor: appState.effortFactor))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Average GAP")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.0f m", strategy.totalElevationGain))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Elevation")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.top, 4)
            }
            .padding(14)
            .background(Theme.slateGray)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.cardBorder, lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 5, y: 1.5)
        }
    }
    
    // MARK: - Water Station Summary Card (Screen 2)
    
    private var waterStationSummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0))
                
                Text("Total time spent at Water Station")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0))
                
                Spacer()
            }
            
            let stopSecs = Int(appState.pitstopDurationSeconds)
            let hours = stopSecs / 3600
            let minutes = (stopSecs % 3600) / 60
            let seconds = stopSecs % 60
            let timeStr = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            
            Text(timeStr)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.slateGray)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 5, y: 1.5)
    }
    
    // MARK: - Helpers
    
    private func formatMeters(_ meters: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        f.maximumFractionDigits = 0
        let str = f.string(from: NSNumber(value: meters)) ?? String(format: "%.0f", meters)
        return "\(str) m"
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
