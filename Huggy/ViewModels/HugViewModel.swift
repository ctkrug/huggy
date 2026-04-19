import Foundation
import SwiftUI
import FirebaseAuth

@MainActor
final class HugViewModel: ObservableObject {
    @Published var hugs: [HugModel] = []
    @Published var couple: CoupleModel?
    @Published var partner: UserModel?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var receivedHug: HugModel?
    @Published var showReceiveView = false
    @Published var inviteLink: URL?

    private var hugListener: Any?
    private var coupleListener: Any?

    var currentUid: String? {
        Auth.auth().currentUser?.uid
    }

    var streakDays: Int {
        couple?.hugStreak ?? 0
    }

    var totalHugs: Int {
        couple?.totalHugs ?? 0
    }

    var lastHugAgo: String? {
        guard let lastHugAt = couple?.lastHugAt else { return nil }
        let date = lastHugAt.dateValue()
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var recentHugs: [HugModel] {
        Array(hugs.prefix(5))
    }

    var hugsByDay: [(String, [HugModel])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let grouped = Dictionary(grouping: hugs) { hug in
            formatter.string(from: hug.sentAt.dateValue())
        }
        return grouped.sorted { lhs, rhs in
            guard let l = lhs.value.first?.sentDate, let r = rhs.value.first?.sentDate else { return false }
            return l > r
        }
    }

    func isHugTypeUnlocked(_ type: HugType) -> Bool {
        if !type.isLocked { return true }
        return streakDays >= 7
    }

    // MARK: - Load Data

    func loadData(coupleId: String) {
        coupleListener = FirebaseService.shared.listenToCouple(coupleId: coupleId) { [weak self] couple in
            DispatchQueue.main.async {
                self?.couple = couple
            }
        }

        hugListener = FirebaseService.shared.listenToHugs(coupleId: coupleId) { [weak self] hugs in
            DispatchQueue.main.async {
                self?.hugs = hugs
            }
        }
    }

    func loadPartner(partnerId: String) async {
        partner = try? await FirebaseService.shared.getUser(uid: partnerId)
    }

    // MARK: - Send Hug

    func sendHug(hugType: HugType, note: String?) async {
        guard let uid = currentUid,
              let user = try? await FirebaseService.shared.getUser(uid: uid),
              let partnerId = user.partnerId,
              let coupleId = user.coupleId else { return }

        isLoading = true
        do {
            try await FirebaseService.shared.sendHug(
                senderId: uid,
                receiverId: partnerId,
                coupleId: coupleId,
                hugType: hugType,
                note: note
            )
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Receive Hug

    func handleReceivedHug(hugId: String) async {
        do {
            let hug = try await FirebaseService.shared.getHug(hugId: hugId)
            if let hug {
                receivedHug = hug
                showReceiveView = true
                try await FirebaseService.shared.markHugOpened(hugId: hugId)
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Hug Request

    func requestHug() async {
        guard let uid = currentUid,
              let user = try? await FirebaseService.shared.getUser(uid: uid),
              let partnerId = user.partnerId,
              let coupleId = user.coupleId else { return }

        do {
            try await FirebaseService.shared.sendHugRequest(
                senderUid: uid,
                receiverUid: partnerId,
                coupleId: coupleId
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Invite

    func createInvite() async {
        guard let uid = currentUid else { return }
        do {
            let token = try await FirebaseService.shared.createInvite(creatorUid: uid)
            inviteLink = FirebaseService.shared.buildInviteLink(token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func acceptInvite(token: String) async {
        guard let uid = currentUid else { return }
        isLoading = true
        do {
            _ = try await FirebaseService.shared.acceptInvite(token: token, acceptorUid: uid)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Unpair

    func unpair() async {
        guard let uid = currentUid,
              let user = try? await FirebaseService.shared.getUser(uid: uid),
              let partnerId = user.partnerId,
              let coupleId = user.coupleId else { return }

        do {
            try await FirebaseService.shared.unpair(coupleId: coupleId, user1: uid, user2: partnerId)
            couple = nil
            partner = nil
            hugs = []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    func senderName(for hug: HugModel) -> String {
        if hug.senderId == currentUid {
            return "You"
        }
        return partner?.displayName ?? "Partner"
    }

    // MARK: - Streak Visual

    func streakDots(days: Int) -> [Bool] {
        // Simple: show last 7 days, filled if hug was sent that day
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return false }
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            return hugs.contains { hug in
                let hugDate = hug.sentDate
                return hugDate >= dayStart && hugDate < dayEnd
            }
        }
    }
}
