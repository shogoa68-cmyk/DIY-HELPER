import SwiftUI
import StoreKit
import KabeBaseCore

/// Pro プランの案内と購入画面
struct PaywallView: View {
    /// どの機能から開いたか（説明の1行目に使う）
    var reason: String?

    @Environment(ProStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private struct Feature: Hashable {
        let icon: String
        let title: String
        let detail: String
    }

    private static let features: [Feature] = [
        Feature(icon: "square.stack.3d.up", title: "部屋・壁を無制限に登録",
                detail: "無料版は壁\(ProPlanPolicy.freeMaxWalls)面・ピン\(ProPlanPolicy.freeMaxPinsPerWall)個/面まで"),
        Feature(icon: "list.bullet.clipboard", title: "原状回復リストを書き出し", detail: "退去前の補修チェックや管理会社への連絡に"),
        Feature(icon: "photo.on.rectangle", title: "カット指示を画像で書き出し", detail: "ホームセンターでそのまま見せられる"),
        Feature(icon: "star", title: "お気に入り保存", detail: "よく使う計算結果をすぐ呼び出せる"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.yellow)
                        Text("KabeBase Pro").font(.largeTitle.bold())
                        if let reason {
                            Text(reason).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }

                    ForEach(Self.features, id: \.self) { feature in
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(feature.title).font(.headline)
                                Text(feature.detail).font(.footnote).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: feature.icon).foregroundStyle(Color.accentColor)
                        }
                    }

                    if store.isPro {
                        Label("Pro をご利用中です。ありがとうございます！", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(.green)
                    } else {
                        purchaseButtons
                    }

                    Text("計算機能（ビス・下穴・アンカー・突っ張り）は無料のまま、ずっと使えます。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Pro プラン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .task { await store.loadProducts() }
            .alert("お知らせ", isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
    }

    @ViewBuilder
    private var purchaseButtons: some View {
        VStack(spacing: 10) {
            if store.products.isEmpty {
                if store.isLoadingProducts {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("いまは購入できません。しばらくしてからお試しください。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            ForEach(store.products, id: \.id) { product in
                Button {
                    Task { await store.purchase(product) }
                } label: {
                    VStack(spacing: 2) {
                        Text(product.displayName).font(.headline)
                        Text(priceText(for: product)).font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.isPurchasing)
            }
            Button("購入を復元") {
                Task { await store.restore() }
            }
            .font(.subheadline)
            .padding(.top, 4)
        }
    }

    private func priceText(for product: Product) -> String {
        if product.subscription != nil {
            return "\(product.displayPrice) / 年"
        }
        return "\(product.displayPrice)（買い切り）"
    }
}

extension View {
    /// Pro が必要な機能で、無料版のときに購入画面を出す
    func paywallSheet(isPresented: Binding<Bool>, reason: String? = nil) -> some View {
        sheet(isPresented: isPresented) {
            PaywallView(reason: reason)
        }
    }
}

#Preview {
    PaywallView(reason: "無料版で登録できる壁は2面までです。")
        .environment(ProStore(previewIsPro: false))
}
