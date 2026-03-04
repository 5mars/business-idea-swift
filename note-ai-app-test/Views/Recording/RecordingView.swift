//
//  RecordingView.swift
//  note-ai-app-test
//

import SwiftUI

struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()
    @State private var showingSaveDialog = false
    @State private var recordingTitle = ""
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Visualization area
                ZStack {
                    if viewModel.isRecording {
                        WaveformBarsView(level: viewModel.audioLevel)
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.brand.opacity(0.07))
                                .frame(width: 180, height: 180)

                            Circle()
                                .fill(Color.brand.opacity(0.05))
                                .frame(width: 130, height: 130)

                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 72))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.brand.opacity(0.4), Color.brandLight.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.isRecording)
                .frame(height: 160)

                Spacer().frame(height: 32)

                // Timer
                Text(formatDuration(viewModel.recordingDuration))
                    .font(.system(size: 52, weight: .light, design: .monospaced))
                    .foregroundStyle(
                        viewModel.isRecording
                        ? AnyShapeStyle(LinearGradient.record)
                        : AnyShapeStyle(Color.textSec)
                    )
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isRecording)
                    .contentTransition(.numericText())

                Spacer().frame(height: 8)

                // Status label
                Text(statusLabel)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.textSec)
                    .animation(.easeInOut, value: viewModel.isRecording)

                Spacer()

                // Record button section
                ZStack {
                    if viewModel.isRecording {
                        // Pulse rings behind stop button
                        PulseRing(color: .brandPink, delay: 0)
                            .frame(width: 96, height: 96)
                        PulseRing(color: .brandPink, delay: 0.6)
                            .frame(width: 96, height: 96)

                        // Stop button
                        Button {
                            viewModel.stopRecording()
                            showingSaveDialog = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.record)
                                    .frame(width: 88, height: 88)
                                    .shadow(color: Color.brandPink.opacity(0.5), radius: 20, x: 0, y: 8)

                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white)
                                    .frame(width: 28, height: 28)
                            }
                        }
                    } else if viewModel.recordingFileURL != nil {
                        // Has recording — show save UI below
                        Circle()
                            .fill(Color.brandGreen.opacity(0.12))
                            .frame(width: 96, height: 96)

                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.brandGreen, Color(hex: "0D9488")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                                .frame(width: 88, height: 88)
                                .shadow(color: Color.brandGreen.opacity(0.4), radius: 18, x: 0, y: 6)

                            Image(systemName: "checkmark")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    } else {
                        // Idle record button
                        Circle()
                            .stroke(Color.brand.opacity(0.2), lineWidth: 3)
                            .frame(width: 108, height: 108)

                        Button {
                            Task { await viewModel.startRecording() }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.brand)
                                    .frame(width: 88, height: 88)
                                    .shadow(color: Color.brand.opacity(0.45), radius: 22, x: 0, y: 8)

                                Image(systemName: "mic.fill")
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(viewModel.isSaving)
                    }
                }
                .frame(height: 120)
                .animation(.spring(response: 0.45, dampingFraction: 0.65), value: viewModel.isRecording)
                .animation(.spring(response: 0.45, dampingFraction: 0.65), value: viewModel.recordingFileURL != nil)

                Spacer().frame(height: 24)

                // Action controls below button
                VStack(spacing: 14) {
                    if viewModel.isRecording {
                        Button {
                            viewModel.cancelRecording()
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.textSec)
                        }
                    } else if viewModel.recordingFileURL != nil {
                        GradientButton(
                            title: "Save Recording",
                            isLoading: viewModel.isSaving
                        ) {
                            showingSaveDialog = true
                        }
                        .padding(.horizontal, 32)

                        Button {
                            viewModel.cancelRecording()
                        } label: {
                            Text("Discard")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.brandRed)
                        }
                    } else {
                        Text("Tap the button to start")
                            .font(.system(size: 14))
                            .foregroundColor(Color.textSec.opacity(0.6))
                    }
                }
                .frame(height: 60)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.brandRed)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 4)
                }

                if viewModel.isSaving {
                    HStack(spacing: 8) {
                        ProgressView().tint(.brand).scaleEffect(0.8)
                        Text("Saving recording...")
                            .font(.system(size: 14))
                            .foregroundColor(.textSec)
                    }
                }

                Spacer().frame(height: 48)
            }
        }
        .navigationTitle("Record")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Save Recording", isPresented: $showingSaveDialog) {
            TextField("Title", text: $recordingTitle)
            Button("Save") {
                Task {
                    _ = await viewModel.saveRecording(
                        title: recordingTitle.isEmpty ? "Untitled Recording" : recordingTitle
                    )
                    recordingTitle = ""
                }
            }
            Button("Cancel", role: .cancel) { recordingTitle = "" }
        } message: {
            Text("Give your recording a title")
        }
    }

    private var statusLabel: String {
        if viewModel.isRecording { return "Recording..." }
        if viewModel.recordingFileURL != nil { return "Recording complete" }
        return "Ready to record"
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationStack {
        RecordingView()
    }
}
