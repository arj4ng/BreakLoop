// BreakLoop/ BreakLoop/ App/ Auth/ RegisterView.swift

// register view
//
// Created by Arjang Khademi on 27.04.2026
/*
  ╔════════════════════════════════════════════════════════╗
  ║  █████╗ ██████╗      ██╗ ██╗  ██╗ ███╗   ██╗  ██████╗  ║
  ║ ██╔══██╗██╔══██╗     ██║ ██║  ██║ ████╗  ██║ ██╔════╝  ║
  ║ ███████║██████╔╝     ██║ ███████║ ██╔██╗ ██║ ██║  ███╗ ║
  ║ ██╔══██║██╔══██╗██   ██║ ╚════██║ ██║╚██╗██║ ██║   ██║ ║
  ║ ██║  ██║██║  ██║╚█████╔╝      ██║ ██║ ╚████║ ╚██████╔╝ ║
  ║ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚════╝       ╚═╝ ╚═╝  ╚═══╝  ╚═════╝  ║
  ╚═════════════════════════════════════════ [ DEV TAG ] ══╝
*/

import SwiftUI
import FirebaseAuth


// MARK: ┏━ [01 APP FLOW] RegisterView
// MARK: ┗━ separater register screen für account erstellung

struct RegisterView: View {

    // auth service führt signup oder guest linking aus
    let authService: AuthServiceProtocol

    // callback für root re-route nach erfolgreichem register
    let onRegistered: () -> Void

    // dismiss schließt modal nach erfolg oder cancel
    @Environment(\.dismiss) private var dismiss

    // form felder für account erstellung
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    // loading blockt doppelte submits
    @State private var isLoading: Bool = false

    // fehler text für validation und firebase errors
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()

                Circle()
                    .fill(Color("BrandAccentSoft").opacity(0.22))
                    .frame(width: 240, height: 240)
                    .blur(radius: 44)
                    .offset(x: 110, y: -260)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Create account", systemImage: "person.crop.circle.badge.plus")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(Color("TextPrimary"))

                            Text("Create your account to save your progress")
                                .font(.subheadline)
                                .foregroundStyle(Color("TextSecondary"))
                        }

                        VStack(spacing: 14) {
                            inputGroup {
                                inputField(title: "Name", text: $displayName, secure: false, emailField: false)
                                inputField(title: "Email", text: $email, secure: false)
                            }

                            inputGroup {
                                inputField(title: "Password", text: $password, secure: true)
                                inputField(title: "Confirm password", text: $confirmPassword, secure: true)
                            }
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(Color("Danger"))
                                .multilineTextAlignment(.leading)
                        }

                        Button {
                            Task { await register() }
                        } label: {
                            Label("Create account", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .foregroundStyle(Color("TextOnAccent"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color("ButtonPrimaryBackground"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .disabled(
                            isLoading ||
                            displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            email.isEmpty ||
                            password.isEmpty ||
                            confirmPassword.isEmpty
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                    .padding(.bottom, 28)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func inputField(title: String, text: Binding<String>, secure: Bool, emailField: Bool = true) -> some View {
        Group {
            if secure {
                SecureField(title, text: text)
                    .textInputAutocapitalization(.never)
            } else {
                TextField(title, text: text)
                    .textInputAutocapitalization(emailField ? .never : .words)
                    .autocorrectionDisabled(!emailField ? false : true)
                    .keyboardType(emailField ? .emailAddress : .default)
            }
        }
        .foregroundStyle(Color("TextPrimary"))
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color("InputBackground").opacity(0.85))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color("Border"), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private func inputGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 10, content: content)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color("SurfaceElevated").opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color("BorderStrong").opacity(0.7), lineWidth: 1)
                    )
            )
    }

    @MainActor
    private func register() async {

        // basic validation vor firebase call
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }

        guard !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter your name"
            return
        }

        isLoading = true
        errorMessage = nil

        do {

            // guest user wird gelinkt damit uid und daten gleich bleiben
            if authService.isAnonymous {
                _ = try await authService.linkAnonymousUser(email: email, password: password)
            } else {
                _ = try await authService.signUp(email: email, password: password)
            }

            // name direkt auf firebase user profil setzen
            try await updateCurrentUserDisplayName(displayName.trimmingCharacters(in: .whitespacesAndNewlines))

            // nach signup bleibt user eingeloggt und root routed weiter
            onRegistered()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func updateCurrentUserDisplayName(_ name: String) async throws {
        guard let user = Auth.auth().currentUser else { return }

        let request = user.createProfileChangeRequest()
        request.displayName = name

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            request.commitChanges { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

#Preview {
    RegisterView(authService: FirebaseAuthService(), onRegistered: {})
}
