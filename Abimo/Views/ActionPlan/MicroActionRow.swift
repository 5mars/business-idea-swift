//
//  MicroActionRow.swift
//  Abimo
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

                    // Template card with action buttons
                    if let template = action.template, !template.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(template)
                                .font(.system(size: 14))
                                .foregroundColor(.textPri)
                                .lineSpacing(3)
                                .textSelection(.enabled)

                            HStack(spacing: 8) {
                                // Primary: "Do it now" deep link button
                                if let url = buildDeepLink() {
                                    Button {
                                        UIApplication.shared.open(url)
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: deepLinkIcon)
                                                .font(.system(size: 12, weight: .medium))
                                            Text(deepLinkLabel)
                                                .font(.system(size: 13, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(LinearGradient.record)
                                        .cornerRadius(10)
                                    }
                                    .buttonStyle(PlayfulButtonStyle())
                                }

                                // Secondary: Copy
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

    // MARK: - Deep Link Helpers

    private func buildDeepLink() -> URL? {
        let type = action.actionType ?? inferActionType()

        switch type {
        case "message":
            let body = action.deepLinkData?.body ?? action.template ?? ""
            guard let encoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
            return URL(string: "sms:&body=\(encoded)")
        case "search":
            let query = action.deepLinkData?.query ?? action.template ?? ""
            guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
            return URL(string: "https://www.google.com/search?q=\(encoded)")
        case "email":
            let body = action.deepLinkData?.body ?? action.template ?? ""
            let subject = action.deepLinkData?.subject ?? ""
            guard let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
            return URL(string: "mailto:?subject=\(subjectEncoded)&body=\(bodyEncoded)")
        case "post":
            if let scheme = action.deepLinkData?.urlScheme {
                return URL(string: scheme)
            }
            return nil
        default:
            return nil
        }
    }

    /// Infer action type from template text for backward compatibility
    private func inferActionType() -> String {
        guard let template = action.template?.lowercased() else { return "generic" }
        let text = action.text.lowercased()

        if text.contains("message") || text.contains("ask") || text.contains("text") ||
           template.contains("hey ") || template.contains("quick question") {
            return "message"
        }
        if text.contains("search") || text.contains("google") ||
           template.contains("alternatives") || template.contains("pricing") {
            return "search"
        }
        if text.contains("email") || template.contains("subject:") {
            return "email"
        }
        if text.contains("post") || text.contains("reddit") || text.contains("twitter") {
            return "post"
        }
        return "generic"
    }

    private var deepLinkIcon: String {
        let type = action.actionType ?? inferActionType()
        switch type {
        case "message": return "message.fill"
        case "search": return "safari.fill"
        case "email": return "envelope.fill"
        case "post": return "square.and.arrow.up.fill"
        default: return "arrow.up.right"
        }
    }

    private var deepLinkLabel: String {
        let type = action.actionType ?? inferActionType()
        switch type {
        case "message": return "Send message"
        case "search": return "Search now"
        case "email": return "Send email"
        case "post": return "Post now"
        default: return "Do it now"
        }
    }
}
