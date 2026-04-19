import Foundation
import FirebaseFirestore

struct HugModel: Codable, Identifiable {
    @DocumentID var id: String?
    var senderId: String
    var receiverId: String
    var coupleId: String
    var hugType: String
    var note: String?
    var sentAt: Timestamp
    var opened: Bool

    var hugTypeEnum: HugType {
        HugType(rawValue: hugType) ?? .heart
    }

    var sentDate: Date {
        sentAt.dateValue()
    }
}

struct InviteModel: Codable {
    var creatorUid: String
    var createdAt: Timestamp
    var expiresAt: Timestamp
    var used: Bool
}

struct HugRequest: Codable {
    var senderUid: String
    var receiverUid: String
    var coupleId: String
    var createdAt: Timestamp
}
