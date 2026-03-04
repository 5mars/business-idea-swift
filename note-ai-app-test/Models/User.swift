//
//  User.swift
//  note-ai-app-test
//
//  Created by Claude on 2026-03-03.
//

import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    let email: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
    }
}
