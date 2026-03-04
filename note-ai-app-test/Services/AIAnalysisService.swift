//
//  AIAnalysisService.swift
//  note-ai-app-test
//

import Foundation
import Supabase
import Combine

@MainActor
class AIAnalysisService: ObservableObject {
    @Published var isAnalyzing = false
    @Published var errorMessage: String?

    private let supabase = SupabaseService.shared

    func analyzeTranscription(_ text: String) async throws -> SWOTAnalysisResponse {
        isAnalyzing = true
        errorMessage = nil
        defer { isAnalyzing = false }

        let response: SWOTAnalysisResponse = try await supabase.client.functions
            .invoke(
                "analyze-swot",
                options: FunctionInvokeOptions(
                    body: ["transcription": text]
                )
            )

        return response
    }

    func generateAndSaveSWOTAnalysis(transcriptionId: UUID, transcriptionText: String) async throws -> SWOTAnalysis {
        let response = try await analyzeTranscription(transcriptionText)

        let analysis = SWOTAnalysis(
            id: UUID(),
            transcriptionId: transcriptionId,
            strengths: [],
            weaknesses: [],
            opportunities: [],
            threats: [],
            summary: response.summary,
            createdAt: Date(),
            strengthItems: response.strengths,
            weaknessItems: response.weaknesses,
            opportunityItems: response.opportunities,
            threatItems: response.threats,
            viabilityScore: response.viabilityScore,
            marketContext: response.marketContext,
            marketInsights: response.marketInsights,
            recommendations: response.recommendations
        )

        try await supabase.createSWOTAnalysis(analysis)
        return analysis
    }
}

// MARK: - Edge Function Response (camelCase — matches GPT-4o JSON output)

struct SWOTAnalysisResponse: Codable {
    let strengths: [SWOTItem]
    let weaknesses: [SWOTItem]
    let opportunities: [SWOTItem]
    let threats: [SWOTItem]
    let viabilityScore: Int
    let marketContext: String
    let marketInsights: MarketInsights
    let recommendations: [String]
    let summary: String?
}
