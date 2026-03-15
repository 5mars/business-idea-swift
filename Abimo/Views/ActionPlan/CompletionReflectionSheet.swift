//
//  CompletionReflectionSheet.swift
//  Abimo
//

import SwiftUI

struct MomentumPickerSheet: View {
    @ObservedObject var viewModel: ActionPlanViewModel
    @Environment(\.dismiss) private var dismiss

    let completedActionId: UUID

    @State private var selectedActionId: UUID?
    @State private var showAll = false

    private var remainingActions: [MicroAction] {
        viewModel.microActions.filter { !$0.isCompleted && $0.id != completedActionId }
    }

    private var visibleActions: [MicroAction] {
        if showAll {
            return remainingActions
        } else {
            return Array(remainingActions.prefix(3))
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Handle
            Capsule()
                .fill(Color.textSec.opacity(0.25))
                .frame(width: 36, height: 4)
                .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.brandAmber)

                        Text("Keep the momentum?")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.textPri)

                        Text("\(viewModel.completedCount) of \(viewModel.totalCount) done")
                            .font(.system(size: 14))
                            .foregroundColor(.textSec)
                    }

                    // Action cards
                    VStack(spacing: 10) {
                        ForEach(visibleActions) { action in
                            actionCard(action)
                        }

                        // Show more button
                        if !showAll && remainingActions.count > 3 {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showAll = true
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text("Show \(remainingActions.count - 3) more")
                                        .font(.system(size: 14, weight: .medium))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundColor(.brand)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(PlayfulButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)

                    // Action buttons
                    VStack(spacing: 10) {
                        Button {
                            guard let selectedId = selectedActionId,
                                  let action = remainingActions.first(where: { $0.id == selectedId }) else { return }
                            Task {
                                await viewModel.commitToAction(action, scheduledFor: nil)
                                dismiss()
                            }
                        } label: {
                            Text("I'm on it")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(selectedActionId != nil ? LinearGradient.record : LinearGradient(
                                    colors: [Color.textSec.opacity(0.3), Color.textSec.opacity(0.3)],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .cornerRadius(18)
                        }
                        .buttonStyle(PlayfulButtonStyle())
                        .disabled(selectedActionId == nil)
                        .padding(.horizontal, 16)

                        Button {
                            dismiss()
                        } label: {
                            Text("Later")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.textSec)
                        }
                        .buttonStyle(PlayfulButtonStyle())
                    }

                    Spacer().frame(height: 20)
                }
            }
        }
        .background(Color.appBg)
        .onAppear {
            // Pre-select the first action
            selectedActionId = visibleActions.first?.id
        }
    }

    // MARK: - Action Card

    private func actionCard(_ action: MicroAction) -> some View {
        let isSelected = selectedActionId == action.id

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedActionId = action.id
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    // Selection indicator
                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color.brand : Color.textSec.opacity(0.25), lineWidth: 1.5)
                            .frame(width: 22, height: 22)
                        if isSelected {
                            Circle()
                                .fill(Color.brand)
                                .frame(width: 14, height: 14)
                        }
                    }

                    Text(action.text)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPri)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Text("\(action.timeEstimateMinutes) min")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSec)
                }

                if let template = action.template, !template.isEmpty {
                    Text(template)
                        .font(.system(size: 13))
                        .foregroundColor(.textSec)
                        .lineLimit(2)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.cardDarkBlue)
                        .cornerRadius(10)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.brand.opacity(0.4) : Color.black.opacity(0.05), lineWidth: 1.5)
            )
        }
        .buttonStyle(PlayfulButtonStyle())
    }
}
