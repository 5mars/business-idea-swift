//
//  JourneyNodeView.swift
//  Abimo
//

import SwiftUI

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

    @State private var isAnimatingCompletion = false
    @State private var unlockAnimating = false

    var body: some View {
        VStack(spacing: 0) {
            // Circle node
            Button(action: onTap) {
                ZStack {
                    // Fill circle
                    Circle()
                        .fill(circleFillColor)
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
            .onChange(of: state) { oldValue, newValue in
                if oldValue != .completed && newValue == .completed {
                    // Bounce up
                    AnimationPolicy.animate(.spring(response: 0.15, dampingFraction: 0.4)) {
                        isAnimatingCompletion = true
                    }
                    // Bounce back
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        AnimationPolicy.animate(.spring(response: 0.15, dampingFraction: 0.6)) {
                            isAnimatingCompletion = false
                        }
                    }
                }
            }
            .onChange(of: justCompletedActionId) { _, completedId in
                guard let completedId = completedId,
                      let completedIndex = actions.firstIndex(where: { $0.id == completedId }),
                      index == completedIndex + 1 else { return }
                // This node is the successor — animate unlock
                AnimationPolicy.animate(.spring(response: 0.5, dampingFraction: 0.7)) {
                    unlockAnimating = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    unlockAnimating = false
                }
            }

            // Connecting line (only if not last node)
            if !isLastNode {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 2, height: 80)
                    .overlay(
                        Rectangle()
                            .stroke(
                                style: StrokeStyle(
                                    lineWidth: 2,
                                    dash: state == .completed ? [] : [6, 4]
                                )
                            )
                            .foregroundColor(
                                state == .completed
                                    ? .brandGreen
                                    : .textSec.opacity(0.3)
                            )
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
            actions: actions
        )
        JourneyNodeView(
            action: actions[1],
            state: .active,
            isLastNode: false,
            onTap: {},
            justCompletedActionId: nil,
            index: 1,
            actions: actions
        )
        JourneyNodeView(
            action: actions[2],
            state: .locked,
            isLastNode: true,
            onTap: {},
            justCompletedActionId: nil,
            index: 2,
            actions: actions
        )
    }
    .padding()
    .background(Color.appBg)
}
