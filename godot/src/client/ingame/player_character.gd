class_name PlayerCharacter
extends CharacterBody3D

## プレイヤーキャラクターの移動・アニメーション・同期を担当する
## PlayerStateMachine でアクション遷移を管理する

const SPEED_RUN: float = 5.0
const SPEED_DASH: float = 8.0
const GRAVITY: float = -20.0

@onready var _camera: Camera3D = $Camera3D
@onready var _sync: MultiplayerSynchronizer = $MultiplayerSynchronizer

var _animation_player: AnimationPlayer
var _state_machine: PlayerStateMachine

func _ready() -> void:
	if name.is_valid_int():
		set_multiplayer_authority(int(name))

	_camera.current = is_multiplayer_authority()

	_state_machine = PlayerStateMachine.new()
	_state_machine.action_changed.connect(_on_action_changed)

	_animation_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _animation_player:
		_load_mixamo_animations()
		_play_action_animation(PlayerAction.Type.IDLE)

func _physics_process(delta: float) -> void:
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
		var speed: float = SPEED_DASH if _is_dashing() else SPEED_RUN
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		rotation.y = atan2(-direction.x, -direction.z)
		var next_action := PlayerAction.Type.DASH if _is_dashing() else PlayerAction.Type.RUN
		_state_machine.transition(next_action)
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED_RUN)
		velocity.z = move_toward(velocity.z, 0.0, SPEED_RUN)
		_state_machine.transition(PlayerAction.Type.IDLE)

func _is_dashing() -> bool:
	return Input.is_action_pressed("dash")

# --- アニメーション ---

func _load_mixamo_animations() -> void:
	## Mixamo FBX からアニメーションを読み込み、AnimationPlayer に登録する
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
				lib.add_animation(anim_name, anim)
		instance.free()

	var loaded: PackedStringArray = _animation_player.get_animation_list()
	print("Loaded animations: ", loaded)

func _on_action_changed(_from: PlayerAction.Type, to: PlayerAction.Type) -> void:
	_play_action_animation(to)

func _play_action_animation(action: PlayerAction.Type) -> void:
	if not _animation_player:
		return

	var target_name: String = PlayerAction.ANIMATION_NAMES.get(action, "")
	if target_name == "":
		return

	# 対応するアニメーションを再生
	if _animation_player.has_animation(target_name):
		if _animation_player.current_animation != target_name:
			_animation_player.play(target_name)
		return

	# フォールバック: 動いていたら最初のアニメーション、止まったら停止
	match action:
		PlayerAction.Type.IDLE:
			_animation_player.stop()
		_:
			var available: PackedStringArray = _animation_player.get_animation_list()
			if available.size() > 0:
				_animation_player.play(available[0])
