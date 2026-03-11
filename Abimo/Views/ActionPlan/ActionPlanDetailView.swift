//
//  ActionPlanDetailView.swift
//  Abimo
//

import SwiftUI

struct ActionPlanDetailView: View {
    let planId: UUID
    let analysisId: UUID

    @StateObject private var viewModel = ActionPlanViewModel()
    @State private var showCommitmentSheet = false

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .tint(.brand)
            } else if let plan = viewModel.actionPlan {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        Spacer().frame(height: 4)

                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(plan.title)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.textPri)
                            Text(plan.summary)
                                .font(.system(size: 15))
                                .foregroundColor(.textSec)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .heroCard(color: .cardDarkTeal)
                        .padding(.horizontal, 16)
                        .cardEntrance(delay: 0)

                        // Progress bar
                        VStack(spacing: 8) {
                            HStack {
                                Text("\(viewModel.completedCount) of \(viewModel.totalCount) done")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.textSec)
                                    .contentTransition(.numericText())
                                Spacer()
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.brand.opacity(0.12))
                                        .frame(height: 6)
                                    Capsule()
                                        .fill(LinearGradient.brand)
                                        .frame(width: geo.size.width * viewModel.progress, height: 6)
                                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.progress)
                                }
                            }
                            .frame(height: 6)
                        }
                        .padding(.horizontal, 16)
                        .cardEntrance(delay: 0.06)

                        // Actions list
                        VStack(spacing: 8) {
                            ForEach(Array(viewModel.microActions.enumerated()), id: \.element.id) { index, action in
                                MicroActionRow(
                                    action: action,
                                    isCommitted: viewModel.activeCommitment?.microActionId == action.id,
                                    onToggle: { isCompleted in
                                        Task {
                                            await viewModel.toggleMicroAction(id: action.id, isCompleted: isCompleted)
                                        }
                                    }
                                )
                                .padding(.horizontal, 16)
                                .cardEntrance(delay: 0.1 + Double(index) * 0.04)
                            }
                        }

                        // Commit CTA
                        if viewModel.activeCommitment == nil,
                           viewModel.microActions.contains(where: { !$0.isCompleted }) {
                            Button {
                                showCommitmentSheet = true
                            } label: {
                                Text("Pick one to do right now")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(LinearGradient.record)
                                    .cornerRadius(18)
                            }
                            .buttonStyle(PlayfulButtonStyle())
                            .padding(.horizontal, 16)
                            .cardEntrance(delay: 0.3)
                        }

                        Spacer().frame(height: 100)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBg, for: .navigationBar)
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
        .sheet(isPresented: $viewModel.showCompletionReflection) {
            if let actionId = viewModel.completingActionId {
                CompletionReflectionSheet(
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
}
