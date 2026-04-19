import SwiftUI

struct OnboardingView: View {
    @Binding var showAuth: Bool

    @State private var appeared = false

    var body: some View {
        ZStack {
            BackgroundGradient()

            VStack(spacing: 30) {
                Spacer()

                HugCharacterView(hugType: .heart, isHugging: false, size: 180)
                    .scaleEffect(appeared ? 1.0 : 0.85)
                    .opacity(appeared ? 1 : 0)

                VStack(spacing: 8) {
                    Text("Huggy")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "3D1C12"))

                    Text("for the two of you \u{1F495}")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(Color(hex: "9B6B60"))
                }
                .opacity(appeared ? 1 : 0)

                Spacer()

                Button(action: { showAuth = true }) {
                    Text("Get started")
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
                .padding(.horizontal, 40)
                .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appeared = true
            }
        }
    }
}

// MARK: - Shared Background

struct BackgroundGradient: View {
    var body: some View {
        LinearGradient(
            colors: [Color(hex: "FFF0EB"), Color(hex: "FFE4DC")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
