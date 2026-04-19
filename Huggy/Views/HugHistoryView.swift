import SwiftUI

struct HugHistoryView: View {
    @EnvironmentObject var hugVM: HugViewModel

    var body: some View {
        ZStack {
            BackgroundGradient()

            ScrollView {
                VStack(spacing: 16) {
                    Text("Our hugs \u{1F495}")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "3D1C12"))
                        .padding(.top, 16)

                    // 7-day streak row
                    streakRow

                    // Hug list by day
                    if hugVM.hugsByDay.isEmpty {
                        VStack(spacing: 12) {
                            HugCharacterView(hugType: .heart, isHugging: false, size: 80)
                            Text("No hugs yet!")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(Color(hex: "9B6B60"))
                        }
                        .padding(.top, 40)
                    } else {
                        ForEach(hugVM.hugsByDay, id: \.0) { day, hugs in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(day)
                                    .font(.system(.caption, design: .rounded))
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(hex: "9B6B60"))
                                    .padding(.horizontal, 20)

                                ForEach(hugs) { hug in
                                    hugRow(hug)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    }

                    Spacer().frame(height: 20)
                }
            }
        }
    }

    private var streakRow: some View {
        HStack(spacing: 8) {
            let dots = hugVM.streakDots(days: 7)
            ForEach(0..<7, id: \.self) { index in
                Circle()
                    .fill(dots[index] ? Color(hex: "FF6B6B") : Color(hex: "F5C4B3").opacity(0.4))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "F5C4B3"), lineWidth: dots[index] ? 0 : 1)
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "F5C4B3"), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 20)
    }

    private func hugRow(_ hug: HugModel) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(hug.hugTypeEnum.color)
                .frame(width: 10, height: 10)

            Text("\(hugVM.senderName(for: hug)) sent a \(hug.hugTypeEnum.displayName)")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(Color(hex: "3D1C12"))

            Spacer()

            Text(timeAgo(hug.sentDate))
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(Color(hex: "9B6B60"))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "F5C4B3"), lineWidth: 0.5)
                )
        )
    }
}
