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

## Mixamoからダウンロードするアニメーション名との対応表
## ダウンロード後にファイル名に合わせて更新する
const ANIMATION_NAMES: Dictionary = {
	Type.IDLE:         "Idle",
	Type.RUN:          "Running",
	Type.DASH:         "Sprinting",
	Type.DRIBBLE:      "Soccer Dribble",
	Type.DASH_DRIBBLE: "Soccer Run Dribble",
	Type.KICK:         "Soccer Kick",
	Type.VOLLEY:       "Soccer Volley",
	Type.HEADING:      "Soccer Heading",
	Type.SLIDING:      "Sliding",
	Type.TACKLE:       "Soccer Tackle",
	Type.JUMP:         "Jump",
	Type.SAVING:       "Goalkeeper Dive",
	Type.PUNCHING:     "Goalkeeper Punch",
}
