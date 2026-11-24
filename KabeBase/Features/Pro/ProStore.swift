import Foundation
import Observation
import StoreKit

/// Pro プランの購入状態を管理する係（StoreKit 2）。
///
/// - 買い切り（非消耗型）と年額（自動更新サブスク）のどちらかを持っていれば Pro。
/// - 購入情報はアップルのサーバーと端末が管理するので、自前のサーバーは要らない。
@MainActor
@Observable
final class ProStore {
    enum ProductID {
        static let lifetime = "com.example.kabebase.pro.lifetime"
        static let yearly = "com.example.kabebase.pro.yearly"
        static let all: Set<String> = [lifetime, yearly]
    }

    private(set) var products: [Product] = []
    private(set) var isPro = false
    private(set) var isLoadingProducts = false
    private(set) var isPurchasing = false
    var errorMessage: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init() {
        // アプリの外（別の端末・ファミリー共有・返金など）で起きた購入の変化を受け取る
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                }
                await self?.refreshEntitlements()
            }
        }
    }

    /// プレビュー・テスト用（StoreKit に接続しない）
    init(previewIsPro: Bool) {
        isPro = previewIsPro
    }

    func start() async {
        await loadProducts()
        await refreshEntitlements()
    }

    func loadProducts() async {
        guard products.isEmpty, !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            products = try await Product.products(for: ProductID.all).sorted { $0.price > $1.price }
        } catch {
            errorMessage = "商品情報を読み込めませんでした。通信状況を確認してください。"
        }
    }

    /// 今持っている権利（買い切り・有効なサブスク）を確認する
    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  ProductID.all.contains(transaction.productID),
                  transaction.revocationDate == nil else { continue }
            if let expiration = transaction.expirationDate, expiration < .now { continue }
            active = true
        }
        isPro = active
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    errorMessage = "購入を確認できませんでした。"
                    return
                }
                await transaction.finish()
                await refreshEntitlements()
            case .pending:
                errorMessage = "購入の承認待ちです。承認されると自動でProになります。"
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = "購入できませんでした。（\(error.localizedDescription)）"
        }
    }

    /// 機種変更などで購入を復元する
    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !isPro { errorMessage = "復元できる購入が見つかりませんでした。" }
        } catch {
            errorMessage = "復元できませんでした。（\(error.localizedDescription)）"
        }
    }
}
