//
//  SWOTAnalysisView.swift
//  note-ai-app-test
//

import SwiftUI
import Charts

struct SWOTAnalysisView: View {
    let transcription: Transcription

    @StateObject private var viewModel: AnalysisViewModel
    @Environment(\.dismiss) var dismiss

    init(transcription: Transcription, preloadedAnalysis: SWOTAnalysis? = nil) {
        self.transcription = transcription
        if let existing = preloadedAnalysis {
            _viewModel = StateObject(wrappedValue: AnalysisViewModel(preloadedAnalysis: existing))
        } else {
            _viewModel = StateObject(wrappedValue: AnalysisViewModel())
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        analyzingView
                    } else if let analysis = viewModel.analysis {
                        analysisContent(analysis)
                    } else if viewModel.errorMessage != nil {
                        errorView
                    } else {
                        readyView
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(Color.appBg, ignoresSafeAreaEdges: .all)
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

    // MARK: - Analysis Content

    @ViewBuilder
    private func analysisContent(_ analysis: SWOTAnalysis) -> some View {
        // 1. Viability Score
        ViabilityGaugeView(score: analysis.viabilityScore ?? 0)

        // 2. Category Overview Bar Chart
        CategoryOverviewChart(analysis: analysis)

        // 3. Market Intelligence
        if let insights = analysis.marketInsights {
            MarketIntelligenceSection(insights: insights, context: analysis.marketContext)
        }

        // 4. Item Score Details per quadrant
        QuadrantItemChart(
            title: "Strengths",
            items: analysis.resolvedStrengths,
            color: .brandGreen,
            gradient: .swotStrength,
            iconName: "checkmark.circle.fill"
        )
        QuadrantItemChart(
            title: "Opportunities",
            items: analysis.resolvedOpportunities,
            color: .brandBlue,
            gradient: .swotOpportunity,
            iconName: "arrow.up.circle.fill"
        )
        QuadrantItemChart(
            title: "Weaknesses",
            items: analysis.resolvedWeaknesses,
            color: .brandRed,
            gradient: .swotWeakness,
            iconName: "xmark.circle.fill"
        )
        QuadrantItemChart(
            title: "Threats",
            items: analysis.resolvedThreats,
            color: .brandOrange,
            gradient: .swotThreat,
            iconName: "exclamationmark.triangle.fill"
        )

        // 5. Recommendations
        if let recs = analysis.recommendations, !recs.isEmpty {
            RecommendationsSection(recommendations: recs)
        }

        // Footer — summary + timestamp
        if let summary = analysis.summary {
            summaryCard(summary)
        }

        Text("Generated \(analysis.createdAt, style: .relative) ago")
            .font(.system(size: 12))
            .foregroundColor(.textSec)
            .padding(.bottom, 8)
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

            Text("Searching market data & building SWOT...")
                .font(.system(size: 14))
                .foregroundColor(.textSec)

            Spacer().frame(height: 60)
        }
        .frame(maxWidth: .infinity)
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
}

// MARK: - Viability Gauge

struct ViabilityGaugeView: View {
    let score: Int
    @State private var animatedScore: Double = 0

    private var scoreColor: Color {
        switch score {
        case 0..<40:  return .brandRed
        case 40..<60: return .brandOrange
        case 60..<80: return .brandAmber
        default:      return .brandGreen
        }
    }

    private var scoreLabel: String {
        switch score {
        case 0..<40:  return "Challenging"
        case 40..<60: return "Moderate"
        case 60..<80: return "Promising"
        default:      return "Strong"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "gauge.with.needle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.brand)
                Text("Viability Score")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPri)
                Spacer()
            }

            ZStack {
                // Track arc
                GaugeArc(progress: 1.0)
                    .stroke(Color.brand.opacity(0.1), style: StrokeStyle(lineWidth: 14, lineCap: .round))

                // Value arc
                GaugeArc(progress: animatedScore / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))

                // Center label
                VStack(spacing: 4) {
                    Text("\(score)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor)
                    Text(scoreLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSec)
                }
            }
            .frame(height: 150)
            .padding(.horizontal, 32)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    animatedScore = Double(score)
                }
            }
        }
        .cardStyle()
    }
}

// 240° arc shape starting at 150° (bottom-left), sweeping clockwise to 30° (bottom-right)
struct GaugeArc: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY + 20)
        let radius = min(rect.width, rect.height) * 0.42
        let startAngle = Angle(degrees: 150)
        let endAngle = Angle(degrees: 150 + 240 * progress)
        var path = Path()
        path.addArc(center: center, radius: radius,
                    startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return path
    }
}

// MARK: - Category Overview Bar Chart

struct CategoryOverviewChart: View {
    let analysis: SWOTAnalysis
    @State private var selectedLabel: String?

    private struct BarData: Identifiable {
        let id: String   // label doubles as stable id
        let score: Double
        let color: Color
    }

