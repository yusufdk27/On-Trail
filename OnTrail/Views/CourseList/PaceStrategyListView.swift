//
//  PaceStrategyListView.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI
import UniformTypeIdentifiers

/// Screen 1: Pace Strategy course selection and direct GPX file ingestion.
/// Strictly follows Apple HIG with pure black OLED background, slate gray containers, and high-vis accents.
struct PaceStrategyListView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("hasSeenOnboarding_v1") private var hasSeenOnboarding = false
    @State private var showingOnboarding = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                if appState.savedStrategies.isEmpty {
                    emptyStateView
                } else {
                    courseListView
                }
                
                // Processing overlay when file is being parsed
                if appState.isProcessing {
                    processingOverlay
                }
            }
            .navigationTitle("Pace Strategy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 14) {
                        Button {
                            showingOnboarding = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.secondary)
                        }
                        
                        // Theme Appearance Switcher (Auto, Dark, Light)
                        Menu {
                            ForEach(AppAppearance.allCases) { mode in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        appState.appearance = mode
                                    }
                                } label: {
                                    HStack {
                                        Label(mode.displayName, systemImage: mode.icon)
                                        if appState.appearance == mode {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: appState.appearance.icon)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Theme.neonOrange)
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appState.showingFileImporter = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .fileImporter(
                isPresented: Binding(
                    get: { appState.showingFileImporter },
                    set: { appState.showingFileImporter = $0 }
                ),
                allowedContentTypes: UTType.gpxTypes,
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        appState.importGPX(from: url)
                    }
                case .failure(let error):
                    appState.importError = error.localizedDescription
                }
            }
            .alert("Gagal Membaca GPX", isPresented: Binding(
                get: { appState.importError != nil },
                set: { if !$0 { appState.dismissError() } }
            )) {
                Button("OK", role: .cancel) {
                    appState.dismissError()
                }
            } message: {
                Text(appState.importError ?? "Terjadi kesalahan saat membuka file GPX.")
            }
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView()
            }
            .onAppear {
                if !hasSeenOnboarding && appState.savedStrategies.isEmpty {
                    showingOnboarding = true
                    hasSeenOnboarding = true
                }
            }
        }
    }
    
    // MARK: - Course List
    
    private var courseListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(appState.savedStrategies) { strategy in
                    Button {
                        appState.selectStrategy(strategy)
                    } label: {
                        courseCard(strategy)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            withAnimation {
                                appState.deleteStrategy(id: strategy.id)
                            }
                        } label: {
                            Label("Hapus", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation {
                                appState.deleteStrategy(id: strategy.id)
                            }
                        } label: {
                            Label("Hapus Course", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Course Card (Matching Reference Screen 1)
    
    private func courseCard(_ strategy: RaceStrategy) -> some View {
        HStack(spacing: 14) {
            // Mini 2D Route Thumbnail
            TrackThumbnailView(trackPoints: strategy.allTrackPoints)
                .frame(width: 58, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            // Course Info
            VStack(alignment: .leading, spacing: 5) {
                Text(strategy.courseName)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(String(format: "%.2f km", strategy.totalDistanceKm))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.secondary)
                    
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.secondary)
                        Text(String(format: "%.0f m", strategy.totalElevationGain))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.secondary)
                    }
                    
                    Text(strategy.locationFormatted)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
        }
        .padding(12)
        .background(Theme.slateGray)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 5, y: 2)
    }
    
    // MARK: - Empty State (Apple Standard)
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "map")
                .font(.system(size: 56))
                .foregroundStyle(Color.secondary)
            
            VStack(spacing: 8) {
                Text("Pace Strategy")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                
                Text("Belum ada rute trail tersimpan. Pilih file GPX untuk mulai merancang pace target dan alokasi rest di water station.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button {
                appState.showingFileImporter = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Pilih File GPX")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Theme.neonOrange)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Processing Overlay
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Theme.neonOrange)
                    .scaleEffect(1.3)
                
                Text(appState.processingStatus)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(24)
            .background(Theme.slateGray)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.borderGray, lineWidth: 1)
            )
        }
    }
}

// MARK: - Vector Track Thumbnail View

/// Draws the normalized 2D polyline of the trail route on a dark tile.
struct TrackThumbnailView: View {
    let trackPoints: [TrackPoint]
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                Color(red: 0.14, green: 0.17, blue: 0.18) // Muted map tile background
                
                if trackPoints.count > 1 {
                    let lats = trackPoints.map(\.latitude)
                    let lons = trackPoints.map(\.longitude)
                    let minLat = lats.min() ?? 0
                    let maxLat = lats.max() ?? 1
                    let minLon = lons.min() ?? 0
                    let maxLon = lons.max() ?? 1
                    
                    let spanLat = max(0.0001, maxLat - minLat)
                    let spanLon = max(0.0001, maxLon - minLon)
                    
                    let pad: CGFloat = 8
                    let innerW = w - (pad * 2)
                    let innerH = h - (pad * 2)
                    
                    Path { path in
                        for (idx, pt) in trackPoints.enumerated() {
                            let normX = CGFloat((pt.longitude - minLon) / spanLon)
                            // Latitude increases northward, so invert Y
                            let normY = CGFloat(1.0 - ((pt.latitude - minLat) / spanLat))
                            
                            let x = pad + (normX * innerW)
                            let y = pad + (normY * innerH)
                            
                            if idx == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        Color(red: 0.20, green: 0.65, blue: 1.0), // Bright cyan/blue route stroke
                        style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: Color(red: 0.20, green: 0.65, blue: 1.0).opacity(0.4), radius: 2)
                    
                    // Start Dot (Cyan)
                    if let first = trackPoints.first {
                        let normX = CGFloat((first.longitude - minLon) / spanLon)
                        let normY = CGFloat(1.0 - ((first.latitude - minLat) / spanLat))
                        Circle()
                            .fill(Color(red: 0.20, green: 0.85, blue: 0.35))
                            .frame(width: 4, height: 4)
                            .position(x: pad + (normX * innerW), y: pad + (normY * innerH))
                    }
                    
                    // Finish Dot (Orange)
                    if let last = trackPoints.last {
                        let normX = CGFloat((last.longitude - minLon) / spanLon)
                        let normY = CGFloat(1.0 - ((last.latitude - minLat) / spanLat))
                        Circle()
                            .fill(Theme.neonOrange)
                            .frame(width: 4, height: 4)
                            .position(x: pad + (normX * innerW), y: pad + (normY * innerH))
                    }
                }
            }
        }
    }
}
