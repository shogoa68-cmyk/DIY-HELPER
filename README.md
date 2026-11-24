# KabeBase（仮）

日本のDIY向け iOS アプリ。
「ビス・下穴・アンカー＆2×4突っ張り計算ナビ」で売り場・作業中に使ってもらい、
その結果を「壁の下地・間柱マップ＆賃貸原状回復ログ」に記録できるようにする。

- iOS 17+ / Swift 5.9+ / SwiftUI / SwiftData（100%オフライン）
- 単位はすべて mm
- 仕様書：[docs/SPEC.md](docs/SPEC.md)

## フォルダ構成

```
Packages/KabeBaseCore/   画面に依存しない計算エンジン＆DIY規格マスタ（Swift Package）
  Sources/KabeBaseCore/
    Standards/           1×4・2×4・合板・ビス長・ドリル径などのマスタ
    Fastening/           ビス長・下穴径・石膏ボードアンカー判定
    TensionPost/         2×4突っ張り柱のカット長
    WallMap/             2点キャリブレーション・間柱グリッド・キャンバス座標変換
    Plan/                無料／Pro の制限ルール
  Tests/KabeBaseCoreTests/  計算エンジンのユニットテスト
KabeBase/                iOS アプリ本体
  App/                   起動・4タブ
  Components/            チップ選択・折り返しレイアウト・結果カードなど共通部品
  Features/Fastening/    タブ2 ビス・下穴ナビ
  Features/TensionPost/  タブ3 2×4突っ張り計算
  Features/WallMap/      タブ1 部屋一覧・壁一覧・壁マップキャンバス・記録先の壁選択
  Features/History/      タブ4 原状回復ログ・計算履歴・買い物メモ
  Features/Pro/          StoreKit 2（ProStore）と購入画面
  Models/                SwiftData モデル（Room / WallSurface / WallAnnotation / DiyCalcRecord）
  Services/ImageStore    写真を Documents に JPEG 保存
KabeBaseTests/           SwiftData モデルのテスト
project.yml              XcodeGen 設定
KabeBase.storekit        シミュレータ用の課金テスト設定（本物のお金は動かない）
```

## Mac でのはじめ方

```bash
brew install xcodegen      # 初回だけ
xcodegen generate          # KabeBase.xcodeproj を作る
open KabeBase.xcodeproj
```

Xcode で `⌘U` を押すとテスト、`⌘R` でシミュレータ起動。
計算エンジンだけなら Xcode なしでもテストできます：

```bash
cd Packages/KabeBaseCore && swift test
```

## 課金（Pro）のテスト

`xcodegen generate` で作ったスキームには `KabeBase.storekit` が設定済みです。
シミュレータで ⌘R すると、本物のお金を使わずに購入・復元を試せます。
（Xcode の Debug → StoreKit → Manage Transactions で購入の取り消しもできます）

| 商品ID | 種類 | 仮の価格 |
|---|---|---|
| `com.example.kabebase.pro.lifetime` | 買い切り（非消耗型） | ¥1,480 |
| `com.example.kabebase.pro.yearly` | 年額（自動更新サブスク） | ¥480 |

公開するときは App Store Connect で同じ商品IDを登録し、IDを自分のものに変えてください（`ProStore.ProductID` と `KabeBase.storekit`）。

> `com.example.kabebase` は仮のバンドルIDです。実機で動かす・公開する前に自分のものに変えてください。

## 開発ステップ

- [x] Step 1：プロジェクト雛形・SwiftData モデル・計算エンジン・ユニットテスト
- [x] Step 2：タブ2（ビス・下穴ナビ）とタブ3（2×4突っ張り）の画面
- [x] Step 3：タブ1（壁マップキャンバス）
- [x] Step 4：計算→ピン転記、タブ4（履歴・原状回復）、StoreKit 2 の Pro 制限
