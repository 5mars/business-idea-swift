//
//  NavigationCoordinator.swift
//  Abimo
//

import SwiftUI
import Combine

enum AppTab: Int, CaseIterable {
    case ideas = 0
    case record = 1
    case actions = 2
    case profile = 3
}

extension AppTab {
    var iconName: String {
        switch self {
        case .ideas:   return "lightbulb"
        case .record:  return "mic"
        case .actions: return "bolt"
        case .profile: return "person"
        }
    }

    var selectedIconName: String {
        switch self {
        case .ideas:   return "lightbulb.fill"
        case .record:  return "mic.fill"
        case .actions: return "bolt.fill"
        case .profile: return "person.fill"
        }
    }
}

@MainActor
final class NavigationCoordinator: ObservableObject {
    @Published var selectedTab: AppTab = .ideas
    @Published var pendingNote: VoiceNote? = nil
    @Published var pendingPlanGeneration: Bool = false

    func navigateToNote(_ note: VoiceNote) {
        selectedTab = .ideas
        pendingNote = note
    }
}
