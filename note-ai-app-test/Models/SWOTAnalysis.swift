//
//  SWOTAnalysis.swift
//  note-ai-app-test
//
//  Created by Claude on 2026-03-03.
//

import Foundation

struct SWOTAnalysis: Identifiable, Codable {
    let id: UUID
    let transcriptionId: UUID
    let strengths: [String]
    let weaknesses: [String]
    let opportunities: [String]
    let threats: [String]
    let summary: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case transcriptionId = "transcription_id"
        case strengths
        case weaknesses
        case opportunities
        case threats
        case summary
        case createdAt = "created_at"
    }
}
