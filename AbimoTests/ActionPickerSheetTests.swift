//
//  ActionPickerSheetTests.swift
//  AbimoTests
//

import XCTest
@testable import Abimo

@MainActor
final class ActionPickerSheetTests: XCTestCase {

    // MARK: - Helpers

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

    /// Creates a MicroAction with a specific completion state for use in tests.
    private func makeMicroAction(index: Int, isCompleted: Bool = false) -> MicroAction {
        MicroAction(
            id: UUID(),
            actionPlanId: UUID(),
            text: "Action \(index + 1)",
            doneCriteria: "Done",
            timeEstimateMinutes: 10,
            priority: index,
            quadrant: nil,
            template: nil,
            actionType: nil,
            deepLinkData: nil,
            isCompleted: isCompleted,
            completedAt: nil,
            isCommitted: false,
            committedAt: nil,
            scheduledFor: nil,
            completionOutcome: nil,
            completionNote: nil,
            createdAt: Date()
        )
    }

    // MARK: - Tests

    func testIncompleteActionsFilterExcludesCompletedAndExcludedId() {
        let vm = makeViewModel(actionCount: 5)
        // Mark action[0] and action[2] completed
        vm.microActions[0].isCompleted = true
        vm.microActions[2].isCompleted = true

        let excludedId = vm.microActions[0].id

        // Replicate ActionPickerSheet's incompleteActions filter
        let incompleteActions = vm.orderedActions.filter { !$0.isCompleted && $0.id != excludedId }

        // Expect: action[1], action[3], action[4] (not action[0] — excluded, not action[2] — completed)
        XCTAssertEqual(incompleteActions.count, 3,
                       "incompleteActions must exclude both completed actions and the excludedId action")
        XCTAssertFalse(incompleteActions.contains(where: { $0.isCompleted }),
                       "incompleteActions must not contain any completed actions")
        XCTAssertFalse(incompleteActions.contains(where: { $0.id == excludedId }),
                       "incompleteActions must not contain the excluded action id")
    }

    func testCompletedActionsFilterExcludesExcludedId() {
        let vm = makeViewModel(actionCount: 5)
        // Mark action[0] and action[2] completed
        vm.microActions[0].isCompleted = true
        vm.microActions[2].isCompleted = true

        let excludedId = vm.microActions[0].id

        // Replicate ActionPickerSheet's completedActions filter
        let completedActions = vm.orderedActions.filter { $0.isCompleted && $0.id != excludedId }

        // Expect: only action[2] (action[0] is excluded)
        XCTAssertEqual(completedActions.count, 1,
                       "completedActions must exclude the action matching excludedId")
        XCTAssertTrue(completedActions.allSatisfy(\.isCompleted),
                      "completedActions must all have isCompleted == true")
        XCTAssertEqual(completedActions.first?.id, vm.microActions[2].id,
                       "completedActions must contain only action[2] (action[0] is excluded)")
    }

    func testFirstVisitPickerShowsAllIncompleteActions() {
        let vm = makeViewModel(actionCount: 4)
        // All actions are incomplete, no excludedId (firstVisit mode)
        let incompleteActions = vm.orderedActions.filter { !$0.isCompleted }

        XCTAssertEqual(incompleteActions.count, 4,
                       "First-visit picker must show all incomplete actions when none are completed")
    }

    func testPickActionDismissesPickerAndReorders() {
        let vm = makeViewModel(actionCount: 3)
        let targetId = vm.microActions[2].id

        vm.pickAction(id: targetId)

        XCTAssertFalse(vm.showActionPicker,
                       "pickAction must set showActionPicker to false")
        XCTAssertEqual(vm.orderedActions.first?.id, targetId,
                       "pickAction must reorder so the picked action is first")
    }

    func testBrowseModeShowsAllActionsIncludingCompleted() {
        // Use makeViewModel + pickAction to reach a state with user ordering set
        // This exercises orderedActions (browse mode's allActions uses same property)
        let vm = makeViewModel(actionCount: 5)
        let targetId = vm.microActions[2].id

        // Trigger pickAction so orderedActions is based on userOrderedIds
        vm.pickAction(id: targetId)

        // Browse mode: allActions == vm.orderedActions (all 5, no exclusion filter)
        let allActions = vm.orderedActions

        XCTAssertEqual(allActions.count, 5,
                       "Browse mode must show all 5 actions (orderedActions count)")
        XCTAssertEqual(allActions.first?.id, targetId,
                       "After pickAction, the picked action must be first in orderedActions")
    }

    func testSelectAsNextCallsPickAction() {
        let vm = makeViewModel(actionCount: 3)
        let targetId = vm.microActions[1].id

        // Select as next calls vm.pickAction(id:) — same as the button action
        vm.pickAction(id: targetId)

        XCTAssertFalse(vm.showActionPicker,
                       "pickAction (Select as next) must set showActionPicker to false")
        XCTAssertEqual(vm.orderedActions.first?.id, targetId,
                       "pickAction (Select as next) must reorder so picked action is first")
    }

    func testHeaderButtonSetsShowActionPicker() {
        let vm = makeViewModel(actionCount: 3)

        // Simulate header button tap
        vm.showActionPicker = true
        XCTAssertTrue(vm.showActionPicker,
                      "Setting showActionPicker = true (header button) must be reflected")

        // Simulate selecting an action dismisses the picker
        let anyId = vm.microActions[0].id
        vm.pickAction(id: anyId)
        XCTAssertFalse(vm.showActionPicker,
                       "pickAction must dismiss the picker (set showActionPicker to false)")
    }

    func testTooltipAndHeaderButtonUseIdenticalPath() {
        // Build shared action IDs to ensure both VMs use same target
        let sharedActions = (0..<3).map { i in makeMicroAction(index: i) }
        let targetId = sharedActions[2].id

        // Tooltip path: showActionPicker = true then pickAction(id:)
        let vm1 = ActionPlanViewModel()
        vm1.microActions = sharedActions
        vm1.showActionPicker = true
        vm1.pickAction(id: targetId)

        // Header button path: same code — showActionPicker = true then pickAction(id:)
        let vm2 = ActionPlanViewModel()
        vm2.microActions = sharedActions
        vm2.showActionPicker = true
        vm2.pickAction(id: targetId)

        // Both paths produce same first action (target action placed first)
        XCTAssertEqual(vm1.orderedActions.first?.id, targetId,
                       "Tooltip path must place target action first")
        XCTAssertEqual(vm2.orderedActions.first?.id, targetId,
                       "Header button path must place target action first")
        // Both dismiss the picker
        XCTAssertFalse(vm1.showActionPicker,
                       "Tooltip path: picker must be dismissed after pickAction")
        XCTAssertFalse(vm2.showActionPicker,
                       "Header path: picker must be dismissed after pickAction")
    }
}
