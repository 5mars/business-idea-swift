//
//  ActionsTabView.swift
//  Abimo
//

import SwiftUI

struct ActionsTabView: View {
    @StateObject private var viewModel = ActionsTabViewModel()

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer().frame(height: 4)

                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.brand)
                            .padding(.top, 60)
                    } else if viewModel.plans.isEmpty {
                        emptyState
                            .cardEntrance(delay: 0.1)
                    } else {
                        // Momentum Dashboard
                        if !viewModel.allCompletionDates.isEmpty || viewModel.activeCommitment != nil {
                            MomentumDashboard(
                                streak: viewModel.currentStreak,
                                weekActivity: viewModel.weekActivity,
                                totalCompletedThisWeek: viewModel.totalCompletedThisWeek,
                                activeCommitmentText: viewModel.activeCommitmentText,
                                activeCommitmentPlanId: viewModel.committedActionPlanId(),
                                activeCommitmentAnalysisId: viewModel.committedActionAnalysisId()
                            )
                            .padding(.horizontal, 16)
                            .cardEntrance(delay: 0)
                        }

                        ForEach(Array(viewModel.plans.enumerated()), id: \.element.id) { index, plan in
                            ideaCard(plan)
                                .padding(.horizontal, 16)
                                .cardEntrance(delay: Double(index) * 0.08 + 0.06)
                        }
                    }

                    Spacer().frame(height: 100)
                }
            }
        }
        .navigationTitle("Actions")
        .toolbarBackground(Color.appBg, for: .navigationBar)
        .task {
            await viewModel.loadAllPlans()
        }
    }

    // MARK: - Idea Card

    private func ideaCard(_ plan: ActionPlan) -> some View {
        let completed = viewModel.completedCount(for: plan.id)
        let total = viewModel.totalCount(for: plan.id)
        let committedText = viewModel.committedActionText(for: plan.id)

        return VStack(alignment: .leading, spacing: 18) {
            // Idea title + progress
            HStack {
                Text(plan.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.textPri)

                Spacer()

                Text("\(completed) of \(total)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.textSec)
                    .contentTransition(.numericText())
            }

            // Committed action (highlighted)
            if let committed = committedText {
                HStack(spacing: 12) {
                    Circle()
                        .stroke(Color.brand, lineWidth: 2)
                        .frame(width: 22, height: 22)

                    Text(committed)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.textPri)
                        .lineLimit(2)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.textSec.opacity(0.5))
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.cardDarkTeal)
                .cornerRadius(16)
            }

            // See all actions
            NavigationLink {
                ActionPlanDetailView(planId: plan.id, analysisId: plan.analysisId)
            } label: {
                HStack(spacing: 6) {
                    Text(committedText != nil ? "See all actions" : "Pick an action")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.brand)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.brand)
                }
            }
            .buttonStyle(PlayfulButtonStyle())
        }
        .cardStyle()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.brand.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(.brand)
            }

            VStack(spacing: 8) {
                Text("No action plans yet")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.textPri)
                Text("Record an idea, run the analysis,\nthen generate your action plan")
                    .font(.system(size: 15))
                    .foregroundColor(.textSec)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}
