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
- XcodeGen 2.40 以降（`make debug` / `make app` は毎回再生成するため必須）

## 起動方法

通常の macOS アプリとして起動する場合:

```bash
cd /path/to/mp4Clipper
make debug
open build/Debug/ClipBatcher.app
```

`make app` でも同じ Debug ビルドの `.app` を `build/ClipBatcher.app` に作成します。

Xcode で開発・実行する場合:

```bash
cd /path/to/mp4Clipper
open ClipBatcher.xcodeproj
```

Xcode で `ClipBatcher` スキームを選択して Run してください。

既存の Xcode project を直接開く場合、`project.yml` を変更したときは、`xcodegen generate` で `ClipBatcher.xcodeproj` を再生成してください。

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

## 切り取り・エンコードの使い方

1. 動画を開くか、ウィンドウへドロップします。
2. 出力フォルダを設定します。
3. 切り取りの基準位置へシークしてマーカーを追加します（`M`）。
4. マーカーの「前」「後」の秒数を変更し、表示される開始・終了時刻を確認します。初期値は前5秒・後20秒です。動画の先頭・末尾を超える部分は短縮されます。
5. マーカー行の書き出しボタンで個別出力、チェックを付けて「選択を書き出し」で一括出力します。一括処理の中では順次書き出します。
6. `Clips` タブで結果を確認します。動画は出力先の `Clips/` に保存されます。

MP4 書き出しには `AVAssetExportPresetHighestQuality` を固定使用します。コーデック、ビットレート、解像度の指定 UI はありません。任意の開始点・終了点を別々に保存する方式ではなく、各マーカーと前後秒数で範囲を定義します。元動画は変更しません。

ショートカット: Space=再生/停止、左右矢印=5秒移動、Shift+左右矢印=1秒移動、M=マーカー追加、S=スクショ候補生成、Delete=選択マーカー削除。テキスト入力中は無効です。

## 動作確認

検証結果・既知の問題・未確認項目は [REQUIREMENTS_AUDIT.md](REQUIREMENTS_AUDIT.md) を参照してください。実装済みであることと、実機操作で検証済みであることは区別しています。

```bash
swift build
bash Tests/smoke-check.sh
```

スモークチェックは Apple 標準 API で4秒の無音 H.264 動画を生成し、実際のモデル・サービスを使ってマーカー操作、範囲計算、2秒の MP4 書き出し、画像保存を検証します。生成物の保存先を出力します。GUI 操作や音声の検証は含みません。`swift test` 用のテストターゲットではありません。
