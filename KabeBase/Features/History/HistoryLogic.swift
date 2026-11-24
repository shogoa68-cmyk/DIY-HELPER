import Foundation
import KabeBaseCore

/// 原状回復ログの絞り込み条件
struct RestorationFilter: Equatable {
    enum Level: String, CaseIterable, Identifiable {
        case all
        case pinHole
        case putty

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "すべて"
            case .pinHole: return "画鋲・ピン穴のみ"
            case .putty: return "パテ補修要"
            }
        }
    }

    var level: Level = .all
    var onlyUnrestored = false
    var onlyRental = true

    func matches(restoration: RestorationLevel, isRestored: Bool, isRental: Bool) -> Bool {
        switch level {
        case .all: break
        case .pinHole: guard restoration == .pinHole else { return false }
        case .putty: guard restoration == .puttyRequired else { return false }
        }
        if onlyUnrestored, isRestored { return false }
        if onlyRental, !isRental { return false }
        return true
    }

    func matches(_ pin: WallAnnotation) -> Bool {
        matches(restoration: pin.restoration, isRestored: pin.isRestored, isRental: pin.wall?.room?.isRental ?? false)
    }
}

/// 原状回復リスト（文字）を作る
enum RestorationReport {
    struct Entry: Equatable {
        let roomName: String
        let wallName: String
        let title: String
        let fastener: String?
        let restoration: RestorationLevel
        let isRestored: Bool
    }

    static func entry(for pin: WallAnnotation) -> Entry {
        Entry(
            roomName: pin.wall?.room?.name ?? "部屋なし",
            wallName: pin.wall?.name ?? "壁なし",
            title: pin.title.isEmpty ? "ピン" : pin.title,
            fastener: pin.fastenerName,
            restoration: pin.restoration,
            isRestored: pin.isRestored
        )
    }

    static func makeText(entries: [Entry], date: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy/MM/dd"

        var lines = ["【原状回復リスト】\(formatter.string(from: date)) 作成"]
        var currentGroup: String?
        for entry in entries {
            let group = "\(entry.roomName)／\(entry.wallName)"
            if group != currentGroup {
                lines.append("")
                lines.append("■ \(group)")
                currentGroup = group
            }
            let fastener = entry.fastener.map { "（\($0)）" } ?? ""
            let state = entry.isRestored ? "補修済み" : "未補修"
            lines.append("・\(entry.title)\(fastener)… \(entry.restoration.displayName)［\(state)］")
        }

        let putty = entries.filter { $0.restoration == .puttyRequired }
        let pinHoles = entries.filter { $0.restoration == .pinHole }
        lines.append("")
        lines.append("合計：パテ補修 \(putty.count)か所（未補修 \(putty.filter { !$0.isRestored }.count)）、ピン穴 \(pinHoles.count)か所（未補修 \(pinHoles.filter { !$0.isRestored }.count)）")
        return lines.joined(separator: "\n")
    }
}

/// 買い物メモ（文字）を作る
enum ShoppingListText {
    struct Item: Equatable {
        let title: String
        let summary: String
        let isPurchased: Bool
    }

    static func makeText(items: [Item]) -> String {
        var lines = ["【DIY買い物メモ】"]
        for item in items {
            lines.append("\(item.isPurchased ? "☑︎" : "☐") \(item.title)")
            lines.append("　\(item.summary)")
        }
        return lines.joined(separator: "\n")
    }
}
