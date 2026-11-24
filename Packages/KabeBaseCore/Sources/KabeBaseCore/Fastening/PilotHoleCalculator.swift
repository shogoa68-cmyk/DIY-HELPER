import Foundation

public struct PilotHoleRecommendation: Hashable, Codable, Sendable {
    /// 実際に使う市販ドリルビット径
    public let drillBitMM: Double
    /// 計算上の理想径
    public let idealDiameterMM: Double
    /// 許容範囲（ビス外径 × 比率の範囲）
    public let acceptableRangeMM: ClosedRange<Double>
    public let hardness: WoodHardness
}

/// 下穴ドリル径の計算
public enum PilotHoleCalculator {
    /// 推奨下穴径 = ビス外径 × 比率（軟木 0.6〜0.7、堅木 0.7〜0.8 の中央値）を、
    /// 市販ドリルビット径のいちばん近い値に丸める。
    public static func recommend(
        screwDiameterMM d: Double,
        hardness: WoodHardness,
        availableBitsMM: [Double] = DIYStandards.drillBitDiametersMM
    ) -> PilotHoleRecommendation? {
        guard d > 0, d.isFinite, !availableBitsMM.isEmpty else { return nil }
        let ratio = hardness.pilotHoleRatioRange
        let ideal = d * (ratio.lowerBound + ratio.upperBound) / 2
        guard let bit = nearestBit(to: ideal, in: availableBitsMM) else { return nil }
        return PilotHoleRecommendation(
            drillBitMM: bit,
            idealDiameterMM: ideal,
            acceptableRangeMM: (d * ratio.lowerBound)...(d * ratio.upperBound),
            hardness: hardness
        )
    }

    /// いちばん近いビット径。ちょうど真ん中なら細い方（ビスがよく効く方）を選ぶ。
    public static func nearestBit(to value: Double, in bits: [Double]) -> Double? {
        bits.min { a, b in
            let da = abs(a - value)
            let db = abs(b - value)
            if abs(da - db) < 1e-9 { return a < b }
            return da < db
        }
    }
}
