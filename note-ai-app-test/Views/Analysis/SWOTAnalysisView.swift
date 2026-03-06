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
            .navigationTitle("Lab Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBg, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .tint(.brand)
                        .fontWeight(.bold)
                        .buttonStyle(PlayfulButtonStyle())
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
            .cardEntrance(delay: 0.05)

        // 2. Game Plan checklist
        GamePlanCard(
            analysis: analysis,
            actionItems: viewModel.actionItems,
            onToggle: { id, completed in await viewModel.toggleAction(id: id, isCompleted: completed) }
        )
        .cardEntrance(delay: 0.10)

        // 3. Quadrant Summary Grid
        QuadrantSummaryGrid(analysis: analysis)
            .cardEntrance(delay: 0.15)

        // 4. Category Overview Bar Chart
        CategoryOverviewChart(analysis: analysis)
            .cardEntrance(delay: 0.20)

        // 5. Market Intelligence
        if let insights = analysis.marketInsights {
            MarketIntelligenceSection(insights: insights, context: analysis.marketContext)
                .cardEntrance(delay: 0.26)
        }

        // 6. Item Score Details per quadrant
        QuadrantItemChart(
            title: "The Wins",
            items: analysis.resolvedStrengths,
            color: .brandGreen,
            gradient: .swotStrength,
            iconName: "checkmark.circle.fill"
        )
        .cardEntrance(delay: 0.32)

        QuadrantItemChart(
            title: "Opportunities",
            items: analysis.resolvedOpportunities,
            color: .brandBlue,
            gradient: .swotOpportunity,
            iconName: "arrow.up.circle.fill"
        )
        .cardEntrance(delay: 0.38)

        QuadrantItemChart(
            title: "Weaknesses",
            items: analysis.resolvedWeaknesses,
            color: .brandRed,
            gradient: .swotWeakness,
            iconName: "xmark.circle.fill"
        )
        .cardEntrance(delay: 0.44)

        QuadrantItemChart(
            title: "Watch Out",
            items: analysis.resolvedThreats,
            color: .brandOrange,
            gradient: .swotThreat,
            iconName: "exclamationmark.triangle.fill"
        )
        .cardEntrance(delay: 0.50)

        // 7. Recommendations
        if let recs = analysis.recommendations, !recs.isEmpty {
            RecommendationsSection(recommendations: recs)
                .cardEntrance(delay: 0.56)
        }

        // Footer — summary + timestamp
        if let summary = analysis.summary {
            summaryCard(summary)
                .cardEntrance(delay: 0.60)
        }

        Text("Cooked up \(analysis.createdAt, style: .relative) ago")
            .font(.system(size: 12))
            .foregroundColor(.textSec)
            .padding(.bottom, 8)
            .cardEntrance(delay: 0.64)
    }

    // MARK: - States

    private let cookingMessages: [String] = [
        "Cooking up insights...",
        "Turning up the heat...",
        "Taste-testing your idea...",
        "Simmering your strategy...",
        "Mixing the formula...",
        "Running the experiment...",
        "Prepping the ingredients...",
        "Almost chef's kiss ready...",
        "Adding a pinch of market data...",
        "Let it marinate for a sec...",
        "Stress-testing your thesis...",
        "Nearly plated up...",
    ]
    @State private var cookingMsgIndex = 0

    private var analyzingView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)

            ZStack {
                Circle()
                    .fill(Color.brand.opacity(0.08))
                    .frame(width: 100, height: 100)

                ProgressView()
                    .tint(.brand)
                    .scaleEffect(1.4)
            }

            VStack(spacing: 8) {
                Text(cookingMessages[cookingMsgIndex % cookingMessages.count])
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.textPri)
                    .multilineTextAlignment(.center)
                    .id(cookingMsgIndex)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: cookingMsgIndex)

                Text("This might take 15–30 seconds")
                    .font(.system(size: 13))
                    .foregroundColor(.textSec)
            }

            Spacer().frame(height: 60)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 2.8, repeats: true) { _ in
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    cookingMsgIndex += 1
                }
            }
        }
    }

    private var readyView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)

            ZStack {
                Circle()
                    .fill(Color.brand.opacity(0.08))
                    .frame(width: 100, height: 100)

                Image(systemName: "sparkles")
                    .font(.system(size: 38))
                    .foregroundStyle(LinearGradient(
                        colors: [.brand, .brandLight],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .symbolEffect(.pulse)
            }

            Text("Let's stress-test this")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.textPri)

            Text("Drop your idea in The Lab and\nwe'll break it down for you")
                .font(.system(size: 15))
                .foregroundColor(.textSec)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            GradientButton(title: "Run the numbers") {
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
                title: "One more time",
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
        SummaryCard(summary: summary)
    }
}

// MARK: - Summary Card

