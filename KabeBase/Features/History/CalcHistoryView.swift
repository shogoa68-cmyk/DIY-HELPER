import SwiftUI
import SwiftData
import KabeBaseCore

/// 計算履歴の一覧
struct CalcHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ProStore.self) private var proStore
    @Query(sort: \DiyCalcRecord.createdAt, order: .reverse)
    private var records: [DiyCalcRecord]

    @State private var showsFavoritesOnly = false
    @State private var isPaywallPresented = false

    private var visibleRecords: [DiyCalcRecord] {
        showsFavoritesOnly ? records.filter(\.isFavorite) : records
    }

    var body: some View {
        List {
            if records.isEmpty {
                Text("ビス・下穴ナビや突っ張り計算で「履歴に保存」すると、ここに残ります。")
                    .foregroundStyle(.secondary)
            } else {
                Toggle("お気に入りだけ表示", isOn: $showsFavoritesOnly)
            }
            ForEach(visibleRecords) { record in
                NavigationLink(value: record) {
                    CalcRecordRow(record: record)
                }
                .swipeActions(edge: .leading) {
                    Button {
                        toggleFavorite(record)
                    } label: {
                        Label("お気に入り", systemImage: record.isFavorite ? "star.slash" : "star")
                    }
                    .tint(.yellow)
                    Button {
                        record.isInShoppingList.toggle()
                    } label: {
                        Label("買い物メモ", systemImage: "cart")
                    }
                    .tint(.blue)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        modelContext.delete(record)
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                }
            }
        }
        .paywallSheet(isPresented: $isPaywallPresented, reason: "お気に入り保存は Pro 機能です。")
    }

    private func toggleFavorite(_ record: DiyCalcRecord) {
        // お気に入りを外すのは無料版でもOK
        guard proStore.isPro || record.isFavorite else {
            isPaywallPresented = true
            return
        }
        record.isFavorite.toggle()
    }
}

struct CalcRecordRow: View {
    let record: DiyCalcRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.kind == .fastening ? "screwdriver" : "ruler")
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(record.title).font(.headline)
                    if record.isFavorite {
                        Image(systemName: "star.fill").font(.caption).foregroundStyle(.yellow)
                    }
                }
                Text(record.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(record.createdAt, format: .dateTime.year().month().day().hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

/// 計算履歴の詳細（保存した結果をもう一度表示）
struct CalcRecordDetailView: View {
    @Bindable var record: DiyCalcRecord
    @State private var isPickingWall = false
    @State private var memoToShow = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(record.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let calc = record.fasteningCalculation {
                    FasteningResultView(result: calc.result)
                } else if let calc = record.tensionPostCalculation {
                    TensionPostResultView(result: calc.result)
                    Button {
                        memoToShow = true
                    } label: {
                        Label("店員さんに見せる（カット依頼メモ）", systemImage: "text.bubble")
                            .frame(maxWidth: .infinity, minHeight: 36)
                    }
                    .buttonStyle(.borderedProminent)
                    .sheet(isPresented: $memoToShow) {
                        CutRequestMemoView(memo: calc.result.cutRequestMemo)
                    }
                } else {
                    Text("この記録は読み込めませんでした。").foregroundStyle(.secondary)
                }

                Toggle("買い物メモに入れる", isOn: $record.isInShoppingList)

                Button {
                    isPickingWall = true
                } label: {
                    Label("壁マップに記録", systemImage: "mappin.and.ellipse")
                        .frame(maxWidth: .infinity, minHeight: 32)
                }
                .buttonStyle(.bordered)

                if !record.annotations.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("この計算を記録した場所").font(.headline)
                        ForEach(record.annotations) { pin in
                            if let wall = pin.wall {
                                NavigationLink(value: wall) {
                                    Label("\(wall.room?.name ?? "")／\(wall.name)：\(pin.title)", systemImage: "mappin")
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(record.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPickingWall) {
            WallPickerSheet(record: record)
        }
    }
}
