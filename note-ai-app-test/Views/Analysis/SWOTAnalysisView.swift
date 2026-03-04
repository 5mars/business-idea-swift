//
//  SWOTAnalysisView.swift
//  note-ai-app-test
//

import SwiftUI

struct SWOTAnalysisView: View {
    let transcription: Transcription

    @StateObject private var viewModel = AnalysisViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if viewModel.isLoading {
                            analyzingView
                        } else if let analysis = viewModel.analysis {
                            // Summary
                            if let summary = analysis.summary {
                                summaryCard(summary)
                            }

                            // SWOT 2x2 grid
                            VStack(spacing: 14) {
                                HStack(spacing: 14) {
                                    SWOTQuadrantView(
                                        title: "Strengths",
                                        items: analysis.strengths,
                                        gradient: .swotStrength,
                                        iconName: "checkmark.circle.fill"
                                    )
                                    SWOTQuadrantView(
                                        title: "Weaknesses",
                                        items: analysis.weaknesses,
                                        gradient: .swotWeakness,
                                        iconName: "xmark.circle.fill"
                                    )
                                }

                                HStack(spacing: 14) {
                                    SWOTQuadrantView(
                                        title: "Opportunities",
                                        items: analysis.opportunities,
                                        gradient: .swotOpportunity,
                                        iconName: "arrow.up.circle.fill"
                                    )
                                    SWOTQuadrantView(
                                        title: "Threats",
                                        items: analysis.threats,
                                        gradient: .swotThreat,
                                        iconName: "exclamationmark.triangle.fill"
                                    )
                                }
                            }

                            Text("Generated \(analysis.createdAt, style: .relative) ago")
                                .font(.system(size: 12))
                                .foregroundColor(.textSec)
                                .padding(.bottom, 8)

                        } else if viewModel.errorMessage != nil {
                            errorView
                        } else {
                            readyView
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("SWOT Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBg, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .tint(.brand)
                        .fontWeight(.semibold)
                }
            }
            .task { await viewModel.loadAnalysis(transcriptionId: transcription.id) }
        }
    }

    // MARK: - States

    private var analyzingView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)

            ZStack {
                Circle()
                    .fill(Color.brand.opacity(0.08))
                    .frame(width: 100, height: 100)

                ProgressView()
                    .tint(.brand)
                    .scaleEffect(1.4)
            }

            Text("Analyzing your idea...")
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .foregroundColor(.textPri)

            Text("Claude AI is thinking")
                .font(.system(size: 14))
                .foregroundColor(.textSec)

            Spacer().frame(height: 60)
        }
        .frame(maxWidth: .infinity)
    }

    private func summaryCard(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.brand)
                        .frame(width: 32, height: 32)
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("Summary")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPri)
            }

            Text(summary)
                .font(.system(size: 15))
                .foregroundColor(.textPri)
                .lineSpacing(4)
        }
        .cardStyle()
    }

    private var readyView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)

            ZStack {
                Circle()
                    .fill(Color.brand.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "sparkles")
                    .font(.system(size: 38))
                    .foregroundStyle(LinearGradient(
                        colors: [.brand, .brandLight],
                        startPoint: .top, endPoint: .bottom
                    ))
            }

            Text("Ready to analyze")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.textPri)

            Text("Generate a SWOT analysis for\nthis business idea")
                .font(.system(size: 15))
                .foregroundColor(.textSec)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            GradientButton(title: "Generate Analysis") {
                Task { await viewModel.generateAnalysis(transcription: transcription) }
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)

            Spacer().frame(height: 40)
        }
    }

    private var errorView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)

            ZStack {
                Circle()
                    .fill(Color.brandOrange.opacity(0.1))
                    .frame(width: 90, height: 90)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.brandOrange)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 15))
                    .foregroundColor(.textSec)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            GradientButton(
                title: "Try Again",
                gradient: LinearGradient(
                    colors: [.brandOrange, .brandAmber],
                    startPoint: .leading, endPoint: .trailing
                )
            ) {
                Task { await viewModel.generateAnalysis(transcription: transcription) }
            }
            .padding(.horizontal, 40)

            Spacer().frame(height: 40)
        }
    }
}

// MARK: - SWOT Quadrant Card

struct SWOTQuadrantView: View {
    let title: String
    let items: [String]
    let gradient: LinearGradient
    let iconName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Gradient header
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)

                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(gradient)

            // Items
            VStack(alignment: .leading, spacing: 8) {
                if items.isEmpty {
                    Text("None identified")
                        .font(.system(size: 13))
                        .foregroundColor(.textSec)
                        .italic()
                        .padding(.top, 4)
                } else {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(gradient)
                                .frame(width: 5, height: 5)
                                .padding(.top, 5)

                            Text(item)
                                .font(.system(size: 13))
                                .foregroundColor(.textPri)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(Color.cardBg)
        .cornerRadius(16)
        .shadow(color: Color.brand.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    SWOTAnalysisView(transcription: Transcription(
        id: UUID(),
        noteId: UUID(),
        text: "Sample transcription text",
        language: "en",
        confidence: 0.95,
        createdAt: Date()
    ))
}
