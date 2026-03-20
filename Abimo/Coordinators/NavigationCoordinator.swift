//
//  NavigationCoordinator.swift
//  Abimo
//

import SwiftUI
import Combine

enum AppTab: Int {
    case notes = 0
    case record = 1
    case actions = 2
    case profile = 3
}

@MainActor
final class NavigationCoordinator: ObservableObject {
    @Published var selectedTab: AppTab = .notes
    @Published var pendingNote: VoiceNote? = nil

    func navigateToNote(_ note: VoiceNote) {
        selectedTab = .notes
        pendingNote = note
    }
}
