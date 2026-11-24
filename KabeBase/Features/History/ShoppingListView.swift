import SwiftUI
import SwiftData

/// 買い物チェックリスト
struct ShoppingListView: View {
    @Query(filter: #Predicate<DiyCalcRecord> { $0.isInShoppingList == true }, sort: \DiyCalcRecord.createdAt)
    private var items: [DiyCalcRecord]

    var body: some View {
        List {
            if items.isEmpty {
                Text("計算画面で「買い物メモへ」を押すと、ここに追加されます。")
                    .foregroundStyle(.secondary)
            }
            ForEach(items) { item in
                ShoppingRow(item: item)
            }
            .onDelete { offsets in
                offsets.map { items[$0] }.forEach { $0.isInShoppingList = false }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if !items.isEmpty {
                    ShareLink(item: ShoppingListText.makeText(items: items.map {
                        ShoppingListText.Item(title: $0.title, summary: $0.summary, isPurchased: $0.isPurchased)
                    })) {
                        Label("共有", systemImage: "square.and.arrow.up")
                    }
                }
                if items.contains(where: \.isPurchased) {
                    Button("購入済みを片付ける") {
                        items.filter(\.isPurchased).forEach {
                            $0.isInShoppingList = false
                            $0.isPurchased = false
                        }
                    }
                }
            }
        }
    }
}

private struct ShoppingRow: View {
    @Bindable var item: DiyCalcRecord

    var body: some View {
        Button {
            item.isPurchased.toggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.isPurchased ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundStyle(item.isPurchased ? Color.green : Color.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .strikethrough(item.isPurchased)
                    Text(item.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: item.isPurchased)
    }
}
