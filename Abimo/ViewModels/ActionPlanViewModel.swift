//
//  ActionPlanViewModel.swift
//  Abimo
//

import Foundation
import Combine

@MainActor
class ActionPlanViewModel: ObservableObject {
    @Published var actionPlan: ActionPlan?
    @Published var microActions: [MicroAction] = []
    @Published var activeCommitment: Commitment?
    @Published var nudges: [NudgeMessage] = []
    @Published var isGenerating = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showCommitmentPicker = false

    private let supabase = SupabaseService.shared
    private let aiService = AIAnalysisService()

    // MARK: - Computed

    var completedCount: Int { microActions.filter(\.isCompleted).count }
    var totalCount: Int { microActions.count }
    var progress: Double { totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0 }

    var nextRecommendedAction: MicroAction? {
        microActions.first(where: { !$0.isCompleted })
    }

    var committedAction: MicroAction? {
        guard let commitment = activeCommitment else { return nil }
        return microActions.first(where: { $0.id == commitment.microActionId })
    }

    // MARK: - Generate Action Plan (one-tap activation energy)

    func generateActionPlan(analysis: SWOTAnalysis, transcriptionText: String) async {
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        do {
            let (plan, actions) = try await aiService.generateAndSaveActionPlan(
                analysis: analysis,
                transcriptionText: transcriptionText
            )
            actionPlan = plan
            microActions = actions
            showCommitmentPicker = true
        } catch {
            errorMessage = "Failed to generate action plan: \(error.localizedDescription)"
        }
    }

    // MARK: - Load Existing Plan

    func loadActionPlan(analysisId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            guard let plan = try await supabase.fetchActionPlan(analysisId: analysisId) else { return }
            actionPlan = plan
            microActions = try await supabase.fetchMicroActions(actionPlanId: plan.id)

            if let userId = try await supabase.getCurrentUser()?.id {
                activeCommitment = try await supabase.fetchActiveCommitment(userId: userId)
            }

            computeNudges()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Toggle Micro Action

    func toggleMicroAction(id: UUID, isCompleted: Bool) async {
        // Optimistic update
        if let idx = microActions.firstIndex(where: { $0.id == id }) {
            microActions[idx].isCompleted = isCompleted
            microActions[idx].completedAt = isCompleted ? Date() : nil
        }

        do {
            try await supabase.toggleMicroAction(id: id, isCompleted: isCompleted)

            // If completing the committed action, also complete the commitment
            if isCompleted, let commitment = activeCommitment, commitment.microActionId == id {
                try await supabase.updateCommitmentStatus(id: commitment.id, status: "completed", completedAt: Date())
                activeCommitment = nil
            }

            computeNudges()
        } catch {
            // Revert on failure
            if let idx = microActions.firstIndex(where: { $0.id == id }) {
                microActions[idx].isCompleted = !isCompleted
                microActions[idx].completedAt = nil
            }
        }
    }

    // MARK: - Commitment (mere-measurement)

    func commitToAction(_ action: MicroAction, scheduledFor: Date?) async {
        guard let userId = try? await supabase.getCurrentUser()?.id else { return }

        // Expire any existing active commitment
        if let existing = activeCommitment {
            try? await supabase.updateCommitmentStatus(id: existing.id, status: "skipped")
        }

        let commitment = Commitment(
            id: UUID(),
            userId: userId,
            microActionId: action.id,
            scheduledFor: scheduledFor,
            status: "active",
            completedAt: nil,
            createdAt: Date()
        )

        do {
            try await supabase.createCommitment(commitment)
            try await supabase.commitMicroAction(id: action.id, scheduledFor: scheduledFor)
            activeCommitment = commitment

            if let idx = microActions.firstIndex(where: { $0.id == action.id }) {
                microActions[idx].isCommitted = true
                microActions[idx].committedAt = Date()
                microActions[idx].scheduledFor = scheduledFor
            }

            computeNudges()
        } catch {
            errorMessage = "Failed to save commitment: \(error.localizedDescription)"
        }
    }

    // MARK: - Nudge Computation (local)

    func computeNudges() {
        var result: [NudgeMessage] = []

        // Inactivity: no completions in last 2+ days
        let lastCompletion = microActions
            .compactMap(\.completedAt)
            .max()

        if let lastDate = lastCompletion {
            let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            if daysSince >= 2 {
                result.append(NudgeMessage(
                    type: .inactivity,
                    title: "Your idea is waiting",
                    body: "You haven't checked off an action in \(daysSince) days. Pick up where you left off?",
                    actionLabel: "Jump back in",
                    relatedActionId: nextRecommendedAction?.id
                ))
            }
        }

        // Commitment due
        if let commitment = activeCommitment,
           let scheduled = commitment.scheduledFor,
           scheduled <= Date() {
            let action = microActions.first(where: { $0.id == commitment.microActionId })
            result.append(NudgeMessage(
                type: .commitmentDue,
                title: "Time's up!",
                body: "You said you'd: \(action?.text ?? "complete your action")",
                actionLabel: "Mark it done",
                relatedActionId: commitment.microActionId
            ))
        }

        // Milestone
        let totalCompleted = microActions.filter(\.isCompleted).count
        if [3, 5, 7].contains(totalCompleted) && totalCompleted == completedCount {
            result.append(NudgeMessage(
                type: .milestone,
                title: "\(totalCompleted) actions done!",
                body: "You're making real progress on this idea",
                actionLabel: nil,
                relatedActionId: nil
            ))
        }

        nudges = result
    }
}

// MARK: - Actions Tab ViewModel (aggregates all plans)

@MainActor
class ActionsTabViewModel: ObservableObject {
    @Published var plans: [ActionPlan] = []
    @Published var microActionsByPlan: [UUID: [MicroAction]] = [:]
    @Published var activeCommitment: Commitment?
    @Published var isLoading = false

