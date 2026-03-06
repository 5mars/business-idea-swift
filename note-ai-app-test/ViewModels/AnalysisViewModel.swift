//
//  AnalysisViewModel.swift
//  note-ai-app-test
//

import Foundation
import Combine

@MainActor
class AnalysisViewModel: ObservableObject {
    @Published var analysis: SWOTAnalysis?
    @Published var actionItems: [PersistedActionItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let aiService = AIAnalysisService()
    private let supabase = SupabaseService.shared

    init() {}

    init(preloadedAnalysis: SWOTAnalysis) {
        self.analysis = preloadedAnalysis
    }

    func loadAnalysis(transcriptionId: UUID) async {
        guard analysis == nil else {
            if let id = analysis?.id { await loadActionItems(analysisId: id) }
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            analysis = try await supabase.fetchSWOTAnalysis(transcriptionId: transcriptionId)
            if let id = analysis?.id { await loadActionItems(analysisId: id) }
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
            if let id = analysis?.id { await loadActionItems(analysisId: id) }
        } catch {
            errorMessage = "Failed to generate analysis: \(error.localizedDescription)"
        }
    }

    func loadActionItems(analysisId: UUID) async {
        do {
            actionItems = try await supabase.fetchActionItems(analysisId: analysisId)
        } catch {
            // Non-fatal — game plan section just shows empty
        }
    }

    func toggleAction(id: UUID, isCompleted: Bool) async {
        // Optimistic update
        guard let idx = actionItems.firstIndex(where: { $0.id == id }) else { return }
        actionItems[idx].isCompleted = isCompleted
        actionItems[idx].completedAt = isCompleted ? Date() : nil

        do {
            try await supabase.toggleActionItem(id: id, isCompleted: isCompleted)
        } catch {
            // Revert on error
            if let revertIdx = actionItems.firstIndex(where: { $0.id == id }) {
                actionItems[revertIdx].isCompleted = !isCompleted
                actionItems[revertIdx].completedAt = nil
            }
        }
    }
}
