import Foundation

/// 入力欄の文字（"2,400"・"２４００"・"2400mm" など）を mm の数値に読み取る。
public enum MeasurementParser {
    /// 読み取れない・0以下なら nil
    public static func value(from text: String) -> Double? {
        var normalized = ""
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0xFF10...0xFF19: // 全角数字 ０〜９
                normalized.unicodeScalars.append(Unicode.Scalar(scalar.value - 0xFEE0)!)
            case 0xFF0E: // 全角ピリオド
                normalized.append(".")
            case 0x2C, 0xFF0C, 0x20, 0x3000: // カンマ・空白は無視
                continue
            default:
                normalized.unicodeScalars.append(scalar)
            }
        }
        normalized = normalized.lowercased()
        for suffix in ["mm", "ｍｍ"] where normalized.hasSuffix(suffix) {
            normalized.removeLast(suffix.count)
        }
        guard let value = Double(normalized), value.isFinite, value > 0 else { return nil }
        return value
    }

    /// 空欄を飛ばして読み取る。読み取れない欄があれば、その番号（0始まり）を返す。
    public static func values(from texts: [String]) -> (values: [Double], invalidIndices: [Int]) {
        var values: [Double] = []
        var invalid: [Int] = []
        for (i, text) in texts.enumerated() {
            if text.trimmingCharacters(in: .whitespaces).isEmpty { continue }
            if let v = value(from: text) {
                values.append(v)
            } else {
                invalid.append(i)
            }
        }
        return (values, invalid)
    }
}
