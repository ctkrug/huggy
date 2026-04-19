import Foundation
import FirebaseFirestore

struct UserModel: Codable, Identifiable {
    @DocumentID var id: String?
    var displayName: String
    var partnerId: String?
    var coupleId: String?
    var fcmToken: String
    var createdAt: Timestamp

    var uid: String { id ?? "" }
}
