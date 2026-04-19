import Foundation
import SwiftUI
import FirebaseAuth
import AuthenticationServices
import CryptoKit

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var currentUser: UserModel?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var email = ""
    @Published var password = ""

    private var currentNonce: String?
    private var userListener: Any?

    init() {
        checkAuth()
    }

    func checkAuth() {
        if let user = Auth.auth().currentUser {
            isSignedIn = true
            listenToUser(uid: user.uid)
        }
    }

    // MARK: - Email Auth

    func signInWithEmail() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            isSignedIn = true
            listenToUser(uid: result.user.uid)
            NotificationService.shared.requestPermission()
            NotificationService.shared.saveFCMToken()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createAccountWithEmail() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let displayName = email.components(separatedBy: "@").first ?? "User"
            try await FirebaseService.shared.createUserDocument(uid: result.user.uid, displayName: displayName)
            isSignedIn = true
            listenToUser(uid: result.user.uid)
            NotificationService.shared.requestPermission()
            NotificationService.shared.saveFCMToken()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Apple Sign In

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Apple Sign In failed."
                return
            }

            isLoading = true
            let credential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: idTokenString,
                rawNonce: nonce
            )

            do {
                let authResult = try await Auth.auth().signIn(with: credential)
                let uid = authResult.user.uid

                // Check if user doc exists
                let existingUser = try await FirebaseService.shared.getUser(uid: uid)
                if existingUser == nil {
                    let name = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                    let displayName = name.isEmpty ? "User" : name
                    try await FirebaseService.shared.createUserDocument(uid: uid, displayName: displayName)
                }

                isSignedIn = true
                listenToUser(uid: uid)
                NotificationService.shared.requestPermission()
                NotificationService.shared.saveFCMToken()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    // MARK: - Sign Out

    func signOut() {
        try? Auth.auth().signOut()
        isSignedIn = false
        currentUser = nil
    }

    // MARK: - User Listener

    private func listenToUser(uid: String) {
        userListener = FirebaseService.shared.listenToUser(uid: uid) { [weak self] user in
            DispatchQueue.main.async {
                self?.currentUser = user
            }
        }
    }

    // MARK: - Nonce Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce.")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
