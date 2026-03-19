//
//  MilestoneBannerView.swift
//  Abimo
//

import SwiftUI

struct MilestoneBannerView: View {
    let count: Int
    @State private var appeared = false

    private var message: String {
        switch count {
        case 3: return "You're on a roll! \u{1F525}"
        case 5: return "Halfway hero! \u{1F4AA}"
        case 7: return "Almost there! \u{26A1}"
        default: return "Keep going! \u{1F389}"
        }
    }

    var body: some View {
        VStack {
            HStack {
                Text(message)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.brand)
                    .cornerRadius(24)
                    .shadow(color: Color.brand.opacity(0.4), radius: 8, y: 4)
            }
            .padding(.top, 60)
            Spacer()
        }
        .offset(y: appeared ? 0 : -120)
        .onAppear {
            AnimationPolicy.animate(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}
