//
//  LoadingView.swift
//  Abimo
//
//  Created by Jeremy Cinq-Mars on 2026-03-16.
//

import SwiftUI

struct LoadingView: View {
    var text: String = "abimo"
    var rotatingMessages: [String] = []
    var subtitle: String? = nil

    @State private var appeared = false
    @State private var spinning = false
    @State private var messageIndex = 0

    private var displayText: String {
        if !rotatingMessages.isEmpty {
            return rotatingMessages[messageIndex % rotatingMessages.count]
        }
        return text
    }

    var body: some View {
        VStack(spacing: 24) {
            // Spinner above mascot
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 32, height: 32)
                .rotationEffect(.degrees(spinning ? 360 : 0))
                .animation(.linear(duration: 0.8).repeatForever(autoreverses: false), value: spinning)

            Image("MascotNeutral")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)

            VStack(spacing: 8) {
                Text(displayText)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .id(messageIndex)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.92)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.brand.ignoresSafeArea())
        .onAppear {
            spinning = true
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
            if !rotatingMessages.isEmpty {
                Timer.scheduledTimer(withTimeInterval: 2.8, repeats: true) { _ in
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                        messageIndex += 1
                    }
                }
            }
        }
    }
}


#Preview {
    LoadingView()
}

#Preview("Rotating") {
    LoadingView(
        rotatingMessages: ["Cooking up insights...", "Turning up the heat...", "Taste-testing your idea..."],
        subtitle: "This might take 15–30 seconds"
    )
}