private struct SummaryCard: View {
    let summary: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.brand)
                            .frame(width: 32, height: 32)
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Text("TL;DR")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPri)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textSec)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isExpanded)
                }
            }
            .buttonStyle(.plain)

            Text(summary)
                .font(.system(size: 15))
                .foregroundColor(.textPri)
                .lineSpacing(4)
                .lineLimit(isExpanded ? nil : 3)
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
                Text("Survival Score")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPri)
                Spacer()
            }

            ZStack {
                // Track arc
                GaugeArc(progress: 1.0)
                    .stroke(Color.black.opacity(0.08), style: StrokeStyle(lineWidth: 14, lineCap: .round))

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

            // Score pill badge
            Text(scoreLabel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(scoreColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(scoreColor.opacity(0.15))
                .clipShape(Capsule())
        }
        .heroCard(color: Color(hex: "F0FAFA"))
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
                Text("The Big Picture")
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
                        .foregroundStyle(Color.black.opacity(0.06))
                    AxisValueLabel()
                        .foregroundStyle(Color.textSec)
                        .font(.system(size: 10))
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.textSec)
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
        .background(Color.cardSurface)
        .cornerRadius(8)
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

    private var trendBg: Color {
        switch insights.trendDirection {
        case "up":   return .cardDarkTeal
        case "down": return .cardDarkRed
        default:     return .cardDarkOrange
        }
    }

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "globe.americas.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.brand)
                    Text("Market Intel")
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
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textSec)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isExpanded)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                // 2×2 tile grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    if let size = insights.marketSize {
                        MarketInsightTile(icon: "chart.pie.fill", label: "Market Size", value: size, color: .brand, tileBackground: .cardDarkPurple)
                    }
                    if let rate = insights.growthRate {
                        MarketInsightTile(icon: "arrow.up.right.circle.fill", label: "Growth Rate", value: rate, color: .brandGreen, tileBackground: .cardDarkTeal)
                    }
                    if let competitors = insights.keyCompetitors, !competitors.isEmpty {
                        MarketInsightTile(icon: "person.3.fill", label: "Competitors", value: competitors.prefix(3).joined(separator: ", "), color: .brandOrange, tileBackground: .cardDarkOrange)
                    }
                    if let dir = insights.trendDirection {
                        MarketInsightTile(icon: "waveform.path.ecg", label: "Market Trend", value: dir.capitalized, color: trendColor, tileBackground: trendBg)
                    }
                }

                if let context = context, !context.isEmpty {
                    Text(context)
                        .font(.system(size: 13))
                        .foregroundColor(.textSec)
                        .lineSpacing(3)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.04))
                        .cornerRadius(10)
                }
            } else {
                // Collapsed summary row
                HStack(spacing: 16) {
                    if let size = insights.marketSize {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Market Size")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.textSec)
                            Text(size)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.textPri)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if let rate = insights.growthRate {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Growth")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.textSec)
                            Text(rate)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.textPri)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
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
    var tileBackground: Color? = nil

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
        .background(tileBackground ?? color.opacity(0.06))
        .cornerRadius(12)
    }
}

// MARK: - Quadrant Item Chart

struct QuadrantItemChart: View {
    let title: String
    let items: [SWOTItem]
    let color: Color
    let gradient: LinearGradient
    let iconName: String

    @State private var isExpanded = false

    private var sortedItems: [SWOTItem] {
        items.sorted { $0.score > $1.score }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Tappable header
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.textPri)
                        Text("\(items.count) item\(items.count == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundColor(.textSec)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textSec)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isExpanded)
                }
            }
            .buttonStyle(.plain)

            if sortedItems.isEmpty {
                Text("Nothing here — that's a good sign")
                    .font(.system(size: 14))
                    .foregroundColor(.textSec)
                    .italic()
                    .padding(.vertical, 4)
            } else {
                // Always show top item
                itemRow(sortedItems[0])

                if isExpanded {
                    ForEach(sortedItems.dropFirst()) { item in
                        itemRow(item)
                    }

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
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.top, 2)
                    }
                } else if sortedItems.count > 1 {
                    Text("+\(sortedItems.count - 1) more")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(color.opacity(0.7))
                }
            }
        }
        .cardStyle()
    }

    private func itemRow(_ item: SWOTItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Text(item.point)
                    .font(.system(size: 14))
                    .foregroundColor(.textPri)
                    .lineLimit(isExpanded ? nil : 2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(item.score)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(color.opacity(0.12))
                    .clipShape(Capsule())
            }

            if isExpanded, let detail = item.detail {
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundColor(.textSec)
                    .lineSpacing(3)
                    .padding(.top, 2)
            }
        }
    }
}

// MARK: - Recommendations

struct RecommendationsSection: View {
    let recommendations: [String]

    @State private var isExpanded = false
    private let previewCount = 2

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.brandAmber)
                    Text("What To Do Next")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPri)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textSec)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isExpanded)
                }
            }
            .buttonStyle(.plain)

            let visible = isExpanded ? recommendations : Array(recommendations.prefix(previewCount))
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(visible.enumerated()), id: \.offset) { index, rec in
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

            if !isExpanded && recommendations.count > previewCount {
                Text("+\(recommendations.count - previewCount) more")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.brand.opacity(0.7))
            }
        }
        .cardStyle()
    }
}

