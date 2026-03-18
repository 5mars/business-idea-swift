//
//  JourneyPathView.swift
//  Abimo
//

import SwiftUI

// MARK: - JourneyPathView

struct JourneyPathView: View {
    @ObservedObject var viewModel: ActionPlanViewModel
    @Binding var selectedAction: MicroAction?

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
                    ForEach(Array(viewModel.microActions.enumerated()), id: \.element.id) { index, action in
                        JourneyNodeView(
                            action: action,
                            state: nodeState(at: index, actions: viewModel.microActions),
                            isLastNode: index == viewModel.microActions.count - 1,
                            onTap: { selectedAction = action }
                        )
                        .offset(x: index.isMultiple(of: 2) ? -60 : 60)
                        .id(action.id)
                        .cardEntrance(delay: Double(index) * 0.05)
                    }
                }
                .padding(.horizontal, 60)
                .padding(.bottom, 100)
                .task {
                    // Defer scroll to after first layout pass
                    try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                    if let activeAction = viewModel.microActions.first(where: { !$0.isCompleted }) {
                        AnimationPolicy.animate(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(activeAction.id, anchor: .center)
                        }
                    }
                }
            }
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
