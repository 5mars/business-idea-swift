//
//  CompletionReflectionSheet.swift
//  Abimo
//

import SwiftUI

struct CompletionReflectionSheet: View {
    @ObservedObject var viewModel: ActionPlanViewModel
    @Environment(\.dismiss) private var dismiss

    let completedActionId: UUID

    @State private var currentScreen: Screen = .reflection
    @State private var selectedOutcome: String?
    @State private var noteText = ""

    private enum Screen {
        case reflection
        case nextAction
    }

    private var completedAction: MicroAction? {
        viewModel.microActions.first(where: { $0.id == completedActionId })
    }

    private var nextAction: MicroAction? {
        viewModel.microActions.first(where: { !$0.isCompleted && $0.id != completedActionId })
    }

    var body: some View {
        VStack(spacing: 20) {
            // Handle
            Capsule()
                .fill(Color.textSec.opacity(0.25))
                .frame(width: 36, height: 4)
                .padding(.top, 8)

            switch currentScreen {
            case .reflection:
                reflectionScreen
            case .nextAction:
                nextActionScreen
            }

            Spacer()
        }
        .background(Color.appBg)
    }

    // MARK: - Screen 1: Reflection

    private var reflectionScreen: some View {
        VStack(spacing: 20) {
            // Celebration
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.brandGreen.opacity(0.12))
                        .frame(width: 64, height: 64)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.brandGreen)
                }

                Text("Nice work!")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.textPri)

                if let action = completedAction {
                    Text(action.text)
                        .font(.system(size: 14))
                        .foregroundColor(.textSec)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }

            // Outcome buttons
            VStack(spacing: 6) {
                Text("What happened?")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPri)

                VStack(spacing: 8) {
                    ForEach(outcomes, id: \.value) { outcome in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedOutcome = outcome.value
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Text(outcome.icon)
                                    .font(.system(size: 18))
                                Text(outcome.label)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.textPri)
                                Spacer()
                                if selectedOutcome == outcome.value {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.brand)
                                }
                            }
                            .padding(14)
                            .background(selectedOutcome == outcome.value ? Color.cardDarkTeal : Color.white)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        selectedOutcome == outcome.value ? Color.brand.opacity(0.3) : Color.black.opacity(0.05),
                                        lineWidth: 1.5
                                    )
                            )
                        }
                        .buttonStyle(PlayfulButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }

            // Optional note
            TextField("Any quick notes? (optional)", text: $noteText)
                .font(.system(size: 14))
                .foregroundColor(.textPri)
                .padding(14)
                .background(Color.white)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.black.opacity(0.05), lineWidth: 1.5)
                )
                .padding(.horizontal, 16)

            // Continue button
            Button {
                guard let outcome = selectedOutcome else { return }
                Task {
                    await viewModel.confirmCompletion(
                        id: completedActionId,
                        outcome: outcome,
                        note: noteText.isEmpty ? nil : noteText
                    )
                    if nextAction != nil {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentScreen = .nextAction
                        }
                    } else {
                        dismiss()
                    }
                }
            } label: {
                Text(nextAction != nil ? "Continue" : "Done")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(selectedOutcome != nil ? LinearGradient.brand : LinearGradient(
                        colors: [Color.textSec.opacity(0.3), Color.textSec.opacity(0.3)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .cornerRadius(18)
            }
            .buttonStyle(PlayfulButtonStyle())
            .disabled(selectedOutcome == nil)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Screen 2: Next Action

    private var nextActionScreen: some View {
        VStack(spacing: 20) {
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

            if let next = nextAction {
                // Next action card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Text("Up next")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.brand)
                            .textCase(.uppercase)
                        Spacer()
                        Text("\(next.timeEstimateMinutes) min")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textSec)
                    }

                    Text(next.text)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPri)
                        .lineLimit(3)

                    if let template = next.template, !template.isEmpty {
                        Text(template)
                            .font(.system(size: 13))
                            .foregroundColor(.textSec)
                            .lineLimit(3)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.cardDarkBlue)
                            .cornerRadius(12)
                    }
                }
                .padding(18)
                .background(Color.white)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.brand.opacity(0.15), lineWidth: 1.5)
                )
                .padding(.horizontal, 16)

                // Action buttons
                VStack(spacing: 10) {
                    Button {
                        Task {
                            await viewModel.commitToAction(next, scheduledFor: nil)
                            dismiss()
                        }
                    } label: {
                        Text("I'm on it")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(LinearGradient.record)
                            .cornerRadius(18)
                    }
                    .buttonStyle(PlayfulButtonStyle())
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
            }
        }
    }
}

// MARK: - Outcome Options

private struct OutcomeOption {
    let value: String
    let label: String
    let icon: String
}

private let outcomes: [OutcomeOption] = [
    OutcomeOption(value: "did_it", label: "Did it exactly", icon: "🎯"),
    OutcomeOption(value: "modified", label: "Modified it a bit", icon: "🔧"),
    OutcomeOption(value: "partial", label: "Partially done", icon: "⏳"),
    OutcomeOption(value: "skipped", label: "Skipped it", icon: "⏭️"),
]
