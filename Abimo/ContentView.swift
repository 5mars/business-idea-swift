//
//  DesignSystem.swift (ContentView.swift)
//  Abimo
//
//  Brand: Teal/Coral primary, warm cream background, white cards
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
        default: (r, g, b) = (78, 205, 196)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }

    // Brand palette
    static let brand        = Color(hex: "4ECDC4")  // Teal
    static let brandLight   = Color(hex: "80E8E2")  // Mint
    static let brandPink    = Color(hex: "FF6B6B")  // Coral (recording)
    static let brandAmber   = Color(hex: "FFAE6B")  // Warm amber
    static let brandGreen   = Color(hex: "6DD88F")  // Soft green
    static let brandRed     = Color(hex: "FF8A80")  // Soft coral-red
    static let brandBlue    = Color(hex: "4DD0E1")  // Sky teal
    static let brandOrange  = Color(hex: "FFAE6B")  // Warm orange

    // Surfaces
    static let appBg               = Color(hex: "F5F2EE")  // Warm cream
    static let cardBg              = Color.white            // White card (alias)
    static let cardSurface         = Color.white            // White card
    static let cardSurfaceElevated = Color.white            // White elevated card
    static let textPri             = Color(hex: "1C1C1E")  // Dark charcoal
    static let textSec             = Color(hex: "8E8E93")  // Medium gray

    // Tinted light card surfaces
    static let cardDarkBlue   = Color(hex: "EBF8FA")  // Light teal tint
    static let cardDarkTeal   = Color(hex: "EDFAF3")  // Light green tint
    static let cardDarkPurple = Color(hex: "F0FAFA")  // Light teal-white
    static let cardDarkOrange = Color(hex: "FFF4EA")  // Light amber tint
    static let cardDarkRed    = Color(hex: "FFF0EE")  // Light coral tint

    // Accent colors
    static let accentBlue   = Color(hex: "4DD0E1")  // Sky teal — charts, data viz
    static let accentTeal   = Color(hex: "4ECDC4")  // Teal — positive indicators
    static let accentCoral  = Color(hex: "FF6B6B")  // Coral — warnings, threats
}

// MARK: - Brand Gradients

extension LinearGradient {
    static let brand = LinearGradient(
        colors: [.brand, .brandLight],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let record = LinearGradient(
        colors: [.brandPink, .brandAmber],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let swotStrength = LinearGradient(
        colors: [Color(hex: "6DD88F"), Color(hex: "4ECDC4")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let swotWeakness = LinearGradient(
        colors: [Color(hex: "FF8A80"), Color(hex: "FF6B6B")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let swotOpportunity = LinearGradient(
        colors: [Color(hex: "4DD0E1"), Color(hex: "4ECDC4")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let swotThreat = LinearGradient(
        colors: [Color(hex: "FFAE6B"), Color(hex: "FF8A80")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Card Style Modifiers

extension View {
    /// Standard card — pure white, fully flat
    func cardStyle(padding: CGFloat = 20) -> some View {
        self
            .padding(padding)
            .background(Color.white)
            .cornerRadius(24)
    }

    /// Tinted card — solid tint color, fully flat
    func tintedCard(color: Color, padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(color)
            .cornerRadius(24)
    }

    /// Hero card — solid tinted background, larger padding, fully flat
    func heroCard(color: Color = .cardDarkPurple, padding: CGFloat = 24) -> some View {
        self
            .padding(padding)
            .background(color)
            .cornerRadius(24)
    }
}

// MARK: - AppTextField

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default

    @FocusState private var isFocused: Bool

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .focused($isFocused)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .focused($isFocused)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(isFocused ? Color.white : Color(hex: "EDEBE8"))
        .cornerRadius(14)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .font(.system(size: 16))
        .foregroundColor(.textPri)
        .tint(Color.brand)
    }
}

// MARK: - Card Entrance Animation

struct CardEntranceModifier: ViewModifier {
    let delay: Double
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 22)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.78).delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func cardEntrance(delay: Double = 0) -> some View {
        modifier(CardEntranceModifier(delay: delay))
    }
}

// MARK: - PlayfulButtonStyle

struct PlayfulButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

// MARK: - GradientButton

struct GradientButton: View {
    let title: String
    var gradient: LinearGradient = .brand
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var cornerRadius: CGFloat = 20
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(.white).scaleEffect(0.9)
                } else {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(gradient.opacity(isDisabled ? 0.45 : 1.0))
            .cornerRadius(cornerRadius)
        }
        .buttonStyle(PlayfulButtonStyle())
        .disabled(isDisabled || isLoading)
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isDisabled)
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
