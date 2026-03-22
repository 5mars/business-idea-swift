//
//  AnimationPolicyTests.swift
//  AbimoTests
//

import XCTest
@testable import Abimo

final class AnimationPolicyTests: XCTestCase {

    func testReduceMotionReturnsBool() {
        // Smoke test: property is accessible and returns a Bool
        let value = AnimationPolicy.reduceMotion
        XCTAssertNotNil(value as Bool?, "reduceMotion must return a Bool")
    }

    func testAnimateExecutesClosure() {
        // Verify the closure is called regardless of reduce motion setting
        var executed = false
        AnimationPolicy.animate {
            executed = true
        }
        XCTAssertTrue(executed, "animate must execute its closure")
    }

    func testAnimateWithCustomAnimation() {
        // Verify custom animation parameter is accepted without crash
        var executed = false
        AnimationPolicy.animate(.easeInOut(duration: 0.3)) {
            executed = true
        }
        XCTAssertTrue(executed)
    }
}
