//
//  NoteDetailViewTests.swift
//  AbimoTests
//

import XCTest
@testable import Abimo

@MainActor
final class NoteDetailViewTests: XCTestCase {

    // MARK: - Helpers

    private func makeTranscription() -> Transcription {
        Transcription(
            id: UUID(),
            noteId: UUID(),
            text: "Some transcribed text",
            language: "en",
            confidence: nil,
            createdAt: Date()
        )
    }

    // MARK: - Tests

    func testPlaceholderShownWhenLoadingAndNoTranscription() {
        XCTAssertTrue(
            NoteDetailView.shouldShowTranscribingPlaceholder(
                isLoadingTranscription: true,
                transcription: nil
            ),
            "Placeholder must show when loading and transcription is nil"
        )
    }

    func testPlaceholderHiddenWhenTranscriptionExists() {
        let transcription = makeTranscription()
        XCTAssertFalse(
            NoteDetailView.shouldShowTranscribingPlaceholder(
                isLoadingTranscription: true,
                transcription: transcription
            ),
            "Placeholder must NOT show when transcription exists, even if still loading"
        )
    }

    func testPlaceholderHiddenWhenNotLoadingAndNoTranscription() {
        XCTAssertFalse(
            NoteDetailView.shouldShowTranscribingPlaceholder(
                isLoadingTranscription: false,
                transcription: nil
            ),
            "Placeholder must NOT show when not loading, even if transcription is nil"
        )
    }

    func testPlaceholderHiddenWhenNotLoadingAndTranscriptionExists() {
        let transcription = makeTranscription()
        XCTAssertFalse(
            NoteDetailView.shouldShowTranscribingPlaceholder(
                isLoadingTranscription: false,
                transcription: transcription
            ),
            "Placeholder must NOT show when not loading and transcription exists"
        )
    }
}
