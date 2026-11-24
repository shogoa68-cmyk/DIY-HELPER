import Foundation
import SwiftData

/// 部屋（例：リビング、寝室）
@Model
final class Room {
    @Attribute(.unique) var id: UUID
    var name: String
    /// 賃貸かどうか（原状回復ログの対象にする）
    var isRental: Bool
    var memo: String
    var sortOrder: Int
    var createdAt: Date

    /// 部屋を消すと、その部屋の壁もいっしょに消える（cascade）
    @Relationship(deleteRule: .cascade, inverse: \WallSurface.room)
    var walls: [WallSurface] = []

    init(name: String, isRental: Bool = true, memo: String = "", sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.isRental = isRental
        self.memo = memo
        self.sortOrder = sortOrder
        self.createdAt = .now
    }
}
