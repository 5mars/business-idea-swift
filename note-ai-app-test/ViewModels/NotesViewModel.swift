//
//  NotesViewModel.swift
//  note-ai-app-test
//
//  Created by Claude on 2026-03-03.
//

import Foundation
import Combine

@MainActor
class NotesViewModel: ObservableObject {
    @Published var notes: [VoiceNote] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = SupabaseService.shared

    func fetchNotes() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            notes = try await supabase.fetchVoiceNotes()
        } catch {
            errorMessage = "Failed to load notes: \(error.localizedDescription)"
        }
    }

    func deleteNote(_ note: VoiceNote) async {
        errorMessage = nil

        do {
            // Delete from database
            try await supabase.deleteVoiceNote(id: note.id)

            // Delete audio file from storage
            try await supabase.deleteAudioFile(filePath: note.audioFileURL)

            // Remove from local array
            notes.removeAll { $0.id == note.id }
        } catch {
            errorMessage = "Failed to delete note: \(error.localizedDescription)"
        }
    }

    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
