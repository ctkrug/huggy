import SwiftUI

struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 4) {
            Text("\u{1F525}")
                .font(.system(.subheadline, design: .rounded))
            Text("\(streak) day streak")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(hex: "FF6B6B"))
        )
    }
}
