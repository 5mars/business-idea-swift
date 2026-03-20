//
//  NavigationCoordinatorTests.swift
//  AbimoTests
//

import XCTest
@testable import Abimo

@MainActor
final class NavigationCoordinatorTests: XCTestCase {

    // MARK: - Helpers

    private func makeVoiceNote() -> VoiceNote {
        VoiceNote(
            id: UUID(),
            userId: UUID(),
            title: "Test Idea",
            audioFileURL: "https://example.com/audio.m4a",
            duration: 10.0,
            createdAt: Date(),
            updatedAt: Date(),
            transcriptionId: nil,
            analysisId: nil
        )
    }

    // MARK: - Tests

    func testInitialSelectedTabIsNotes() async {
        let coordinator = NavigationCoordinator()
        XCTAssertEqual(coordinator.selectedTab, .notes,
                       "NavigationCoordinator must initialize with selectedTab == .notes")
    }

    func testInitialPendingNoteIsNil() async {
        let coordinator = NavigationCoordinator()
        XCTAssertNil(coordinator.pendingNote,
                     "NavigationCoordinator must initialize with pendingNote == nil")
    }

    func testSettingSelectedTabUpdatesPublishedValue() async {
        let coordinator = NavigationCoordinator()
        coordinator.selectedTab = .record
        XCTAssertEqual(coordinator.selectedTab, .record,
                       "Setting selectedTab to .record must update the published value")
    }

    func testNavigateToNoteSetsSelectedTabAndPendingNote() async {
        let coordinator = NavigationCoordinator()
        let note = makeVoiceNote()

        coordinator.navigateToNote(note)

        XCTAssertEqual(coordinator.selectedTab, .notes,
                       "navigateToNote must set selectedTab to .notes")
        XCTAssertEqual(coordinator.pendingNote?.id, note.id,
                       "navigateToNote must set pendingNote to the given note")
    }

    func testClearingPendingNoteDoesNotChangeSelectedTab() async {
        let coordinator = NavigationCoordinator()
        coordinator.selectedTab = .record
        let note = makeVoiceNote()
        coordinator.pendingNote = note

        // Clear pendingNote
        coordinator.pendingNote = nil

        XCTAssertEqual(coordinator.selectedTab, .record,
                       "Clearing pendingNote must not change selectedTab")
        XCTAssertNil(coordinator.pendingNote,
                     "pendingNote must be nil after clearing")
    }
}
