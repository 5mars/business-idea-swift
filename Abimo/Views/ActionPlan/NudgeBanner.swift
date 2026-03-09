//
//  NudgeBanner.swift
//  Abimo
//

import SwiftUI

struct NudgeBanner: View {
    let nudge: NudgeMessage
    @State private var isVisible = true

    private var iconName: String {
        switch nudge.type {
        case .inactivity:    return "bell.badge"
        case .commitmentDue: return "clock.badge.exclamationmark"
        case .milestone:     return "party.popper"
        case .nextAction:    return "arrow.right.circle"
        }
    }

    private var tintColor: Color {
        switch nudge.type {
        case .inactivity:    return .brandAmber
        case .commitmentDue: return .brandPink
        case .milestone:     return .brandGreen
        case .nextAction:    return .brand
        }
    }

    private var bgColor: Color {
        switch nudge.type {
        case .inactivity:    return .cardDarkOrange
        case .commitmentDue: return .cardDarkRed
        case .milestone:     return .cardDarkTeal
        case .nextAction:    return .cardDarkBlue
        }
    }

    var body: some View {
        if isVisible {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(tintColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(nudge.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.textPri)
                    Text(nudge.body)
                        .font(.system(size: 13))
                        .foregroundColor(.textSec)
                        .lineLimit(2)
                }

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isVisible = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.textSec)
                        .padding(6)
                }
            }
            .padding(14)
            .background(bgColor)
            .cornerRadius(18)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}
