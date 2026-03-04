//
//  RecordingViewModel.swift
//  note-ai-app-test
//
//  Created by Claude on 2026-03-03.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class RecordingViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var recordingFileURL: URL?

    private let audioService = AudioRecordingService()
    private let supabase = SupabaseService.shared
    private let permissionsManager = PermissionsManager()

    var recordingDuration: TimeInterval {
        audioService.recordingDuration
    }

    var audioLevel: Float {
        audioService.audioLevel
    }

    func checkAndRequestPermissions() async -> Bool {
        if !permissionsManager.microphoneAuthorized || !permissionsManager.speechRecognitionAuthorized {
            return await permissionsManager.requestAllPermissions()
        }
        return true
    }

    func startRecording() async {
        errorMessage = nil

        // Check permissions
        guard await checkAndRequestPermissions() else {
            errorMessage = "Microphone and speech recognition permissions are required"
            return
        }

        do {
            recordingFileURL = try audioService.startRecording()
            isRecording = true
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }

    func stopRecording() {
        guard let fileURL = audioService.stopRecording() else {
            errorMessage = "Failed to stop recording"
            return
        }
        recordingFileURL = fileURL
        isRecording = false
    }

    func cancelRecording() {
        audioService.cancelRecording()
        recordingFileURL = nil
        isRecording = false
        errorMessage = nil
    }

    func saveRecording(title: String) async -> VoiceNote? {
        guard let fileURL = recordingFileURL else {
            errorMessage = "No recording to save"
            return nil
        }

        guard let duration = AudioFileManager.getDuration(of: fileURL) else {
            errorMessage = "Could not determine recording duration"
            return nil
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            // Get current user
            guard let user = try await supabase.getCurrentUser() else {
                errorMessage = "Not authenticated"
                return nil
            }

            print("🔐 User authenticated - ID: \(user.id)")

            // Upload audio file
            let audioURL = try await supabase.uploadAudioFile(userId: user.id, fileURL: fileURL)
            print("✅ Audio uploaded to: \(audioURL)")

            // Create voice note record
            let voiceNote = VoiceNote(
                id: UUID(),
                userId: user.id,
                title: title,
                audioFileURL: audioURL,
                duration: duration,
                createdAt: Date(),
                updatedAt: Date(),
                transcriptionId: nil,
                analysisId: nil
            )

            print("📝 Creating voice note with user_id: \(voiceNote.userId)")

            try await supabase.createVoiceNote(voiceNote)
            print("✅ Voice note saved successfully!")

            // Clean up local file
            AudioFileManager.deleteFile(at: fileURL)
            recordingFileURL = nil

            return voiceNote
        } catch {
            print("❌ Error saving recording: \(error)")
            print("❌ Error details: \(String(describing: error))")
            errorMessage = "Failed to save recording: \(error.localizedDescription)"
            return nil
        }
    }
}
