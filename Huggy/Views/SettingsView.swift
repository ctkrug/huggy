import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var hugVM: HugViewModel

    @State private var showUnpairAlert = false
    @State private var showSignOutAlert = false

    var body: some View {
        ZStack {
            BackgroundGradient()

            ScrollView {
                VStack(spacing: 20) {
                    Text("Settings")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "3D1C12"))
                        .padding(.top, 16)

                    // Partner info
                    if let partner = hugVM.partner {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: "FFE4DC"))
                                .overlay(
                                    Text(initials(partner.displayName))
                                        .font(.system(.title3, design: .rounded))
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(hex: "E8735A"))
                                )
                                .frame(width: 60, height: 60)

                            Text("Paired with \(partner.displayName)")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(Color(hex: "3D1C12"))

                            if hugVM.totalHugs > 0 {
                                Text("\(hugVM.totalHugs) hugs shared")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(Color(hex: "9B6B60"))
                            }
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
                        .padding(.horizontal, 20)
                    }

                    // Notifications
                    Button(action: openNotificationSettings) {
                        settingsRow(icon: "bell.fill", title: "Notifications", subtitle: "Manage in system settings")
                    }
                    .padding(.horizontal, 20)

                    // Unpair
                    Button(action: { showUnpairAlert = true }) {
                        settingsRow(icon: "person.crop.circle.badge.minus", title: "Unpair from partner", subtitle: "This will remove your connection", destructive: true)
                    }
                    .padding(.horizontal, 20)
                    .alert("Unpair from partner?", isPresented: $showUnpairAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Unpair", role: .destructive) {
                            Task { await hugVM.unpair() }
                        }
                    } message: {
                        Text("This will remove your connection. You can always pair again later.")
                    }

                    // Sign out
                    Button(action: { showSignOutAlert = true }) {
                        settingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign out", subtitle: nil)
                    }
                    .padding(.horizontal, 20)
                    .alert("Sign out?", isPresented: $showSignOutAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Sign out", role: .destructive) {
                            authVM.signOut()
                        }
                    }

                    // Version
                    Text("Huggy v1.0.0")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(Color(hex: "9B6B60"))
                        .padding(.top, 20)

                    Spacer().frame(height: 30)
                }
            }
        }
    }

    private func settingsRow(icon: String, title: String, subtitle: String?, destructive: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, design: .rounded))
                .foregroundColor(destructive ? .red : Color(hex: "E8735A"))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(destructive ? .red : Color(hex: "3D1C12"))

                if let subtitle {
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(Color(hex: "9B6B60"))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(Color(hex: "9B6B60"))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "F5C4B3"), lineWidth: 0.5)
                )
        )
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
