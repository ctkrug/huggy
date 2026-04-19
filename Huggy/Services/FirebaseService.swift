import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    private init() {}

    // MARK: - User

    func createUserDocument(uid: String, displayName: String) async throws {
        let data: [String: Any] = [
            "displayName": displayName,
            "fcmToken": "",
            "createdAt": FieldValue.serverTimestamp()
        ]
        try await db.collection("users").document(uid).setData(data, merge: true)
    }

    func getUser(uid: String) async throws -> UserModel? {
        let doc = try await db.collection("users").document(uid).getDocument()
        return try? doc.data(as: UserModel.self)
    }

    func updateFCMToken(uid: String, token: String) async throws {
        try await db.collection("users").document(uid).updateData(["fcmToken": token])
    }

    func listenToUser(uid: String, onChange: @escaping (UserModel?) -> Void) -> ListenerRegistration {
        db.collection("users").document(uid).addSnapshotListener { snapshot, _ in
            guard let snapshot else { onChange(nil); return }
            onChange(try? snapshot.data(as: UserModel.self))
        }
    }

    // MARK: - Invite / Pairing (Deep Link)

    func createInvite(creatorUid: String) async throws -> String {
        let token = UUID().uuidString
        let now = Timestamp()
        let expires = Timestamp(date: Date().addingTimeInterval(48 * 3600))
        let invite = InviteModel(
            creatorUid: creatorUid,
            createdAt: now,
            expiresAt: expires,
            used: false
        )
        try await db.collection("invites").document(token).setData(from: invite)
        return token
    }

    func acceptInvite(token: String, acceptorUid: String) async throws -> String {
        let inviteRef = db.collection("invites").document(token)
        let doc = try await inviteRef.getDocument()

        guard let invite = try? doc.data(as: InviteModel.self) else {
            throw HuggyError.invalidInvite
        }

        guard !invite.used else { throw HuggyError.inviteAlreadyUsed }
        guard invite.expiresAt.dateValue() > Date() else { throw HuggyError.inviteExpired }

        let creatorUid = invite.creatorUid
        guard creatorUid != acceptorUid else { throw HuggyError.cannotPairWithSelf }

        let coupleId = UUID().uuidString
        let coupleData: [String: Any] = [
            "user1Uid": creatorUid,
            "user2Uid": acceptorUid,
            "createdAt": FieldValue.serverTimestamp(),
            "hugStreak": 0,
            "totalHugs": 0
        ]

        let batch = db.batch()
        batch.setData(coupleData, forDocument: db.collection("couples").document(coupleId))
        batch.updateData(["partnerId": acceptorUid, "coupleId": coupleId],
                         forDocument: db.collection("users").document(creatorUid))
        batch.updateData(["partnerId": creatorUid, "coupleId": coupleId],
                         forDocument: db.collection("users").document(acceptorUid))
        batch.updateData(["used": true], forDocument: inviteRef)
        try await batch.commit()

        return coupleId
    }

    func buildInviteLink(token: String) -> URL {
        // Firebase Dynamic Link format
        // Developer must set up huggy.page.link in Firebase Console
        var components = URLComponents()
        components.scheme = "https"
        components.host = "huggy.page.link"
        components.path = "/invite"
        components.queryItems = [URLQueryItem(name: "token", value: token)]
        return components.url!
    }

    // MARK: - Couple

    func getCouple(coupleId: String) async throws -> CoupleModel? {
        let doc = try await db.collection("couples").document(coupleId).getDocument()
        return try? doc.data(as: CoupleModel.self)
    }

    func listenToCouple(coupleId: String, onChange: @escaping (CoupleModel?) -> Void) -> ListenerRegistration {
        db.collection("couples").document(coupleId).addSnapshotListener { snapshot, _ in
            guard let snapshot else { onChange(nil); return }
            onChange(try? snapshot.data(as: CoupleModel.self))
        }
    }

    func unpair(coupleId: String, user1: String, user2: String) async throws {
        let batch = db.batch()
        batch.deleteDocument(db.collection("couples").document(coupleId))
        batch.updateData(["partnerId": FieldValue.delete(), "coupleId": FieldValue.delete()],
                         forDocument: db.collection("users").document(user1))
        batch.updateData(["partnerId": FieldValue.delete(), "coupleId": FieldValue.delete()],
                         forDocument: db.collection("users").document(user2))
        try await batch.commit()
    }

    // MARK: - Hugs

    func sendHug(senderId: String, receiverId: String, coupleId: String, hugType: HugType, note: String?) async throws {
        let data: [String: Any] = [
            "senderId": senderId,
            "receiverId": receiverId,
            "coupleId": coupleId,
            "hugType": hugType.rawValue,
            "note": note ?? "",
            "sentAt": FieldValue.serverTimestamp(),
            "opened": false
        ]
        try await db.collection("hugs").addDocument(data: data)

        // Update couple stats
        try await db.collection("couples").document(coupleId).updateData([
            "totalHugs": FieldValue.increment(Int64(1)),
            "lastHugAt": FieldValue.serverTimestamp()
        ])
    }

    func markHugOpened(hugId: String) async throws {
        try await db.collection("hugs").document(hugId).updateData(["opened": true])
    }

    func listenToHugs(coupleId: String, onChange: @escaping ([HugModel]) -> Void) -> ListenerRegistration {
        db.collection("hugs")
            .whereField("coupleId", isEqualTo: coupleId)
            .order(by: "sentAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { onChange([]); return }
                let hugs = docs.compactMap { try? $0.data(as: HugModel.self) }
                onChange(hugs)
            }
    }

    func getHug(hugId: String) async throws -> HugModel? {
        let doc = try await db.collection("hugs").document(hugId).getDocument()
        return try? doc.data(as: HugModel.self)
    }

    // MARK: - Hug Request

    func sendHugRequest(senderUid: String, receiverUid: String, coupleId: String) async throws {
        let data: [String: Any] = [
            "senderUid": senderUid,
            "receiverUid": receiverUid,
            "coupleId": coupleId,
            "createdAt": FieldValue.serverTimestamp()
        ]
        try await db.collection("hugRequests").addDocument(data: data)
    }
}

// MARK: - Errors

enum HuggyError: LocalizedError {
    case invalidInvite
    case inviteAlreadyUsed
    case inviteExpired
    case cannotPairWithSelf
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .invalidInvite: return "This invite link is invalid."
        case .inviteAlreadyUsed: return "This invite has already been used."
        case .inviteExpired: return "This invite has expired."
        case .cannotPairWithSelf: return "You can't pair with yourself!"
        case .notSignedIn: return "Please sign in first."
        }
    }
}
