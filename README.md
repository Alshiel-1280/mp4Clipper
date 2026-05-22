# ClipBatcher / mp4Clipper

ClipBatcher は、長尺の配信アーカイブ動画から SNS 投稿用の短い動画クリップとスクリーンショット候補をまとめて作る macOS ネイティブアプリです。このリポジトリ名と実行ターゲット名は `mp4Clipper` です。

AI、クラウド連携、FFmpeg は使わず、動画再生・書き出し・静止画抽出は Apple 標準の AVFoundation を使います。

## 主な機能

- `.mp4`, `.mov`, `.m4v` の読み込み
- AVPlayer による再生、停止、シーク、1秒/5秒移動
- 現在時刻へのマーカー追加、メモ、個別切り抜き秒数調整
- マーカー前後の範囲を AVAssetExportSession で MP4 書き出し
- 現在時刻またはマーカー周辺のスクリーンショット候補生成
- 現在時刻のスクリーンショット即保存
- スクリーンショット候補のプレビュー、選択、まとめ保存
- 出力フォルダ、画像形式、デフォルト秒数、スクショオフセットの設定保存

## 開発環境

- macOS 13 以降
- Xcode 15 以降推奨
- Swift 5.9 以降
- XcodeGen（`project.yml` から Xcode project を再生成する場合）

## 起動方法

通常の macOS アプリとして起動する場合:

```bash
cd /Users/ryo1280/cursor/mp4Clipper
make debug
open build/Debug/ClipBatcher.app
```

`make app` でも同じ Debug ビルドの `.app` を `build/ClipBatcher.app` に作成します。

Xcode で開発・実行する場合:

```bash
cd /Users/ryo1280/cursor/mp4Clipper
open ClipBatcher.xcodeproj
```

Xcode で `ClipBatcher` スキームを選択して Run してください。

`project.yml` を変更した場合だけ、`xcodegen generate` で `ClipBatcher.xcodeproj` を再生成してください。

SwiftPM executable としてビルド確認する場合:

```bash
swift build
```

`swift build` は SwiftPM の仕様上 `.app` ではなく実行ファイルを生成します。アプリ形式が必要な場合は `make debug` または Xcode の `ClipBatcher` スキームで Debug ビルドしてください。

## 現時点の制限事項

- フレーム単位移動は未実装です。
- プロジェクト保存は未実装です。
- 縦動画クロップ、字幕、テロップ、SNS 投稿連携は対象外です。
- 複数動画をまたぐ管理は対象外です。
