//
//  WaterStationsStrategySectionView.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// Water Station & Aid Station Strategy Section (COROS Style).
/// Displays each checkpoint with terrain split metrics, arrival/departure times,
/// cut-off safety margins, and interactive per-station stop duration steppers.
struct WaterStationsStrategySectionView: View {
    let strategy: RaceStrategy
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row (Apple Fitness Style)
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Image(systemName: "drop.triangle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.cyan)
                    
                    Text("WATER STATIONS & AID STRATEGY")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.secondary)
                        .tracking(0.8)
                }
                
                Spacer()
                
                // Total Stop Badge
                HStack(spacing: 4) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 10))
                    Text(strategy.totalStationStopDurationFormatted)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundStyle(Theme.neonOrange)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Theme.neonOrange.opacity(0.16))
                .clipShape(Capsule())
            }
            
            // Subtitle & Batch Controls Bar
            HStack {
                Text("Alokasikan waktu istirahat & restock per pos:")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                
                Spacer()
                
                // Quick Batch Buttons
                Menu {
                    Button {
                        appState.resetAllStationStops()
                    } label: {
                        Label("Reset Semua Pos (0m)", systemImage: "arrow.counterclockwise")
                    }
                    
                    Button {
                        appState.applyUniformStationStop(minutes: 3)
                    } label: {
                        Label("Setel Semua Pos ke 3 Menit", systemImage: "timer")
                    }
                    
                    Button {
                        appState.applyUniformStationStop(minutes: 5)
                    } label: {
                        Label("Setel Semua Pos ke 5 Menit", systemImage: "timer")
                    }
                    
                    Button {
                        appState.applyUniformStationStop(minutes: 10)
                    } label: {
                        Label("Setel Semua Pos ke 10 Menit", systemImage: "timer")
                    }
                } label: {
                    Label("Atur Massal", systemImage: "slider.horizontal.3")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.mini)
                .tint(Color.secondary)
            }
            
            // List of Checkpoints
            VStack(spacing: 10) {
                ForEach(strategy.checkpoints) { checkpoint in
                    CheckpointRow(
                        checkpoint: checkpoint,
                        onAdjustStop: { deltaMinutes in
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                appState.adjustStationStopMinutes(checkpointId: checkpoint.id, deltaMinutes: deltaMinutes)
                            }
                        },
                        onTapCard: {
                            appState.selectedCheckpoint = checkpoint
                            appState.showingCheckpointEditor = true
                        }
                    )
                }
            }
            
            // Helpful Trail Footnote
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.warningYellow)
                    .padding(.top, 2)
                
                Text("Sistem COROS On Trail: Waktu yang Anda habiskan di tiap pos secara otomatis memperbarui waktu keberangkatan, waktu tiba di pos berikutnya, dan prediksi jam finish lomba.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                    .lineSpacing(2)
            }
            .padding(10)
            .background(Theme.surfaceGray)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Theme.cardBorder, lineWidth: 0.6)
            )
        }
    }
}
