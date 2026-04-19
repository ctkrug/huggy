import SwiftUI

struct HugTypeCard: View {
    let hugType: HugType
    let isSelected: Bool
    let isUnlocked: Bool
    let streakDays: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) { cardContent }
            .buttonStyle(ScaleButtonStyle())
            .disabled(!isUnlocked)
    }

    private var cardContent: some View {
        VStack(spacing: 6) {
            ZStack {
                HugCharacterView(hugType: hugType, isHugging: true, size: 50)
                    .saturation(isUnlocked ? 1.0 : 0.0)
                    .opacity(isUnlocked ? 1.0 : 0.5)

                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(Color(hex: "9B6B60"))
                }

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, design: .rounded))
                        .foregroundColor(Color(hex: "E8735A"))
                        .offset(x: 18, y: -18)
                }
            }

            Text(hugType.displayName)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(Color(hex: "3D1C12"))
                .lineLimit(1)

            if !isUnlocked {
                Text("7 days \u{1F525}")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(Color(hex: "9B6B60"))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isSelected ? Color(hex: "E8735A") : hugType.color.opacity(0.4),
                            lineWidth: isSelected ? 2 : 0.5
                        )
                )
        )
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
