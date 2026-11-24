import Foundation
import SwiftData
import KabeBaseCore

/// 壁に置く印の種類
enum AnnotationKind: String, Codable, CaseIterable {
    /// 間柱ライン
    case studLine
    /// 配線・配管があるのでビスを打ってはいけない範囲
    case ngZone
    /// 施工ピン（ここにビス・アンカーを打った）
    case pin
}

/// 間柱の素材
enum StudMaterial: String, Codable, CaseIterable {
    case wood
    case lightSteel

    var displayName: String {
        switch self {
        case .wood: return "木"
        case .lightSteel: return "軽量鉄骨（軽天）"
        }
    }
}

/// NGゾーンの理由
enum NGZoneReason: String, Codable, CaseIterable {
    case wiring
    case piping
    case other

    var displayName: String {
        switch self {
        case .wiring: return "配線"
        case .piping: return "配管"
        case .other: return "その他"
        }
    }
}

/// 壁の上に置く印（間柱ライン・NGゾーン・施工ピン）。
/// 位置は写真に対する正規化座標（0〜1）で保存する。
@Model
final class WallAnnotation {
    @Attribute(.unique) var id: UUID
    var wall: WallSurface?

    /// AnnotationKind の rawValue（SwiftData の検索で扱いやすいよう文字列で保存）
    var kindRaw: String
    /// ピンの位置／ラインの始点／ゾーンの左上
    var x: Double
    var y: Double
    /// ラインの終点／ゾーンの右下（ピンでは nil）
    var endX: Double?
    var endY: Double?

    var title: String
    var note: String

    // 間柱ライン用
    var studMaterialRaw: String?
    // NGゾーン用
    var ngReasonRaw: String?

    // 施工ピン用
    /// 例：「スリムビス（細軸） 45mm」
    var fastenerName: String?
    var anchorTypeRaw: String?
    var loadKg: Double?
    /// RestorationLevel の rawValue
    var restorationRaw: String
    /// 原状回復（穴埋めなど）が済んだか
    var isRestored: Bool

    var createdAt: Date

    /// 元になった計算履歴（計算画面から転記したとき）
    var calcRecord: DiyCalcRecord?

    init(kind: AnnotationKind, x: Double, y: Double, endX: Double? = nil, endY: Double? = nil, title: String = "", note: String = "") {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.x = x
        self.y = y
        self.endX = endX
        self.endY = endY
        self.title = title
        self.note = note
        self.restorationRaw = RestorationLevel.none.rawValue
        self.isRestored = false
        self.createdAt = .now
    }

    var kind: AnnotationKind {
        get { AnnotationKind(rawValue: kindRaw) ?? .pin }
        set { kindRaw = newValue.rawValue }
    }

    var restoration: RestorationLevel {
        get { RestorationLevel(rawValue: restorationRaw) ?? .none }
        set { restorationRaw = newValue.rawValue }
    }

    var studMaterial: StudMaterial? {
        get { studMaterialRaw.flatMap(StudMaterial.init(rawValue:)) }
        set { studMaterialRaw = newValue?.rawValue }
    }

    var ngReason: NGZoneReason? {
        get { ngReasonRaw.flatMap(NGZoneReason.init(rawValue:)) }
        set { ngReasonRaw = newValue?.rawValue }
    }

    var anchorType: AnchorType? {
        get { anchorTypeRaw.flatMap(AnchorType.init(rawValue:)) }
        set { anchorTypeRaw = newValue?.rawValue }
    }

    var position: NormalizedPoint { NormalizedPoint(x: x, y: y) }
}