// MARK: - Quadrant Summary Grid

struct QuadrantSummaryGrid: View {
    let analysis: SWOTAnalysis

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            QuadrantMiniCard(
                letter: "S",
                title: "The Wins",
                count: analysis.resolvedStrengths.count,
                avgScore: analysis.avgStrengthScore,
                color: .brandGreen,
                background: .cardDarkTeal
            )
            QuadrantMiniCard(
                letter: "O",
                title: "Opportunities",
                count: analysis.resolvedOpportunities.count,
                avgScore: analysis.avgOpportunityScore,
                color: .brandBlue,
                background: .cardDarkBlue
            )
            QuadrantMiniCard(
                letter: "W",
                title: "Weaknesses",
                count: analysis.resolvedWeaknesses.count,
                avgScore: analysis.avgWeaknessScore,
                color: .brandRed,
                background: .cardDarkRed
            )
            QuadrantMiniCard(
                letter: "T",
                title: "Watch Out",
                count: analysis.resolvedThreats.count,
                avgScore: analysis.avgThreatScore,
                color: .brandOrange,
                background: .cardDarkOrange
            )
        }
    }
}

struct QuadrantMiniCard: View {
    let letter: String
    let title: String
    let count: Int
    let avgScore: Double
    let color: Color
    let background: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(letter)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(color)
                Spacer()
                Text("\(count)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textSec)
                Text("items")
                    .font(.system(size: 11))
                    .foregroundColor(.textSec.opacity(0.6))
            }
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textSec)
            // Score bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.08))
                        .frame(height: 4)
                    Capsule()
                        .fill(color.gradient)
                        .frame(width: max(4, geo.size.width * CGFloat(avgScore / 100)), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(16)
        .background(background)
        .cornerRadius(20)
    }
}

// MARK: - Game Plan Card

struct GamePlanCard: View {
    let analysis: SWOTAnalysis
    let actionItems: [PersistedActionItem]
    let onToggle: (UUID, Bool) async -> Void

    @State private var isExpanded = true
    private let collapsedCount = 3

    private var allItems: [SWOTItem] {
        analysis.resolvedStrengths + analysis.resolvedOpportunities +
        analysis.resolvedWeaknesses + analysis.resolvedThreats
    }

    private func score(for action: PersistedActionItem) -> Int {
        allItems.first(where: { $0.id == action.swotItemId })?.score ?? 0
    }

    private var sortedActions: [PersistedActionItem] {
        actionItems.sorted { score(for: $0) > score(for: $1) }
    }

    private var completedCount: Int { actionItems.filter(\.isCompleted).count }
    private var totalCount: Int { actionItems.count }
    private var progress: Double { totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text("⚡")
                        .font(.system(size: 16))
                    Text("Your Game Plan")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPri)
                    Spacer()
                    if totalCount > 0 {
                        Text("\(completedCount) / \(totalCount) done")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textSec)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.35), value: completedCount)
                    }
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textSec)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isExpanded)
                }
            }
            .buttonStyle(.plain)

            // Progress bar
            if totalCount > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.black.opacity(0.08)).frame(height: 4)
                        Capsule()
                            .fill(LinearGradient.brand)
                            .frame(width: max(0, geo.size.width * CGFloat(progress)), height: 4)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                    }
                }
                .frame(height: 4)
            }

            if actionItems.isEmpty {
                Text("Generate an analysis to get your action plan")
                    .font(.system(size: 13))
                    .foregroundColor(.textSec)
                    .italic()
            } else if completedCount == totalCount {
                Text("You're cooking — all actions checked off")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.brandGreen)
                    .padding(.vertical, 4)
            } else {
                let displayed = isExpanded ? sortedActions : Array(sortedActions.prefix(collapsedCount))
                VStack(spacing: 10) {
                    ForEach(displayed) { action in
                        ActionRow(action: action) {
                            Task { await onToggle(action.id, !action.isCompleted) }
                        }
                    }
                }
                if !isExpanded && sortedActions.count > collapsedCount {
                    Text("+\(sortedActions.count - collapsedCount) more")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.brand.opacity(0.7))
                }
            }
        }
        .padding(18)
        .background(Color.cardDarkBlue)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.07), lineWidth: 1.5)
        )
    }
}

private struct ActionRow: View {
    let action: PersistedActionItem
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onTap) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            action.isCompleted ? Color.brand : Color.black.opacity(0.2),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)
                        .background(
                            Circle().fill(action.isCompleted ? Color.brand : Color.clear)
                        )
                    if action.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlayfulButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(action.text)
                    .font(.system(size: 13))
                    .foregroundColor(action.isCompleted ? .textSec : .textPri)
                    .strikethrough(action.isCompleted, color: .textSec)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                if let estimate = action.timeEstimate {
                    Text(estimate)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.brand.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.brand.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(action.isCompleted ? 0.45 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: action.isCompleted)
        }
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
