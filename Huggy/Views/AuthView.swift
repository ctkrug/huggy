import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var appeared = false

    var body: some View {
        ZStack {
            BackgroundGradient()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 60)

                    HugCharacterView(hugType: .heart, isHugging: true, size: 100)

                    Text("Welcome to Huggy")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "3D1C12"))

                    // Apple Sign In
                    SignInWithAppleButton(.signIn) { request in
                        let hashedNonce = authVM.prepareAppleSignIn()
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = hashedNonce
                    } onCompletion: { result in
                        Task {
                            await authVM.handleAppleSignIn(result: result)
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .cornerRadius(26)
                    .padding(.horizontal, 40)

                    // Divider
                    HStack {
                        Rectangle().fill(Color(hex: "F5C4B3")).frame(height: 1)
                        Text("or")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(Color(hex: "9B6B60"))
                        Rectangle().fill(Color(hex: "F5C4B3")).frame(height: 1)
                    }
                    .padding(.horizontal, 40)

                    // Email fields
                    VStack(spacing: 14) {
                        TextField("Email", text: $authVM.email)
                            .font(.system(.body, design: .rounded))
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(hex: "F5C4B3"), lineWidth: 0.5)
                                    )
                            )

                        SecureField("Password", text: $authVM.password)
                            .font(.system(.body, design: .rounded))
                            .textContentType(.password)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(hex: "F5C4B3"), lineWidth: 0.5)
                                    )
                            )
                    }
                    .padding(.horizontal, 40)

                    if let error = authVM.errorMessage {
                        Text(error)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.red)
                            .padding(.horizontal, 40)
                    }

                    // Buttons
                    VStack(spacing: 12) {
                        Button(action: { Task { await authVM.signInWithEmail() } }) {
                            Text("Sign in")
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 26)
                                        .fill(Color(hex: "E8735A"))
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())

                        Button(action: { Task { await authVM.createAccountWithEmail() } }) {
                            Text("Create account")
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "E8735A"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 26)
                                        .fill(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 26)
                                                .stroke(Color(hex: "E8735A"), lineWidth: 1.5)
                                        )
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 40)

                    if authVM.isLoading {
                        ProgressView()
                            .tint(Color(hex: "E8735A"))
                    }

                    Spacer().frame(height: 40)
                }
            }
        }
        .scaleEffect(appeared ? 1.0 : 0.85)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appeared = true
            }
        }
    }
}
