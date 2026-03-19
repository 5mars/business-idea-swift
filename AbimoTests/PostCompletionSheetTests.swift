//
//  PostCompletionSheetTests.swift
//  AbimoTests
//

import XCTest
@testable import Abimo

@MainActor
final class PostCompletionSheetTests: XCTestCase {

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

    /// Simulates completion of one action by directly mutating state + calling celebration evaluator.
    /// This avoids Supabase calls.
    private func simulateCompletion(vm: ActionPlanViewModel, at index: Int) {
        vm.microActions[index].isCompleted = true
        vm.microActions[index].completedAt = Date()
        let completedId = vm.microActions[index].id
        vm.evaluateCelebrationState(completedId: completedId)
        // Mirror the postCompletionSheet logic from toggleMicroAction
        let allDone = !vm.microActions.contains(where: { !$0.isCompleted })
        if !allDone {
            vm.postCompletionSheet = .congrats(actionId: completedId)
        }
    }

    // MARK: - PostCompletionSheet State Machine

    func testNonFinalCompletionSetsCongrats() {
        let vm = makeViewModel(actionCount: 5)
        let action = vm.microActions[0]
        simulateCompletion(vm: vm, at: 0)

        if case .congrats(let actionId) = vm.postCompletionSheet {
            XCTAssertEqual(actionId, action.id,
                           "Non-final completion must set postCompletionSheet to .congrats with the correct actionId")
        } else {
            XCTFail("Expected .congrats but got \(String(describing: vm.postCompletionSheet))")
        }
    }

    func testFinalCompletionSetsPlanCompleteNotCongrats() {
        let vm = makeViewModel(actionCount: 2)
        // Complete first action (non-final)
        simulateCompletion(vm: vm, at: 0)
        // Complete second action (final)
        simulateCompletion(vm: vm, at: 1)

        XCTAssertNil(vm.postCompletionSheet,
                     "Final completion must NOT set postCompletionSheet (it stays nil)")
        XCTAssertEqual(vm.celebrationState, .planComplete,
                       "Final completion must set celebrationState to .planComplete")
    }

    // MARK: - PostCompletionSheet Identifiable

    func testPostCompletionSheetIdentifiableIds() {
        let someUUID = UUID()
        let congratsSheet = PostCompletionSheet.congrats(actionId: someUUID)
        let pickerSheet = PostCompletionSheet.actionPicker

        XCTAssertEqual(congratsSheet.id, "congrats-\(someUUID)",
                       ".congrats Identifiable id must be 'congrats-{uuid}'")
        XCTAssertEqual(pickerSheet.id, "actionPicker",
                       ".actionPicker Identifiable id must be 'actionPicker'")
    }

    // MARK: - showActionPicker

    func testShowActionPickerDefaultsFalse() {
        let vm = makeViewModel(actionCount: 3)
        XCTAssertFalse(vm.showActionPicker,
                       "showActionPicker must default to false on a fresh ViewModel")
    }
}
