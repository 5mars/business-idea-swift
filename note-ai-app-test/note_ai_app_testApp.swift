//
//  note_ai_app_testApp.swift
//  note-ai-app-test
//
//  Created by Jeremy Cinq-Mars on 2026-03-03.
//

import SwiftUI
import Supabase

@main
struct note_ai_app_testApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .onOpenURL { url in
                    Task {
                        try? await SupabaseService.shared.client.auth.handle(url)
                    }
                }
        }
    }
}
