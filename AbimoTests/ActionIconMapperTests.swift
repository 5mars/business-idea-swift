//
//  ActionIconMapperTests.swift
//  AbimoTests
//

import XCTest
@testable import Abimo

final class ActionIconMapperTests: XCTestCase {

    // MARK: - Known Action Types

    func testEmailReturnsEnvelopeIcon() {
        let result = ActionIconMapper.icon(for: "email")
        XCTAssertFalse(result.emoji.isEmpty, "emoji must not be empty")
        XCTAssertEqual(result.symbol, "envelope")
    }

    func testSearchReturnsMagnifyingGlassIcon() {
        let result = ActionIconMapper.icon(for: "search")
        XCTAssertFalse(result.emoji.isEmpty)
        XCTAssertEqual(result.symbol, "magnifyingglass")
    }

    func testMessageReturnsMessageIcon() {
        let result = ActionIconMapper.icon(for: "message")
        XCTAssertFalse(result.emoji.isEmpty)
        XCTAssertEqual(result.symbol, "message")
    }

    func testPostReturnsMegaphoneIcon() {
        let result = ActionIconMapper.icon(for: "post")
        XCTAssertFalse(result.emoji.isEmpty)
        XCTAssertEqual(result.symbol, "megaphone")
    }

    // MARK: - Default Fallback

    func testNilReturnsDefault() {
        let result = ActionIconMapper.icon(for: nil)
        XCTAssertFalse(result.emoji.isEmpty, "default emoji must not be empty")
        XCTAssertEqual(result.symbol, "checkmark.circle")
    }

    func testUnknownTypeReturnsDefault() {
        let result = ActionIconMapper.icon(for: "UNKNOWN")
        XCTAssertEqual(result.symbol, "checkmark.circle")
    }

    func testEmptyStringReturnsDefault() {
        let result = ActionIconMapper.icon(for: "")
        XCTAssertEqual(result.symbol, "checkmark.circle")
    }

    // MARK: - Case Insensitivity

    func testUppercaseEmailReturnsSameAsLowercase() {
        let upper = ActionIconMapper.icon(for: "EMAIL")
        let lower = ActionIconMapper.icon(for: "email")
        XCTAssertEqual(upper.symbol, lower.symbol)
        XCTAssertEqual(upper.emoji, lower.emoji)
    }

    func testMixedCaseMessageReturnsSameAsLowercase() {
        let mixed = ActionIconMapper.icon(for: "Message")
        let lower = ActionIconMapper.icon(for: "message")
        XCTAssertEqual(mixed.symbol, lower.symbol)
    }
}
