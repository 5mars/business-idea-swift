//
//  ActionPlanTitleTests.swift
//  AbimoTests
//

import XCTest
@testable import Abimo

@MainActor
final class ActionPlanTitleTests: XCTestCase {

    // MARK: - Tests

    func testPlanTitleUsesTitleFormatWhenNoteTitleIsNonEmpty() async {
        let result = AIAnalysisService.planTitle(noteTitle: "My Idea", responseTitle: "AI Title")
        XCTAssertEqual(
            result,
            "My Idea's action plan",
            "Should produce '{noteTitle}'s action plan' format when noteTitle is non-empty"
        )
    }

    func testPlanTitleFallsBackToAITitleWhenNoteTitleIsEmpty() async {
        let result = AIAnalysisService.planTitle(noteTitle: "", responseTitle: "AI Title")
        XCTAssertEqual(
            result,
            "AI Title",
            "Should fall back to AI-generated title when noteTitle is empty"
        )
    }

    func testPlanTitleFallsBackToAITitleWhenNoteTitleIsWhitespaceOnly() async {
        let result = AIAnalysisService.planTitle(noteTitle: "  ", responseTitle: "AI Title")
        XCTAssertEqual(
            result,
            "AI Title",
            "Should fall back to AI-generated title when noteTitle contains only whitespace"
        )
    }
}
