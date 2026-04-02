class_name PlayerCharacter
extends CharacterBody3D

## プレイヤーキャラクターの移動・同期を担当する
## ノード名にピアIDを設定することで multiplayer_authority を自動決定する

const SPEED: float = 5.0
const GRAVITY: float = -20.0

@onready var _camera: Camera3D = $Camera3D
@onready var _sync: MultiplayerSynchronizer = $MultiplayerSynchronizer

func _ready() -> void:
	# ノード名（ピアID）からオーナーシップを設定
	if name.is_valid_int():
		set_multiplayer_authority(int(name))

	# 自分のプレイヤーのカメラのみ有効化
	_camera.current = is_multiplayer_authority()

func _physics_process(delta: float) -> void:
	# 操作権を持つクライアントのみ入力処理を行う
	if not is_multiplayer_authority():
		return

	_apply_gravity(delta)
	_handle_movement()
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func _handle_movement() -> void:
	var input_dir: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)
	var direction := Vector3(input_dir.x, 0.0, input_dir.y).normalized()
	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
