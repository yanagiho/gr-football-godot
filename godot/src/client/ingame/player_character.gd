class_name PlayerCharacter
extends CharacterBody3D

## プレイヤーキャラクターの移動・アニメーション・ボール操作・同期を担当する
## PlayerStateMachine でアクション遷移を管理する
##
## 操作（Unity版準拠）:
##   WASD / 矢印キー = 移動（ワールド空間・8方向）
##   Shift = ダッシュ
##   マウス左クリック / Enter = キック
##   Space = ジャンプ
##
## CharacterBody3D 自体は回転しない（カメラが子ノードのため）
## 回転は $ModelPivot のみに適用する

const SPEED_RUN: float = 5.0
const SPEED_DASH: float = 8.0
const GRAVITY: float = -20.0
const ROTATION_SPEED: float = 10.0
const KICK_LOCK_TIME: float = 0.8
const TURN_THRESHOLD: float = 2.0
const JUMP_VELOCITY: float = 6.0

@onready var _camera: Camera3D = $Camera3D
@onready var _model_pivot: Node3D = $ModelPivot
@onready var _sync: MultiplayerSynchronizer = $MultiplayerSynchronizer

var _animation_player: AnimationPlayer
var _state_machine: PlayerStateMachine
var _is_kicking: bool = false
var _kick_timer: float = 0.0
var _last_move_direction: Vector3 = Vector3(0.0, 0.0, -1.0)
var _model_rotation_y: float = PI  # 初期状態で画面奥（-Z）を向く

func _ready() -> void:
	if name.is_valid_int():
		set_multiplayer_authority(int(name))

	_camera.current = is_multiplayer_authority()

	_state_machine = PlayerStateMachine.new()
	_state_machine.action_changed.connect(_on_action_changed)

	_animation_player = _model_pivot.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _animation_player:
		_load_mixamo_animations()
		_play_action_animation(PlayerAction.Type.IDLE)
		_animation_player.animation_finished.connect(_on_animation_finished)

	_model_pivot.rotation.y = _model_rotation_y
	print("[Player] ready authority=%s is_server=%s" % [is_multiplayer_authority(), multiplayer.is_server()])

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	_apply_gravity(delta)
	_update_kick_timer(delta)
	_handle_movement(delta)
	_handle_action_input()
	_handle_dribble()
	move_and_slide()
	# CharacterBody3D 自体は絶対に回転させない（カメラ固定のため）
	rotation = Vector3.ZERO

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func _update_kick_timer(delta: float) -> void:
	if _is_kicking:
		_kick_timer -= delta
		if _kick_timer <= 0.0:
			_is_kicking = false
			_state_machine.force_transition(PlayerAction.Type.IDLE)

func _handle_movement(delta: float) -> void:
	if _is_kicking:
		velocity.x = move_toward(velocity.x, 0.0, SPEED_RUN)
		velocity.z = move_toward(velocity.z, 0.0, SPEED_RUN)
		return

	var input_dir: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)
	var direction := Vector3(input_dir.x, 0.0, input_dir.y).normalized()

	if direction != Vector3.ZERO:
		print("[Move] input=(%0.2f,%0.2f) dir=(%0.2f,%0.2f,%0.2f) vel=(%0.2f,%0.2f,%0.2f) pos=(%0.1f,%0.1f,%0.1f)" % [
			input_dir.x, input_dir.y,
			direction.x, direction.y, direction.z,
			velocity.x, velocity.y, velocity.z,
			global_position.x, global_position.y, global_position.z,
		])
		_last_move_direction = direction
		var is_near_ball: bool = _is_near_ball()
		var speed: float = SPEED_DASH if _is_dashing() else SPEED_RUN

		# 急旋回時は速度を落とす（ターン表現）
		var target_rot: float = atan2(direction.x, direction.z)
		var angle_diff: float = absf(angle_difference(_model_rotation_y, target_rot))
		if angle_diff > TURN_THRESHOLD:
			speed *= 0.4

		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

		# ModelPivot だけ回転
		_model_rotation_y = lerp_angle(_model_rotation_y, target_rot, ROTATION_SPEED * delta)
		_model_pivot.rotation.y = _model_rotation_y

		if is_near_ball:
			var next_action := PlayerAction.Type.DASH_DRIBBLE if _is_dashing() else PlayerAction.Type.DRIBBLE
			_state_machine.transition(next_action)
		else:
			var next_action := PlayerAction.Type.DASH if _is_dashing() else PlayerAction.Type.RUN
			_state_machine.transition(next_action)
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED_RUN)
		velocity.z = move_toward(velocity.z, 0.0, SPEED_RUN)
		_state_machine.transition(PlayerAction.Type.IDLE)

