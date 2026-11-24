import Foundation

public enum ScrewType: String, CaseIterable, Codable, Sendable {
    case coarseThread
    case slim

    public var displayName: String {
        switch self {
        case .coarseThread: return "コーススレッド"
        case .slim: return "スリムビス（細軸）"
        }
    }

    /// 代表的な外径（mm）。メーカーにより多少違う。
    public func representativeDiameterMM(lengthMM: Int) -> Double {
        switch self {
        case .slim: return 3.3
        case .coarseThread: return lengthMM >= 90 ? 4.2 : 3.8
        }
    }
}

/// ビス長の「OKな範囲」
public struct ScrewLengthRange: Hashable, Codable, Sendable {
    /// 手前の材＋効かない層（石膏ボード）の厚み
    public let throughLayerMM: Double
    /// 推奨最小長 = 手前の層 + 20mm
    public let minimumMM: Double
    /// 最大許容長 = 手前の層 + 相手材厚 − 2mm（突き抜け防止）
    public let maximumMM: Double
    /// いちばんちょうどいい長さ（候補選びの基準）
    public let idealMM: Double

    public var isSatisfiable: Bool { minimumMM <= maximumMM }
}

public struct ScrewRecommendation: Hashable, Codable, Sendable {
    public enum Status: String, Codable, Sendable {
        /// 条件をすべて満たすビスがある
        case ok
        /// 突き抜けないビスはあるが、効き深さが20mm未満
        case insufficientEmbed
        /// 使えるビスがない
        case noCandidate
    }

    public let status: Status
    public let screwType: ScrewType
    public let lengthMM: Int?
    public let diameterMM: Double?
    public let range: ScrewLengthRange
    /// 範囲内のほかの候補
    public let alternativeLengthsMM: [Int]
    /// 相手材に実際に効く深さ
    public let embedDepthMM: Double?
    public let pilotHole: PilotHoleRecommendation?
    public let notes: [String]

    public var displayTitle: String {
        guard let lengthMM else { return "合うビスがありません" }
        return "\(screwType.displayName) \(lengthMM)mm"
    }
}

/// 木工ビス長の判定
public enum ScrewCalculator {
    /// 長さの範囲を計算する（純粋関数）
    public static func lengthRange(
        attachedThicknessMM t1: Double,
        nonHoldingLayerMM gap: Double = 0,
        holdingThicknessMM t2: Double,
        load: LoadClass = .light
    ) -> ScrewLengthRange {
        let through = t1 + gap
        let minimum = through + DIYStandards.minimumEmbedMM
        let maximum = through + t2 - DIYStandards.throughMarginMM
        // 相手材の厚みの7割くらいを効かせるのが目安（20〜30mm）。重い物は少し深く。
        let preferredEmbed = min(max(t2 * 0.7, DIYStandards.minimumEmbedMM), DIYStandards.preferredEmbedCapMM)
            + load.extraEmbedMM
        let ideal = min(through + preferredEmbed, maximum)
        return ScrewLengthRange(throughLayerMM: through, minimumMM: minimum, maximumMM: maximum, idealMM: ideal)
    }

    /// 市販の長さリストから選ぶ
    public static func selectLength(
        for range: ScrewLengthRange,
        from lengths: [Int] = DIYStandards.screwLengthsMM
    ) -> (lengthMM: Int?, status: ScrewRecommendation.Status, alternatives: [Int]) {
        let sorted = lengths.sorted()
        let candidates = sorted.filter { Double($0) >= range.minimumMM && Double($0) <= range.maximumMM }

        // 理想の長さにいちばん近いもの。同じ近さなら長い方（よく効く方）。
        if let best = candidates.min(by: { a, b in
            let da = abs(Double(a) - range.idealMM)
            let db = abs(Double(b) - range.idealMM)
            if abs(da - db) < 1e-9 { return a > b }
            return da < db
        }) {
            return (best, .ok, candidates.filter { $0 != best })
        }

        // 20mm効かせられないときは、突き抜けない範囲でいちばん長いもの
        if let fallback = sorted.filter({ Double($0) <= range.maximumMM && Double($0) > range.throughLayerMM }).max() {
            return (fallback, .insufficientEmbed, [])
        }
        return (nil, .noCandidate, [])
    }

    /// 薄い材（19mm以下）や材の端に打つときは、木割れ防止でスリムビス。
    public static func screwType(attached: AttachedMaterial, isEdgeScrewing: Bool) -> ScrewType {
        guard attached.isWood else { return .coarseThread }
        return (attached.thicknessMM <= 19 || isEdgeScrewing) ? .slim : .coarseThread
    }

    public static func recommend(
        _ input: FasteningInput,
        availableLengthsMM: [Int] = DIYStandards.screwLengthsMM
    ) -> ScrewRecommendation {
        let t2 = input.target.holdingThicknessMM ?? 0
        let range = lengthRange(
            attachedThicknessMM: input.attached.thicknessMM,
            nonHoldingLayerMM: input.target.nonHoldingLayerMM,
            holdingThicknessMM: t2,
            load: input.load
        )
        let type = screwType(attached: input.attached, isEdgeScrewing: input.isEdgeScrewing)
        let selection = selectLength(for: range, from: availableLengthsMM)

        var diameter: Double?
        var pilot: PilotHoleRecommendation?
        var embed: Double?
        if let length = selection.lengthMM {
            let d = type.representativeDiameterMM(lengthMM: length)
            diameter = d
            pilot = PilotHoleCalculator.recommend(screwDiameterMM: d, hardness: input.woodHardness)
            embed = Double(length) - range.throughLayerMM
        }

        var notes: [String] = []
        if type == .slim {
            if input.isEdgeScrewing {
                notes.append("材の端に打つと割れやすいので、細軸のスリムビス＋下穴がおすすめです。")
            } else {
                notes.append("19mm以下の薄い材は割れやすいので、細軸のスリムビスがおすすめです。")
            }
        }
        if !input.attached.isWood {
            notes.append("金具の穴の大きさに合う太さのビスを選んでください。")
        }
        if case .studBehindGypsum(let board) = input.target {
            notes.append("石膏ボードにはビスが効かないため、ボード厚 \(MMFormatter.string(board.thicknessMM))mm を足して計算しています。")
            notes.append("間柱の位置は下地センサーや下地探しピンで必ず確認してください。")
        }
        switch selection.status {
        case .ok:
            break
        case .insufficientEmbed:
            let e = embed.map(MMFormatter.string) ?? "-"
            notes.append("相手材が薄く、ビスが \(e)mm しか効きません（目安は20mm以上）。L字金具の併用や裏から留める方法も検討してください。")
        case .noCandidate:
            notes.append("この組み合わせに合う市販ビスが見つかりません。材の組み合わせを見直してください。")
        }
        if let pilot {
            notes.append("下穴は \(MMFormatter.string(pilot.drillBitMM))mm のドリルで開けると木割れを防げます。")
        }

        return ScrewRecommendation(
            status: selection.status,
            screwType: type,
            lengthMM: selection.lengthMM,
            diameterMM: diameter,
            range: range,
            alternativeLengthsMM: selection.alternatives,
            embedDepthMM: embed,
            pilotHole: pilot,
            notes: notes
        )
    }
}
