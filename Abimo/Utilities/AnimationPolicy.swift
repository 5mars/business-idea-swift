//
//  AnimationPolicy.swift
//  Abimo
//

import SwiftUI
import UIKit

enum AnimationPolicy {
    /// Returns true if animations should be suppressed per system preference.
    /// Reads the live system value on every call — never cached.
    static var reduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    /// Runs `change()` inside withAnimation only if reduce motion is off.
    /// If reduce motion is on, executes `change()` immediately with no animation.
    /// Default animation: spring with 0.4 response, 0.75 damping.
    static func animate(
        _ animation: Animation = .spring(response: 0.4, dampingFraction: 0.75),
        body change: () -> Void
    ) {
        if reduceMotion {
            change()
        } else {
            withAnimation(animation) { change() }
        }
    }
}
