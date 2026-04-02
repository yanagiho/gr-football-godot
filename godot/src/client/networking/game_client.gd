class_name GameClient
extends Node

## サーバーへの WebSocket 接続を担当する

signal connected_to_server()
signal connection_failed()

const PORT: int = 9000

func connect_to_server(address: String) -> Error:
	var peer := WebSocketMultiplayerPeer.new()
	var error := peer.create_client("ws://%s:%d" % [address, PORT])
	if error != OK:
		push_error("接続失敗: %s" % error_string(error))
		connection_failed.emit()
		return error
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	return OK

func _on_connected() -> void:
	print("サーバーに接続しました")
	GameManager.local_peer_id = multiplayer.get_unique_id()
	connected_to_server.emit()

func _on_connection_failed() -> void:
	push_error("サーバーへの接続に失敗しました")
	connection_failed.emit()
