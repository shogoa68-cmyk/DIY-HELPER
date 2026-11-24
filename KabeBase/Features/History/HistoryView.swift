import SwiftUI
import SwiftData

/// タブ4：履歴・原状回復ログ
struct HistoryView: View {
    enum HistorySection: String, CaseIterable, Identifiable {
        case restoration
        case calculations
        case shopping

        var id: String { rawValue }

        var title: String {
            switch self {
            case .restoration: return "原状回復"
            case .calculations: return "計算履歴"
            case .shopping: return "買い物メモ"
            }
        }
    }

    @Environment(ProStore.self) private var proStore
    @State private var section: HistorySection = .restoration
    @State private var isPaywallPresented = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("表示", selection: $section) {
                    ForEach(HistorySection.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .bottom])

                switch section {
                case .restoration: RestorationLogView()
                case .calculations: CalcHistoryView()
                case .shopping: ShoppingListView()
                }
            }
            .navigationTitle("履歴")
            .navigationDestination(for: WallSurface.self) { wall in
                WallEditorView(wall: wall)
            }
            .navigationDestination(for: DiyCalcRecord.self) { record in
                CalcRecordDetailView(record: record)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isPaywallPresented = true
                    } label: {
                        Label(proStore.isPro ? "Pro利用中" : "Pro", systemImage: proStore.isPro ? "crown.fill" : "crown")
                    }
                }
            }
            .paywallSheet(isPresented: $isPaywallPresented)
        }
    }
}
