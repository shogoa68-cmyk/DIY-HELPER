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
    WallMap/             2点キャリブレーション・間柱グリッド計算
    Plan/                無料／Pro の制限ルール
  Tests/KabeBaseCoreTests/  計算エンジンのユニットテスト
KabeBase/                iOS アプリ本体
  App/                   起動・4タブ
  Components/            チップ選択・折り返しレイアウト・結果カードなど共通部品
  Features/Fastening/    タブ2 ビス・下穴ナビ
  Features/TensionPost/  タブ3 2×4突っ張り計算
  Models/                SwiftData モデル（Room / WallSurface / WallAnnotation / DiyCalcRecord）
  Services/ImageStore    写真を Documents に JPEG 保存
KabeBaseTests/           SwiftData モデルのテスト
project.yml              XcodeGen 設定
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

> `com.example.kabebase` は仮のバンドルIDです。実機で動かす・公開する前に自分のものに変えてください。

## 開発ステップ

- [x] Step 1：プロジェクト雛形・SwiftData モデル・計算エンジン・ユニットテスト
- [x] Step 2：タブ2（ビス・下穴ナビ）とタブ3（2×4突っ張り）の画面
- [ ] Step 3：タブ1（壁マップキャンバス）
- [ ] Step 4：計算→ピン転記、タブ4（履歴・原状回復）、StoreKit 2 の Pro 制限
