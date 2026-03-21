//
//  NodeBubbleView.swift
//  Abimo
//

import SwiftUI

// MARK: - BubbleShape

/// Rounded rectangle with a downward-pointing triangle arrow at bottom center.
struct BubbleShape: Shape {
    /// Horizontal offset of the arrow center within the full bubble width.
    var arrowOffset: CGFloat

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
    let arrowOffset: CGFloat        // Injected from bubbleOverlay — computed from node position
    let onComplete: () -> Void
    let onSwitch: () -> Void        // Calls pickAction(id:) to make this the next action
    let onSeeMore: () -> Void
    let onDismiss: () -> Void

    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Action name — full title, no truncation (TIPS-01)
            Text(action.text)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.textPri)
                .fixedSize(horizontal: false, vertical: true)

            Divider()
                .padding(.vertical, 4)

            // State-driven button row
            stateContent
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: 290, alignment: .leading)
        .background(
            BubbleShape(arrowOffset: arrowOffset)
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
            // Active: Complete + See More (D-10 — no Switch button)
            HStack(spacing: 12) {
                // Complete button
                Button(action: onComplete) {
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22, weight: .medium))
                        Text("Done")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.brand)
                    .cornerRadius(12)
                }
                .buttonStyle(PlayfulButtonStyle())

                // See more button
                Button(action: onSeeMore) {
                    VStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 22, weight: .medium))
                        Text("More")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.textSec)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.textSec.opacity(0.06))
                    .cornerRadius(12)
                }
                .buttonStyle(PlayfulButtonStyle())
            }

        case .completed:
            // Completed: Done badge + See More (D-12 — no Complete, no Switch)
            HStack {
                // Done badge (green capsule)
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Done")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.brandGreen))

                Spacer()

                // See more button (compact)
                Button(action: onSeeMore) {
                    VStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 22, weight: .medium))
                        Text("More")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.textSec)
                    .frame(width: 60, height: 52)
                    .background(Color.textSec.opacity(0.06))
                    .cornerRadius(12)
                }
                .buttonStyle(PlayfulButtonStyle())
            }

        case .locked:
            // Locked: Switch ("Do this next") + See More (D-11 — no Complete button)
            HStack(spacing: 12) {
                // Switch button — makes this the next action
                Button(action: onSwitch) {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 22, weight: .medium))
                        Text("Next")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.brand)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.brand.opacity(0.08))
                    .cornerRadius(12)
                }
                .buttonStyle(PlayfulButtonStyle())

                // See more button (same as active state)
                Button(action: onSeeMore) {
                    VStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 22, weight: .medium))
                        Text("More")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.textSec)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.textSec.opacity(0.06))
                    .cornerRadius(12)
                }
                .buttonStyle(PlayfulButtonStyle())
            }
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
            arrowOffset: 145,
            onComplete: {},
            onSwitch: {},
            onSeeMore: {},
            onDismiss: {}
        )

        NodeBubbleView(
            action: completedAction,
            state: .completed,
            arrowOffset: 145,
            onComplete: {},
            onSwitch: {},
            onSeeMore: {},
            onDismiss: {}
        )

        NodeBubbleView(
            action: lockedAction,
            state: .locked,
            arrowOffset: 145,
            onComplete: {},
            onSwitch: {},
            onSeeMore: {},
            onDismiss: {}
        )
    }
    .padding()
    .background(Color.appBg)
}
