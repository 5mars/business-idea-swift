//
//  NoteDetailView.swift
//  note-ai-app-test
//
//  Created by Claude on 2026-03-03.
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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Note Info
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "waveform.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading) {
                            Text(note.title)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(formatDuration(note.duration))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    Text(note.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                // Audio Playback Controls
                VStack(spacing: 15) {
                    Text("Audio Playback")
                        .font(.headline)

                    HStack(spacing: 20) {
                        // Play/Pause Button
                        Button {
                            Task {
                                await togglePlayback()
                            }
                        } label: {
                            Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                        }
                        .disabled(audioPlayer.isLoading)

                        VStack(alignment: .leading, spacing: 5) {
                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 4)

                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(width: geometry.size.width * CGFloat(audioPlayer.progress), height: 4)
                                }
                            }
                            .frame(height: 4)

                            HStack {
                                Text(formatDuration(audioPlayer.currentTime))
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text(formatDuration(note.duration))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    if audioPlayer.isLoading {
                        ProgressView("Loading audio...")
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                // Transcription Section
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Transcription")
                            .font(.headline)

                        Spacer()

                        if let _ = transcription, !isEditingTranscript {
                            Button {
                                isEditingTranscript = true
                                editedTranscriptionText = transcription?.text ?? ""
                            } label: {
                                Label("Edit", systemImage: "pencil")
                                    .font(.caption)
                            }
                        }
                    }

                    if isLoadingTranscription {
                        HStack {
                            ProgressView()
                            Text("Transcribing with Whisper AI...")
                                .foregroundColor(.secondary)
                        }
                    } else if let transcription = transcription {
                        if isEditingTranscript {
                            // Editable transcript
                            TextEditor(text: $editedTranscriptionText)
                                .frame(minHeight: 150)
                                .padding(8)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                                .border(Color.blue, width: 2)
                                .onChange(of: editedTranscriptionText) { oldValue, newValue in
                                    hasUnsavedChanges = newValue != transcription.text
                                }

                            HStack {
                                Button("Cancel") {
                                    isEditingTranscript = false
                                    hasUnsavedChanges = false
                                    editedTranscriptionText = transcription.text
                                }
                                .foregroundColor(.red)

                                Spacer()

                                Button("Save Changes") {
                                    Task {
                                        await saveTranscriptionEdit()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(!hasUnsavedChanges)
                            }
                        } else {
                            // Read-only transcript
                            Text(transcription.text)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)

                            Button {
                                showingSWOTAnalysis = true
                            } label: {
                                Label("Generate SWOT Analysis", systemImage: "chart.bar.doc.horizontal")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    } else {
                        Text("No transcription available")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .italic()

                        Button {
                            Task {
                                await loadTranscription()
                            }
                        } label: {
                            Label("Transcribe Audio", systemImage: "waveform.and.mic")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Recording Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSWOTAnalysis) {
            if let transcription = transcription {
                SWOTAnalysisView(transcription: transcription)
            }
        }
        .task {
            await loadTranscription()
        }
        .onDisappear {
            audioPlayer.stop()
        }
    }

    private func togglePlayback() async {
        if audioPlayer.isPlaying {
            audioPlayer.pause()
        } else {
            if audioPlayer.audioURL == nil {
                // Download audio file first
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
            // Check if transcription already exists
            if let existing = try await supabase.fetchTranscription(noteId: note.id) {
                transcription = existing
                editedTranscriptionText = existing.text
                return
            }

            // Generate a signed URL for temporary access to the private audio file
            print("🔐 Generating signed URL for audio file...")
            print("📁 File path: \(note.audioFileURL)")
            let signedURL = try await supabase.getSignedAudioURL(filePath: note.audioFileURL, expiresIn: 3600)
            print("✅ Signed URL generated: \(signedURL.prefix(100))...")

            // Use Whisper to transcribe (pass signed URL)
            print("🎤 Starting Whisper transcription...")
            let transcriptionText = try await transcriptionService.transcribeWithWhisper(storageURL: signedURL)
            print("✅ Transcription completed: \(transcriptionText.prefix(50))...")

            // Create transcription record
            let newTranscription = Transcription(
                id: UUID(),
                noteId: note.id,
                text: transcriptionText,
                language: "en",
                confidence: nil,
                createdAt: Date()
            )

            // Save to database
            try await supabase.createTranscription(newTranscription)
            print("✅ Transcription saved to database")

            // Update UI
            transcription = newTranscription
            editedTranscriptionText = transcriptionText

        } catch {
            print("❌ Transcription error: \(error)")
            errorMessage = "Failed to transcribe: \(error.localizedDescription)"
        }
    }

    private func saveTranscriptionEdit() async {
        guard let transcription = transcription else { return }

        // Update the transcription in the database
        do {
            // For simplicity, we'll create a new transcription record
            // In production, you'd add an UPDATE method to SupabaseService
            let updatedTranscription = Transcription(
                id: transcription.id,
                noteId: transcription.noteId,
                text: editedTranscriptionText,
                language: transcription.language,
                confidence: transcription.confidence,
                createdAt: transcription.createdAt
            )

            // Update in database (we'll need to add this method)
            try await supabase.updateTranscription(updatedTranscription)

            // Update local state
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
