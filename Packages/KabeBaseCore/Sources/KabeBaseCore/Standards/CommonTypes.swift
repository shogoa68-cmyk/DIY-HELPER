import Foundation

/// 想定する重さ（荷重）。プリセットボタンで選ぶ。
public enum LoadClass: String, CaseIterable, Codable, Sendable, Identifiable {
    case light
    case medium
    case heavy
    case veryHeavy

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .light: return "〜3kg"
        case .medium: return "〜10kg"
        case .heavy: return "〜20kg"
        case .veryHeavy: return "20kg超"
        }
    }

    public var examples: String {
        switch self {
        case .light: return "時計・額・カレンダー"
        case .medium: return "小さな棚・フック"
        case .heavy: return "本棚・ウォールシェルフ"
        case .veryHeavy: return "TV・大型収納"
        }
    }

    /// 重さの上限の目安（kg）。20kg超は上限なしで nil。
    public var upperKg: Double? {
        switch self {
        case .light: return 3
        case .medium: return 10
        case .heavy: return 20
        case .veryHeavy: return nil
        }
    }

    /// 重いものほど、ビスを少し深く効かせる（mm）
    var extraEmbedMM: Double {
        switch self {
        case .light, .medium: return 0
        case .heavy: return 5
        case .veryHeavy: return 10
        }
    }
}

/// 木の硬さ。下穴の太さを決めるのに使う。
public enum WoodHardness: String, CaseIterable, Codable, Sendable, Identifiable {
    case softwood
    case hardwood

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .softwood: return "軟木（SPF・パイン・合板）"
        case .hardwood: return "堅木（ナラ・タモなど）"
        }
    }

    /// 下穴径 ÷ ビス外径 の目安範囲
    public var pilotHoleRatioRange: ClosedRange<Double> {
        switch self {
        case .softwood: return 0.6...0.7
        case .hardwood: return 0.7...0.8
        }
    }
}

/// 賃貸の原状回復（退去時に元に戻す）でどのくらい手間がかかる穴か。
public enum RestorationLevel: String, CaseIterable, Codable, Sendable, Identifiable {
    case none
    case pinHole
    case puttyRequired

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .none: return "穴なし"
        case .pinHole: return "画鋲・ピン穴のみ"
        case .puttyRequired: return "ビス穴・アンカー穴（パテ補修要）"
        }
    }
}
