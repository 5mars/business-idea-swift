//
//  AuthViewModel.swift
//  note-ai-app-test
//
//  Created by Claude on 2026-03-03.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = SupabaseService.shared

    init() {
        Task {
            await checkAuthStatus()
        }
    }

    func checkAuthStatus() async {
        isLoading = true
        defer { isLoading = false }

        do {
            currentUser = try await supabase.getCurrentUser()
            isAuthenticated = currentUser != nil
        } catch {
            print("Auth check error: \(error.localizedDescription)")
            isAuthenticated = false
        }
    }

    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            currentUser = try await supabase.signUp(email: email, password: password)
            isAuthenticated = true
        } catch {
            errorMessage = "Sign up failed: \(error.localizedDescription)"
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            currentUser = try await supabase.signIn(email: email, password: password)
            isAuthenticated = true
        } catch {
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
    }

    func signOut() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await supabase.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
        }
    }
}
