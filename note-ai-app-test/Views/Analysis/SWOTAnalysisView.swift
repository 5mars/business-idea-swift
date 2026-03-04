//
//  SWOTAnalysisView.swift
//  note-ai-app-test
//
//  Created by Claude on 2026-03-03.
//

import SwiftUI

struct SWOTAnalysisView: View {
    let transcription: Transcription

    @StateObject private var viewModel = AnalysisViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        VStack(spacing: 15) {
                            ProgressView()
                                .scaleEffect(1.5)

                            Text("Analyzing your business idea...")
                                .font(.headline)

                            Text("This may take a few seconds")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                    } else if let analysis = viewModel.analysis {
                        // Summary Section
                        if let summary = analysis.summary {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Summary", systemImage: "doc.text")
                                    .font(.headline)

                                Text(summary)
                                    .font(.body)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }

                        // SWOT Grid
                        VStack(spacing: 15) {
                            HStack(spacing: 15) {
                                SWOTQuadrantView(
                                    title: "Strengths",
                                    items: analysis.strengths,
                                    color: .green,
                                    icon: "checkmark.circle.fill"
                                )

                                SWOTQuadrantView(
                                    title: "Weaknesses",
                                    items: analysis.weaknesses,
                                    color: .red,
                                    icon: "xmark.circle.fill"
                                )
                            }

                            HStack(spacing: 15) {
                                SWOTQuadrantView(
                                    title: "Opportunities",
                                    items: analysis.opportunities,
                                    color: .blue,
                                    icon: "arrow.up.circle.fill"
                                )

                                SWOTQuadrantView(
                                    title: "Threats",
                                    items: analysis.threats,
                                    color: .orange,
                                    icon: "exclamationmark.triangle.fill"
                                )
                            }
                        }
                        .padding(.horizontal)

                        // Timestamp
                        Text("Generated \(analysis.createdAt, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                    } else if viewModel.errorMessage != nil {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)

                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding()
                            }

                            Button {
                                Task {
                                    await viewModel.generateAnalysis(transcription: transcription)
                                }
                            } label: {
                                Label("Try Again", systemImage: "arrow.clockwise")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)

                            Text("Ready to analyze")
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text("Generate a SWOT analysis for this business idea")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)

                            Button {
                                Task {
                                    await viewModel.generateAnalysis(transcription: transcription)
                                }
                            } label: {
                                Label("Generate Analysis", systemImage: "sparkles")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("SWOT Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadAnalysis(transcriptionId: transcription.id)
            }
        }
    }
}

struct SWOTQuadrantView: View {
    let title: String
    let items: [String]
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)

                        Text(item)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
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
