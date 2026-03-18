//
//  HapticEngineTests.swift
//  AbimoTests
//

import XCTest
@testable import Abimo

final class HapticEngineTests: XCTestCase {

    func testPrepareDoesNotCrash() {
        // Smoke test: prepare() should not throw or crash
        HapticEngine.prepare()
    }

    func testPrepareCanBeCalledMultipleTimes() {
        HapticEngine.prepare()
        HapticEngine.prepare()
        HapticEngine.prepare()
        // No crash = pass
    }

    func testImpactDoesNotCrash() {
        HapticEngine.impact()
    }

    func testImpactWithStyleDoesNotCrash() {
        HapticEngine.impact(style: .light)
        HapticEngine.impact(style: .medium)
        HapticEngine.impact(style: .heavy)
    }

    func testSuccessDoesNotCrash() {
        HapticEngine.success()
    }

    func testSelectionDoesNotCrash() {
        HapticEngine.selection()
    }
}
