//
//  JourneyPathView.swift
//  Abimo
//

import SwiftUI

// MARK: - JourneyPathView

struct JourneyPathView: View {
    @ObservedObject var viewModel: ActionPlanViewModel
    @Binding var selectedAction: MicroAction?

    @State private var activeBubbleId: UUID? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    // Header: ProgressRingView + plan title
                    VStack(spacing: 12) {
                        ProgressRingView(
                            progress: viewModel.progress,
                            completed: viewModel.completedCount,
                            total: viewModel.totalCount
                        )
                        if let plan = viewModel.actionPlan {
                            Text(plan.title)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.textPri)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 32)

                    // Nodes
                    ForEach(Array(viewModel.orderedActions.enumerated()), id: \.element.id) { index, action in
                        let offset: CGFloat = index.isMultiple(of: 2) ? -60 : 60
                        JourneyNodeView(
                            action: action,
                            state: nodeState(at: index, actions: viewModel.orderedActions),
                            isLastNode: index == viewModel.orderedActions.count - 1,
                            onTap: {
                                AnimationPolicy.animate(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    activeBubbleId = activeBubbleId == action.id ? nil : action.id
                                }
                            },
                            justCompletedActionId: viewModel.justCompletedActionId,
                            index: index,
                            actions: viewModel.orderedActions,
                            zigzagOffset: offset,
                            celebrationState: viewModel.celebrationState
                        )
                        .offset(x: offset)
                        .id(action.id)
                        .cardEntrance(delay: Double(index) * 0.05)
                    }
                }
                .padding(.horizontal, 60)
                .padding(.bottom, 100)
                .overlay(alignment: .topLeading) {
                    bubbleOverlay
                }
                .task {
                    // Defer scroll to after first layout pass
                    try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                    if let activeAction = viewModel.orderedActions.first(where: { !$0.isCompleted }) {
                        AnimationPolicy.animate(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(activeAction.id, anchor: .center)
                        }
                    }
                }
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 10).onChanged { _ in
                if activeBubbleId != nil {
                    AnimationPolicy.animate(.easeOut(duration: 0.2)) {
                        activeBubbleId = nil
                    }
                }
            }
        )
    }

    // MARK: - Bubble Overlay

    @ViewBuilder
    private var bubbleOverlay: some View {
        if let id = activeBubbleId,
           let index = viewModel.orderedActions.firstIndex(where: { $0.id == id }) {
            let action = viewModel.orderedActions[index]
            let state = nodeState(at: index, actions: viewModel.orderedActions)
            let zigzagOffset: CGFloat = index.isMultiple(of: 2) ? -60 : 60

            // Positioning constants
            // Header: 16pt top + ProgressRingView(~80pt) + 12pt spacing + title(~22pt) + 32pt bottom = ~162pt
            let headerHeight: CGFloat = 162
            let nodeStride: CGFloat = 136   // 56pt node + 80pt connecting line
            let bubbleWidth: CGFloat = 220
            let bubbleEstimatedHeight: CGFloat = 100
            let arrowHeight: CGFloat = 8
            let gapAboveNode: CGFloat = 4

            // Vertical: place bubble so its arrow tip is just above the node center
            let nodeCenterY = headerHeight + CGFloat(index) * nodeStride + 28  // +28 = half of 56pt node
            let yPos = nodeCenterY - 28 - arrowHeight - gapAboveNode - bubbleEstimatedHeight

            // Horizontal: center bubble on node center, clamped to avoid screen edges
            // VStack has .padding(.horizontal, 60) so usable width = screenWidth - 120
            let screenWidth = UIScreen.main.bounds.width - 120
            let rawX = (screenWidth / 2 - bubbleWidth / 2) + zigzagOffset
            let xPos = max(8, min(screenWidth - bubbleWidth - 8, rawX))

            NodeBubbleView(
                action: action,
                state: state,
                onComplete: {
                    activeBubbleId = nil
                    Task { await viewModel.toggleMicroAction(id: action.id, isCompleted: true) }
                },
                onSeeMore: {
                    activeBubbleId = nil
                    selectedAction = action
                },
                onDismiss: {
                    activeBubbleId = nil
                }
            )
            .frame(width: bubbleWidth)
            .offset(x: xPos, y: yPos)
            .transition(.scale(scale: 0.01, anchor: .bottom).combined(with: .opacity))
            .zIndex(10)
            .id(id)
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ActionPlanViewModel()

    return JourneyPathView(
        viewModel: viewModel,
        selectedAction: .constant(nil)
    )
    .background(Color.appBg)
}
