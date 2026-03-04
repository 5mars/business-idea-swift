//
//  LoginView.swift
//  note-ai-app-test
//
//  Created by Claude on 2026-03-03.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                // App Icon/Logo
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("Voice SWOT")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Record ideas, analyze instantly")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                // Login Form
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)

                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task {
                            await authViewModel.signIn(email: email, password: password)
                        }
                    } label: {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty)

                    Button {
                        showSignUp = true
                    } label: {
                        Text("Don't have an account? Sign Up")
                            .font(.subheadline)
                    }
                    .disabled(authViewModel.isLoading)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .sheet(isPresented: $showSignUp) {
                SignUpView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
