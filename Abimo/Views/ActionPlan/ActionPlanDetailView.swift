//
//  ActionPlanDetailView.swift
//  Abimo
//

import SwiftUI

struct ActionPlanDetailView: View {
    let planId: UUID
    let analysisId: UUID

    @StateObject private var viewModel = ActionPlanViewModel()
    @State private var selectedAction: MicroAction? = nil
    @State private var showCommitmentSheet = false

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            if viewModel.isLoading {
                LoadingView(text: "Loading your plan...")
            } else if viewModel.actionPlan != nil {
                JourneyPathView(
                    viewModel: viewModel,
                    selectedAction: $selectedAction
                )
            }

            // Milestone banner
            if case .milestone(let count) = viewModel.celebrationState {
                MilestoneBannerView(count: count)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }

            // Plan completion overlay
            if viewModel.celebrationState == .planComplete {
                PlanCompletionView(viewModel: viewModel, onDismiss: {
                    viewModel.celebrationState = .idle
                })
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(2)
                .ignoresSafeArea()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.celebrationState)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBg, for: .navigationBar)
        .sheet(item: $selectedAction) { action in
            let state = nodeStateForAction(action)
            ActionDetailSheet(
                action: action,
                state: state,
                viewModel: viewModel
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.appBg)
        }
        .sheet(isPresented: $showCommitmentSheet) {
            CommitmentSheet(viewModel: viewModel)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showCommitmentPicker) {
            CommitmentSheet(viewModel: viewModel)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showMomentumPicker) {
            if let actionId = viewModel.completingActionId {
                MomentumPickerSheet(
                    viewModel: viewModel,
                    completedActionId: actionId
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .task {
            await viewModel.loadActionPlan(analysisId: analysisId)
        }
    }

    private func nodeStateForAction(_ action: MicroAction) -> NodeState {
        guard let index = viewModel.microActions.firstIndex(where: { $0.id == action.id }) else {
            return .locked
        }
        return nodeState(at: index, actions: viewModel.microActions)
    }
}
