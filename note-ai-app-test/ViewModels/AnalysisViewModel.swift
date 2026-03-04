//
//  AnalysisViewModel.swift
//  note-ai-app-test
//
//  Created by Claude on 2026-03-03.
//

import Foundation
import Combine

@MainActor
class AnalysisViewModel: ObservableObject {
    @Published var analysis: SWOTAnalysis?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let aiService = AIAnalysisService()
    private let supabase = SupabaseService.shared

    func loadAnalysis(transcriptionId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            analysis = try await supabase.fetchSWOTAnalysis(transcriptionId: transcriptionId)
        } catch {
            errorMessage = "Failed to load analysis: \(error.localizedDescription)"
        }
    }

    func generateAnalysis(transcription: Transcription) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            analysis = try await aiService.generateAndSaveSWOTAnalysis(
                transcriptionId: transcription.id,
                transcriptionText: transcription.text
            )
        } catch {
            errorMessage = "Failed to generate analysis: \(error.localizedDescription)"
        }
    }
}
