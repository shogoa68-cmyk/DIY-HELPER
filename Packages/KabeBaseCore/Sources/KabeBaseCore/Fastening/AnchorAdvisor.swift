import Foundation

/// 石膏ボード用アンカーの種類
public enum AnchorType: String, CaseIterable, Codable, Sendable, Identifiable {
    case pinHook
    case screwInAnchor
    case umbrellaAnchor
    case toggleAnchor

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .pinHook: return "石膏ボード用ピンフック"
        case .screwInAnchor: return "ねじ込み式ボードアンカー"
        case .umbrellaAnchor: return "中空アンカー（カサ式）"
        case .toggleAnchor: return "トグルアンカー"
        }
    }

    public var summary: String {
        switch self {
        case .pinHook: return "細いピンを数本刺すタイプ。穴が目立ちにくい。"
        case .screwInAnchor: return "ドライバーでねじ込むだけ。下穴不要の製品が多い。"
        case .umbrellaAnchor: return "ボードの裏でカサが開いて固定する。"
        case .toggleAnchor: return "ボードの裏で羽が開き、広い面で支える。"
        }
    }

    public var restorationLevel: RestorationLevel {
        self == .pinHook ? .pinHole : .puttyRequired
    }
}

public struct AnchorRecommendation: Hashable, Codable, Sendable {
    /// nil のときはアンカーでは支えられない（下地や突っ張り柱を使う）
    public let primary: AnchorType?
    public let alternatives: [AnchorType]
    public let board: GypsumBoardThickness
    public let load: LoadClass
    public let notes: [String]

    public var restorationLevel: RestorationLevel { primary?.restorationLevel ?? .none }

    public var displayTitle: String { primary?.displayName ?? "アンカー非推奨（下地を探す）" }
}

/// 下地のない石膏ボードに取り付けるときのアンカー選び
public enum AnchorAdvisor {
    public static func recommend(board: GypsumBoardThickness, load: LoadClass) -> AnchorRecommendation {
        let boardNote = "ボード厚 \(MMFormatter.string(board.thicknessMM))mm に対応した製品を選んでください。"
        let checkNote = "耐荷重はあくまで目安です。製品パッケージの表示を必ず確認してください。"
        switch load {
        case .light:
            return AnchorRecommendation(
                primary: .pinHook, alternatives: [.screwInAnchor], board: board, load: load,
                notes: ["画鋲程度の穴で済むので、賃貸の原状回復がかんたんです。", checkNote]
            )
        case .medium:
            return AnchorRecommendation(
                primary: .screwInAnchor, alternatives: [.umbrellaAnchor], board: board, load: load,
                notes: [boardNote, checkNote, "退去時はパテで穴埋めが必要です。"]
            )
        case .heavy:
            return AnchorRecommendation(
                primary: .toggleAnchor, alternatives: [.umbrellaAnchor], board: board, load: load,
                notes: [boardNote, checkNote, "複数本に重さを分散させましょう。できれば間柱を探してビス留めが安心です。"]
            )
        case .veryHeavy:
            return AnchorRecommendation(
                primary: nil, alternatives: [], board: board, load: load,
                notes: ["石膏ボードだけでは支えられません。間柱を探してビス留めするか、2×4突っ張り柱を使いましょう。"]
            )
        }
    }
}
