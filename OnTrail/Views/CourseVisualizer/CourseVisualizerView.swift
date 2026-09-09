//
//  CourseVisualizerView.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI
import MapKit

/// Interactive Course Visualizer & Strategy Builder with Apple Maps Style Bottom Sheet.
/// Matches Gambar 1 (Compact / Peek State ~38% height with full map behind) and
/// Gambar 2 (Expanded State ~88% height with full momentum scrolling).
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
            return "Seg \(seg.segmentIndex + 1): \(seg.phase.displayName)"
        }
        return "Start - End"
    }
    
    private var displayDistanceKm: Double {
        if let seg = currentSegment {
            return seg.distanceKm
        }
        return strategy.totalDistanceKm
    }
    
    private var displayAscentMeters: Double {
        if let seg = currentSegment {
            return seg.elevationGain
        }
        return strategy.totalElevationGain
    }
    
    private var displayDescentMeters: Double {
        if let seg = currentSegment {
            return seg.elevationLoss
        }
        return strategy.totalElevationLoss
    }
    
    private var effortBadgeText: String {
        if appState.effortSliderValue < 0.35 {
            return "Konservatif"
        } else if appState.effortSliderValue > 0.65 {
            return "Race Pace"
        } else {
            return "Target GAP"
        }
    }
    
    private var effortBadgeColor: Color {
        if appState.effortSliderValue < 0.35 {
            return Theme.successGreen
        } else if appState.effortSliderValue > 0.65 {
            return Theme.neonOrange
        } else {
            return Theme.warningYellow
        }
    }
    
    var body: some View {
        NavigationStack {
            CourseMapView(
                strategy: strategy,
                selectedDistance: selectedDistance,
                isFullScreen: true,
                onCheckpointTapped: { checkpoint in
                    appState.selectedCheckpoint = checkpoint
                    appState.showingCheckpointEditor = true
                }
            )
            .ignoresSafeArea()
            .navigationTitle(strategy.courseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        appState.clearCurrentCourse()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                
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
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.small)
                    .tint(Color.blue)
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .sheet(isPresented: .constant(true)) {
                sheetContentView
                    .presentationDetents([.fraction(0.40), .large], selection: $sheetDetent)
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.40)))
                    .interactiveDismissDisabled()
                    .presentationBackground(.regularMaterial)
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
                
                // Summary Metrics Row: Distance, Total Ascent, Total Descent
                metricsSummaryRow
                
                // Swift Charts Elevation Profile (Lime-Green Gradient)
                ElevationProfileChart(
                    strategy: strategy,
                    focusedSegment: currentSegment,
                    selectedDistance: $selectedDistance
                )
                
                // Goal Finish Section
                goalFinishSection
                
                // 3-Phase Energy Pacing Breakdown
                EnergyStrategyPhasesView(
                    strategy: strategy,
                    effortFactor: appState.effortFactor
                )
                
                // Water Stations & Checkpoints Strategy (COROS-Style Per-Station Rest & Leg Splits)
                if !strategy.checkpoints.isEmpty {
                    WaterStationsStrategySectionView(strategy: strategy)
                }
                
                // Sync to Watch CTA Button
                watchSyncButton
                
                Spacer()
                    .frame(height: 50)
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
    
    // MARK: - Native Segment Switcher Carousel
    
    private var segmentSwitcherHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    if selectedSegmentIndex == -1 {
                        selectedSegmentIndex = strategy.segments.count - 1
                    } else if selectedSegmentIndex == 0 {
                        selectedSegmentIndex = -1
                    } else {
                        selectedSegmentIndex -= 1
                    }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .controlSize(.small)
            .tint(Color.secondary)
            
            Spacer()
            
            Text(segmentTitle)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            
            Spacer()
            
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    if selectedSegmentIndex >= strategy.segments.count - 1 {
                        selectedSegmentIndex = -1
                    } else {
                        selectedSegmentIndex += 1
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .controlSize(.small)
            .tint(Color.secondary)
        }
    }
    
    // MARK: - Metrics Summary Row (Distance, Ascent, Descent)
    
    private var metricsSummaryRow: some View {
        HStack(spacing: 0) {
            // Distance
            VStack(alignment: .leading, spacing: 3) {
                Text("DISTANCE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.secondary)
                    .tracking(0.5)
                
                HStack(spacing: 4) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.neonOrange)
                    Text(String(format: "%.2f km", displayDistanceKm))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Total Ascent
            VStack(alignment: .leading, spacing: 3) {
                Text("TOTAL ASCENT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.secondary)
                    .tracking(0.5)
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(SegmentPhase.climb.color)
                    Text(String(format: "+%.0f m", displayAscentMeters))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Total Descent
            VStack(alignment: .leading, spacing: 3) {
                Text("TOTAL DESCENT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.secondary)
                    .tracking(0.5)
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(SegmentPhase.descent.color)
                    Text(String(format: "-%.0f m", displayDescentMeters))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Goal Finish Section (Apple Health / Fitness Native Style)
    
    private var goalFinishSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Row with Apple Activity Badge
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Image(systemName: "flag.checkered.2.crossed")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.neonOrange)
                    
                    Text("GOAL FINISH & TARGET PACING")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.secondary)
                        .tracking(0.8)
                }
                
                Spacer()
                
                Text(effortBadgeText)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(effortBadgeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(effortBadgeColor.opacity(0.16))
                    .clipShape(Capsule())
            }
            
            // Main Big Digital Clock Card + Race Start/Finish Clock Pill
            VStack(alignment: .leading, spacing: 6) {
                let dynamicFinish = strategy.dynamicGoalFinishFormatted(
                    effortFactor: appState.effortFactor,
                    pitstopSeconds: appState.pitstopDurationSeconds
                )
                
                HStack(alignment: .firstTextBaseline) {
                    Text(dynamicFinish)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .monospacedDigit()
                    
                    Spacer()
                    
                    // Race Start & Predicted Clock Finish Pill (Tap to configure flag-off time)
                    Button {
                        showingRaceStartTimePicker = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Theme.neonOrange)
                            Text("\(formattedRaceStart) → \(strategy.dynamicGoalFinishClock(raceStartTime: appState.raceStartTime, effortFactor: appState.effortFactor))")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .controlSize(.mini)
                    .tint(Color.secondary)
                }
                
                Text("ESTIMASI TOTAL DURASI (WAKTU BERGERAK + ISTIRAHAT POS)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                    .tracking(0.5)
                
                // Visual Time Allocation Bar (Moving vs Station Rest)
                timeAllocationBar
            }
            
            // Effort Slider with Multi-spectrum Gradient
            VStack(alignment: .leading, spacing: 6) {
                EffortSliderView(value: Binding(
                    get: { appState.effortSliderValue },
                    set: { appState.effortSliderValue = $0 }
                ))
            }
            .padding(.vertical, 2)
            
            // 3-Column Metrics Grid (Apple Fitness Pillar Layout)
            HStack(spacing: 8) {
                // Column 1: Average Actual Pace
                VStack(alignment: .leading, spacing: 3) {
                    Text("AVG PACE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.secondary)
                        .tracking(0.5)
                    
                    Text(strategy.dynamicAveragePaceFormatted(effortFactor: appState.effortFactor))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    
                    Text("Kecepatan riil gunung")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .frame(height: 38)
                    .background(Theme.borderGray)
                
                // Column 2: Average GAP
                VStack(alignment: .leading, spacing: 3) {
                    Text("TARGET GAP")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.secondary)
                        .tracking(0.5)
                    
                    Text(strategy.dynamicAverageGAPFormatted(effortFactor: appState.effortFactor))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.neonOrange)
                    
                    Text("Ekuivalen jalan datar")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .frame(height: 38)
                    .background(Theme.borderGray)
                
                // Column 3: Elevation Gain
                VStack(alignment: .leading, spacing: 3) {
                    Text("TOTAL D+")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.secondary)
                        .tracking(0.5)
                    
                    Text(String(format: "+%.0f m", strategy.totalElevationGain))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    
                    Text("Total tanjakan rute")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(Theme.surfaceGray)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Trail Running Science Insight Callout (Apple Health Style)
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.neonOrange)
                    .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Konteks Trail: Average Pace vs. GAP")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    
                    Text("Pace riil (\(strategy.dynamicAveragePaceFormatted(effortFactor: appState.effortFactor))) melambat drastis di tanjakan gunung (power hike). Namun GAP (\(strategy.dynamicAverageGAPFormatted(effortFactor: appState.effortFactor))) mencerminkan beban fisiologis & metabolisme detak jantung Anda yang tetap stabil setara jalan datar.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                        .lineSpacing(2)
                }
            }
            .padding(12)
            .background(Theme.neonOrange.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.neonOrange.opacity(0.18), lineWidth: 0.8)
            )
        }
        .padding(16)
        .background(Theme.slateGray)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
    
    // MARK: - Time Allocation Bar (Moving Time vs Station Stop Rest)
    
    private var timeAllocationBar: some View {
        let movingSecs = strategy.dynamicTotalMovingSeconds(effortFactor: appState.effortFactor)
        let stopSecs = appState.pitstopDurationSeconds
        let totalSecs = max(1, movingSecs + stopSecs)
        let movingRatio = movingSecs / totalSecs
        let stopRatio = stopSecs / totalSecs
        
        return VStack(spacing: 6) {
            GeometryReader { barGeo in
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.neonOrange)
                        .frame(width: max(4, barGeo.size.width * CGFloat(movingRatio)))
                    
                    if stopSecs > 0 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.warningYellow)
                            .frame(width: max(4, barGeo.size.width * CGFloat(stopRatio)))
                    }
                }
            }
            .frame(height: 5)
            
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Theme.neonOrange)
                        .frame(width: 6, height: 6)
                    Text("Lari & Hike: \(strategy.dynamicTotalMovingFormatted(effortFactor: appState.effortFactor))")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Theme.warningYellow)
                        .frame(width: 6, height: 6)
                    Text("Pos Istirahat: \(Int(stopSecs / 60))m")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .padding(.top, 4)
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
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 38)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .tint(Theme.neonOrange)
        .foregroundStyle(.black)
        .padding(.top, 6)
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
