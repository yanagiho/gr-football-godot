class_name PlayerAction

## プレイヤーが取れるアクションの定義
## アクション.xlsx の内容をそのままコードに反映

enum Type {
	IDLE = 0,         # 待機
	RUN = 1,          # 走り
	DASH = 2,         # ダッシュ
	DRIBBLE = 3,      # ドリブル
	DASH_DRIBBLE = 4, # ダッシュドリブル
	KICK = 5,         # キック
	VOLLEY = 6,       # ボレー
	HEADING = 7,      # ヘディング
	SLIDING = 8,      # スライディング
	TACKLE = 9,       # タックル
	JUMP = 10,        # ジャンプ
	SAVING = 11,      # セービング（GK専用）
	PUNCHING = 12,    # パンチング（GK専用）
}

## アクション名（日本語）
const DISPLAY_NAMES: Dictionary = {
	Type.IDLE:         "待機",
	Type.RUN:          "走り",
	Type.DASH:         "ダッシュ",
	Type.DRIBBLE:      "ドリブル",
	Type.DASH_DRIBBLE: "ダッシュドリブル",
	Type.KICK:         "キック",
	Type.VOLLEY:       "ボレー",
	Type.HEADING:      "ヘディング",
	Type.SLIDING:      "スライディング",
	Type.TACKLE:       "タックル",
	Type.JUMP:         "ジャンプ",
	Type.SAVING:       "セービング",
	Type.PUNCHING:     "パンチング",
}

## アニメーション名との対応表（AnimationPlayer に登録する名前）
const ANIMATION_NAMES: Dictionary = {
	Type.IDLE:         "idle",
	Type.RUN:          "run",
	Type.DASH:         "dash",
	Type.DRIBBLE:      "dribble",
	Type.DASH_DRIBBLE: "dribble",      # ドリブルを流用
	Type.KICK:         "kick",
	Type.VOLLEY:       "kick_pass",     # パスモーションを流用
	Type.HEADING:      "heading",
	Type.SLIDING:      "slide_tackle",
	Type.TACKLE:       "slide_tackle",  # スライディングを流用
	Type.JUMP:         "jump",
	Type.SAVING:       "",              # 未実装（GK専用）
	Type.PUNCHING:     "",              # 未実装（GK専用）
}

## アクション → Mixamo FBX ファイルパスの対応表
const ANIMATION_FBX: Dictionary = {
	"idle":         "res://assets/animations/mixamo/idle.fbx",
	"run":          "res://assets/animations/mixamo/run.fbx",
	"dash":         "res://assets/animations/mixamo/run.fbx",  # Run を流用
	"dribble":      "res://assets/animations/mixamo/dribble.fbx",
	"kick":         "res://assets/animations/mixamo/kick.fbx",
	"kick_pass":    "res://assets/animations/mixamo/kick_pass.fbx",
	"heading":      "res://assets/animations/mixamo/header.fbx",
	"slide_tackle": "res://assets/animations/mixamo/slide_tackle.fbx",
	"jump":         "res://assets/animations/mixamo/jump.fbx",
}
