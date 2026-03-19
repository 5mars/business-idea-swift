//
//  ActionPickerSheet.swift
//  Abimo
//

import SwiftUI

// MARK: - PickerMode

enum PickerMode {
    case firstVisit
    case postCompletion
}

// MARK: - ActionPickerSheet

struct ActionPickerSheet: View {
    @ObservedObject var viewModel: ActionPlanViewModel
    @Environment(\.dismiss) private var dismiss

    let mode: PickerMode
    var excludedActionId: UUID? = nil

    @State private var selectedActionId: UUID?

    // MARK: - Computed

    private var incompleteActions: [MicroAction] {
        viewModel.orderedActions.filter { !$0.isCompleted && $0.id != excludedActionId }
    }

    private var completedActions: [MicroAction] {
        viewModel.orderedActions.filter { $0.isCompleted && $0.id != excludedActionId }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // Drag handle
            Capsule()
                .fill(Color.textSec.opacity(0.25))
                .frame(width: 36, height: 4)
                .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text(headingText)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.textPri)

                        if case .firstVisit = mode {
                            Text("Choose the action you'll tackle first")
                                .font(.system(size: 14))
                                .foregroundColor(.textSec)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Cards
                    if incompleteActions.isEmpty && completedActions.isEmpty {
                        emptyStateView
                            .padding(.horizontal, 16)
                    } else {
                        VStack(spacing: 10) {
                            if incompleteActions.isEmpty {
                                emptyStateView
                            } else {
                                ForEach(incompleteActions) { action in
                                    actionCard(action)
                                }
                            }

                            ForEach(completedActions) { action in
                                completedCard(action)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 20)
            }

            // Confirm button (fixed outside ScrollView)
            Button {
                guard let id = selectedActionId else { return }
                viewModel.pickAction(id: id)
                dismiss()
            } label: {
                Text("Start this one!")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        selectedActionId != nil
                            ? LinearGradient.record
                            : LinearGradient(
                                colors: [Color.textSec.opacity(0.3), Color.textSec.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .cornerRadius(18)
            }
            .buttonStyle(PlayfulButtonStyle())
            .disabled(selectedActionId == nil)
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: selectedActionId != nil)
        }
        .background(Color.appBg)
    }

    // MARK: - Heading

    private var headingText: String {
        switch mode {
        case .firstVisit: return "Pick your first action"
        case .postCompletion: return "Keep the momentum?"
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Text("All done!")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.textPri)
            Text("You've completed every action in this plan.")
                .font(.system(size: 14))
                .foregroundColor(.textSec)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 32)
    }

    // MARK: - Incomplete Card

    private func actionCard(_ action: MicroAction) -> some View {
        let isSelected = selectedActionId == action.id

        return Button {
            AnimationPolicy.animate(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedActionId = action.id
            }
        } label: {
            HStack(spacing: 12) {
                Text(ActionIconMapper.icon(for: action.actionType).emoji)
                    .font(.system(size: 24))

                Text(action.text)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPri)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.brand)
                        .font(.system(size: 20))
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.brand.opacity(0.4) : Color.black.opacity(0.05),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlayfulButtonStyle())
    }

    // MARK: - Completed Card

    private func completedCard(_ action: MicroAction) -> some View {
        HStack(spacing: 12) {
            Text(ActionIconMapper.icon(for: action.actionType).emoji)
                .font(.system(size: 24))

            Text(action.text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textSec)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.brandGreen)
                .font(.system(size: 20))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .allowsHitTesting(false)
    }
}
