//
//  SignUpView.swift
//  note-ai-app-test
//
//  Created by Claude on 2026-03-03.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Create Account")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding(.top, 40)

                Spacer()

                // Sign Up Form
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)

                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    if !password.isEmpty && password != confirmPassword {
                        Text("Passwords do not match")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Button {
                        Task {
                            await authViewModel.signUp(email: email, password: password)
                            if authViewModel.isAuthenticated {
                                dismiss()
                            }
                        }
                    } label: {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty || password != confirmPassword)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(authViewModel.isLoading)
                }
            }
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthViewModel())
}
