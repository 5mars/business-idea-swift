//
//  CommitmentSheet.swift
//  Abimo
//

import SwiftUI

struct CommitmentSheet: View {
    @ObservedObject var viewModel: ActionPlanViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedAction: MicroAction?
    @State private var useSchedule = false
    @State private var scheduledDate = Date()

    private var topActions: [MicroAction] {
        Array(viewModel.microActions
            .filter { !$0.isCompleted }
            .prefix(3))
    }

    var body: some View {
        VStack(spacing: 20) {
            // Handle
            Capsule()
                .fill(Color.textSec.opacity(0.25))
                .frame(width: 36, height: 4)
                .padding(.top, 8)

            // Header
            VStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.brandPink)

                Text("Pick ONE action to do right now")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.textPri)
                    .multilineTextAlignment(.center)

                Text("Choosing makes you 2x more likely to do it")
                    .font(.system(size: 14))
                    .foregroundColor(.textSec)
            }

            // Action cards
            VStack(spacing: 10) {
                ForEach(topActions) { action in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedAction = action
                        }
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .stroke(
                                        selectedAction?.id == action.id ? Color.brand : Color.textSec.opacity(0.2),
                                        lineWidth: 2
                                    )
                                    .frame(width: 24, height: 24)
                                if selectedAction?.id == action.id {
                                    Circle()
                                        .fill(Color.brand)
                                        .frame(width: 14, height: 14)
                                }
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(action.text)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.textPri)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)

                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 10))
                                    Text("\(action.timeEstimateMinutes) min")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(.textSec)
                            }

                            Spacer()
                        }
                        .padding(14)
                        .background(selectedAction?.id == action.id ? Color.cardDarkTeal : Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    selectedAction?.id == action.id ? Color.brand.opacity(0.3) : Color.black.opacity(0.05),
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .buttonStyle(PlayfulButtonStyle())
                }
            }
            .padding(.horizontal, 16)

            // Schedule toggle
            VStack(spacing: 10) {
                Toggle(isOn: $useSchedule) {
                    Text("Set a time")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textPri)
                }
                .tint(.brand)
                .padding(.horizontal, 16)

                if useSchedule {
                    DatePicker(
                        "When",
                        selection: $scheduledDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .padding(.horizontal, 16)
                    .transition(.opacity)
                }
            }

            // Confirm
            Button {
                guard let action = selectedAction else { return }
                Task {
                    await viewModel.commitToAction(action, scheduledFor: useSchedule ? scheduledDate : nil)
                    dismiss()
                }
            } label: {
                Text("I'm on it")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        (selectedAction != nil ? LinearGradient.record : LinearGradient(
                            colors: [Color.textSec.opacity(0.3), Color.textSec.opacity(0.3)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                    )
                    .cornerRadius(18)
            }
            .buttonStyle(PlayfulButtonStyle())
            .disabled(selectedAction == nil)
            .padding(.horizontal, 16)

            Spacer()
        }
        .background(Color.appBg)
    }
}