    private var data: [BarData] {
        [
            BarData(id: "Strengths",     score: analysis.avgStrengthScore,    color: .brandGreen),
            BarData(id: "Opportunities", score: analysis.avgOpportunityScore, color: .brandBlue),
            BarData(id: "Weaknesses",    score: analysis.avgWeaknessScore,    color: .brandRed),
            BarData(id: "Threats",       score: analysis.avgThreatScore,      color: .brandOrange),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.brand)
                Text("Quadrant Overview")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPri)
                Spacer()
                if selectedLabel != nil {
                    Text("Tap elsewhere to dismiss")
                        .font(.system(size: 10))
                        .foregroundColor(.textSec)
                }
            }

            Chart(data) { item in
                BarMark(
                    x: .value("Quadrant", item.id),
                    y: .value("Avg Score", item.score)
                )
                .foregroundStyle(
                    (selectedLabel == nil || selectedLabel == item.id)
                        ? AnyShapeStyle(item.color.gradient)
                        : AnyShapeStyle(item.color.opacity(0.25))
                )
                .cornerRadius(6)

                if selectedLabel == item.id {
                    RuleMark(x: .value("Selected", item.id))
                        .foregroundStyle(.clear)
                        .annotation(
                            position: .top,
                            alignment: .center,
                            spacing: 6,
                            overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                        ) {
                            BarTooltip(label: item.id, score: item.score, color: item.color)
                        }
                }
            }
            .chartXSelection(value: $selectedLabel)
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.brand.opacity(0.15))
                    AxisValueLabel()
                        .foregroundStyle(Color.textSec)
                        .font(.system(size: 10))
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.textPri)
                        .font(.system(size: 11, weight: .medium))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)  // extra height to accommodate tooltip above bar
        }
        .cardStyle()
    }
}

struct BarTooltip: View {
    let label: String
    let score: Double
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(Int(score.rounded()))")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text("avg score")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.textSec)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.cardBg)
                .shadow(color: color.opacity(0.25), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Market Intelligence

struct MarketIntelligenceSection: View {
    let insights: MarketInsights
    let context: String?

    private var trendIcon: String {
        switch insights.trendDirection {
        case "up":     return "arrow.up.right"
        case "down":   return "arrow.down.right"
        default:       return "arrow.right"
        }
    }

    private var trendColor: Color {
        switch insights.trendDirection {
        case "up":   return .brandGreen
        case "down": return .brandRed
        default:     return .brandAmber
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.brand)
                Text("Market Intelligence")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPri)
                Spacer()
                Label(insights.trendDirection?.capitalized ?? "Stable", systemImage: trendIcon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(trendColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(trendColor.opacity(0.1))
                    .cornerRadius(20)
            }

            // 2×2 tile grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if let size = insights.marketSize {
                    MarketInsightTile(icon: "chart.pie.fill", label: "Market Size", value: size, color: .brand)
                }
                if let rate = insights.growthRate {
                    MarketInsightTile(icon: "arrow.up.right.circle.fill", label: "Growth Rate", value: rate, color: .brandGreen)
                }
                if let competitors = insights.keyCompetitors, !competitors.isEmpty {
                    MarketInsightTile(icon: "person.3.fill", label: "Competitors", value: competitors.prefix(3).joined(separator: ", "), color: .brandOrange)
                }
                if let dir = insights.trendDirection {
                    MarketInsightTile(icon: "waveform.path.ecg", label: "Market Trend", value: dir.capitalized, color: trendColor)
                }
            }

            if let context = context, !context.isEmpty {
                Text(context)
                    .font(.system(size: 13))
                    .foregroundColor(.textSec)
                    .lineSpacing(3)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.brand.opacity(0.04))
                    .cornerRadius(10)
            }
        }
        .cardStyle()
    }
}

struct MarketInsightTile: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.textSec)
            }
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textPri)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.06))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Quadrant Item Chart

struct QuadrantItemChart: View {
    let title: String
    let items: [SWOTItem]
    let color: Color
    let gradient: LinearGradient
    let iconName: String

    private var sortedItems: [SWOTItem] {
        items.sorted { $0.score > $1.score }
    }

    private func shortLabel(_ text: String) -> String {
        text.count > 22 ? String(text.prefix(22)) + "…" : text
    }

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
                Spacer()
                Text("\(items.count) items")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(gradient)

            VStack(alignment: .leading, spacing: 14) {
                if sortedItems.isEmpty {
                    Text("None identified")
                        .font(.system(size: 13))
                        .foregroundColor(.textSec)
                        .italic()
                } else {
                    Chart(sortedItems) { item in
                        BarMark(
                            x: .value("Score", item.score),
                            y: .value("Item", shortLabel(item.point))
                        )
                        .foregroundStyle(color.gradient)
                        .cornerRadius(4)
                    }
                    .chartXScale(domain: 0...100)
                    .chartXAxis {
                        AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3]))
                                .foregroundStyle(Color.brand.opacity(0.15))
                            AxisValueLabel()
                                .foregroundStyle(Color.textSec)
                                .font(.system(size: 9))
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(Color.textPri)
                                .font(.system(size: 11))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: CGFloat(max(2, sortedItems.count)) * 44)

                    // Category pills
                    let categories = Array(Set(sortedItems.map(\.category))).sorted()
                    if !categories.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(categories, id: \.self) { cat in
                                    Text(cat)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(color)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(color.opacity(0.1))
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.cardBg)
        }
        .frame(maxWidth: .infinity)
        .cornerRadius(16)
        .shadow(color: Color.brand.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Recommendations

struct RecommendationsSection: View {
    let recommendations: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.brandAmber)
                Text("Recommendations")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPri)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(recommendations.enumerated()), id: \.offset) { index, rec in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(LinearGradient.brand)
                            .clipShape(Circle())

                        Text(rec)
                            .font(.system(size: 14))
                            .foregroundColor(.textPri)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .cardStyle()
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
