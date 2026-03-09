//
//  Transcription.swift
//  Abimo
//
//  Created by Claude on 2026-03-03.
//

import Foundation

struct Transcription: Identifiable, Codable {
    let id: UUID
    let noteId: UUID
    let text: String
    let language: String
    let confidence: Double?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case noteId = "note_id"
        case text
        case language
        case confidence
        case createdAt = "created_at"
    }
}
