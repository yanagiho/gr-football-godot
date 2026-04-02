class_name MainMenu
extends Control

## メインメニュー：UIをコードで構築する

const INGAME_SCENE: String = "res://scenes/ingame/ingame.tscn"

var _address_input: LineEdit
var _connect_button: Button
var _start_server_button: Button
var _status_label: Label
var _client: GameClient

func _ready() -> void:
	print("MainMenu 起動")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

	_client = GameClient.new()
	add_child(_client)
	_client.connected_to_server.connect(_on_connected_to_server)
	_client.connection_failed.connect(_on_connection_failed)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.12, 0.12, 0.12)
	add_child(bg)

	var center := VBoxContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center.custom_minimum_size = Vector2(320.0, 240.0)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 12)
	add_child(center)

	var title := Label.new()
	title.text = "Grassroots Football"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	center.add_child(title)

	_address_input = LineEdit.new()
	_address_input.placeholder_text = "サーバーアドレス (例: 127.0.0.1)"
	_address_input.text = "127.0.0.1"
	center.add_child(_address_input)

	_connect_button = Button.new()
	_connect_button.text = "接続する"
	_connect_button.pressed.connect(_on_connect_pressed)
	center.add_child(_connect_button)

	_start_server_button = Button.new()
	_start_server_button.text = "サーバーを起動する"
	_start_server_button.pressed.connect(_on_start_server_pressed)
	center.add_child(_start_server_button)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_status_label)

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
