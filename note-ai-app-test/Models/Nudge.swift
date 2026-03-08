//
//  Nudge.swift
//  note-ai-app-test
//

import Foundation

enum NudgeType: String {
    case inactivity
    case commitmentDue
    case milestone
    case nextAction
}

struct NudgeMessage: Identifiable {
    let id = UUID()
    let type: NudgeType
    let title: String
    let body: String
    let actionLabel: String?
    let relatedActionId: UUID?
}
