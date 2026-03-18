//
//  ActionDetailSheet.swift
//  Abimo
//

import SwiftUI

struct ActionDetailSheet: View {
    let action: MicroAction
    let state: NodeState
    @ObservedObject var viewModel: ActionPlanViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var copied = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Drag handle spacer (system indicator handles this)
                Spacer().frame(height: 8)

                // PRIMARY CONTENT — visible at medium detent

                // 1. Emoji (large, centered)
                let (emoji, _) = ActionIconMapper.icon(for: action.actionType)
                Text(emoji)
                    .font(.system(size: 48))

                // 2. Action text
                Text(action.text)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPri)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                // 3. Time estimate pill
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 13, weight: .medium))
                    Text("\(action.timeEstimateMinutes) min")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.textSec)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.textSec.opacity(0.08))
                .cornerRadius(12)

                // 4. CTA button
                if state == .completed {
                    // Green "Completed" badge
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                        Text("Completed")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundColor(.brandGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.brandGreen.opacity(0.12))
                    .cornerRadius(18)
                } else if state == .locked {
                    // Locked — no button, show hint text
                    Text("Complete earlier actions to unlock")
                        .font(.system(size: 14))
                        .foregroundColor(.textSec)
                } else {
                    // Active — Mark Complete button
                    Button {
                        dismiss()
                        Task {
                            await viewModel.toggleMicroAction(id: action.id, isCompleted: true)
                        }
                    } label: {
                        Text("Mark Complete")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(LinearGradient.record)
                            .cornerRadius(18)
                    }
                    .buttonStyle(PlayfulButtonStyle())
                }

                // SECONDARY CONTENT — revealed on scroll

                // Scroll hint chevron
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textSec.opacity(0.4))
                    .padding(.top, 4)

                Divider()
                    .padding(.horizontal, 16)

                // Done criteria
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.textSec)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Done when")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textSec)
                            .textCase(.uppercase)
                        Text(action.doneCriteria)
                            .font(.system(size: 15))
                            .foregroundColor(.textPri)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Template + deep link buttons (only if template exists)
                if let template = action.template, !template.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(template)
                            .font(.system(size: 14))
                            .foregroundColor(.textPri)
                            .lineSpacing(3)
                            .textSelection(.enabled)

                        HStack(spacing: 8) {
                            // Deep link button
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

                            // Copy button
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
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
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
