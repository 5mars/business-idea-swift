//
//  CelebrationStateTests.swift
//  AbimoTests
//

import XCTest
@testable import Abimo

@MainActor
final class CelebrationStateTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a fresh ViewModel with microActions pre-populated (no Supabase).
    /// Sets microActions directly, bypassing loadActionPlan.
    private func makeViewModel(actionCount: Int) -> ActionPlanViewModel {
        let vm = ActionPlanViewModel()
        vm.microActions = (0..<actionCount).map { i in
            MicroAction(
                id: UUID(),
                actionPlanId: UUID(),
                text: "Action \(i + 1)",
                doneCriteria: "Done",
                timeEstimateMinutes: 10,
                priority: i,
                quadrant: nil,
                template: nil,
                actionType: nil,
                deepLinkData: nil,
                isCompleted: false,
                completedAt: nil,
                isCommitted: false,
                committedAt: nil,
                scheduledFor: nil,
                completionOutcome: nil,
                completionNote: nil,
                createdAt: Date()
            )
        }
        return vm
    }

    /// Simulates completion of one action by directly mutating state + calling the
    /// internal celebration evaluator. This avoids Supabase calls.
    private func simulateCompletion(vm: ActionPlanViewModel, at index: Int) {
        vm.microActions[index].isCompleted = true
        vm.microActions[index].completedAt = Date()
        let completedId = vm.microActions[index].id
        vm.evaluateCelebrationState(completedId: completedId)
    }

    // MARK: - Initial State

    func testCelebrationStateStartsIdle() {
        let vm = makeViewModel(actionCount: 5)
        XCTAssertEqual(vm.celebrationState, .idle, "Initial celebrationState must be .idle")
    }

    // MARK: - Inline Confetti

    func testNonMilestoneNonFinalCompletionSetsInlineConfetti() {
        let vm = makeViewModel(actionCount: 5)
        simulateCompletion(vm: vm, at: 0) // 1st completion, not milestone, not final
        if case .inlineConfetti(let actionId) = vm.celebrationState {
            XCTAssertEqual(actionId, vm.microActions[0].id)
        } else {
            XCTFail("Expected .inlineConfetti but got \(vm.celebrationState)")
        }
    }

    func testSecondCompletionSetsInlineConfetti() {
        let vm = makeViewModel(actionCount: 5)
        simulateCompletion(vm: vm, at: 0)
        simulateCompletion(vm: vm, at: 1) // 2nd completion, not milestone
        if case .inlineConfetti(let actionId) = vm.celebrationState {
            XCTAssertEqual(actionId, vm.microActions[1].id)
        } else {
            XCTFail("Expected .inlineConfetti but got \(vm.celebrationState)")
        }
    }

    // MARK: - Milestone

    func testThirdCompletionSetsMilestone3() {
        let vm = makeViewModel(actionCount: 5)
        simulateCompletion(vm: vm, at: 0)
        simulateCompletion(vm: vm, at: 1)
        simulateCompletion(vm: vm, at: 2) // 3rd completion
        XCTAssertEqual(vm.celebrationState, .milestone(count: 3), "3rd completion must set .milestone(count: 3)")
    }

    func testFifthCompletionSetsMilestone5() {
        let vm = makeViewModel(actionCount: 7)
        for i in 0..<5 {
            simulateCompletion(vm: vm, at: i)
        }
        XCTAssertEqual(vm.celebrationState, .milestone(count: 5), "5th completion must set .milestone(count: 5)")
    }

    func testSeventhCompletionNotLastSetsMilestone7() {
        let vm = makeViewModel(actionCount: 9)
        for i in 0..<7 {
            simulateCompletion(vm: vm, at: i)
        }
        XCTAssertEqual(vm.celebrationState, .milestone(count: 7), "7th completion (not last) must set .milestone(count: 7)")
    }

    // MARK: - Plan Complete

    func testLastActionCompletionSetsPlanComplete() {
        let vm = makeViewModel(actionCount: 4)
        for i in 0..<4 {
            simulateCompletion(vm: vm, at: i)
        }
        XCTAssertEqual(vm.celebrationState, .planComplete, "Completing all actions must set .planComplete")
    }

    func testPlanCompleteOverridesMilestoneWhen7thIsLast() {
        // Plan with exactly 7 actions — 7th completion is BOTH milestone(7) AND last action
        let vm = makeViewModel(actionCount: 7)
        for i in 0..<7 {
            simulateCompletion(vm: vm, at: i)
        }
        XCTAssertEqual(vm.celebrationState, .planComplete,
                       "planComplete must take priority over milestone(7) when 7th action is also the last")
    }

    func testPlanCompleteOverridesMilestoneWhen3rdIsLast() {
        // Unusual edge case: plan with exactly 3 actions
        let vm = makeViewModel(actionCount: 3)
        for i in 0..<3 {
            simulateCompletion(vm: vm, at: i)
        }
        XCTAssertEqual(vm.celebrationState, .planComplete,
                       "planComplete must take priority when plan has exactly 3 actions and 3rd is completed")
    }

    // MARK: - Completed Minutes

    func testCompletedMinutesReturnsZeroWhenNoneCompleted() {
        let vm = makeViewModel(actionCount: 3)
        XCTAssertEqual(vm.completedMinutes, 0, "completedMinutes must be 0 when no actions completed")
    }

    func testCompletedMinutesSumsCompletedActionsOnly() {
        let vm = makeViewModel(actionCount: 3)
        // Complete first action (10 min), leave others incomplete
        simulateCompletion(vm: vm, at: 0)
        XCTAssertEqual(vm.completedMinutes, 10,
                       "completedMinutes must sum timeEstimateMinutes for completed actions only")
    }

    func testCompletedMinutesSumsMultipleCompletedActions() {
        let vm = makeViewModel(actionCount: 3)
        simulateCompletion(vm: vm, at: 0) // 10 min
        simulateCompletion(vm: vm, at: 2) // 10 min
        // Action at index 1 is NOT completed
        XCTAssertEqual(vm.completedMinutes, 20,
                       "completedMinutes must sum only completed actions (not all)")
    }

    func testCompletedMinutesExcludesIncompleteActions() {
        // Each action has timeEstimateMinutes = 10; complete only 2 of 4
        let vm = makeViewModel(actionCount: 4)
        simulateCompletion(vm: vm, at: 0)
        simulateCompletion(vm: vm, at: 1)
        XCTAssertEqual(vm.completedMinutes, 20,
                       "completedMinutes must not include incomplete actions (2 completed = 20 min)")
        XCTAssertNotEqual(vm.completedMinutes, 40,
                          "completedMinutes must not include all actions when only 2 of 4 are complete")
    }

    // MARK: - CelebrationState Equatable

    func testCelebrationStateEquatable() {
        XCTAssertEqual(CelebrationState.idle, CelebrationState.idle)
        XCTAssertEqual(CelebrationState.planComplete, CelebrationState.planComplete)

        let id = UUID()
        XCTAssertEqual(CelebrationState.inlineConfetti(actionId: id), CelebrationState.inlineConfetti(actionId: id))
        XCTAssertNotEqual(CelebrationState.inlineConfetti(actionId: id), CelebrationState.inlineConfetti(actionId: UUID()))

        XCTAssertEqual(CelebrationState.milestone(count: 3), CelebrationState.milestone(count: 3))
        XCTAssertNotEqual(CelebrationState.milestone(count: 3), CelebrationState.milestone(count: 5))

        XCTAssertNotEqual(CelebrationState.idle, CelebrationState.planComplete)
    }
}
