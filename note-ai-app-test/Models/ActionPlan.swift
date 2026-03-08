//
//  ActionPlan.swift
//  note-ai-app-test
//

import Foundation

// MARK: - ActionPlan

struct ActionPlan: Identifiable, Codable {
    let id: UUID
    let analysisId: UUID
    let userId: UUID
    let title: String
    let summary: String
    let totalEstimateMinutes: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case analysisId          = "analysis_id"
        case userId              = "user_id"
        case title
        case summary
        case totalEstimateMinutes = "total_estimate_minutes"
        case createdAt           = "created_at"
    }
}

// MARK: - MicroAction

struct MicroAction: Identifiable, Codable, Hashable {
    let id: UUID
    let actionPlanId: UUID
    let text: String
    let doneCriteria: String
    let timeEstimateMinutes: Int
    let priority: Int
    let quadrant: String?
    let template: String?
    var isCompleted: Bool
    var completedAt: Date?
    var isCommitted: Bool
    var committedAt: Date?
    var scheduledFor: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case actionPlanId        = "action_plan_id"
        case text
        case doneCriteria        = "done_criteria"
        case timeEstimateMinutes = "time_estimate_minutes"
        case priority
        case quadrant
        case template
        case isCompleted         = "is_completed"
        case completedAt         = "completed_at"
        case isCommitted         = "is_committed"
        case committedAt         = "committed_at"
        case scheduledFor        = "scheduled_for"
        case createdAt           = "created_at"
    }
}

// MARK: - Commitment

struct Commitment: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let microActionId: UUID
    let scheduledFor: Date?
    var status: String
    var completedAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId          = "user_id"
        case microActionId   = "micro_action_id"
        case scheduledFor    = "scheduled_for"
        case status
        case completedAt     = "completed_at"
        case createdAt       = "created_at"
    }
}

// MARK: - AI Response (Edge Function JSON)

struct ActionPlanResponse: Codable {
    let title: String
    let summary: String
    let actions: [ActionPlanResponseItem]
}

struct ActionPlanResponseItem: Codable {
    let text: String
    let doneCriteria: String
    let timeEstimateMinutes: Int
    let priority: Int
    let quadrant: String?
    let template: String?

    enum CodingKeys: String, CodingKey {
        case text
        case doneCriteria        = "done_criteria"
        case timeEstimateMinutes = "time_estimate_minutes"
        case priority
        case quadrant
        case template
    }
}
