# 茶室情報アプリ

信長の野望 出陣の茶室募集情報を表示するFlutterアプリケーション

## 機能

- 茶室募集情報の取得と表示
- カード形式での情報表示
- エリア（東京・神奈川）の優先表示
- 地図アプリとの連携
- WebView/リスト表示の切り替え

## 技術スタック

- Flutter
- WebView
- JavaScript
- Material Design 3

## 主な機能

1. データ取得
- WebViewを使用したスクレイピング
- JavaScriptによるデータ抽出
- エリアによる優先順位付け

2. UI
- Material Design 3に準拠したUI
- カード型レイアウト
- ローディング表示
- エリアごとの強調表示

3. 地図連携
- Google Mapsアプリの起動
- 位置情報の連携

## 開発環境

- Flutter 3.x
- Dart 3.x
- iOS 12.0以上

## 使用パッケージ

- webview_flutter: WebViewの実装
- webview_flutter_wkwebview: iOS WebView対応
- url_launcher: 外部アプリの起動

## インストール手順

```bash
# リポジトリのクローン
git clone https://github.com/nsadorou/chashitsu-finder.git

# 依存関係のインストール
cd chashitsu-finder
flutter pub get

# アプリの実行
flutter run