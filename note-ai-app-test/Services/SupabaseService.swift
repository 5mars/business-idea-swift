//
//  SupabaseService.swift
//  note-ai-app-test
//
//  Created by Claude on 2026-03-03.
//

import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        // TODO: Replace with your actual Supabase credentials
        let supabaseURL = URL(string: "https://ymbfqlrarlnqtzatgfah.supabase.co")!
        let supabaseAnonKey = "sb_publishable_HUIZRQ5EfaFU3EV-1IzqNQ_8uOBDJ39"

        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseAnonKey
        )
    }

    // MARK: - Authentication

    func signUp(email: String, password: String) async throws -> User {
        let response = try await client.auth.signUp(
            email: email,
            password: password
        )

        return User(
            id: response.user.id,
            email: response.user.email,
            createdAt: response.user.createdAt
        )
    }

    func signIn(email: String, password: String) async throws -> User {
        let response = try await client.auth.signIn(
            email: email,
            password: password
        )

        return User(
            id: response.user.id,
            email: response.user.email,
            createdAt: response.user.createdAt
        )
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func getCurrentUser() async throws -> User? {
        do {
            let session = try await client.auth.session
            return User(
                id: session.user.id,
                email: session.user.email,
                createdAt: session.user.createdAt
            )
        } catch {
            // No session means user is not logged in
            return nil
        }
    }

    // MARK: - Voice Notes

    func createVoiceNote(_ note: VoiceNote) async throws {
        try await client
            .from("voice_notes")
            .insert(note)
            .execute()
    }

    func fetchVoiceNotes() async throws -> [VoiceNote] {
        let response: [VoiceNote] = try await client
            .from("voice_notes")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value

        return response
    }

    func deleteVoiceNote(id: UUID) async throws {
        try await client
            .from("voice_notes")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Storage

    func uploadAudioFile(userId: UUID, fileURL: URL) async throws -> String {
        let fileName = "\(userId)/\(UUID().uuidString).m4a"
        let fileData = try Data(contentsOf: fileURL)

        let uploadResponse = try await client.storage
            .from("voice-recordings")
            .upload(
                fileName,
                data: fileData,
                options: FileOptions(contentType: "audio/m4a")
            )

        // Return the file path, not a URL (we'll generate signed URLs when needed)
        return uploadResponse.path
    }

    func getSignedAudioURL(filePath: String, expiresIn: Int = 3600) async throws -> String {
        // Generate a signed URL that allows temporary access to private files
        let signedURL = try await client.storage
            .from("voice-recordings")
            .createSignedURL(path: filePath, expiresIn: expiresIn)

        return signedURL.absoluteString
    }

    func downloadAudioFile(filePath: String) async throws -> URL {
        // Download the file data
        let data = try await client.storage
            .from("voice-recordings")
            .download(path: filePath)

        // Save to temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent(UUID().uuidString + ".m4a")
        try data.write(to: tempFile)

        return tempFile
    }

    func deleteAudioFile(filePath: String) async throws {
        try await client.storage
            .from("voice-recordings")
            .remove(paths: [filePath])
    }

    // MARK: - Transcriptions

    func createTranscription(_ transcription: Transcription) async throws {
        try await client
            .from("transcriptions")
            .insert(transcription)
            .execute()
    }

    func fetchTranscription(noteId: UUID) async throws -> Transcription? {
        let response: [Transcription] = try await client
            .from("transcriptions")
            .select()
            .eq("note_id", value: noteId)
            .execute()
            .value

        return response.first
    }

    func updateTranscription(_ transcription: Transcription) async throws {
        try await client
            .from("transcriptions")
            .update(transcription)
            .eq("id", value: transcription.id)
            .execute()
    }

    // MARK: - SWOT Analyses

    func createSWOTAnalysis(_ analysis: SWOTAnalysis) async throws {
        try await client
            .from("swot_analyses")
            .insert(analysis)
            .execute()
    }

    func fetchSWOTAnalysis(transcriptionId: UUID) async throws -> SWOTAnalysis? {
        let response: [SWOTAnalysis] = try await client
            .from("swot_analyses")
            .select()
            .eq("transcription_id", value: transcriptionId)
            .execute()
            .value

        return response.first
    }
}
