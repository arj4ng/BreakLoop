// BreakLoop/ BreakLoop/ Shared/ Services/ AuthService.swift

// auth service
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

import Foundation
import FirebaseAuth


// MARK: ┏━ [10 FIREBASE] AuthUserSession
// MARK: ┗━ minimales session objekt für app flow routing

struct AuthUserSession: Hashable, Sendable {

    // firebase uid
    let userId: String

    // true wenn account noch guest anon ist
    let isAnonymous: Bool

    // optional email wenn provider email liefert
    let email: String?
}


// MARK: ┏━ [10 FIREBASE] AuthServiceProtocol
// MARK: ┗━ auth contract für login, signup, guest und account linking

protocol AuthServiceProtocol {

    // aktive uid wenn session da ist
    var currentUserId: String? { get }

    // signal ob user noch im guest mode läuft
    var isAnonymous: Bool { get }

    // liefert session snapshot für app routing
    func currentSession() -> AuthUserSession?

    // startet guest auth nur wenn keine session existiert
    func signInAnonymouslyIfNeeded() async throws -> AuthUserSession

    // email login für bestehenden account
    func signIn(email: String, password: String) async throws -> AuthUserSession

    // email signup für neuen account
    func signUp(email: String, password: String) async throws -> AuthUserSession

    // verbindet guest account mit email ohne uid wechsel
    func linkAnonymousUser(email: String, password: String) async throws -> AuthUserSession

    // beendet lokale auth session
    func signOut() throws
}


// MARK: ┏━ [10 FIREBASE] FirebaseAuthService
// MARK: ┗━ konkrete auth implementierung mit firebase auth sdk

final class FirebaseAuthService: AuthServiceProtocol {

    // zentrale firebase auth instanz
    private let auth: Auth

    init(auth: Auth = .auth()) {

        // auth instanz injizierbar für tests
        self.auth = auth
    }

    var currentUserId: String? {

        // uid direkt aus currentUser lesen
        auth.currentUser?.uid
    }

    var isAnonymous: Bool {

        // false wenn kein user oder normaler account
        auth.currentUser?.isAnonymous ?? false
    }

    func currentSession() -> AuthUserSession? {
        guard let user = auth.currentUser else { return nil }

        // map hält nur felder die app flow braucht
        return AuthUserSession(
            userId: user.uid,
            isAnonymous: user.isAnonymous,
            email: user.email
        )
    }

    func signInAnonymouslyIfNeeded() async throws -> AuthUserSession {
        if let session = currentSession() {

            // bestehende session wiederverwenden
            return session
        }

        // guest flow als default app entry
        let result = try await auth.signInAnonymously()
        return mapSession(from: result.user)
    }

    func signIn(email: String, password: String) async throws -> AuthUserSession {

        // klassischer email login
        let result = try await auth.signIn(withEmail: email, password: password)
        return mapSession(from: result.user)
    }

    func signUp(email: String, password: String) async throws -> AuthUserSession {

        // create account für neuen user
        let result = try await auth.createUser(withEmail: email, password: password)
        return mapSession(from: result.user)
    }

    func linkAnonymousUser(email: String, password: String) async throws -> AuthUserSession {
        guard let user = auth.currentUser else {
            throw AuthError.noCurrentUser
        }

        guard user.isAnonymous else {
            throw AuthError.currentUserNotAnonymous
        }

        // linking hält gleiche uid und behält firestore daten
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        let result = try await user.link(with: credential)

        return mapSession(from: result.user)
    }

    func signOut() throws {

        // firebase wirft wenn signout fehlschlägt
        try auth.signOut()
    }

    private func mapSession(from user: User) -> AuthUserSession {

        // einheitliches mapping für alle auth paths
        AuthUserSession(
            userId: user.uid,
            isAnonymous: user.isAnonymous,
            email: user.email
        )
    }
}


enum AuthError: LocalizedError {
    case noCurrentUser
    case currentUserNotAnonymous

    var errorDescription: String? {
        switch self {
        case .noCurrentUser:
            return "Kein aktiver User für Linking"
        case .currentUserNotAnonymous:
            return "Linking nur für anon User erlaubt"
        }
    }
}
