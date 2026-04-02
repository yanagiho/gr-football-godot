class_name PlayerStateMachine

## アニメーション遷移ルールを管理するステートマシン
## アクション.xlsx の遷移表（○/×）をそのままコードに反映
##
## 使い方:
##   var sm = PlayerStateMachine.new()
##   if sm.can_transition(current_action, next_action):
##       sm.transition(next_action)

signal action_changed(from: PlayerAction.Type, to: PlayerAction.Type)

## 遷移テーブル（アクション.xlsx より）
## キー: 現在のアクション
## 値: 遷移できるアクションの配列
const TRANSITIONS: Dictionary = {
	# 待機 → 全て遷移可能
	PlayerAction.Type.IDLE: [
		PlayerAction.Type.RUN,
		PlayerAction.Type.DASH,
		PlayerAction.Type.DRIBBLE,
		PlayerAction.Type.DASH_DRIBBLE,
		PlayerAction.Type.KICK,
		PlayerAction.Type.VOLLEY,
		PlayerAction.Type.HEADING,
		PlayerAction.Type.SLIDING,
		PlayerAction.Type.TACKLE,
		PlayerAction.Type.JUMP,
		PlayerAction.Type.SAVING,
		PlayerAction.Type.PUNCHING,
	],
	# キック → 遷移なし（モーション終了後に待機へ戻る）
	PlayerAction.Type.KICK: [],
	# 走り → 全て遷移可能
	PlayerAction.Type.RUN: [
		PlayerAction.Type.IDLE,
		PlayerAction.Type.RUN,
		PlayerAction.Type.DASH,
		PlayerAction.Type.DRIBBLE,
		PlayerAction.Type.DASH_DRIBBLE,
		PlayerAction.Type.KICK,
		PlayerAction.Type.VOLLEY,
		PlayerAction.Type.HEADING,
		PlayerAction.Type.SLIDING,
		PlayerAction.Type.TACKLE,
		PlayerAction.Type.JUMP,
		PlayerAction.Type.SAVING,
		PlayerAction.Type.PUNCHING,
	],
	# ダッシュ → 全て遷移可能
	PlayerAction.Type.DASH: [
		PlayerAction.Type.IDLE,
		PlayerAction.Type.RUN,
		PlayerAction.Type.DASH,
		PlayerAction.Type.DRIBBLE,
		PlayerAction.Type.DASH_DRIBBLE,
		PlayerAction.Type.KICK,
		PlayerAction.Type.VOLLEY,
		PlayerAction.Type.HEADING,
		PlayerAction.Type.SLIDING,
		PlayerAction.Type.TACKLE,
		PlayerAction.Type.JUMP,
		PlayerAction.Type.SAVING,
		PlayerAction.Type.PUNCHING,
	],
	# ドリブル → 一部のみ遷移可能
	PlayerAction.Type.DRIBBLE: [
		PlayerAction.Type.IDLE,
		PlayerAction.Type.RUN,
		PlayerAction.Type.DASH,
		PlayerAction.Type.DRIBBLE,
		PlayerAction.Type.DASH_DRIBBLE,
		PlayerAction.Type.TACKLE,
		PlayerAction.Type.JUMP,
	],
	# ダッシュドリブル → 一部のみ遷移可能
	PlayerAction.Type.DASH_DRIBBLE: [
		PlayerAction.Type.IDLE,
		PlayerAction.Type.RUN,
		PlayerAction.Type.DASH,
		PlayerAction.Type.DRIBBLE,
		PlayerAction.Type.DASH_DRIBBLE,
		PlayerAction.Type.TACKLE,
		PlayerAction.Type.JUMP,
	],
	# ボレー → 走り・ダッシュのみ
	PlayerAction.Type.VOLLEY: [
		PlayerAction.Type.IDLE,
		PlayerAction.Type.RUN,
		PlayerAction.Type.DASH,
	],
	# ヘディング → 走り・ダッシュのみ
	PlayerAction.Type.HEADING: [
		PlayerAction.Type.IDLE,
		PlayerAction.Type.RUN,
		PlayerAction.Type.DASH,
	],
	# スライディング → 一部のみ遷移可能
	PlayerAction.Type.SLIDING: [
		PlayerAction.Type.IDLE,
		PlayerAction.Type.RUN,
		PlayerAction.Type.DASH,
		PlayerAction.Type.DRIBBLE,
		PlayerAction.Type.DASH_DRIBBLE,
		PlayerAction.Type.SLIDING,
		PlayerAction.Type.TACKLE,
		PlayerAction.Type.JUMP,
	],
	# タックル → 一部のみ遷移可能
	PlayerAction.Type.TACKLE: [
		PlayerAction.Type.IDLE,
		PlayerAction.Type.RUN,
		PlayerAction.Type.DASH,
		PlayerAction.Type.DRIBBLE,
		PlayerAction.Type.DASH_DRIBBLE,
		PlayerAction.Type.SLIDING,
		PlayerAction.Type.TACKLE,
		PlayerAction.Type.JUMP,
	],
	# ジャンプ → 全て遷移可能
	PlayerAction.Type.JUMP: [
		PlayerAction.Type.IDLE,
		PlayerAction.Type.RUN,
		PlayerAction.Type.DASH,
		PlayerAction.Type.DRIBBLE,
		PlayerAction.Type.DASH_DRIBBLE,
		PlayerAction.Type.KICK,
		PlayerAction.Type.VOLLEY,
		PlayerAction.Type.HEADING,
		PlayerAction.Type.SLIDING,
		PlayerAction.Type.TACKLE,
		PlayerAction.Type.JUMP,
		PlayerAction.Type.SAVING,
		PlayerAction.Type.PUNCHING,
	],
	# セービング（GK）→ 全て遷移可能
	PlayerAction.Type.SAVING: [
		PlayerAction.Type.IDLE,
		PlayerAction.Type.RUN,
		PlayerAction.Type.DASH,
		PlayerAction.Type.DRIBBLE,
		PlayerAction.Type.DASH_DRIBBLE,
		PlayerAction.Type.KICK,
		PlayerAction.Type.VOLLEY,
		PlayerAction.Type.HEADING,
		PlayerAction.Type.SLIDING,
		PlayerAction.Type.TACKLE,
		PlayerAction.Type.JUMP,
		PlayerAction.Type.SAVING,
		PlayerAction.Type.PUNCHING,
	],
	# パンチング（GK）→ 全て遷移可能
	PlayerAction.Type.PUNCHING: [
		PlayerAction.Type.IDLE,
		PlayerAction.Type.RUN,
		PlayerAction.Type.DASH,
		PlayerAction.Type.DRIBBLE,
		PlayerAction.Type.DASH_DRIBBLE,
		PlayerAction.Type.KICK,
		PlayerAction.Type.VOLLEY,
		PlayerAction.Type.HEADING,
		PlayerAction.Type.SLIDING,
		PlayerAction.Type.TACKLE,
		PlayerAction.Type.JUMP,
		PlayerAction.Type.SAVING,
		PlayerAction.Type.PUNCHING,
	],
}

var current_action: PlayerAction.Type = PlayerAction.Type.IDLE

func can_transition(to: PlayerAction.Type) -> bool:
	if not TRANSITIONS.has(current_action):
		return false
	return to in TRANSITIONS[current_action]

func transition(to: PlayerAction.Type) -> bool:
	if not can_transition(to):
		return false
	var from: PlayerAction.Type = current_action
	current_action = to
	action_changed.emit(from, to)
	return true

func force_transition(to: PlayerAction.Type) -> void:
	var from: PlayerAction.Type = current_action
	current_action = to
	action_changed.emit(from, to)
