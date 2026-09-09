//
//  CheckpointEditorSheet.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// Modal sheet for editing Checkpoint details: Planned stop duration (COROS style),
/// Cut-Off Time (COT), safety margin analysis, and split terrain metrics.
struct CheckpointEditorSheet: View {
    let checkpoint: Checkpoint
    var onSave: ((Checkpoint) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    
    @State private var checkpointName: String = ""
    @State private var plannedStopMinutes: Int = 5
    @State private var hasCutOffTime: Bool = false
    @State private var cotHours: Int = 2
    @State private var cotMinutes: Int = 30
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Checkpoint Header Card
                        headerCard
                        
                        // Checkpoint Name
                        nameSection
                        
                        // Time Spent / Planned Stop at Station (COROS Feature)
                        stopDurationSection
                        
                        // Leg Split Preview (From previous pos)
                        if checkpoint.legDistanceKm > 0 {
                            legSplitCard
                        }
                        
                        // Cut-Off Time Section
                        cotSection
                        
                        // Safety Margin & Arrival Analysis
                        timingAnalysisCard
                        
                        Spacer()
                            .frame(height: 30)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Atur Water Station / Pos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Batal") {
                        dismiss()
                    }
                    .foregroundStyle(Color.secondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Simpan") {
                        saveChanges()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.small)
                    .tint(Theme.neonOrange)
                    .foregroundStyle(.black)
                }
            }
            .onAppear {
                setupInitialValues()
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Subviews
    
    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconBackgroundColor.opacity(0.18))
                    .frame(width: 48, height: 48)
                
                Image(systemName: checkpoint.type.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(iconBackgroundColor)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(checkpoint.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                
                Text(String(format: "KM %.1f · Elevasi %.0f m · %@", checkpoint.distanceKm, checkpoint.elevation ?? 0, checkpoint.type.displayName))
                    .font(.system(size: 12))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }
            
            Spacer()
        }
        .padding(14)
        .background(Theme.slateGray)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NAMA CHECKPOINT")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.secondary)
                .tracking(0.8)
            
            TextField("Nama Checkpoint", text: $checkpointName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(12)
                .background(Theme.slateGray)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.cardBorder, lineWidth: 0.8)
                )
        }
    }
    
    // MARK: - Time Spent at Station Section (COROS Style)
    
    private var stopDurationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.neonOrange)
                    
                    Text("TIME SPENT / WAKTU ISTIRAHAT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.secondary)
                        .tracking(0.8)
                }
                
                Spacer()
                
                Text("\(plannedStopMinutes) Menit")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.neonOrange)
            }
            
            Text("Waktu yang dialokasikan untuk isi air, makan, atau drop bag di pos ini:")
                .font(.system(size: 12))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
            
            // Quick preset pills
            HStack(spacing: 8) {
                ForEach([0, 3, 5, 10, 15, 20], id: \.self) { mins in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            plannedStopMinutes = mins
                        }
                    } label: {
                        Text("\(mins)m")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(plannedStopMinutes == mins ? Color.black : Theme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(plannedStopMinutes == mins ? Theme.neonOrange : Theme.surfaceGray)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Departure Preview
            if let arrival = checkpoint.estimatedArrivalSeconds {
                let dep = arrival + Double(plannedStopMinutes * 60)
                HStack {
                    Text("Tiba: \(PacingZone.formatDuration(arrival))")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.secondary)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.secondary)
                    
                    Text("Berangkat: \(PacingZone.formatDuration(dep))")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .background(Theme.slateGray)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
    
    // MARK: - Leg Split Card (From previous station)
    
    private var legSplitCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DATA SEKTOR MENUJU POS INI")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.secondary)
                .tracking(0.8)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("JARAK SEKTOR")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.secondary)
                    Text(String(format: "%.1f km", checkpoint.legDistanceKm))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("ELEVASI SEKTOR")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.secondary)
                    Text(String(format: "+%.0f / -%.0fm", checkpoint.legElevationGain, checkpoint.legElevationLoss))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.neonOrange)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("WAKTU TEMPUH")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.secondary)
                    Text(checkpoint.legMovingDurationFormatted)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .background(Theme.slateGray)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
    
    // MARK: - Cut-Off Time Section
    
    private var cotSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $hasCutOffTime.animation()) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cut-Off Time (COT)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Batas waktu eliminasi panitia di pos ini")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }
            }
            .tint(Theme.neonOrange)
            
            if hasCutOffTime {
                Divider()
                    .background(Theme.borderGray)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("JAM")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.secondary)
                        
                        Picker("Jam", selection: $cotHours) {
                            ForEach(0...36, id: \.self) { h in
                                Text("\(h) jam").tag(h)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.surfaceGray)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MENIT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.secondary)
                        
                        Picker("Menit", selection: $cotMinutes) {
                            ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { m in
                                Text("\(m) mnt").tag(m)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.surfaceGray)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(14)
        .background(Theme.slateGray)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
    
    // MARK: - Timing & Safety Margin Card
    
    private var timingAnalysisCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ANALISIS WAKTU & KEAMANAN")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.secondary)
                .tracking(0.8)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Target Tiba (ETA)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                    Text(checkpoint.estimatedArrivalFormatted)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
                
                Spacer()
                
                if hasCutOffTime {
                    let totalSeconds = Double(cotHours * 3600 + cotMinutes * 60)
                    let margin = totalSeconds - (checkpoint.estimatedArrivalSeconds ?? 0)
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Margin Keamanan COT")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.secondary)
                        
                        Text(formatMargin(margin))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(marginColor(margin))
                    }
                }
            }
        }
        .padding(14)
        .background(Theme.slateGray)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
    
    // MARK: - Helpers
    
    private var iconBackgroundColor: Color {
        switch checkpoint.type {
        case .waterStation: return .blue
        case .aidStation: return Theme.successGreen
        case .cutOff: return Theme.warningYellow
        case .start: return Theme.successGreen
        case .finish: return Theme.neonOrange
        case .summit: return Theme.neonOrange
        }
    }
    
    private func setupInitialValues() {
        checkpointName = checkpoint.name
        plannedStopMinutes = Int(checkpoint.plannedStopDurationSeconds.rounded()) / 60
        
        if let cot = checkpoint.cutOffTimeSeconds {
            hasCutOffTime = true
            cotHours = Int(cot) / 3600
            cotMinutes = (Int(cot) % 3600) / 60
        } else {
            hasCutOffTime = false
            let est = checkpoint.estimatedArrivalSeconds ?? 3600
            cotHours = Int(est) / 3600 + 1
            cotMinutes = 0
        }
    }
    
    private func saveChanges() {
        let finalCotSeconds: Double? = hasCutOffTime ? Double(cotHours * 3600 + cotMinutes * 60) : nil
        let updated = Checkpoint(
            id: checkpoint.id,
            name: checkpointName.isEmpty ? checkpoint.name : checkpointName,
            type: checkpoint.type,
            latitude: checkpoint.latitude,
            longitude: checkpoint.longitude,
            distanceFromStart: checkpoint.distanceFromStart,
            cutOffTimeSeconds: finalCotSeconds,
            elevation: checkpoint.elevation,
            estimatedArrivalSeconds: checkpoint.estimatedArrivalSeconds,
            plannedStopDurationSeconds: Double(plannedStopMinutes * 60),
            legDistanceMeters: checkpoint.legDistanceMeters,
            legElevationGain: checkpoint.legElevationGain,
            legElevationLoss: checkpoint.legElevationLoss,
            legMovingTimeSeconds: checkpoint.legMovingTimeSeconds,
            legPaceSecondsPerKm: checkpoint.legPaceSecondsPerKm
        )
        onSave?(updated)
    }
    
    private func formatMargin(_ seconds: Double) -> String {
        let mins = Int(abs(seconds)) / 60
        let sign = seconds >= 0 ? "+" : "-"
        return "\(sign)\(mins) menit"
    }
    
    private func marginColor(_ seconds: Double) -> Color {
        if seconds > 1800 { return Theme.successGreen }
        if seconds > 0 { return Theme.warningYellow }
        return Theme.dangerRed
    }
}
