import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var hugVM: HugViewModel

    @State private var showSendHug = false
    @State private var appeared = false

    var body: some View {
        TabView {
            homeTab
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            HugHistoryView()
                .tabItem {
                    Image(systemName: "heart.text.square.fill")
                    Text("History")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
        .tint(Color(hex: "E8735A"))
        .onAppear {
            if let coupleId = authVM.currentUser?.coupleId {
                hugVM.loadData(coupleId: coupleId)
            }
            if let partnerId = authVM.currentUser?.partnerId {
                Task { await hugVM.loadPartner(partnerId: partnerId) }
            }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appeared = true
            }
        }
        .onChange(of: hugVM.showReceiveView) { show in
            if show { showSendHug = false }
        }
        .fullScreenCover(isPresented: $hugVM.showReceiveView) {
            if let hug = hugVM.receivedHug {
                ReceiveHugView(hug: hug, partnerName: hugVM.partner?.displayName ?? "Partner")
            }
        }
    }

    private var homeTab: some View {
        ZStack {
            BackgroundGradient()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text("huggy")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "3D1C12"))
                        .padding(.top, 16)

                    // Partner avatar
                    VStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: "FFE4DC"))
                            .overlay(
                                Text(partnerInitials)
                                    .font(.system(.title, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "E8735A"))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: "F5C4B3"), lineWidth: 2)
                            )
                            .frame(width: 80, height: 80)

                        Text(hugVM.partner?.displayName ?? "Partner")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: "3D1C12"))

                        if let ago = hugVM.lastHugAgo {
                            Text("Last hugged \(ago)")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(Color(hex: "9B6B60"))
                        } else {
                            Text("Send your first hug!")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(Color(hex: "9B6B60"))
                        }
                    }

                    // Streak
                    if hugVM.streakDays > 0 {
                        StreakBadge(streak: hugVM.streakDays)
                    }

                    // Main buttons
                    VStack(spacing: 12) {
                        Button(action: { showSendHug = true }) {
                            Text("Send a hug \u{1F917}")
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

                        Button(action: { Task { await hugVM.requestHug() } }) {
                            Text("I need a hug \u{1F4AC}")
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
                    .padding(.horizontal, 20)

                    // Recent hugs
                    if !hugVM.recentHugs.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent hugs")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(Color(hex: "9B6B60"))
                                .padding(.horizontal, 20)

                            ForEach(hugVM.recentHugs) { hug in
                                hugRow(hug)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }

                    Spacer().frame(height: 20)
                }
            }
        }
        .fullScreenCover(isPresented: $showSendHug) {
            SendHugView()
        }
        .scaleEffect(appeared ? 1.0 : 0.85)
        .opacity(appeared ? 1 : 0)
    }

    private var partnerInitials: String {
        let name = hugVM.partner?.displayName ?? "?"
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
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

func timeAgo(_ date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: date, relativeTo: Date())
}
