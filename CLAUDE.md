# Grassroots Football (Godot)

## プロジェクト概要

3Dマルチプレイヤーサッカーゲーム。
インターネット越しに複数人でプレイできることを最終目標とする。

## 技術スタック

| レイヤー | 技術 |
|----------|------|
| クライアント / サーバー | Godot 4 (GDScript, 3D) |
| マッチメイキング | Cloudflare Workers + Durable Objects |
| 通信 | WebSocket（ENetではなくWebSocketMultiplayerPeerを使う） |

## リポジトリ構成

```
gr-football-godot/
├── CLAUDE.md
├── .gitignore
├── godot/                     # Godot プロジェクト（クライアント・サーバー共用）
│   ├── project.godot
│   ├── src/
│   │   ├── shared/            # クライアント・サーバー両方で使うコード
│   │   │   ├── models/        # データ定義（ValueObject相当）
│   │   │   └── utils/
│   │   ├── client/            # クライアント専用（描画・入力・UI）
│   │   │   ├── ingame/        # インゲーム処理
│   │   │   └── outgame/       # アウトゲーム処理（ロビー・マッチング画面）
│   │   └── server/            # サーバー専用（ゲームロジック・状態同期）
│   └── scenes/
│       ├── ingame/
│       └── outgame/
└── matchmaking/               # Cloudflare Workers
    ├── wrangler.toml
    └── src/
        ├── index.ts           # Workers エントリポイント
        └── rooms/             # Durable Objects（ルーム管理）
```

## アーキテクチャ

```
[Godot Client]
    │
    ├─ HTTP/WS ──▶ [Cloudflare Workers + Durable Objects]
    │                  ロビー・マッチメイキング・ルーム管理
    │
    └─ WebSocket ──▶ [Godot Dedicated Server (VPS)]
                        ゲームシミュレーション・状態同期
```

## GDScript コーディング規約

### 命名規則

```gdscript
# クラス名: PascalCase
class_name PlayerCharacter

# 変数・関数: snake_case
var player_speed: float = 5.0
func move_player() -> void:
    pass

# 定数: ALL_CAPS
const MAX_PLAYERS: int = 11

# シグナル: 過去形または動詞_名詞
signal player_joined(player_id: String)
signal ball_kicked()

# プライベートメンバー: アンダースコアプレフィックス
var _is_initialized: bool = false
func _setup() -> void:
    pass
```

### ファイル構成（各スクリプトの記述順）

```gdscript
class_name Foo
extends Node

# 1. シグナル
# 2. enum
# 3. 定数
# 4. @export 変数
# 5. パブリック変数
# 6. プライベート変数
# 7. @onready
# 8. 組み込み関数（_ready, _process等）
# 9. パブリック関数
# 10. プライベート関数
```

### 型アノテーション

- **必ず型を明示する**（推論に頼らない）
- 戻り値の型も必ず書く

```gdscript
# Good
var speed: float = 5.0
func get_player_name() -> String:
    return _name

# Bad
var speed = 5
func get_player_name():
    return _name
```

## ブランチ戦略

```
main        ← リリース済み（直接pushしない）
develop     ← 開発統合ブランチ
feature/*   ← 新機能
fix/*       ← バグ修正
```

PRは必ず `develop` にマージする。`main` へのマージはリリース時のみ。

## やってはいけないこと

- `main` ブランチに直接 push しない
- クライアント専用コードを `src/shared/` に置かない
- サーバー専用コードをクライアントに読み込まない（`OS.has_feature("dedicated_server")` で分岐）
- ENet を使わない（Cloudflare が WebSocket のみ対応のため）
- `.godot/` フォルダをコミットしない

## Cloudflare 開発

```bash
# Wrangler CLI（Cloudflare Workers開発ツール）
cd matchmaking
npx wrangler dev          # ローカル開発サーバー起動
npx wrangler deploy       # 本番デプロイ
```

## Godot サーバー起動（ローカルテスト）

```bash
# ヘッドレス（サーバーモード）で起動
godot --headless -- --server
```

## 開発フェーズ

