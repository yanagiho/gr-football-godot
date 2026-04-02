class_name MainMenu
extends Control

## メインメニュー：サーバー起動またはサーバーへの接続を行う

const INGAME_SCENE: String = "res://scenes/ingame/ingame.tscn"

@onready var _address_input: LineEdit = $VBoxContainer/AddressInput
@onready var _connect_button: Button = $VBoxContainer/ConnectButton
@onready var _start_server_button: Button = $VBoxContainer/StartServerButton
@onready var _status_label: Label = $VBoxContainer/StatusLabel

var _client: GameClient

func _ready() -> void:
	_client = GameClient.new()
	add_child(_client)
	_client.connected_to_server.connect(_on_connected_to_server)
	_client.connection_failed.connect(_on_connection_failed)

	_connect_button.pressed.connect(_on_connect_pressed)
	_start_server_button.pressed.connect(_on_start_server_pressed)

func _on_connect_pressed() -> void:
	var address: String = _address_input.text.strip_edges()
	if address.is_empty():
		_status_label.text = "アドレスを入力してください"
		return
	_status_label.text = "接続中..."
	_connect_button.disabled = true
	_start_server_button.disabled = true
	_client.connect_to_server(address)

func _on_start_server_pressed() -> void:
	var server := GameServer.new()
	add_child(server)
	var error := server.start()
	if error != OK:
		_status_label.text = "サーバー起動に失敗しました"
		return
	GameManager.is_server = true
	GameManager.local_peer_id = 1
	get_tree().change_scene_to_file(INGAME_SCENE)

func _on_connected_to_server() -> void:
	get_tree().change_scene_to_file(INGAME_SCENE)

func _on_connection_failed() -> void:
	_status_label.text = "接続に失敗しました"
	_connect_button.disabled = false
	_start_server_button.disabled = false
