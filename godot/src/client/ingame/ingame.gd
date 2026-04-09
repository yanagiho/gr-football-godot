class_name InGame
extends Node3D

## インゲームシーンの管理：プレイヤーのスポーン・退出・ボール管理を担当する
##
## フロー:
##   サーバー: _ready() で自分のプレイヤーとボールをスポーン、peer_disconnected でプレイヤー削除
##   クライアント: _ready() でサーバーに準備完了を通知 → サーバーがスポーン

const PLAYER_SCENE: PackedScene = preload("res://scenes/ingame/player.tscn")
const BALL_SCENE: PackedScene = preload("res://scenes/ingame/ball.tscn")

# スポーン位置（最大 11 人分）
const SPAWN_POSITIONS: Array[Vector3] = [
	Vector3(0.0, 0.5, 0.0),
	Vector3(5.0, 0.5, 0.0),
	Vector3(-5.0, 0.5, 0.0),
	Vector3(0.0, 0.5, 5.0),
	Vector3(0.0, 0.5, -5.0),
	Vector3(5.0, 0.5, 5.0),
	Vector3(-5.0, 0.5, -5.0),
	Vector3(5.0, 0.5, -5.0),
	Vector3(-5.0, 0.5, 5.0),
	Vector3(8.0, 0.5, 0.0),
	Vector3(-8.0, 0.5, 0.0),
]

const BALL_SPAWN_POSITION: Vector3 = Vector3(0.0, 0.5, 0.0)

@onready var _players: Node3D = $Players

var _ball: Ball
var _spawn_count: int = 0

func _ready() -> void:
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		_spawn_ball()
		_spawn_player(multiplayer.get_unique_id())
	else:
		# クライアントはサーバーに準備完了を通知
		_notify_ready.rpc_id(1)

func _on_peer_disconnected(peer_id: int) -> void:
	var player := _players.get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
		_spawn_count -= 1

@rpc("any_peer", "reliable")
func _notify_ready() -> void:
	# サーバーのみ処理する
	if not multiplayer.is_server():
		return
	_spawn_player(multiplayer.get_remote_sender_id())

func _spawn_player(peer_id: int) -> void:
	var player: PlayerCharacter = PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	_players.add_child(player, true)
	# ボールと重ならないようにスポーン位置をずらす
	var spawn_idx: int = (_spawn_count + 1) % SPAWN_POSITIONS.size()
	player.position = SPAWN_POSITIONS[spawn_idx]
	_spawn_count += 1
	print("プレイヤースポーン: %d" % peer_id)

func _spawn_ball() -> void:
	_ball = BALL_SCENE.instantiate()
	_ball.name = "Ball"
	add_child(_ball, true)
	_ball.position = BALL_SPAWN_POSITION
	print("ボールスポーン")

func get_ball() -> Ball:
	return _ball
