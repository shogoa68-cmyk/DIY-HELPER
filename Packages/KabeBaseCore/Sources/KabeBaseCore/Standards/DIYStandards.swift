import Foundation

/// 流通木材のサイズ（実寸）。
public struct LumberSize: Hashable, Codable, Sendable {
    public let name: String
    public let thicknessMM: Double
    public let widthMM: Double

    public init(name: String, thicknessMM: Double, widthMM: Double) {
        self.name = name
        self.thicknessMM = thicknessMM
        self.widthMM = widthMM
    }
}

/// ホームセンターで売っている定尺（決まった長さ）の材。
public struct StockLength: Hashable, Codable, Sendable {
    public let name: String
    public let lengthMM: Double

    public init(name: String, lengthMM: Double) {
        self.name = name
        self.lengthMM = lengthMM
    }

    public var displayName: String { "\(name)（\(MMFormatter.string(lengthMM))mm）" }
}

/// 日本のDIY規格マスタ。数値はすべて mm（ミリメートル）。
public enum DIYStandards {
    // MARK: 木材・ボード
    public static let oneByFour = LumberSize(name: "1×4材", thicknessMM: 19, widthMM: 89)
    public static let twoByFour = LumberSize(name: "2×4材", thicknessMM: 38, widthMM: 89)
    /// 合板・パイン集成材の代表的な厚み
    public static let boardThicknessesMM: [Double] = [9, 12, 15, 18, 24]

    // MARK: 間柱（壁の中の柱）
    /// 木造住宅の間柱ピッチ（尺モジュール）
    public static let studPitchesMM: [Double] = [303, 455]
    /// 間柱（27×105mm が一般的）の奥行き。ビスが効く深さとして使う。
    public static let studDepthMM: Double = 105

    // MARK: ビス・ドリル
    /// 市販コーススレッド／スリムビスの長さ
    public static let screwLengthsMM: [Int] = [25, 32, 38, 41, 45, 51, 65, 75, 90]
    /// 市販ドリルビット径
    public static let drillBitDiametersMM: [Double] = [1.5, 2.0, 2.5, 3.0, 3.2, 3.5, 4.0]
    /// 相手材にねじ込みたい最低の深さ
    public static let minimumEmbedMM: Double = 20
    /// 相手材を突き抜けないための余裕
    public static let throughMarginMM: Double = 2
    /// ビスの効き深さの「ちょうどいい」上限（これ以上長くしても効果が小さい）
    public static let preferredEmbedCapMM: Double = 30

    // MARK: 2×4 定尺
    public static let twoByFourStockLengths: [StockLength] = [
        StockLength(name: "6F", lengthMM: 1829),
        StockLength(name: "8F", lengthMM: 2438),
        StockLength(name: "10F", lengthMM: 3048),
        StockLength(name: "12F", lengthMM: 3658),
    ]
}

/// mm の数値を画面表示用の文字列にする（19 → "19"、9.5 → "9.5"）。
public enum MMFormatter {
    public static func string(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded == rounded.rounded() {
            return String(Int(rounded))
        }
        return String(format: "%.1f", rounded)
    }
}
