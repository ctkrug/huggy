import SwiftUI

struct ReceiveHugView: View {
    let hug: HugModel
    let partnerName: String

    @EnvironmentObject var hugVM: HugViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var characterScale: CGFloat = 0.3
    @State private var showConfetti = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            BackgroundGradient()

            if showConfetti {
                ConfettiView()
            }

            VStack(spacing: 24) {
                Spacer()

                HugCharacterView(hugType: hug.hugTypeEnum, isHugging: true, size: 200)
                    .scaleEffect(characterScale)
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
                            characterScale = 1.1
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                characterScale = 1.0
                            }
                        }
                    }

                Text("\(partnerName) sent you a \(hug.hugTypeEnum.displayName)! \u{1F389}")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "3D1C12"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)

                if let note = hug.note, !note.isEmpty {
                    Text(note)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(Color(hex: "3D1C12"))
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(hex: "F5C4B3"), lineWidth: 0.5)
                                )
                        )
                        .padding(.horizontal, 40)
                }

                Spacer()

                VStack(spacing: 14) {
                    Button(action: hugBack) {
                        Text("Hug back \u{1F495}")
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

                    Button(action: { dismiss() }) {
                        Text("Close")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(Color(hex: "9B6B60"))
                    }
                }
                .padding(.horizontal, 40)

                Spacer().frame(height: 40)
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            showConfetti = true
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appeared = true
            }
            // Haptic
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }
    }

    private func hugBack() {
        Task {
            await hugVM.sendHug(hugType: .heart, note: nil)
            dismiss()
        }
    }
}
