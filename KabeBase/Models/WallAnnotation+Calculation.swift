import Foundation
import KabeBaseCore

extension WallAnnotation {
    /// 計算結果（ビス・アンカー・突っ張り柱）をピンに書き写す
    func apply(_ record: DiyCalcRecord) {
        calcRecord = record
        if let calc = record.fasteningCalculation {
            fastenerName = calc.result.displayTitle
            restoration = calc.result.restorationLevel
            loadKg = calc.input.load.upperKg
            if case .anchor(let anchor) = calc.result {
                anchorType = anchor.primary
            }
            if note.isEmpty {
                note = "\(calc.input.attached.displayName) → \(calc.input.target.displayName)／\(calc.result.summaryLine)"
            }
        } else if let calc = record.tensionPostCalculation {
            fastenerName = "2×4突っ張り柱 \(calc.result.cutLengthMM)mm"
            // 突っ張り柱は壁に穴をあけない
            restoration = .none
            if note.isEmpty {
                note = "\(calc.result.adjuster.displayName)／天井高 \(MMFormatter.string(calc.result.baseHeightMM))mm"
            }
        }
    }
}
