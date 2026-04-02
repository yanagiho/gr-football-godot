class_name GameServer
extends Node

## WebSocket サーバーの起動・接続管理を担当する

const PORT: int = 9000
const MAX_PLAYERS: int = 11

func start() -> Error:
	var peer := WebSocketMultiplayerPeer.new()
	var error := peer.create_server(PORT)
	if error != OK:
		push_error("サーバー起動失敗: %s" % error_string(error))
		return error
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	print("サーバーをポート %d で起動しました" % PORT)
	return OK

func _on_peer_connected(peer_id: int) -> void:
	print("プレイヤー接続: %d" % peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	print("プレイヤー切断: %d" % peer_id)
