//
//  OrderingTests.swift
//  AbimoTests
//

import XCTest
@testable import Abimo

@MainActor
final class OrderingTests: XCTestCase {

    // MARK: - Helpers

    private let testSuiteName = "test_ordering"

    override func setUp() {
        super.setUp()
        UserDefaults(suiteName: testSuiteName)?.removePersistentDomain(forName: testSuiteName)
    }

    /// Creates a fresh ViewModel with microActions pre-populated (no Supabase).
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

    /// Simulates completion of one action by directly mutating state.
    private func simulateCompletion(vm: ActionPlanViewModel, at index: Int) {
        vm.microActions[index].isCompleted = true
        vm.microActions[index].completedAt = Date()
        let completedId = vm.microActions[index].id
        vm.evaluateCelebrationState(completedId: completedId)
    }

    // MARK: - orderedActions Default Behavior

    func testOrderedActionsReturnsMicroActionsWhenNoUserOrder() {
        let vm = makeViewModel(actionCount: 5)
        // No pickAction called, userOrderedIds is empty
        XCTAssertEqual(vm.orderedActions.map(\.id), vm.microActions.map(\.id),
                       "orderedActions must equal microActions when no user order is set")
    }

    // MARK: - pickAction

    func testPickActionPlacesChosenAtFirstIncompleteSlot() {
        let vm = makeViewModel(actionCount: 5)
        let actions = vm.microActions
        vm.pickAction(id: actions[2].id)
        XCTAssertEqual(vm.orderedActions[0].id, actions[2].id,
                       "Picked action must appear at the first incomplete slot (index 0)")
    }

    func testPickActionPreservesRelativeOrderOfRemainingActions() {
        let vm = makeViewModel(actionCount: 5)
        // Actions have priority 0-4 in order
        let actions = vm.microActions
        vm.pickAction(id: actions[3].id)

        // After picking actions[3], remaining should be [0, 1, 2, 4] in their original relative order
        let orderedIds = vm.orderedActions.map(\.id)
        // actions[3] must be first
        XCTAssertEqual(orderedIds[0], actions[3].id, "Picked action must be at index 0")
        // The other 4 actions must maintain their relative priority order
        let remainingIds = Array(orderedIds.dropFirst())
        XCTAssertEqual(remainingIds, [actions[0].id, actions[1].id, actions[2].id, actions[4].id],
                       "Remaining actions must maintain their relative priority order after a pick")
    }

    func testPickActionWithCompletedActionsPreservesCompletedPositions() {
        let vm = makeViewModel(actionCount: 5)
        let actions = vm.microActions
        // Complete action[0]
        simulateCompletion(vm: vm, at: 0)
        // Now pick actions[3]
        vm.pickAction(id: actions[3].id)

        let orderedIds = vm.orderedActions.map(\.id)
        // Completed action stays at position 0 (it comes before the first incomplete)
        XCTAssertEqual(orderedIds[0], actions[0].id,
                       "Completed action must remain at its position before incomplete actions")
        // Picked action must be at the first INCOMPLETE slot (index 1, since index 0 is completed)
        XCTAssertEqual(orderedIds[1], actions[3].id,
                       "Picked action must be at the first incomplete slot after completed actions")
    }

    // MARK: - UserDefaults Round-Trip

    func testUserDefaultsRoundTrip() {
        let vm = makeViewModel(actionCount: 5)
        let planId = UUID()
        // Simulate having an actionPlan so saveOrderToUserDefaults uses the correct key
        let plan = ActionPlan(
            id: planId,
            analysisId: UUID(),
            userId: UUID(),
            title: "Test Plan",
            summary: "Summary",
            totalEstimateMinutes: 50,
            createdAt: Date()
        )
        vm.actionPlan = plan
        vm.pickAction(id: vm.microActions[2].id)
        let savedIds = vm.userOrderedIds

        // Create a second VM with the same microActions and same planId
        let vm2 = ActionPlanViewModel()
        vm2.microActions = vm.microActions
        vm2.actionPlan = plan
        vm2.mergeUserOrder(planId: planId)

        XCTAssertEqual(vm2.userOrderedIds, savedIds,
                       "userOrderedIds must survive a UserDefaults round-trip")
    }

    // MARK: - mergeUserOrder

    func testMergeUserOrderDropsStaleIds() {
        let vm = makeViewModel(actionCount: 5)
        let planId = UUID()
        let plan = ActionPlan(
            id: planId,
            analysisId: UUID(),
            userId: UUID(),
            title: "Test Plan",
            summary: "Summary",
            totalEstimateMinutes: 50,
            createdAt: Date()
        )
        vm.actionPlan = plan

        // Manually set userOrderedIds to include a stale UUID
        let staleId = UUID()
        let knownIds = vm.microActions.map(\.id)
        vm.userOrderedIds = [staleId] + knownIds
        vm.saveOrderToUserDefaults()

        // Create a new VM that loads and merges
        let vm2 = ActionPlanViewModel()
        vm2.microActions = vm.microActions  // same actions, but staleId is not in them
        vm2.actionPlan = plan
        vm2.mergeUserOrder(planId: planId)

        XCTAssertFalse(vm2.userOrderedIds.contains(staleId),
                       "mergeUserOrder must drop stale IDs not present in current microActions")
    }

    func testMergeUserOrderAppendsNewIdsInPriorityOrder() {
        let vm = makeViewModel(actionCount: 5)
        let planId = UUID()
        let plan = ActionPlan(
            id: planId,
            analysisId: UUID(),
            userId: UUID(),
            title: "Test Plan",
            summary: "Summary",
            totalEstimateMinutes: 50,
            createdAt: Date()
        )
        vm.actionPlan = plan
        let allActions = vm.microActions

        // Store only the first 3 action IDs
        vm.userOrderedIds = [allActions[0].id, allActions[1].id, allActions[2].id]
        vm.saveOrderToUserDefaults()

        // Create a new VM with all 5 actions — 2 new ones (at indices 3 and 4)
        let vm2 = ActionPlanViewModel()
        vm2.microActions = allActions
        vm2.actionPlan = plan
        vm2.mergeUserOrder(planId: planId)

        // The stored 3 IDs come first, then the 2 missing IDs appended in priority order
        XCTAssertEqual(vm2.userOrderedIds.count, 5,
                       "mergeUserOrder must produce an entry for every action")
        // First 3 preserve stored order
        XCTAssertEqual(Array(vm2.userOrderedIds.prefix(3)),
                       [allActions[0].id, allActions[1].id, allActions[2].id],
                       "Stored order must be preserved at the front")
        // New IDs appended in priority order (priority 3 before priority 4)
        XCTAssertEqual(Array(vm2.userOrderedIds.suffix(2)),
                       [allActions[3].id, allActions[4].id],
                       "New IDs must be appended in priority order after stored IDs")
    }
}
