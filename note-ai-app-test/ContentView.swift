//
//  DesignSystem.swift (ContentView.swift)
//  note-ai-app-test
//
//  Brand: Indigo/Violet primary, soft lavender background, white cards
//

import SwiftUI

// MARK: - Brand Colors

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3:  (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (99, 102, 241)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }

    // Brand palette
    static let brand        = Color(hex: "6366F1")  // Indigo
    static let brandLight   = Color(hex: "A78BFA")  // Violet
    static let brandPink    = Color(hex: "EC4899")  // Pink (recording)
    static let brandAmber   = Color(hex: "F59E0B")  // Amber
    static let brandGreen   = Color(hex: "10B981")  // Emerald
    static let brandRed     = Color(hex: "F43F5E")  // Rose
    static let brandBlue    = Color(hex: "3B82F6")  // Blue
    static let brandOrange  = Color(hex: "F97316")  // Orange

    // Surfaces
    static let appBg        = Color(hex: "F5F3FF")  // Soft lavender background
    static let cardBg       = Color.white
    static let textPri      = Color(hex: "1E1B4B")  // Deep navy
    static let textSec      = Color(hex: "6B7280")  // Gray
}

// MARK: - Brand Gradients

extension LinearGradient {
    static let brand = LinearGradient(
        colors: [.brand, .brandLight],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let record = LinearGradient(
        colors: [.brandPink, .brandOrange],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let swotStrength = LinearGradient(
        colors: [Color(hex: "10B981"), Color(hex: "0D9488")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let swotWeakness = LinearGradient(
        colors: [Color(hex: "F43F5E"), Color(hex: "EC4899")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let swotOpportunity = LinearGradient(
        colors: [Color(hex: "3B82F6"), Color(hex: "6366F1")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let swotThreat = LinearGradient(
        colors: [Color(hex: "F97316"), Color(hex: "F59E0B")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Card Style

extension View {
    func cardStyle(padding: CGFloat = 20) -> some View {
        self
            .padding(padding)
            .background(Color.cardBg)
            .cornerRadius(20)
            .shadow(color: Color.brand.opacity(0.08), radius: 16, x: 0, y: 6)
    }
}

// MARK: - AppTextField

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.brand.opacity(0.06))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    text.isEmpty ? Color(hex: "DDD6FE") : Color.brand.opacity(0.4),
                    lineWidth: 1.5
                )
        )
        .font(.system(size: 16))
        .tint(Color.brand)
    }
}

// MARK: - GradientButton

struct GradientButton: View {
    let title: String
    var gradient: LinearGradient = .brand
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(.white).scaleEffect(0.9)
                } else {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(gradient.opacity(isDisabled ? 0.4 : 1.0))
            .cornerRadius(16)
            .shadow(
                color: isDisabled ? .clear : Color.brand.opacity(0.35),
                radius: 10, x: 0, y: 5
            )
        }
        .disabled(isDisabled || isLoading)
        .animation(.easeInOut(duration: 0.15), value: isDisabled)
    }
}

// MARK: - Pulse Ring (recording animation)

struct PulseRing: View {
    let color: Color
    var delay: Double = 0
    @State private var animating = false

    var body: some View {
        Circle()
            .stroke(color, lineWidth: 2)
            .scaleEffect(animating ? 2.4 : 1.0)
            .opacity(animating ? 0 : 0.55)
            .animation(
                .easeOut(duration: 1.6)
                .repeatForever(autoreverses: false)
                .delay(delay),
                value: animating
            )
            .onAppear { animating = true }
    }
}

// MARK: - Waveform Bars (audio level visualization)

struct WaveformBarsView: View {
    let level: Float
    private let barCount = 28

    private func height(for index: Int) -> CGFloat {
        let center = Double(barCount - 1) / 2.0
        let dist = abs(Double(index) - center) / center
        let envelope = 1.0 - pow(dist, 1.5) * 0.65
        let base: CGFloat = 4
        let maxExtra: CGFloat = 52
        return base + maxExtra * CGFloat(level) * CGFloat(envelope)
    }

    var body: some View {
        HStack(spacing: 3.5) {
            ForEach(0..<barCount, id: \.self) { i in
                Capsule()
                    .fill(LinearGradient.record)
                    .frame(width: 3.5, height: height(for: i))
            }
        }
        .frame(height: 64)
        .animation(.spring(response: 0.12, dampingFraction: 0.6), value: level)
    }
}
