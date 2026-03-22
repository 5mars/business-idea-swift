//
//  ProgressRingView.swift
//  Abimo
//

import SwiftUI

// MARK: - ProgressRingView

struct ProgressRingView: View {
    let progress: Double
    let completed: Int
    let total: Int

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.brand.opacity(0.12), lineWidth: 8)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.brandGreen,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)

            // Center text
            VStack(spacing: 0) {
                Text("\(completed)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.textPri)
                    .contentTransition(.numericText())

                Text("of \(total)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSec)
            }
        }
        .frame(width: 80, height: 80)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        ProgressRingView(progress: 0.0, completed: 0, total: 5)
        ProgressRingView(progress: 0.4, completed: 2, total: 5)
        ProgressRingView(progress: 1.0, completed: 5, total: 5)
    }
    .padding()
    .background(Color.appBg)
}
