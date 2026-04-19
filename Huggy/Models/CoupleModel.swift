import Foundation
import FirebaseFirestore

struct CoupleModel: Codable, Identifiable {
    @DocumentID var id: String?
    var user1Uid: String
    var user2Uid: String
    var createdAt: Timestamp
    var hugStreak: Int
    var lastHugAt: Timestamp?
    var totalHugs: Int

    var coupleId: String { id ?? "" }
}
