//
//  NodeBubbleView.swift
//  Abimo
//

import SwiftUI

// MARK: - BubbleShape

/// Rounded rectangle with a downward-pointing triangle arrow at bottom center.
struct BubbleShape: Shape {
    /// Horizontal offset of the arrow center within the full bubble width.
    var arrowOffset: CGFloat = 110

    func path(in rect: CGRect) -> Path {
        let cornerRadius: CGFloat = 12
        let arrowWidth: CGFloat = 12
        let arrowHeight: CGFloat = 8

        // Body rect excludes the arrow area at the bottom
        let bodyRect = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: rect.height - arrowHeight
        )

        var path = Path()

        // Draw rounded rect body
        path.addRoundedRect(in: bodyRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))

        // Arrow tip x: arrowOffset from left edge
        let arrowTipX = max(arrowWidth / 2 + cornerRadius, min(rect.width - arrowWidth / 2 - cornerRadius, arrowOffset))
        let arrowBaseY = bodyRect.maxY
        let arrowTipY = rect.maxY

        // Arrow triangle (drawn on top of the rounded rect bottom edge)
        path.move(to: CGPoint(x: arrowTipX - arrowWidth / 2, y: arrowBaseY))
        path.addLine(to: CGPoint(x: arrowTipX + arrowWidth / 2, y: arrowBaseY))
        path.addLine(to: CGPoint(x: arrowTipX, y: arrowTipY))
        path.closeSubpath()

        return path
    }
}

// MARK: - NodeBubbleView

struct NodeBubbleView: View {
    let action: MicroAction
    let state: NodeState
    let onComplete: () -> Void
    let onSeeMore: () -> Void
    let onDismiss: () -> Void

    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Action name
            Text(action.text)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.textPri)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)

            // State-driven bottom content
            stateContent
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 220, alignment: .leading)
        .background(
            BubbleShape(arrowOffset: 110)
                .fill(Color.white)
                .shadow(color: Color.textPri.opacity(0.12), radius: 12, x: 0, y: 4)
        )
        .scaleEffect(isVisible ? 1.0 : 0.01, anchor: .bottom)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            HapticEngine.impact(style: .light)
            AnimationPolicy.animate(.spring(response: 0.3, dampingFraction: 0.6)) {
                isVisible = true
            }
        }
    }

    // MARK: - State Content

    @ViewBuilder
    private var stateContent: some View {
        switch state {
        case .active:
            Button(action: onComplete) {
                Text("Complete!")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .background(Color.brand)
                    .cornerRadius(10)
            }
            .buttonStyle(PlayfulButtonStyle())

        case .completed:
            HStack {
                // "Done" badge
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Done")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.brandGreen))

                Spacer()

                // "See more" link
                Button(action: onSeeMore) {
                    Text("See more")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.brand)
                }
                .buttonStyle(.plain)
            }

        case .locked:
            Text("Coming up")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.textSec)
        }
    }
}

// MARK: - Preview

#Preview {
    let baseAction = MicroAction(
        id: UUID(),
        actionPlanId: UUID(),
        text: "Review and revise the first draft of your proposal",
        doneCriteria: "Proposal revised",
        timeEstimateMinutes: 30,
        priority: 1,
        quadrant: nil,
        template: nil,
        actionType: "write",
        deepLinkData: nil,
        isCompleted: false,
        completedAt: nil,
        isCommitted: false,
        committedAt: nil,
        scheduledFor: nil,
        completionOutcome: nil,
        completionNote: nil,
        createdAt: Date()
    )

    let completedAction = MicroAction(
        id: UUID(),
        actionPlanId: UUID(),
        text: "Send email to team",
        doneCriteria: "Email sent",
        timeEstimateMinutes: 5,
        priority: 2,
        quadrant: nil,
        template: nil,
        actionType: "email",
        deepLinkData: nil,
        isCompleted: true,
        completedAt: Date(),
        isCommitted: false,
        committedAt: nil,
        scheduledFor: nil,
        completionOutcome: nil,
        completionNote: nil,
        createdAt: Date()
    )

    let lockedAction = MicroAction(
        id: UUID(),
        actionPlanId: UUID(),
        text: "Post update to LinkedIn",
        doneCriteria: "Post published",
        timeEstimateMinutes: 10,
        priority: 3,
        quadrant: nil,
        template: nil,
        actionType: "post",
        deepLinkData: nil,
        isCompleted: false,
        completedAt: nil,
        isCommitted: false,
        committedAt: nil,
        scheduledFor: nil,
        completionOutcome: nil,
        completionNote: nil,
        createdAt: Date()
    )

    VStack(spacing: 24) {
        NodeBubbleView(
            action: baseAction,
            state: .active,
            onComplete: {},
            onSeeMore: {},
            onDismiss: {}
        )

        NodeBubbleView(
            action: completedAction,
            state: .completed,
            onComplete: {},
            onSeeMore: {},
            onDismiss: {}
        )

        NodeBubbleView(
            action: lockedAction,
            state: .locked,
            onComplete: {},
            onSeeMore: {},
            onDismiss: {}
        )
    }
    .padding()
    .background(Color.appBg)
}
