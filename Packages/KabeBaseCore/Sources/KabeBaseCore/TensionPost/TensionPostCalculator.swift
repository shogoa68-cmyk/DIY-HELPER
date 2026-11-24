import Foundation

/// 突っ張りアジャスターの種類と「差し引く長さ」
public struct AdjusterPreset: Hashable, Codable, Sendable, Identifiable {
    public let id: String
    public let displayName: String
    /// 天井高から差し引く長さ Δ（mm）
    public let deductionMM: Double

    public init(id: String, displayName: String, deductionMM: Double) {
        self.id = id
        self.displayName = displayName
        self.deductionMM = deductionMM
    }

    /// ラブリコ 2×4アジャスター（標準）
    public static let labrico2x4 = AdjusterPreset(id: "labrico-2x4", displayName: "ラブリコ 2×4アジャスター", deductionMM: 95)
    /// ディアウォール（標準）
    public static let diawall2x4 = AdjusterPreset(id: "diawall-2x4", displayName: "ディアウォール 2×4", deductionMM: 45)

    public static let presets: [AdjusterPreset] = [.labrico2x4, .diawall2x4]

    /// 自分で差し引き値を決める（Pro機能想定）
    public static func custom(deductionMM: Double, name: String = "カスタム") -> AdjusterPreset {
        AdjusterPreset(id: "custom-\(MMFormatter.string(deductionMM))", displayName: name, deductionMM: deductionMM)
    }
}

public struct TensionPostInput: Hashable, Codable, Sendable {
    /// 測った天井高（複数箇所）
    public var measuredHeightsMM: [Double]
    public var adjuster: AdjusterPreset
    public var postCount: Int

    public init(measuredHeightsMM: [Double], adjuster: AdjusterPreset, postCount: Int = 1) {
        self.measuredHeightsMM = measuredHeightsMM
        self.adjuster = adjuster
        self.postCount = postCount
    }
}

public struct TensionPostResult: Hashable, Codable, Sendable {
    /// 2×4材のカット長（mm、1mm未満は切り捨て）
    public let cutLengthMM: Int
    /// 計算に使った天井高（測った中でいちばん低い値）
    public let baseHeightMM: Double
    /// 測った天井高の最大と最小の差
    public let heightSpreadMM: Double
    public let adjuster: AdjusterPreset
    public let postCount: Int
    /// ホームセンターで買うべき定尺（足りる中でいちばん短いもの）
    public let recommendedStock: StockLength?
    public let warnings: [String]
    /// 木材カット依頼用のメモ
    public let cutRequestMemo: String

    public var displayTitle: String { "2×4カット \(cutLengthMM)mm × \(postCount)本" }
}

public enum TensionPostError: Error, Equatable, Sendable, LocalizedError {
    case noMeasurements
    case invalidMeasurement(Double)
    case heightTooLow(heightMM: Double, deductionMM: Double)
    case invalidPostCount(Int)

    public var errorDescription: String? {
        switch self {
        case .noMeasurements:
            return "天井高を入力してください。"
        case .invalidMeasurement(let v):
            return "天井高 \(MMFormatter.string(v))mm は正しい値ではありません。"
        case .heightTooLow(let h, let d):
            return "天井高 \(MMFormatter.string(h))mm がアジャスターの差し引き値 \(MMFormatter.string(d))mm より短いため計算できません。"
        case .invalidPostCount(let n):
            return "本数 \(n) は正しい値ではありません。1本以上にしてください。"
        }
    }
}

/// タブ3「2×4突っ張り計算」
public enum TensionPostCalculator {
    public static let recommendedMeasurementCount = 3
    /// これ以上ばらつくと注意を出す（mm）
    public static let spreadWarningThresholdMM: Double = 5
    public static let disclaimer = "製品ロットや天井のたわみにより数mmの差が出ることがあります。カット前に必ず現地で測り直し、メーカーの説明書を確認してください。"

    /// カット長 = 天井高 − 差し引き値（純粋関数）
    public static func cutLength(ceilingHeightMM h: Double, deductionMM delta: Double) -> Double {
        h - delta
    }

    public static func calculate(
        _ input: TensionPostInput,
        stockLengths: [StockLength] = DIYStandards.twoByFourStockLengths
    ) throws -> TensionPostResult {
        guard !input.measuredHeightsMM.isEmpty else { throw TensionPostError.noMeasurements }
        if let bad = input.measuredHeightsMM.first(where: { !$0.isFinite || $0 <= 0 }) {
            throw TensionPostError.invalidMeasurement(bad)
        }
        guard input.postCount >= 1 else { throw TensionPostError.invalidPostCount(input.postCount) }

        // 天井は場所によって高さが違うことがあるので、いちばん低い値に合わせる（長すぎると立たない）
        let base = input.measuredHeightsMM.min()!
        let top = input.measuredHeightsMM.max()!
        let delta = input.adjuster.deductionMM
        let raw = cutLength(ceilingHeightMM: base, deductionMM: delta)
        guard raw > 0 else { throw TensionPostError.heightTooLow(heightMM: base, deductionMM: delta) }
        let cut = Int(raw.rounded(.down))
        let spread = top - base
        let stock = stockLengths.sorted { $0.lengthMM < $1.lengthMM }.first { $0.lengthMM >= Double(cut) }

        var warnings: [String] = []
        if input.measuredHeightsMM.count < recommendedMeasurementCount {
            warnings.append("天井高は左・中央・右など最低\(recommendedMeasurementCount)か所測りましょう（いまは\(input.measuredHeightsMM.count)か所）。")
        }
        if spread > spreadWarningThresholdMM {
            warnings.append("測った場所によって天井高が \(MMFormatter.string(spread))mm 違います。いちばん低い \(MMFormatter.string(base))mm で計算しました。")
        }
        if stock == nil {
            warnings.append("一般的な2×4定尺（最長12F）より長いため、1本では足りません。")
        }

        var memoLines = ["【木材カットのお願い】"]
        if let stock {
            memoLines.append("材料：2×4材（38×89mm） \(stock.displayName)")
        } else {
            memoLines.append("材料：2×4材（38×89mm）")
        }
        memoLines.append("カット寸法：\(cut)mm × \(input.postCount)本")
        memoLines.append("（\(input.adjuster.displayName)用／天井高 \(MMFormatter.string(base))mm − \(MMFormatter.string(delta))mm）")

        return TensionPostResult(
            cutLengthMM: cut,
            baseHeightMM: base,
            heightSpreadMM: spread,
            adjuster: input.adjuster,
            postCount: input.postCount,
            recommendedStock: stock,
            warnings: warnings,
            cutRequestMemo: memoLines.joined(separator: "\n")
        )
    }
}

/// 入力と結果のセット（履歴保存用）
public struct TensionPostCalculation: Hashable, Codable, Sendable {
    public let input: TensionPostInput
    public let result: TensionPostResult

    public init(input: TensionPostInput, result: TensionPostResult) {
        self.input = input
        self.result = result
    }
}
