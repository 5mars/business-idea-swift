//
//  JourneyNodeView.swift
//  Abimo
//

import SwiftUI
import Vortex

// MARK: - NodeState

enum NodeState {
    case locked
    case active
    case completed
}

// MARK: - State Helper

func nodeState(at index: Int, actions: [MicroAction]) -> NodeState {
    let action = actions[index]
    if action.isCompleted { return .completed }
    let firstIncompleteIndex = actions.firstIndex(where: { !$0.isCompleted })
    if firstIncompleteIndex == index { return .active }
    return .locked
}

// MARK: - JourneyNodeView

struct JourneyNodeView: View {
    let action: MicroAction
    let state: NodeState
    let isLastNode: Bool
    let onTap: () -> Void
    let justCompletedActionId: UUID?
    let index: Int
    let actions: [MicroAction]
    /// The horizontal offset applied to THIS node by the parent zigzag layout.
    /// Used to calculate the diagonal connecting line to the next node.
    var zigzagOffset: CGFloat = 0
    var celebrationState: CelebrationState = .idle

    @State private var isAnimatingCompletion = false
    @State private var unlockAnimating = false
    @State private var animatedFillColor: Color = Color.textSec.opacity(0.3)

    var body: some View {
        VStack(spacing: 0) {
            // Circle node
            Button(action: onTap) {
                ZStack {
                    // Fill circle
                    Circle()
                        .fill(animatedFillColor)
                        .frame(width: 56, height: 56)

                    // Content overlay
                    nodeContent
                }
                .frame(width: 56, height: 56)
                .shadow(
                    color: state == .active ? Color.brand.opacity(0.4) : .clear,
                    radius: 8,
                    y: 2
                )
                .scaleEffect(isAnimatingCompletion ? 1.2 : 1.0)
                .scaleEffect(unlockAnimating ? 1.15 : 1.0)
            }
            .buttonStyle(.plain)
            .overlay {
                if case .inlineConfetti(let actionId) = celebrationState,
                   actionId == action.id {
                    InlineConfettiView()
                        .allowsHitTesting(false)
                }
            }
            .onAppear {
                animatedFillColor = circleFillColor
            }
            .onChange(of: state) { oldValue, newValue in
                if oldValue != .completed && newValue == .completed {
                    // Bounce up + color change simultaneously (coral to green during bounce)
                    AnimationPolicy.animate(.spring(response: 0.15, dampingFraction: 0.4)) {
                        isAnimatingCompletion = true
                        animatedFillColor = Color.brandGreen
                    }
                    // Bounce back
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        AnimationPolicy.animate(.spring(response: 0.15, dampingFraction: 0.6)) {
                            isAnimatingCompletion = false
                        }
                    }
                } else if oldValue != newValue {
                    // Generic state change (e.g., active->locked on undo) — animate color
                    AnimationPolicy.animate(.easeInOut(duration: 0.3)) {
                        animatedFillColor = circleFillColor
                    }
                }
            }
            .onChange(of: justCompletedActionId) { _, completedId in
                guard let completedId = completedId,
                      let completedIndex = actions.firstIndex(where: { $0.id == completedId }),
                      index == completedIndex + 1 else { return }

                // Beat 1: Pulse scale up
                AnimationPolicy.animate(.spring(response: 0.3, dampingFraction: 0.6)) {
                    unlockAnimating = true
                }

                // Beat 2: After pulse, scale down + color fade grey->coral
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    AnimationPolicy.animate(.easeInOut(duration: 0.3)) {
                        unlockAnimating = false
                        animatedFillColor = Color.brand
                    }
                }
            }

            // Connecting line (only if not last node)
            if !isLastNode {
                ConnectingLineView(
                    isCompleted: state == .completed,
                    zigzagOffset: zigzagOffset
                )
            }
        }
    }

    // MARK: - Private Helpers

    private var circleFillColor: Color {
        switch state {
        case .locked:    return Color.textSec.opacity(0.3)
        case .active:    return Color.brand
        case .completed: return Color.brandGreen
        }
    }

    @ViewBuilder
    private var nodeContent: some View {
        switch state {
        case .locked:
            Text("🔒")
                .font(.system(size: 24))
        case .active:
            Text(ActionIconMapper.icon(for: action.actionType).emoji)
                .font(.system(size: 24))
        case .completed:
            Image(systemName: "checkmark")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - ConnectingLineView

struct ConnectingLineView: View {
    let isCompleted: Bool
    let zigzagOffset: CGFloat

    /// The horizontal distance from this node's center to the next node's center.
    /// Since nodes alternate ±60, the delta is always 120 (or -120).
    private var horizontalDelta: CGFloat {
        -zigzagOffset * 2
    }

    var body: some View {
        let lineColor: Color = isCompleted ? .brandGreen : .textSec.opacity(0.3)

        Canvas { context, size in
            let from = CGPoint(x: size.width / 2, y: 0)
            let to = CGPoint(x: size.width / 2 + horizontalDelta, y: size.height)

            var path = Path()
            path.move(to: from)
            path.addLine(to: to)

            if isCompleted {
                context.stroke(path, with: .color(lineColor), lineWidth: 2.5)
            } else {
                context.stroke(
                    path,
                    with: .color(lineColor),
                    style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                )
            }
        }
        .frame(height: 80)
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview {
    let actions: [MicroAction] = [
        MicroAction(
            id: UUID(),
            actionPlanId: UUID(),
            text: "Send email",
            doneCriteria: "Email sent",
            timeEstimateMinutes: 5,
            priority: 1,
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
        ),
        MicroAction(
            id: UUID(),
            actionPlanId: UUID(),
            text: "Search online",
            doneCriteria: "Found resources",
            timeEstimateMinutes: 10,
            priority: 2,
            quadrant: nil,
            template: nil,
            actionType: "search",
            deepLinkData: nil,
            isCompleted: false,
            completedAt: nil,
            isCommitted: false,
            committedAt: nil,
            scheduledFor: nil,
            completionOutcome: nil,
            completionNote: nil,
            createdAt: Date()
        ),
        MicroAction(
            id: UUID(),
            actionPlanId: UUID(),
            text: "Post update",
            doneCriteria: "Post published",
            timeEstimateMinutes: 15,
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
        ),
    ]

    VStack(spacing: 0) {
        JourneyNodeView(
            action: actions[0],
            state: .completed,
            isLastNode: false,
            onTap: {},
            justCompletedActionId: nil,
            index: 0,
            actions: actions,
            zigzagOffset: -60
        )
        .offset(x: -60)
        JourneyNodeView(
            action: actions[1],
            state: .active,
            isLastNode: false,
            onTap: {},
            justCompletedActionId: nil,
            index: 1,
            actions: actions,
            zigzagOffset: 60
        )
        .offset(x: 60)
        JourneyNodeView(
            action: actions[2],
            state: .locked,
            isLastNode: true,
            onTap: {},
            justCompletedActionId: nil,
            index: 2,
            actions: actions,
            zigzagOffset: -60
        )
        .offset(x: -60)
    }
    .padding()
    .background(Color.appBg)
}
