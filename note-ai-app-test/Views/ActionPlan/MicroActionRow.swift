//
//  MicroActionRow.swift
//  note-ai-app-test
//

import SwiftUI

struct MicroActionRow: View {
    let action: MicroAction
    let isCommitted: Bool
    let onToggle: (Bool) -> Void

    @State private var isExpanded = false
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Surface — tap to expand
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    // Checkbox
                    Button {
                        onToggle(!action.isCompleted)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(action.isCompleted ? Color.brand : Color.textSec.opacity(0.25), lineWidth: 1.5)
                                .frame(width: 24, height: 24)
                            if action.isCompleted {
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(Color.brand)
                                    .frame(width: 24, height: 24)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    // Action text
                    Text(action.text)
                        .font(.system(size: 15, weight: action.isCompleted ? .regular : .medium))
                        .foregroundColor(action.isCompleted ? .textSec : .textPri)
                        .strikethrough(action.isCompleted, color: .textSec)
                        .lineLimit(isExpanded ? nil : 2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Time pill
                    Text("\(action.timeEstimateMinutes)m")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSec)
                }
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            // Expanded — done criteria + template
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Done criteria
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 12))
                            .foregroundColor(.textSec)
                        Text(action.doneCriteria)
                            .font(.system(size: 13))
                            .foregroundColor(.textSec)
                    }
                    .padding(.leading, 36)

                    // Template card with copy button
                    if let template = action.template, !template.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(template)
                                .font(.system(size: 14))
                                .foregroundColor(.textPri)
                                .lineSpacing(3)
                                .textSelection(.enabled)

                            Button {
                                UIPasteboard.general.string = template
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    copied = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation { copied = false }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 12, weight: .medium))
                                    Text(copied ? "Copied!" : "Copy")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(copied ? .brandGreen : .brand)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(copied ? Color.brandGreen.opacity(0.1) : Color.brand.opacity(0.08))
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlayfulButtonStyle())
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.cardDarkBlue)
                        .cornerRadius(14)
                        .padding(.leading, 36)
                    }
                }
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            // Subtle left border for committed action
            HStack {
                if isCommitted && !action.isCompleted {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.brand)
                        .frame(width: 3)
                }
                Spacer()
            }
        )
    }
}
