//
//  SWOTAnalysis.swift
//  note-ai-app-test
//

import Foundation

// MARK: - SWOTItem

struct SWOTItem: Identifiable, Codable, Hashable {
    var id = UUID()
    let point: String
    let score: Int        // 0–100
    let category: String

    enum CodingKeys: String, CodingKey {
        case point, score, category
    }
}

// MARK: - MarketInsights

struct MarketInsights: Codable {
    let marketSize: String?
    let growthRate: String?
    let trendDirection: String?   // "up" | "down" | "stable"
    let keyCompetitors: [String]?

    enum CodingKeys: String, CodingKey {
        case marketSize      = "market_size"
        case growthRate      = "growth_rate"
        case trendDirection  = "trend_direction"
        case keyCompetitors  = "key_competitors"
    }
}

// MARK: - SWOTAnalysis

struct SWOTAnalysis: Identifiable, Codable {
    let id: UUID
    let transcriptionId: UUID

    // Legacy arrays — kept for backward compatibility with old DB rows
    let strengths: [String]
    let weaknesses: [String]
    let opportunities: [String]
    let threats: [String]

    let summary: String?
    let createdAt: Date

    // Rich fields added by migration (nullable — old rows have NULL)
    let strengthItems: [SWOTItem]?
    let weaknessItems: [SWOTItem]?
    let opportunityItems: [SWOTItem]?
    let threatItems: [SWOTItem]?
    let viabilityScore: Int?
    let marketContext: String?
    let marketInsights: MarketInsights?
    let recommendations: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case transcriptionId  = "transcription_id"
        case strengths
        case weaknesses
        case opportunities
        case threats
        case summary
        case createdAt        = "created_at"
        case strengthItems    = "strength_items"
        case weaknessItems    = "weakness_items"
        case opportunityItems = "opportunity_items"
        case threatItems      = "threat_items"
        case viabilityScore   = "viability_score"
        case marketContext    = "market_context"
        case marketInsights   = "market_insights"
        case recommendations
    }

    // MARK: - Computed helpers (Charts fall back to score=50 for legacy rows)

    var resolvedStrengths: [SWOTItem] {
        strengthItems ?? strengths.map { SWOTItem(point: $0, score: 50, category: "General") }
    }
    var resolvedWeaknesses: [SWOTItem] {
        weaknessItems ?? weaknesses.map { SWOTItem(point: $0, score: 50, category: "General") }
    }
    var resolvedOpportunities: [SWOTItem] {
        opportunityItems ?? opportunities.map { SWOTItem(point: $0, score: 50, category: "General") }
    }
    var resolvedThreats: [SWOTItem] {
        threatItems ?? threats.map { SWOTItem(point: $0, score: 50, category: "General") }
    }

    var avgStrengthScore: Double {
        let items = resolvedStrengths
        guard !items.isEmpty else { return 0 }
        return Double(items.map(\.score).reduce(0, +)) / Double(items.count)
    }
    var avgWeaknessScore: Double {
        let items = resolvedWeaknesses
        guard !items.isEmpty else { return 0 }
        return Double(items.map(\.score).reduce(0, +)) / Double(items.count)
    }
    var avgOpportunityScore: Double {
        let items = resolvedOpportunities
        guard !items.isEmpty else { return 0 }
        return Double(items.map(\.score).reduce(0, +)) / Double(items.count)
    }
    var avgThreatScore: Double {
        let items = resolvedThreats
        guard !items.isEmpty else { return 0 }
        return Double(items.map(\.score).reduce(0, +)) / Double(items.count)
    }
}
