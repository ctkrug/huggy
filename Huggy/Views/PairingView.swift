import SwiftUI

struct PairingView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var hugVM: HugViewModel
    @State private var appeared = false
    @State private var showShareSheet = false
    @State private var isPulsing = false

    private var isWaiting: Bool {
        hugVM.inviteLink != nil
    }

    var body: some View {
        ZStack {
            BackgroundGradient()

            VStack(spacing: 28) {
                Spacer()

                HugCharacterView(hugType: .heart, isHugging: false, size: 160)
                    .scaleEffect(isPulsing ? 1.05 : 1.0)

                Text("Find your person")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "3D1C12"))

                if isWaiting {
                    waitingView
                } else {
                    optionsView
                }

                Spacer()
            }
            .padding(.horizontal, 30)
        }
        .scaleEffect(appeared ? 1.0 : 0.85)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appeared = true
            }
        }
    }

    private var optionsView: some View {
        VStack(spacing: 16) {
            // Option A: Invite partner
            Button(action: {
                Task {
                    await hugVM.createInvite()
                    showShareSheet = true
                }
            }) {
                cardLabel(title: "Invite my partner \u{1F48C}", subtitle: "Send a link to connect")
            }
            .buttonStyle(ScaleButtonStyle())
            .sheet(isPresented: $showShareSheet) {
                if let link = hugVM.inviteLink {
                    ShareSheet(items: ["I want to hug you \u{1F917} Join me on Huggy: \(link.absoluteString)"])
                }
            }

            // Option B: Waiting for link
            cardView(title: "I have an invite \u{1F517}", subtitle: "Ask your partner to send you the Huggy invite link, then tap it to connect automatically.")
        }
    }

    private var waitingView: some View {
        VStack(spacing: 16) {
            Text("Waiting for your partner...")
                .font(.system(.body, design: .rounded))
                .foregroundColor(Color(hex: "9B6B60"))
                .scaleEffect(isPulsing ? 1.03 : 1.0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }

            if let link = hugVM.inviteLink {
                Button(action: { showShareSheet = true }) {
                    Text("Share invite again")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "E8735A"))
                }
                .sheet(isPresented: $showShareSheet) {
                    ShareSheet(items: ["I want to hug you \u{1F917} Join me on Huggy: \(link.absoluteString)"])
                }
            }
        }
    }

    private func cardLabel(title: String, subtitle: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "3D1C12"))
            Text(subtitle)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(Color(hex: "9B6B60"))
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(hex: "F5C4B3"), lineWidth: 0.5)
                )
        )
    }

    private func cardView(title: String, subtitle: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "3D1C12"))
            Text(subtitle)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(Color(hex: "9B6B60"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(hex: "F5C4B3"), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
