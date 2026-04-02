class_name PlayerCharacter
extends CharacterBody3D

## プレイヤーキャラクターの移動・アニメーション・同期を担当する

const SPEED: float = 5.0
const GRAVITY: float = -20.0

@onready var _camera: Camera3D = $Camera3D
@onready var _sync: MultiplayerSynchronizer = $MultiplayerSynchronizer

var _animation_player: AnimationPlayer

func _ready() -> void:
	# ノード名（ピアID）からオーナーシップを設定
	if name.is_valid_int():
		set_multiplayer_authority(int(name))

	# 自分のプレイヤーのカメラのみ有効化
	_camera.current = is_multiplayer_authority()

	# AnimationPlayer をモデル内から検索
	_animation_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _animation_player:
		print("AnimationPlayer 発見。アニメーション一覧: ", _animation_player.get_animation_list())
		_play_animation_idle()

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	_apply_gravity(delta)
	_handle_movement()
	move_and_slide()
	_update_animation()

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
		# 移動方向にキャラクターを向ける
		rotation.y = atan2(-direction.x, -direction.z)
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

func _update_animation() -> void:
	if not _animation_player:
		return
	var is_moving: bool = Vector2(velocity.x, velocity.z).length() > 0.5
	if is_moving:
		_play_animation_run()
	else:
		_play_animation_idle()

func _play_animation_idle() -> void:
	if not _animation_player:
		return
	var animations: Array = _animation_player.get_animation_list()
	# idle / stand 系のアニメーションを探す
	for name in ["idle", "Idle", "stand", "Stand", "Take 001"]:
		if name in animations:
			if _animation_player.current_animation != name:
				_animation_player.play(name)
			return
	# 見つからなければ最初のアニメーションを再生
	if animations.size() > 0 and _animation_player.current_animation == "":
		_animation_player.play(animations[0])

func _play_animation_run() -> void:
	if not _animation_player:
		return
	var animations: Array = _animation_player.get_animation_list()
	# run / walk 系のアニメーションを探す
	for name in ["run", "Run", "walk", "Walk", "3D_run", "3D_walk"]:
		if name in animations:
			if _animation_player.current_animation != name:
				_animation_player.play(name)
			return
	# 見つからなければ最初のアニメーションを再生
	if animations.size() > 0:
		_animation_player.play(animations[0])