    private let supabase = SupabaseService.shared

    var nudges: [NudgeMessage] {
        var result: [NudgeMessage] = []

        // Commitment due nudge
        if let commitment = activeCommitment,
           let scheduled = commitment.scheduledFor,
           scheduled <= Date() {
            let action = microActionsByPlan.values
                .flatMap { $0 }
                .first(where: { $0.id == commitment.microActionId })
            result.append(NudgeMessage(
                type: .commitmentDue,
                title: "Time's up!",
                body: "You said you'd: \(action?.text ?? "complete your action")",
                actionLabel: "Mark it done",
                relatedActionId: commitment.microActionId
            ))
        }

        // Inactivity nudge across all plans
        let allActions = microActionsByPlan.values.flatMap { $0 }
        let lastCompletion = allActions.compactMap(\.completedAt).max()
        if let lastDate = lastCompletion, !allActions.allSatisfy(\.isCompleted) {
            let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            if daysSince >= 2 {
                result.append(NudgeMessage(
                    type: .inactivity,
                    title: "Your ideas are waiting",
                    body: "You haven't checked off an action in \(daysSince) days",
                    actionLabel: "Jump back in",
                    relatedActionId: nil
                ))
            }
        }

        return result
    }

    func loadAllPlans() async {
        isLoading = true
        defer { isLoading = false }

        guard let userId = try? await supabase.getCurrentUser()?.id else { return }

        do {
            plans = try await supabase.fetchAllActionPlans(userId: userId)
            for plan in plans {
                let actions = try await supabase.fetchMicroActions(actionPlanId: plan.id)
                microActionsByPlan[plan.id] = actions
            }
            activeCommitment = try? await supabase.fetchActiveCommitment(userId: userId)
        } catch {
            // Silent failure — tab just shows empty state
        }
    }

    func completedCount(for planId: UUID) -> Int {
        microActionsByPlan[planId]?.filter(\.isCompleted).count ?? 0
    }

    func totalCount(for planId: UUID) -> Int {
        microActionsByPlan[planId]?.count ?? 0
    }

    func progress(for planId: UUID) -> Double {
        let total = totalCount(for: planId)
        guard total > 0 else { return 0 }
        return Double(completedCount(for: planId)) / Double(total)
    }

    func committedActionText(for planId: UUID) -> String? {
        guard let commitment = activeCommitment else { return nil }
        return microActionsByPlan[planId]?
            .first(where: { $0.id == commitment.microActionId })?
            .text
    }
}
