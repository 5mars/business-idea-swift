//
//  RecordingView.swift
//  note-ai-app-test
//
//  Created by Claude on 2026-03-03.
//

import SwiftUI

struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()
    @State private var showingSaveDialog = false
    @State private var recordingTitle = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                // Audio level visualization
                if viewModel.isRecording {
                    AudioLevelView(level: viewModel.audioLevel)
                        .frame(width: 200, height: 200)
                } else {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 120))
                        .foregroundColor(.gray.opacity(0.3))
                }

                // Duration display
                Text(formatDuration(viewModel.recordingDuration))
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .foregroundColor(viewModel.isRecording ? .red : .primary)

                Spacer()

                // Recording controls
                VStack(spacing: 20) {
                    if viewModel.isRecording {
                        HStack(spacing: 30) {
                            // Cancel button
                            Button {
                                viewModel.cancelRecording()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                            }

                            // Stop button
                            Button {
                                viewModel.stopRecording()
                                showingSaveDialog = true
                            } label: {
                                Image(systemName: "stop.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.red)
                            }
                        }
                    } else if viewModel.recordingFileURL != nil {
                        Button {
                            showingSaveDialog = true
                        } label: {
                            Label("Save Recording", systemImage: "checkmark.circle.fill")
                                .font(.title2)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }
                        .padding(.horizontal)

                        Button {
                            viewModel.cancelRecording()
                        } label: {
                            Text("Discard")
                                .foregroundColor(.red)
                        }
                    } else {
                        // Record button
                        Button {
                            Task {
                                await viewModel.startRecording()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 80, height: 80)

                                Circle()
                                    .stroke(Color.red, lineWidth: 4)
                                    .frame(width: 100, height: 100)
                            }
                        }
                        .disabled(viewModel.isSaving)

                        Text("Tap to record")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }

                    if viewModel.isSaving {
                        ProgressView("Saving recording...")
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Record")
            .alert("Save Recording", isPresented: $showingSaveDialog) {
                TextField("Title", text: $recordingTitle)
                Button("Save") {
                    Task {
                        _ = await viewModel.saveRecording(title: recordingTitle.isEmpty ? "Untitled Recording" : recordingTitle)
                        recordingTitle = ""
                    }
                }
                Button("Cancel", role: .cancel) {
                    recordingTitle = ""
                }
            } message: {
                Text("Give your recording a title")
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct AudioLevelView: View {
    let level: Float

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red.opacity(0.1))

            Circle()
                .fill(Color.red.opacity(0.3))
                .scaleEffect(CGFloat(level))

            Circle()
                .fill(Color.red)
                .scaleEffect(0.3 + CGFloat(level) * 0.2)

            Image(systemName: "waveform")
                .font(.system(size: 50))
                .foregroundColor(.white)
        }
        .animation(.easeInOut(duration: 0.1), value: level)
    }
}

#Preview {
    RecordingView()
}
