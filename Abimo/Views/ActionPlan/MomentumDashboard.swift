//
//  MomentumDashboard.swift
//  Abimo
//

import SwiftUI

struct MomentumDashboard: View {
    let streak: Int
    let weekActivity: [Bool] // 7 bools, Mon–Sun
    let totalCompletedThisWeek: Int
    let activeCommitmentText: String?
    let activeCommitmentPlanId: UUID?
    let activeCommitmentAnalysisId: UUID?

    var body: some View {
        VStack(spacing: 16) {
            // Streak + week header
            HStack(alignment: .top) {
                // Streak
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: streak > 0 ? "flame.fill" : "flame")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(streak > 0 ? .brandOrange : .textSec)
                        Text("\(streak)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.textPri)
                            .contentTransition(.numericText())
                    }
                    Text(streak == 1 ? "day streak" : "day streak")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSec)
                }

                Spacer()

                // Week view
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 6) {
                        ForEach(0..<7, id: \.self) { i in
                            Circle()
                                .fill(weekActivity[i] ? Color.brand : Color.brand.opacity(0.12))
                                .frame(width: 14, height: 14)
                        }
                    }
                    HStack(spacing: 0) {
                        Text("\(totalCompletedThisWeek) action\(totalCompletedThisWeek == 1 ? "" : "s") this week")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textSec)
                    }
                }
            }

            // Active commitment
            if let text = activeCommitmentText,
               let planId = activeCommitmentPlanId,
               let analysisId = activeCommitmentAnalysisId {
                NavigationLink {
                    ActionPlanDetailView(planId: planId, analysisId: analysisId)
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.brand.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.brand)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Your commitment")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.textSec)
                                .textCase(.uppercase)
                            Text(text)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.textPri)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()

                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.brand)
                    }
                    .padding(14)
                    .background(Color.cardDarkTeal)
                    .cornerRadius(16)
                }
                .buttonStyle(PlayfulButtonStyle())
            }
        }
        .cardStyle()
    }
}

// MARK: - Day labels

private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