- **Phase 1**: ローカルでGodotクライアント + Godotサーバー間の接続・移動同期 ✅ 完了
- **Phase 2**: Cloudflare WorkersでマッチメイキングAPI実装
- **Phase 3**: VPSにGodotサーバーをデプロイ、Cloudflare経由で接続

## 開発メンバー

| 役割 | 担当 |
|------|------|
| 開発者 | yanagi（オーナー・意思決定・実装） |
| AIアシスタント | Claude（コード実装・設計サポート・調査） |

作業は基本的に **yanagi の指示のもと Claude が実装** し、動作確認は yanagi が行う。

---

## 現在の進捗（2026-04-05時点）

### 完了済み
- WebSocketマルチプレイヤー基盤（サーバー起動・接続・移動同期）
- プレイヤーモデル（Player.fbx）をGodotにインポート済み
- ボールモデル（Football_01.fbx）をGodotにインポート済み
- Mixamoアニメーションのダウンロード・配置・ランタイム読み込み実装
- `--server` コマンドライン引数による自動サーバー起動
- 現在のブランチ: `feature/animation-state-machine`

### 次にやること（優先順）
1. **アニメーション動作確認**（トラックパスが正しくキャラクターに適用されるかGUIで確認）
2. Phase 2: Cloudflare Workersマッチメイキング実装

### アニメーションシステム
- `src/shared/models/player_action.gd` — アクションenum・ANIMATION_NAMES・ANIMATION_FBX対応表
- `src/shared/models/player_state_machine.gd` — アクション.xlsxの遷移表を実装
- `src/client/ingame/player_character.gd` — ステートマシン連携・Mixamo FBXランタイム読み込み
- 入力: WASD移動、Shift でダッシュ
- アニメーション読み込み方式: 起動時に各FBXをPackedSceneとしてロード → AnimationPlayerから抽出 → プレイヤーのAnimationLibraryに登録

### Mixamoアニメーション配置（`assets/animations/mixamo/`）
| ファイル | アクション | 備考 |
|---------|-----------|------|
| `idle.fbx` | IDLE（待機） | |
| `run.fbx` | RUN（走り） | DASHでも流用 |
| `dribble.fbx` | DRIBBLE（ドリブル） | DASH_DRIBBLEでも流用 |
| `kick.fbx` | KICK（キック） | |
| `kick_pass.fbx` | VOLLEY（ボレー） | パスモーション流用 |
| `header.fbx` | HEADING（ヘディング） | |
| `slide_tackle.fbx` | SLIDING / TACKLE | 両方で流用 |
| `jump.fbx` | JUMP（ジャンプ） | |
| `crouch.fbx` | 未割当 | PlayerActionに未定義 |
| `interact.fbx` | 未割当 | PlayerActionに未定義 |
| `celebrate.fbx` | 未割当 | PlayerActionに未定義 |
| `down.fbx` | 未割当 | PlayerActionに未定義 |
| `celebrate_jump.fbx` | 予備 | |
| `celebrate_dance.fbx` | 予備 | |

### 未整理アニメーション（`assets/animations/maximo/`）
- Mixamoからダウンロードした生ファイル（70+個）
- ゴールキーパー用アニメ多数、Soccer Game Pack含む
- 必要に応じて `mixamo/` にリネームコピーして使う

### 既知の注意点
- `project.godot` のメインシーン設定は `run/main_scene`（`config/run/main_scene` ではない）
- `game_manager.gd` は autoload のため `class_name` を付けない
- UI はシーンファイルではなくコード（`_build_ui()`）で構築している
- Godot バージョン: 4.6.2
- FBXファイルはGodotエディタで一度開いてインポートが必要（`.import`ファイル生成）

### アセット
| ファイル | 場所 | 状態 |
|---------|------|------|
| Player.fbx | `assets/models/characters/` | インポート済み・アニメーションは Take 001 のみ |
| Football_01.fbx | `assets/models/ball/` | インポート済み・未配置 |
| Mixamo FBX (14個) | `assets/animations/mixamo/` | インポート済み・ランタイム読み込み実装済み |
| 3D_run/walk/dash.anim | `assets/animations/` | Unity形式・Godotでは使用不可 |
