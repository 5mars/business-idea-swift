//
//  CongratsHalfSheetTests.swift
//  AbimoTests
//

import XCTest
@testable import Abimo

@MainActor
final class CongratsHalfSheetTests: XCTestCase {

    func testMessagePoolIsNotEmpty() {
        XCTAssertFalse(CongratsHalfSheet.messages.isEmpty,
                       "Message pool must contain at least one message")
    }

    func testMessagePoolHasExpectedCount() {
        XCTAssertEqual(CongratsHalfSheet.messages.count, 7,
                       "Message pool must contain exactly 7 messages")
    }

    func testAllMessagesContainEmoji() {
        for msg in CongratsHalfSheet.messages {
            XCTAssertTrue(msg.unicodeScalars.contains(where: { $0.properties.isEmoji && $0.value > 0x238C }),
                          "Each message must contain at least one emoji: '\(msg)'")
        }
    }

    func testSheetPhaseEnumHasBothCases() {
        let congrats = SheetPhase.congrats
        let picker = SheetPhase.picker
        XCTAssertNotEqual(String(describing: congrats), String(describing: picker),
                          "SheetPhase must have distinct congrats and picker cases")
    }
}
