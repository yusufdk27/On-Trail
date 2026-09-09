//
//  OnboardingView.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI
import UniformTypeIdentifiers

/// Welcome screen with GPX file import, raw XML paste sheet, and sample course loading.
struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var animateLogo = false
    @State private var animateContent = false
    @State private var mountainOffset: CGFloat = 50
    @State private var pastedXMLText: String = ""
    
    var body: some View {
        ZStack {
            // Apple Native Background
            Theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Apple Standard Welcome Header
                        welcomeHeader
                            .padding(.top, 40)
                        
                        // Apple Standard 3-Feature List
                        featureListView
                            .padding(.horizontal, 8)
                    }
                    .padding(.horizontal, 24)
                }
                
                // Bottom Fixed Native Action Controls
                bottomActionsSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .padding(.top, 12)
                    .background(
                        Theme.background
                            .shadow(color: Color.black.opacity(0.08), radius: 16, y: -8)
                    )
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Color(uiColor: .systemGray2))
                }
                .padding(.top, 18)
                .padding(.trailing, 20)
            }
            
            // Processing overlay
            if appState.isProcessing {
                processingOverlay
            }
            
            // Error alert overlay
            if appState.importError != nil {
                errorOverlay
            }
        }
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
        .sheet(
            isPresented: Binding(
                get: { appState.showingPasteSheet },
                set: { appState.showingPasteSheet = $0 }
            )
        ) {
            pasteXMLSheet
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateContent = true
            }
            withAnimation(.easeOut(duration: 1.2).delay(0.4)) {
                mountainOffset = 0
            }
            withAnimation(
                .easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
                .delay(1.0)
            ) {
                animateLogo = true
            }
        }
        .onChange(of: appState.currentStrategy?.id) { _, newValue in
            if newValue != nil {
                dismiss()
            }
        }
    }
    
    // MARK: - Welcome Header (Apple Standard)
    
    private var welcomeHeader: some View {
        VStack(spacing: 14) {
            AppLogoView(size: 76)
                .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
            
            VStack(spacing: 6) {
                Text("On Trail")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                
                Text("Perencanaan Pace & Strategi Elevasi Trail Running")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Feature List View (Apple HIG Standard What's New Style)
    
    private var featureListView: some View {
        VStack(spacing: 24) {
            featureRow(
                icon: "mountain.2.fill",
                color: Theme.neonOrange,
                title: "Grade Adjusted Pace (GAP)",
                description: "Menghitung beban fisiologis setara jalan datar pada tanjakan power-hiking dan turunan teknis berbatu (Minetti model)."
            )
            
            featureRow(
                icon: "cup.and.saucer.fill",
                color: Color.cyan,
                title: "Water Station ala COROS",
                description: "Alokasikan waktu istirahat di setiap pos air dengan prediksi jam tiba & jam keluar riil serta evaluasi Cut-Off Time (COT)."
            )
            
            featureRow(
                icon: "applewatch.radiowaves.left.and.right",
                color: Theme.successGreen,
                title: "Sinkronisasi Apple Watch",
                description: "Kirim panduan strategi rute offline ke jam tangan untuk navigasi dan pacing akurat tanpa jaringan seluler."
            )
        }
        .padding(.vertical, 8)
    }
    
    private func featureRow(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.18))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondary)
                    .lineSpacing(2)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Bottom Actions Section (Apple Native Buttons)
    
    private var bottomActionsSection: some View {
        VStack(spacing: 12) {
            // Primary Import Button
            Button {
                appState.showingFileImporter = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Pilih File GPX")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Theme.neonOrange)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            // Secondary Sample Course Button
            Button {
                appState.loadSampleCourse()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Buka Contoh Rute (Rinjani)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Theme.surfaceGray)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            // Manual XML Text Option
            Button {
                appState.showingPasteSheet = true
            } label: {
                Text("Tempel Teks GPX XML")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            
            // Format Support Caption
            Text("Mendukung format GPX standar Garmin, COROS, Suunto, dan Strava.")
                .font(.system(size: 10))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Paste XML Sheet
    
    private var pasteXMLSheet: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    Text("Tempel teks XML GPX dari clipboard atau aplikasi lain:")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.textSecondary)
                    
                    TextEditor(text: $pastedXMLText)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(Theme.spacingM)
                        .background(Theme.slateGray)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                                .stroke(Theme.borderGray, lineWidth: 1)
                        )
                    
                    HStack(spacing: Theme.spacingM) {
                        Button {
                            if let clipString = UIPasteboard.general.string {
                                pastedXMLText = clipString
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.clipboard")
                                Text("Paste Clipboard")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.neonOrange)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Theme.surfaceGray)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall))
                        }
                        
                        Button {
                            appState.importGPXString(pastedXMLText)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark")
                                Text("Proses Rute")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(pastedXMLText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Theme.textTertiary : Color.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(pastedXMLText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Theme.surfaceGray : Theme.neonOrange)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall))
                        }
                        .disabled(pastedXMLText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(Theme.spacingL)
            }
            .navigationTitle("Paste GPX XML")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Tutup") {
                        appState.showingPasteSheet = false
                    }
                    .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Processing Overlay
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: Theme.spacingXL) {
                ProcessingAnimation()
                    .frame(height: 60)
                    .padding(.horizontal, 40)
                
                VStack(spacing: Theme.spacingS) {
                    Text(appState.processingStatus)
                        .font(Theme.heading)
                        .foregroundStyle(Theme.textPrimary)
                    
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.surfaceGray)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.orangeGradient)
                                .frame(width: geo.size.width * appState.processingProgress)
                                .animation(.easeInOut(duration: 0.3), value: appState.processingProgress)
                        }
                    }
                    .frame(height: 6)
                    .padding(.horizontal, 60)
                    
                    Text("\(Int(appState.processingProgress * 100))%")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Error Overlay
    
    private var errorOverlay: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    appState.dismissError()
                }
            
            VStack(spacing: Theme.spacingL) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.warningYellow)
                
                Text("Gagal Membaca GPX")
                    .font(Theme.title)
                    .foregroundStyle(Theme.textPrimary)
                
                Text(appState.importError ?? "Format file tidak dikenal.")
                    .font(Theme.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: Theme.spacingM) {
                    NeonButton(title: "Coba Lagi", icon: "arrow.clockwise") {
                        appState.dismissError()
                    }
                    
                    Button {
                        appState.dismissError()
                        appState.showingPasteSheet = true
                    } label: {
                        Text("Tempel Teks GPX Manual")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.neonOrange)
                    }
                }
            }
            .padding(Theme.spacingXL)
            .background(Theme.slateGray)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusXL))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusXL)
                    .stroke(Theme.cardBorder, lineWidth: 0.8)
            )
            .padding(.horizontal, Theme.spacingXL)
        }
        .transition(.opacity)
    }
}

// MARK: - Processing Animation

struct ProcessingAnimation: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            Path { path in
                path.move(to: CGPoint(x: 0, y: h * 0.8))
                path.addLine(to: CGPoint(x: w * 0.1, y: h * 0.6))
                path.addLine(to: CGPoint(x: w * 0.2, y: h * 0.7))
                path.addLine(to: CGPoint(x: w * 0.3, y: h * 0.3))
                path.addLine(to: CGPoint(x: w * 0.4, y: h * 0.5))
                path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.2))
                path.addLine(to: CGPoint(x: w * 0.6, y: h * 0.4))
                path.addLine(to: CGPoint(x: w * 0.7, y: h * 0.6))
                path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.3))
                path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.5))
                path.addLine(to: CGPoint(x: w, y: h * 0.7))
            }
            .trim(from: 0, to: 1)
            .stroke(
                Theme.neonOrange,
                style: StrokeStyle(
                    lineWidth: 2.5,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: [8, 6],
                    dashPhase: phase
                )
            )
            .shadow(color: Theme.neonOrange.opacity(0.5), radius: 4)
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = -28
                }
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
