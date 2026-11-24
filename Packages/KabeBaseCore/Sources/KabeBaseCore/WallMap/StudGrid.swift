import Foundation

/// 303mm / 455mm ピッチの間柱補助グリッド
public enum StudGrid {
    /// 0〜spanMM の範囲にある補助線の位置（mm）。
    /// offsetMM は「基準の間柱がどこにあるか」。ピッチより大きくてもマイナスでもOK。
    public static func linePositionsMM(spanMM: Double, pitchMM: Double, offsetMM: Double) -> [Double] {
        guard spanMM > 0, pitchMM > 0, spanMM.isFinite, offsetMM.isFinite else { return [] }
        var start = offsetMM.truncatingRemainder(dividingBy: pitchMM)
        if start < 0 { start += pitchMM }
        var result: [Double] = []
        var i = 0
        while true {
            let p = start + Double(i) * pitchMM
            if p > spanMM + 1e-9 { break }
            result.append(p)
            i += 1
        }
        return result
    }

    /// 写真の横方向の正規化座標（0〜1）で補助線の位置を返す
    public static func normalizedLinePositions(
        calibration: ScaleCalibration,
        pitchMM: Double,
        offsetMM: Double
    ) -> [Double] {
        let width = calibration.imageWidthMM
        return linePositionsMM(spanMM: width, pitchMM: pitchMM, offsetMM: offsetMM).map { $0 / width }
    }
}
