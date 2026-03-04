//
//  RootView.swift
//  note-ai-app-test
//

import SwiftUI

struct RootView: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if authViewModel.isLoading {
                SplashView()
            } else if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

// MARK: - Splash / Loading

struct SplashView: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.brand.opacity(0.12))
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulse ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulse)

                    Circle()
                        .fill(LinearGradient.brand)
                        .frame(width: 84, height: 84)
                        .shadow(color: Color.brand.opacity(0.4), radius: 20, x: 0, y: 8)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("Voice SWOT")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.textPri)
            }
        }
        .onAppear { pulse = true }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        TabView {
            NavigationStack {
                NotesListView()
            }
            .tabItem {
                Label("Notes", systemImage: "note.text")
            }

            NavigationStack {
                RecordingView()
            }
            .tabItem {
                Label("Record", systemImage: "mic.fill")
            }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(.brand)
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 20)

                        // Avatar
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.brand)
                                    .frame(width: 88, height: 88)
                                    .shadow(color: Color.brand.opacity(0.35), radius: 16, x: 0, y: 6)

                                Image(systemName: "person.fill")
                                    .font(.system(size: 34, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            if let email = authViewModel.currentUser?.email {
                                Text(email)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.textSec)
                            }
                        }

                        // Account card
                        VStack(spacing: 0) {
                            HStack {
                                Text("Account")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.textSec)
                                    .textCase(.uppercase)
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                            .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                if let email = authViewModel.currentUser?.email {
                                    HStack {
                                        Image(systemName: "envelope.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.brand)
                                            .frame(width: 28)

                                        Text("Email")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.textPri)

                                        Spacer()

                                        Text(email)
                                            .font(.system(size: 14))
                                            .foregroundColor(.textSec)
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }
                            }
                            .background(Color.cardBg)
                            .cornerRadius(16)
                            .shadow(color: Color.brand.opacity(0.07), radius: 12, x: 0, y: 4)
                        }
                        .padding(.horizontal, 16)

                        // Sign out card
                        VStack(spacing: 0) {
                            HStack {
                                Text("Actions")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.textSec)
                                    .textCase(.uppercase)
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                            .padding(.bottom, 8)

                            Button {
                                showSignOutAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.brandRed)
                                        .frame(width: 28)

                                    Text("Sign Out")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.brandRed)

                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                            .disabled(authViewModel.isLoading)
                            .background(Color.cardBg)
                            .cornerRadius(16)
                            .shadow(color: Color.brand.opacity(0.07), radius: 12, x: 0, y: 4)
                        }
                        .padding(.horizontal, 16)

                        Spacer()
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbarBackground(Color.appBg, for: .navigationBar)
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Sign Out", role: .destructive) {
                Task { await authViewModel.signOut() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

#Preview {
    RootView()
}
