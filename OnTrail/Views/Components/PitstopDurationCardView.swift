//
//  PitstopDurationCardView.swift
//  On Trail
//
//  Created by On Trail Team.
//

import SwiftUI

/// Pitstop Duration Card designed according to Apple Health & Fitness native guidelines.
/// Calculates total estimated rest & hydration time at aid stations/checkpoints.
struct PitstopDurationCardView: View {
    @Environment(AppState.self) private var appState
    @State private var showingCustomTimePicker = false
    @State private var pickerHours: Int = 0
    @State private var pickerMinutes: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Row (Apple Fitness Style)
            HStack(spacing: 6) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.neonOrange)
                
                Text("PITSTOP & AID STATIONS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.secondary)
                    .tracking(0.8)
                
                Spacer()
                
                if appState.pitstopDurationSeconds > 0 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            appState.resetPitstop()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Reset")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(Color.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.surfaceGray)
                        .clipShape(Capsule())
                    }
                }
            }
            
            // Sub-container Card
            VStack(alignment: .leading, spacing: 12) {
                Text("Waktu istirahat, hidrasi & isi nutrisi di water station/pos ditambahkan ke target finish:")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                    .lineLimit(2)
                
                // Big Digital Duration & Quick Steppers
                HStack(alignment: .center) {
                    Button {
                        let totalMin = Int(appState.pitstopDurationSeconds) / 60
                        pickerHours = totalMin / 60
                        pickerMinutes = totalMin % 60
                        showingCustomTimePicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Text(appState.pitstopFormatted)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                                .monospacedDigit()
                            
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // Quick Adjustment Steppers
                    HStack(spacing: 8) {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                appState.adjustPitstopMinutes(-5)
                            }
                        } label: {
                            Text("-5m")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(appState.pitstopDurationSeconds > 0 ? Theme.textPrimary : Color.secondary.opacity(0.5))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Theme.surfaceGray)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .disabled(appState.pitstopDurationSeconds == 0)
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                appState.adjustPitstopMinutes(5)
                            }
                        } label: {
                            Text("+5m")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.neonOrange)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Theme.neonOrange.opacity(0.18))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                appState.adjustPitstopMinutes(15)
                            }
                        } label: {
                            Text("+15m")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.neonOrange)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Theme.neonOrange.opacity(0.18))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
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
        .sheet(isPresented: $showingCustomTimePicker) {
            NavigationStack {
                ZStack {
                    Theme.background.ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        Text("Atur Waktu Istirahat Pos / Checkpoint")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.top, 20)
                        
                        HStack(spacing: 24) {
                            // Hours picker
                            VStack(spacing: 4) {
                                Text("JAM")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.secondary)
                                Picker("Jam", selection: $pickerHours) {
                                    ForEach(0..<12) { h in
                                        Text("\(h) jam").tag(h)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 120)
                            }
                            
                            // Minutes picker
                            VStack(spacing: 4) {
                                Text("MENIT")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.secondary)
                                Picker("Menit", selection: $pickerMinutes) {
                                    ForEach(0..<60) { m in
                                        Text("\(m) mnt").tag(m)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 120)
                            }
                        }
                        
                        Button {
                            let totalMin = (pickerHours * 60) + pickerMinutes
                            appState.applyUniformStationStop(minutes: totalMin)
                            showingCustomTimePicker = false
                        } label: {
                            Text("Simpan Pitstop")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Theme.neonOrange)
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer()
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Tutup") {
                            showingCustomTimePicker = false
                        }
                        .foregroundStyle(Color.secondary)
                    }
                }
            }
            .presentationDetents([.fraction(0.45)])
        }
    }
}
