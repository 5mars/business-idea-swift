//
//  InlineConfettiView.swift
//  Abimo
//

import SwiftUI
import Vortex

struct InlineConfettiView: View {
    var body: some View {
        VortexViewReader { proxy in
            VortexView(.confetti) {
                Rectangle()
                    .fill(Color.brand)
                    .frame(width: 8, height: 8)
                    .tag("square")
                Circle()
                    .fill(Color.brandGreen)
                    .frame(width: 8)
                    .tag("circle")
                Rectangle()
                    .fill(Color.brandAmber)
                    .frame(width: 8, height: 8)
                    .tag("square2")
            }
            .onAppear {
                if !AnimationPolicy.reduceMotion {
                    proxy.burst()
                }
            }
            .allowsHitTesting(false)
        }
        .frame(width: 200, height: 200)
    }
}