func _handle_action_input() -> void:
	if _is_kicking:
		return

	# キック: マウス左クリック / Enter
	if Input.is_action_just_pressed("kick"):
		print("[Player] kick pressed")
		_try_kick(Ball.KICK_FORCE)

	# ジャンプ: Space
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		_state_machine.force_transition(PlayerAction.Type.JUMP)

func _try_kick(force: float) -> void:
	var ball: Ball = _get_ball()
	if not ball:
		print("[Player] kick failed: ball not found")
		return
	if not ball.is_in_kick_range(global_position):
		print("[Player] kick failed: out of range (player=%s ball=%s)" % [global_position, ball.global_position])
		return

	_is_kicking = true
	_kick_timer = KICK_LOCK_TIME
	_state_machine.force_transition(PlayerAction.Type.KICK)

	var kick_dir := _last_move_direction.normalized()
	kick_dir.y = 0.0
	print("[Player] kicking dir=%s force=%.1f" % [kick_dir, force])

	if multiplayer.is_server():
		ball.kick(kick_dir, force)
	else:
		_request_kick.rpc_id(1, kick_dir, force)

@rpc("any_peer", "reliable")
func _request_kick(direction: Vector3, force: float) -> void:
	if not multiplayer.is_server():
		return
	var ball: Ball = _get_ball()
	if not ball:
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	var sender_node := get_parent().get_node_or_null(str(sender_id))
	if sender_node and ball.is_in_kick_range(sender_node.global_position):
		ball.kick(direction, clampf(force, 0.0, Ball.KICK_FORCE))

func _handle_dribble() -> void:
	if _is_kicking:
		return
	if not multiplayer.is_server():
		return

	var ball: Ball = _get_ball()
	if not ball:
		return
	if not ball.is_in_dribble_range(global_position):
		return

	var flat_vel := Vector3(velocity.x, 0.0, velocity.z)
	if flat_vel.length() < 0.5:
		return

	var target := global_position + _last_move_direction.normalized() * 1.0
	target.y = ball.global_position.y
	ball.dribble_toward(target)

func _is_dashing() -> bool:
	return Input.is_action_pressed("dash")

func _is_near_ball() -> bool:
	var ball: Ball = _get_ball()
	if not ball:
		return false
	return ball.is_in_dribble_range(global_position)

func _get_ball() -> Ball:
	var ingame := get_parent().get_parent() as InGame
	if ingame:
		return ingame.get_ball()
	return null

# --- アニメーション ---

func _load_mixamo_animations() -> void:
	var lib: AnimationLibrary = _animation_player.get_animation_library("")
	if not lib:
		lib = AnimationLibrary.new()
		_animation_player.add_animation_library("", lib)

	for anim_name: String in PlayerAction.ANIMATION_FBX:
		if lib.has_animation(anim_name):
			continue

		var fbx_path: String = PlayerAction.ANIMATION_FBX[anim_name]
		var scene: PackedScene = load(fbx_path) as PackedScene
		if not scene:
			push_warning("Animation FBX not found: %s" % fbx_path)
			continue

		var instance: Node = scene.instantiate()
		var src_ap: AnimationPlayer = instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if src_ap:
			var src_anims: PackedStringArray = src_ap.get_animation_list()
			if src_anims.size() > 0:
				var anim: Animation = src_ap.get_animation(src_anims[0]).duplicate()
				if anim_name in ["kick", "kick_pass", "heading", "slide_tackle", "jump"]:
					anim.loop_mode = Animation.LOOP_NONE
				lib.add_animation(anim_name, anim)
		instance.free()

	var loaded: PackedStringArray = _animation_player.get_animation_list()
	print("[Player] Loaded animations: ", loaded)

func _on_action_changed(_from: PlayerAction.Type, to: PlayerAction.Type) -> void:
	_play_action_animation(to)

func _on_animation_finished(anim_name: StringName) -> void:
	if _is_kicking:
		_is_kicking = false
		_kick_timer = 0.0
		_state_machine.force_transition(PlayerAction.Type.IDLE)

func _play_action_animation(action: PlayerAction.Type) -> void:
	if not _animation_player:
		return

	var target_name: String = PlayerAction.ANIMATION_NAMES.get(action, "")
	if target_name == "":
		return

	if _animation_player.has_animation(target_name):
		if _animation_player.current_animation != target_name:
			_animation_player.play(target_name)
		return

	match action:
		PlayerAction.Type.IDLE:
			_animation_player.stop()
		_:
			var available: PackedStringArray = _animation_player.get_animation_list()
			if available.size() > 0:
				_animation_player.play(available[0])
