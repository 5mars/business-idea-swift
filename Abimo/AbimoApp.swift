//
//  AbimoApp.swift
//  Abimo
//
//  Created by Jeremy Cinq-Mars on 2026-03-03.
//

import SwiftUI
import Supabase

@main
struct AbimoApp: App {
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
