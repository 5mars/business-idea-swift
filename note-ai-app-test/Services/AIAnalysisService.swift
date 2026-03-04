//
//  AIAnalysisService.swift
//  note-ai-app-test
//
//  Created by Claude on 2026-03-03.
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

        // Call Supabase Edge Function
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
        // Generate analysis via Edge Function
        let response = try await analyzeTranscription(transcriptionText)

        // Create SWOT analysis record
        let analysis = SWOTAnalysis(
            id: UUID(),
            transcriptionId: transcriptionId,
            strengths: response.strengths,
            weaknesses: response.weaknesses,
            opportunities: response.opportunities,
            threats: response.threats,
            summary: response.summary,
            createdAt: Date()
        )

        // Save to database
        try await supabase.createSWOTAnalysis(analysis)

        return analysis
    }
}

// Response structure from Edge Function
struct SWOTAnalysisResponse: Codable {
    let strengths: [String]
    let weaknesses: [String]
    let opportunities: [String]
    let threats: [String]
    let summary: String?
}
