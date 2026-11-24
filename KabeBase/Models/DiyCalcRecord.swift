import Foundation
import SwiftData
import KabeBaseCore

enum CalcKind: String, Codable, CaseIterable {
    case fastening
    case tensionPost

    var displayName: String {
        switch self {
        case .fastening: return "ビス・下穴"
        case .tensionPost: return "2×4突っ張り"
        }
    }
}

/// 計算の履歴。買い物メモとしても使う。
@Model
final class DiyCalcRecord {
    @Attribute(.unique) var id: UUID
    var kindRaw: String
    var createdAt: Date
    /// 一覧に出すタイトル（例：「スリムビス（細軸） 45mm」）
    var title: String
    /// 1行まとめ（例：「1×4材 → 2×4材／下穴 2mm」）
    var summary: String
    /// 入力と結果を JSON にしたもの（あとで画面を復元するため）
    var payload: Data

    var isFavorite: Bool
    var isInShoppingList: Bool
    var isPurchased: Bool

    /// この計算を転記した施工ピン
    @Relationship(deleteRule: .nullify, inverse: \WallAnnotation.calcRecord)
    var annotations: [WallAnnotation] = []

    init(kind: CalcKind, title: String, summary: String, payload: Data) {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.createdAt = .now
        self.title = title
        self.summary = summary
        self.payload = payload
        self.isFavorite = false
        self.isInShoppingList = false
        self.isPurchased = false
    }

    var kind: CalcKind { CalcKind(rawValue: kindRaw) ?? .fastening }

    // MARK: 計算エンジンの結果から作る

    static func make(from calc: FasteningCalculation) -> DiyCalcRecord {
        DiyCalcRecord(
            kind: .fastening,
            title: calc.result.displayTitle,
            summary: "\(calc.input.attached.displayName) → \(calc.input.target.displayName)／\(calc.result.summaryLine)",
            payload: (try? JSONEncoder().encode(calc)) ?? Data()
        )
    }

    static func make(from calc: TensionPostCalculation) -> DiyCalcRecord {
        DiyCalcRecord(
            kind: .tensionPost,
            title: calc.result.displayTitle,
            summary: "\(calc.input.adjuster.displayName)／天井高 \(MMFormatter.string(calc.result.baseHeightMM))mm",
            payload: (try? JSONEncoder().encode(calc)) ?? Data()
        )
    }

    var fasteningCalculation: FasteningCalculation? {
        guard kind == .fastening else { return nil }
        return try? JSONDecoder().decode(FasteningCalculation.self, from: payload)
    }

    var tensionPostCalculation: TensionPostCalculation? {
        guard kind == .tensionPost else { return nil }
        return try? JSONDecoder().decode(TensionPostCalculation.self, from: payload)
    }
}
