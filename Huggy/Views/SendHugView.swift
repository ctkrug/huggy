import SwiftUI

struct SendHugView: View {
    @EnvironmentObject var hugVM: HugViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: HugType?
    @State private var note: String = ""
    @State private var appeared = false
    @State private var isSending = false

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ZStack {
            BackgroundGradient()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "9B6B60"))
                            .padding(10)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 20) {
                        Text("Send a hug \u{1F495}")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "3D1C12"))

                        // Character preview
                        HugCharacterView(
                            hugType: selectedType ?? .heart,
                            isHugging: true,
                            size: 120
                        )

                        // Hug type grid
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(HugType.allCases) { type in
                                let unlocked = hugVM.isHugTypeUnlocked(type)
                                HugTypeCard(
                                    hugType: type,
                                    isSelected: selectedType == type,
                                    isUnlocked: unlocked,
                                    streakDays: hugVM.streakDays
                                ) {
                                    if unlocked {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedType = type
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Note field
                        TextField("Add a little note... (optional)", text: $note)
                            .font(.system(.body, design: .rounded))
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(hex: "F5C4B3"), lineWidth: 0.5)
                                    )
                            )
                            .padding(.horizontal, 20)
                            .onChange(of: note) { newValue in
                                if newValue.count > 60 {
                                    note = String(newValue.prefix(60))
                                }
                            }

                        // Send button
                        Button(action: sendHug) {
                            if isSending {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            } else {
                                Text("Send hug \u{1F917}")
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 26)
                                .fill(selectedType != nil ? Color(hex: "E8735A") : Color.gray.opacity(0.4))
                        )
                        .cornerRadius(26)
                        .disabled(selectedType == nil || isSending)
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 20)

                        Spacer().frame(height: 30)
                    }
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

    private func sendHug() {
        guard let type = selectedType else { return }
        isSending = true
        Task {
            await hugVM.sendHug(hugType: type, note: note.isEmpty ? nil : note)
            isSending = false
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                dismiss()
            }
        }
    }
}
