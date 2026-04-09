class_name Ball
extends RigidBody3D

## サッカーボールの物理挙動・キック・ドリブルを担当する
## サーバー権威: 物理演算はサーバーで実行し、クライアントに同期する

const KICK_FORCE: float = 12.0
const PASS_FORCE: float = 8.0
const DRIBBLE_FORCE: float = 3.0
const DRIBBLE_RANGE: float = 1.5
const KICK_RANGE: float = 2.0
const MAX_SPEED: float = 20.0

func _ready() -> void:
	gravity_scale = 1.0
	mass = 0.45
	linear_damp = 1.5
	angular_damp = 2.0
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.4
	physics_material_override.friction = 0.8
	contact_monitor = true
	max_contacts_reported = 4
	# sleeping で安定化（freeze と違い、力を加えると自動で起きる）
	sleeping = true

func _physics_process(_delta: float) -> void:
	if not multiplayer.is_server():
		return
	if linear_velocity.length() > MAX_SPEED:
		linear_velocity = linear_velocity.normalized() * MAX_SPEED
	if global_position.y < -10.0:
		_reset_position()

func kick(direction: Vector3, force: float = KICK_FORCE) -> void:
	## ボールを蹴る（サーバーで実行）
	if not multiplayer.is_server():
		return
	sleeping = false
	var impulse := direction.normalized() * force
	impulse.y = force * 0.15
	apply_central_impulse(impulse)
	print("[Ball] kick dir=%s force=%.1f impulse=%s pos=%s" % [direction, force, impulse, global_position])

func dribble_toward(target_pos: Vector3) -> void:
	## ドリブル: ボールをターゲット位置に向けて移動させる（サーバーで実行）
	if not multiplayer.is_server():
		return
	sleeping = false
	var to_target := target_pos - global_position
	to_target.y = 0.0
	var dist: float = to_target.length()
	if dist > 0.05:
		var force := to_target.normalized() * DRIBBLE_FORCE * clampf(dist, 0.5, 2.0)
		apply_central_force(force)

func is_in_kick_range(player_pos: Vector3) -> bool:
	var dist := _flat_distance(player_pos)
	return dist < KICK_RANGE

func is_in_dribble_range(player_pos: Vector3) -> bool:
	var dist := _flat_distance(player_pos)
	return dist < DRIBBLE_RANGE

func _flat_distance(pos: Vector3) -> float:
	var a := Vector2(global_position.x, global_position.z)
	var b := Vector2(pos.x, pos.z)
	return a.distance_to(b)

func _reset_position() -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_position = Vector3(0.0, 0.5, 0.0)
	sleeping = true
