// BreakLoop/ BreakLoop/ App/ Auth/ AuthView.swift

// auth view
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


enum AuthEntryIntent {
    case signIn
    case register
    case guest
}


// MARK: ┏━ [01 APP FLOW] AuthView
// MARK: ┗━ minimaler auth screen für login plus register navigation

struct AuthView: View {

    // auth calls laufen über service protocol
    let authService: AuthServiceProtocol

    // callback informiert root dass auth state sich geändert hat
    let onAuthenticated: () -> Void

    // intent erlaubt onboarding gesteuerten einstieg
    let initialIntent: AuthEntryIntent

    // true wenn auth aus onboarding geöffnet wurde
    let canGoBackToOnboarding: Bool

    // optionaler callback zurück zu onboarding
    let onBackToOnboarding: (() -> Void)?

    // migration repo prüft und migriert guest daten falls nötig
    private let migrationRepository = FirestoreTrackingRepository()

    // form felder für email auth
    @State private var email: String = ""
    @State private var password: String = ""

    // register sheet wird über onboarding intent geöffnet
    @State private var showsRegisterView: Bool = false

    // loading blockt doppelte requests
    @State private var isLoading: Bool = false

    // fehler text für schnelle debug sicht im dev flow
    @State private var errorMessage: String?

    // prompt wenn guest auf bestehendes konto sign in will
    @State private var showsGuestDataDecisionPrompt: Bool = false

    // pending creds nach prompt confirmation
    @State private var pendingSignInEmail: String = ""
    @State private var pendingSignInPassword: String = ""

    // schützt vor wiederholtem auto trigger bei rerender
    @State private var didApplyInitialIntent: Bool = false

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            Circle()
                .fill(Color("BrandAccentSoft").opacity(0.28))
                .frame(width: 260, height: 260)
                .blur(radius: 40)
                .offset(x: 120, y: -280)

            Circle()
                .fill(Color("BrandAccent").opacity(0.18))
                .frame(width: 220, height: 220)
                .blur(radius: 50)
                .offset(x: -140, y: -120)

            VStack(spacing: 0) {
                ZStack {
                    HStack(spacing: 8) {
                        if canGoBackToOnboarding {
                            Button {
                                onBackToOnboarding?()
                            } label: {
                                Label("Back", systemImage: "chevron.left")
                                    .font(.footnote.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color("TextSecondary"))
                            .background(
                                Capsule()
                                    .fill(Color("Surface"))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color("Border"), lineWidth: 1)
                                    )
                            )
                        }

                        Spacer()
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color("BrandAccentStrong"))

                        Text("BreakLoop")
                            .font(.title2.bold())
                            .foregroundStyle(Color("TextPrimary"))
                    }
                }
                .padding(.top, 6)
                .frame(maxWidth: .infinity, alignment: .center)

                Spacer()

                // login card bleibt vertikal mittig
                VStack(spacing: 22) {
                    VStack(spacing: 10) {

                        Text("Welcome back")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color("TextPrimary"))

                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundStyle(Color("TextSecondary"))
                    }

                    VStack(spacing: 10) {
                        inputField(
                            title: "Email",
                            text: $email,
                            secure: false
                        )

                        inputField(
                            title: "Password",
                            text: $password,
                            secure: true
                        )
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Color("Danger"))
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 10) {
                        Button {
                            Task { await handlePrimaryAuthAction() }
                        } label: {
                            Label("Sign in", systemImage: "arrow.right.circle.fill")
                                .font(.headline)
                                .foregroundStyle(Color("TextOnAccent"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .tint(Color("ButtonPrimaryBackground"))
                        .buttonStyle(.borderedProminent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 28)
                .background {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .stroke(Color("BorderStrong").opacity(0.7), lineWidth: 1)
                        }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .safeAreaPadding(.top, 8)
        }
        .alert("Existing account found", isPresented: $showsGuestDataDecisionPrompt) {
            Button("Cancel", role: .cancel) {}
            Button("Continue") {
                Task { await completeSignInWithGuestPolicy() }
            }
        } message: {
            Text("Guest data will be replaced by existing account data. If the existing account is empty, your guest data will be migrated.")
        }
        .sheet(isPresented: $showsRegisterView) {
            RegisterView(authService: authService, onRegistered: {
                onAuthenticated()
            }, onClose: nil)
        }
        .task {
            await applyInitialIntentIfNeeded()
        }
    }

    @ViewBuilder
    private func inputField(title: String, text: Binding<String>, secure: Bool) -> some View {
        Group {
            if secure {
                SecureField(title, text: text)
                    .textInputAutocapitalization(.never)
            } else {
                TextField(title, text: text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
            }
        }
        .foregroundStyle(Color("TextPrimary"))
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color("InputBackground").opacity(0.82))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color("Border"), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @MainActor
    private func handlePrimaryAuthAction() async {
        guard !email.isEmpty, !password.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {

            // guest sign in immer erst mit daten policy bestätigen
            if authService.isAnonymous {
                pendingSignInEmail = email
                pendingSignInPassword = password
                showsGuestDataDecisionPrompt = true
                isLoading = false
                return
            }

            _ = try await authService.signIn(email: email, password: password)

            // root bekommt signal und routed neu
            onAuthenticated()
        } catch {

            // rohe firebase meldung reicht erstmal im bootcamp flow
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    private func completeSignInWithGuestPolicy() async {
        guard !pendingSignInEmail.isEmpty, !pendingSignInPassword.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let guestUserId = authService.currentUserId

            // guest snapshot vor sign in sichern
            let guestSnapshot: FirestoreUserDataSnapshot?
            if let guestUserId, authService.isAnonymous {
                guestSnapshot = try await migrationRepository.exportUserDataSnapshot(userId: guestUserId, scope: .guest)
            } else {
                guestSnapshot = nil
            }

            let targetSession = try await authService.signIn(email: pendingSignInEmail, password: pendingSignInPassword)

            // nur migrieren wenn target account wirklich leer ist
            if let guestSnapshot, guestSnapshot.hasAnyData {
                let isTargetEmpty = try await migrationRepository.isAccountDataEmpty(userId: targetSession.userId)
                if isTargetEmpty {
                    try await migrationRepository.importUserDataSnapshot(
                        guestSnapshot,
                        targetUserId: targetSession.userId,
                        targetScope: .registered
                    )
                }
            }

            pendingSignInEmail = ""
            pendingSignInPassword = ""
            onAuthenticated()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    private func continueAsGuest() async {
        isLoading = true
        errorMessage = nil

        do {

            // guest flow erstellt session wenn noch keine da ist
            _ = try await authService.signInAnonymouslyIfNeeded()
            onAuthenticated()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    private func applyInitialIntentIfNeeded() async {
        guard !didApplyInitialIntent else { return }
        didApplyInitialIntent = true

        switch initialIntent {
        case .signIn:
            return
        case .register:
            showsRegisterView = true
        case .guest:
            await continueAsGuest()
        }
    }
}

#Preview {
    AuthView(
        authService: FirebaseAuthService(),
        onAuthenticated: {},
        initialIntent: .signIn,
        canGoBackToOnboarding: true,
        onBackToOnboarding: {}
    )
}
