//
//  NoteDetailView.swift
//  note-ai-app-test
//

import SwiftUI
import AVFoundation

struct NoteDetailView: View {
    let note: VoiceNote

    @StateObject private var transcriptionService = TranscriptionService()
    @StateObject private var audioPlayer = AudioPlayerService()
    @State private var transcription: Transcription?
    @State private var isLoadingTranscription = false
    @State private var showingSWOTAnalysis = false
    @State private var errorMessage: String?
    @State private var editedTranscriptionText = ""
    @State private var isEditingTranscript = false
    @State private var hasUnsavedChanges = false

    private let supabase = SupabaseService.shared

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    // Note header card
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient.brand)
                                .frame(width: 56, height: 56)
                                .shadow(color: Color.brand.opacity(0.35), radius: 10, x: 0, y: 4)
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.title)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.textPri)

                            HStack(spacing: 12) {
                                Label(formatDuration(note.duration), systemImage: "clock")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.brand.opacity(0.8))

                                Text(note.createdAt, style: .date)
                                    .font(.system(size: 13))
                                    .foregroundColor(.textSec)
                            }
                        }
                        Spacer()
                    }
                    .cardStyle()

                    // Audio playback card
                    VStack(spacing: 16) {
                        HStack {
                            Text("Playback")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.textPri)
                            Spacer()
                        }

                        HStack(spacing: 16) {
                            Button {
                                Task { await togglePlayback() }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient.brand)
                                        .frame(width: 52, height: 52)
                                        .shadow(color: Color.brand.opacity(0.35), radius: 8, x: 0, y: 4)

                                    if audioPlayer.isLoading {
                                        ProgressView().tint(.white).scaleEffect(0.8)
                                    } else {
                                        Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                            .offset(x: audioPlayer.isPlaying ? 0 : 2)
                                    }
                                }
                            }
                            .disabled(audioPlayer.isLoading)

                            VStack(spacing: 8) {
                                // Progress bar
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.brand.opacity(0.1))
                                            .frame(height: 6)

                                        Capsule()
                                            .fill(LinearGradient.brand)
                                            .frame(
                                                width: max(6, geo.size.width * CGFloat(audioPlayer.progress)),
                                                height: 6
                                            )
                                    }
                                }
                                .frame(height: 6)

                                HStack {
                                    Text(formatDuration(audioPlayer.currentTime))
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(.textSec)

                                    Spacer()

                                    Text(formatDuration(note.duration))
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(.textSec)
                                }
                            }
                        }
                    }
                    .cardStyle()

                    // Transcription card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.brand.opacity(0.1))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "text.bubble.fill")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.brand)
                                }
                                Text("Transcription")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.textPri)
                            }

                            Spacer()

                            if transcription != nil && !isEditingTranscript {
                                Button {
                                    isEditingTranscript = true
                                    editedTranscriptionText = transcription?.text ?? ""
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.brand)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.brand.opacity(0.08))
                                        .cornerRadius(20)
                                }
                            }
                        }

                        if isLoadingTranscription {
                            HStack(spacing: 10) {
                                ProgressView().tint(.brand).scaleEffect(0.9)
                                Text("Transcribing with Whisper AI...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSec)
                            }
                            .padding(.vertical, 8)
                        } else if let transcription = transcription {
                            if isEditingTranscript {
                                TextEditor(text: $editedTranscriptionText)
                                    .frame(minHeight: 150)
                                    .padding(12)
                                    .background(Color.brand.opacity(0.04))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.brand.opacity(0.35), lineWidth: 1.5)
                                    )
                                    .font(.system(size: 15))
                                    .tint(.brand)
                                    .onChange(of: editedTranscriptionText) { oldValue, newValue in
                                        hasUnsavedChanges = newValue != transcription.text
                                    }

                                HStack {
                                    Button("Cancel") {
                                        isEditingTranscript = false
                                        hasUnsavedChanges = false
                                        editedTranscriptionText = transcription.text
                                    }
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.textSec)

                                    Spacer()

                                    Button {
                                        Task { await saveTranscriptionEdit() }
                                    } label: {
                                        Text("Save Changes")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 9)
                                            .background(hasUnsavedChanges ? Color.brand : Color.gray.opacity(0.3))
                                            .cornerRadius(12)
                                    }
                                    .disabled(!hasUnsavedChanges)
                                }
                            } else {
                                Text(transcription.text)
                                    .font(.system(size: 15))
                                    .foregroundColor(.textPri)
                                    .lineSpacing(4)
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.brand.opacity(0.04))
                                    .cornerRadius(12)

                                GradientButton(
                                    title: "Generate SWOT Analysis",
                                    gradient: LinearGradient(
                                        colors: [.brand, .brandLight],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                ) {
                                    showingSWOTAnalysis = true
                                }
                            }
                        } else {
                            VStack(spacing: 14) {
                                Text("No transcription yet")
                                    .font(.system(size: 15))
                                    .foregroundColor(.textSec)
                                    .italic()

                                GradientButton(title: "Transcribe Audio") {
                                    Task { await loadTranscription() }
                                }
                            }
                        }
                    }
                    .cardStyle()

                    if let error = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 13))
                            Text(error)
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.brandRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Recording Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBg, for: .navigationBar)
        .sheet(isPresented: $showingSWOTAnalysis) {
            if let transcription = transcription {
                SWOTAnalysisView(transcription: transcription)
            }
        }
        .task { await loadTranscription() }
        .onDisappear { audioPlayer.stop() }
    }

    // MARK: - Private Methods

    private func togglePlayback() async {
        if audioPlayer.isPlaying {
            audioPlayer.pause()
        } else {
            if audioPlayer.audioURL == nil {
                do {
                    let localURL = try await supabase.downloadAudioFile(filePath: note.audioFileURL)
                    try await audioPlayer.prepare(url: localURL)
                    audioPlayer.play()
                } catch {
                    errorMessage = "Failed to load audio: \(error.localizedDescription)"
                }
            } else {
                audioPlayer.play()
            }
        }
    }

    private func loadTranscription() async {
        isLoadingTranscription = true
        errorMessage = nil
        defer { isLoadingTranscription = false }

        do {
            if let existing = try await supabase.fetchTranscription(noteId: note.id) {
                transcription = existing
                editedTranscriptionText = existing.text
                return
            }

            let signedURL = try await supabase.getSignedAudioURL(filePath: note.audioFileURL, expiresIn: 3600)
            let transcriptionText = try await transcriptionService.transcribeWithWhisper(storageURL: signedURL)

            let newTranscription = Transcription(
                id: UUID(),
                noteId: note.id,
                text: transcriptionText,
                language: "en",
                confidence: nil,
                createdAt: Date()
            )

            try await supabase.createTranscription(newTranscription)
            transcription = newTranscription
            editedTranscriptionText = transcriptionText
        } catch {
            errorMessage = "Failed to transcribe: \(error.localizedDescription)"
        }
    }

    private func saveTranscriptionEdit() async {
        guard let transcription = transcription else { return }

        do {
            let updatedTranscription = Transcription(
                id: transcription.id,
                noteId: transcription.noteId,
                text: editedTranscriptionText,
                language: transcription.language,
                confidence: transcription.confidence,
                createdAt: transcription.createdAt
            )
            try await supabase.updateTranscription(updatedTranscription)
            self.transcription = updatedTranscription
            isEditingTranscript = false
            hasUnsavedChanges = false
        } catch {
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationStack {
        NoteDetailView(note: VoiceNote(
            id: UUID(),
            userId: UUID(),
            title: "Sample Recording",
            audioFileURL: "https://example.com/audio.m4a",
            duration: 125.5,
            createdAt: Date(),
            updatedAt: Date(),
            transcriptionId: nil,
            analysisId: nil
        ))
    }
}
