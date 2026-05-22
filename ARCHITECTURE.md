# Architecture

対象アプリの仮称は ClipBatcher です。リポジトリ名と SwiftPM ターゲット名は `mp4Clipper` としています。

## 採用技術

- SwiftUI: macOS UI
- AVPlayer: 動画再生
- AVAssetExportSession: クリップ書き出し
- AVAssetImageGenerator: 静止画抽出
- UserDefaults: 設定保存
- Swift Concurrency: 書き出し・画像抽出の非同期処理

## 構成

- `Models`: マーカー、スクショ候補、書き出しジョブ、動画メタデータ
- `ViewModels`: 画面状態と業務操作を管理
- `Services`: AVFoundation 処理、ファイル命名、時刻フォーマット
- `Views`: 3カラム構成の SwiftUI 画面

## Service の責務

- `VideoMetadataService`: 動画長、解像度、FPS の読み取り
- `ClipExportService`: 指定範囲の動画書き出しと進捗通知
- `ScreenshotExtractionService`: 指定時刻の画像抽出と PNG/JPEG 保存
- `FileNamingService`: Clips/Screenshots サブフォルダ作成、重複回避ファイル名生成
- `TimeFormattingService`: UI 表示とファイル名向けの時刻変換

## 状態管理

`EditorViewModel` が現在の `VideoProject`、`AVPlayer`、現在時刻、選択中マーカー、選択中スクショ、エラー表示を保持します。View は ViewModel の公開 API を呼び、AVFoundation の処理を直接持ちません。

`SettingsViewModel` は UserDefaults と同期し、デフォルト切り抜き秒、スクショオフセット、画像形式、出力先を保存します。

## 動画切り抜きフロー

1. マーカー時刻と前後オフセットから開始・終了秒を計算
2. `0...動画長` にクランプ
3. `start < end` を検証
4. `FileNamingService` が出力 URL を生成
5. `ClipExportService` が `AVAssetExportSession` で書き出し
6. `ClipExportJob` に進捗、成功、失敗を反映

## スクショ抽出フロー

1. 現在時刻、またはマーカー時刻 + 設定オフセットから候補時刻を生成
2. 動画長の範囲にクランプ
3. `AVAssetImageGenerator` で `NSImage` を生成
4. UI 上の候補一覧に追加
5. 選択された候補だけ PNG/JPEG として保存
