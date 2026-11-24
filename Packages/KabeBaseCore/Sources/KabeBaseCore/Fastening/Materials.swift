import Foundation

/// 石膏ボードの厚み
public enum GypsumBoardThickness: String, CaseIterable, Codable, Sendable, Identifiable {
    /// 壁・天井用一般
    case t9_5
    /// 遮音・耐火・標準壁
    case t12_5

    public var id: String { rawValue }

    public var thicknessMM: Double {
        switch self {
        case .t9_5: return 9.5
        case .t12_5: return 12.5
        }
    }
}

/// 取り付ける材（手前側。ビスの頭がある側）
public enum AttachedMaterial: Hashable, Codable, Sendable {
    case oneByFour
    case twoByFour
    /// 合板・パイン集成材
    case board(thicknessMM: Double)
    /// L字金具などの金属プレート
    case metalBracket(thicknessMM: Double)

    public var thicknessMM: Double {
        switch self {
        case .oneByFour: return DIYStandards.oneByFour.thicknessMM
        case .twoByFour: return DIYStandards.twoByFour.thicknessMM
        case .board(let t), .metalBracket(let t): return t
        }
    }

    public var isWood: Bool {
        if case .metalBracket = self { return false }
        return true
    }

    public var displayName: String {
        switch self {
        case .oneByFour: return "1×4材（19mm）"
        case .twoByFour: return "2×4材（38mm）"
        case .board(let t): return "合板・集成材 \(MMFormatter.string(t))mm"
        case .metalBracket(let t): return "金具 \(MMFormatter.string(t))mm"
        }
    }

    /// 画面のプリセットチップ用
    public static let presets: [AttachedMaterial] =
        [.oneByFour, .twoByFour]
        + DIYStandards.boardThicknessesMM.map { AttachedMaterial.board(thicknessMM: $0) }
        + [.metalBracket(thicknessMM: 2)]
}

/// 相手材（奥側。ビスの先が効く側）
public enum TargetMaterial: Hashable, Codable, Sendable {
    case twoByFour
    case oneByFour
    /// 下地のない石膏ボードだけ → ビスは効かないのでアンカー
    case gypsumBoardOnly(GypsumBoardThickness)
    /// 石膏ボードの奥にある間柱
    case studBehindGypsum(GypsumBoardThickness)

    /// ビスが効く層の厚み。石膏ボードのみの場合は nil。
    public var holdingThicknessMM: Double? {
        switch self {
        case .twoByFour: return DIYStandards.twoByFour.thicknessMM
        case .oneByFour: return DIYStandards.oneByFour.thicknessMM
        case .gypsumBoardOnly: return nil
        case .studBehindGypsum: return DIYStandards.studDepthMM
        }
    }

    /// ビスは通るけれど効かない層（石膏ボード）の厚み
    public var nonHoldingLayerMM: Double {
        switch self {
        case .twoByFour, .oneByFour, .gypsumBoardOnly: return 0
        case .studBehindGypsum(let board): return board.thicknessMM
        }
    }

    public var displayName: String {
        switch self {
        case .twoByFour: return "2×4材"
        case .oneByFour: return "1×4材"
        case .gypsumBoardOnly(let b): return "石膏ボード \(MMFormatter.string(b.thicknessMM))mm（下地なし）"
        case .studBehindGypsum(let b): return "間柱（石膏ボード \(MMFormatter.string(b.thicknessMM))mm 越し）"
        }
    }

    public static let presets: [TargetMaterial] = [
        .twoByFour,
        .oneByFour,
        .gypsumBoardOnly(.t9_5),
        .gypsumBoardOnly(.t12_5),
        .studBehindGypsum(.t9_5),
        .studBehindGypsum(.t12_5),
    ]
}

/// ビス・下穴・アンカー計算の入力
public struct FasteningInput: Hashable, Codable, Sendable {
    public var attached: AttachedMaterial
    public var target: TargetMaterial
    public var load: LoadClass
    /// 材の端（木口の近く）に打つか
    public var isEdgeScrewing: Bool
    public var woodHardness: WoodHardness

    public init(
        attached: AttachedMaterial,
        target: TargetMaterial,
        load: LoadClass = .light,
        isEdgeScrewing: Bool = false,
        woodHardness: WoodHardness = .softwood
    ) {
        self.attached = attached
        self.target = target
        self.load = load
        self.isEdgeScrewing = isEdgeScrewing
        self.woodHardness = woodHardness
    }
}
