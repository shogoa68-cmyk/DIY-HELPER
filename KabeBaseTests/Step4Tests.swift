import XCTest
import SwiftData
import KabeBaseCore
@testable import KabeBase

@MainActor
final class CalculationTransferTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }

    override func setUp() async throws {
        container = try AppSchema.makeContainer(inMemory: true)
    }

    func testScrewCalculationIsCopiedToPin() {
        let record = DiyCalcRecord.make(from: FasteningAdvisor.calculate(
            FasteningInput(attached: .oneByFour, target: .studBehindGypsum(.t12_5), load: .medium)
        ))
        context.insert(record)
        let pin = WallAnnotation(kind: .pin, x: 0.5, y: 0.5)
        context.insert(pin)

        pin.apply(record)

        XCTAssertEqual(pin.fastenerName, record.title)
        XCTAssertEqual(pin.restoration, .puttyRequired)
        XCTAssertEqual(pin.loadKg, 10)
        XCTAssertNil(pin.anchorType)
        XCTAssertTrue(pin.calcRecord === record)
        XCTAssertFalse(pin.note.isEmpty)
    }

    func testAnchorCalculationSetsAnchorType() {
        let record = DiyCalcRecord.make(from: FasteningAdvisor.calculate(
            FasteningInput(attached: .board(thicknessMM: 12), target: .gypsumBoardOnly(.t9_5), load: .light)
        ))
        context.insert(record)
        let pin = WallAnnotation(kind: .pin, x: 0.1, y: 0.1)
        context.insert(pin)

        pin.apply(record)

        XCTAssertEqual(pin.anchorType, .pinHook)
        XCTAssertEqual(pin.restoration, .pinHole)
    }

    func testTensionPostMakesNoHole() throws {
        let input = TensionPostInput(measuredHeightsMM: [2400, 2400, 2400], adjuster: .labrico2x4)
        let calc = TensionPostCalculation(input: input, result: try TensionPostCalculator.calculate(input))
        let record = DiyCalcRecord.make(from: calc)
        context.insert(record)
        let pin = WallAnnotation(kind: .pin, x: 0.3, y: 0.5)
        context.insert(pin)

        pin.apply(record)

        XCTAssertEqual(pin.fastenerName, "2×4突っ張り柱 2305mm")
        XCTAssertEqual(pin.restoration, RestorationLevel.none)
    }
}

final class HistoryLogicTests: XCTestCase {
    func testRestorationFilter() {
        var filter = RestorationFilter()
        XCTAssertTrue(filter.matches(restoration: .puttyRequired, isRestored: false, isRental: true))
        XCTAssertFalse(filter.matches(restoration: .puttyRequired, isRestored: false, isRental: false), "賃貸だけ")

        filter.onlyRental = false
        filter.level = .pinHole
        XCTAssertFalse(filter.matches(restoration: .puttyRequired, isRestored: false, isRental: false))
        XCTAssertTrue(filter.matches(restoration: .pinHole, isRestored: true, isRental: false))

        filter.onlyUnrestored = true
        XCTAssertFalse(filter.matches(restoration: .pinHole, isRestored: true, isRental: false))
    }

    func testRestorationReport() {
        let entries = [
            RestorationReport.Entry(roomName: "リビング", wallName: "テレビ側", title: "棚受け", fastener: "スリムビス 45mm", restoration: .puttyRequired, isRestored: false),
            RestorationReport.Entry(roomName: "リビング", wallName: "テレビ側", title: "時計", fastener: nil, restoration: .pinHole, isRestored: true),
            RestorationReport.Entry(roomName: "寝室", wallName: "北の壁", title: "額", fastener: "画鋲", restoration: .pinHole, isRestored: false),
        ]
        var components = DateComponents()
        components.year = 2026
        components.month = 11
        components.day = 24
        components.hour = 12
        let date = Calendar(identifier: .gregorian).date(from: components)!

        let text = RestorationReport.makeText(entries: entries, date: date)
        XCTAssertTrue(text.hasPrefix("【原状回復リスト】2026/11/24 作成"))
        XCTAssertTrue(text.contains("■ リビング／テレビ側"))
        XCTAssertTrue(text.contains("■ 寝室／北の壁"))
        XCTAssertTrue(text.contains("・棚受け（スリムビス 45mm）… ビス穴・アンカー穴（パテ補修要）［未補修］"))
        XCTAssertTrue(text.contains("・時計… 画鋲・ピン穴のみ［補修済み］"))
        XCTAssertTrue(text.contains("合計：パテ補修 1か所（未補修 1）、ピン穴 2か所（未補修 1）"))
        // 同じ壁の見出しは1回だけ
        XCTAssertEqual(text.components(separatedBy: "■ リビング").count, 2)
    }

    func testShoppingListText() {
        let text = ShoppingListText.makeText(items: [
            .init(title: "スリムビス 45mm", summary: "1×4 → 2×4", isPurchased: true),
            .init(title: "2×4カット 2305mm × 2本", summary: "ラブリコ", isPurchased: false),
        ])
        XCTAssertEqual(text, "【DIY買い物メモ】\n☑︎ スリムビス 45mm\n　1×4 → 2×4\n☐ 2×4カット 2305mm × 2本\n　ラブリコ")
    }

    @MainActor
    func testPreviewProStore() {
        XCTAssertTrue(ProStore(previewIsPro: true).isPro)
        XCTAssertFalse(ProStore(previewIsPro: false).isPro)
    }
}
