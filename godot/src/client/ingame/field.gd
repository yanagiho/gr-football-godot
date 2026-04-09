class_name Field
extends Node3D

## サッカーフィールドのライン・ゴール・地面を構築する
## フィールドサイズ: 30m(X) x 50m(Z)

const FIELD_WIDTH: float = 30.0
const FIELD_LENGTH: float = 50.0
const HALF_W: float = 15.0
const HALF_L: float = 25.0

const LINE_WIDTH: float = 0.12
const LINE_HEIGHT: float = 0.02
const PENALTY_AREA_W: float = 16.0  # ペナルティエリア幅
const PENALTY_AREA_D: float = 6.0   # ペナルティエリア深さ
const GOAL_AREA_W: float = 10.0
const GOAL_AREA_D: float = 3.0
const CENTER_RADIUS: float = 4.5
const GOAL_WIDTH: float = 5.0
const GOAL_HEIGHT: float = 2.0
const GOAL_DEPTH: float = 1.0
const GOAL_POST_R: float = 0.08

var _white_mat: StandardMaterial3D
var _goal_mat: StandardMaterial3D
var _grass_dark: StandardMaterial3D
var _grass_light: StandardMaterial3D

func _ready() -> void:
	_setup_materials()
	_build_ground()
	_build_boundary()
	_build_center_line()
	_build_center_circle()
	_build_penalty_area(1.0)   # +Z 側
	_build_penalty_area(-1.0)  # -Z 側
	_build_goal_area(1.0)
	_build_goal_area(-1.0)
	_build_goal(1.0)
	_build_goal(-1.0)
	_build_penalty_spots()
	_build_center_spot()

func _setup_materials() -> void:
	_white_mat = StandardMaterial3D.new()
	_white_mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	_white_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_goal_mat = StandardMaterial3D.new()
	_goal_mat.albedo_color = Color(0.9, 0.9, 0.9, 1.0)

	_grass_dark = StandardMaterial3D.new()
	_grass_dark.albedo_color = Color(0.18, 0.55, 0.18, 1.0)

	_grass_light = StandardMaterial3D.new()
	_grass_light.albedo_color = Color(0.22, 0.63, 0.22, 1.0)

func _build_ground() -> void:
	# 芝目模様（交互ストライプ）
	var stripe_count: int = 10
	var stripe_depth: float = FIELD_LENGTH / stripe_count
	for i: int in range(stripe_count):
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(FIELD_WIDTH + 4.0, stripe_depth)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = _grass_dark if i % 2 == 0 else _grass_light
		mi.position = Vector3(0.0, -0.001, -HALF_L + stripe_depth * (i + 0.5))
		add_child(mi)

	# フィールド外の地面
	var outer := PlaneMesh.new()
	outer.size = Vector2(FIELD_WIDTH + 20.0, FIELD_LENGTH + 20.0)
	var outer_mi := MeshInstance3D.new()
	outer_mi.mesh = outer
	var outer_mat := StandardMaterial3D.new()
	outer_mat.albedo_color = Color(0.15, 0.45, 0.15, 1.0)
	outer_mi.material_override = outer_mat
	outer_mi.position = Vector3(0.0, -0.005, 0.0)
	add_child(outer_mi)

func _build_boundary() -> void:
	# 外枠4辺
	_add_line(Vector3(0.0, 0.0, -HALF_L), FIELD_WIDTH, LINE_WIDTH)  # 上
	_add_line(Vector3(0.0, 0.0, HALF_L), FIELD_WIDTH, LINE_WIDTH)   # 下
	_add_line_z(Vector3(-HALF_W, 0.0, 0.0), FIELD_LENGTH, LINE_WIDTH) # 左
	_add_line_z(Vector3(HALF_W, 0.0, 0.0), FIELD_LENGTH, LINE_WIDTH)  # 右

func _build_center_line() -> void:
	_add_line(Vector3(0.0, 0.0, 0.0), FIELD_WIDTH, LINE_WIDTH)

func _build_center_circle() -> void:
	var segments: int = 36
	for i: int in range(segments):
		var a1: float = TAU * i / segments
		var a2: float = TAU * (i + 1) / segments
		var p1 := Vector3(cos(a1) * CENTER_RADIUS, 0.0, sin(a1) * CENTER_RADIUS)
		var p2 := Vector3(cos(a2) * CENTER_RADIUS, 0.0, sin(a2) * CENTER_RADIUS)
		_add_line_between(p1, p2)

func _build_penalty_area(side: float) -> void:
	var z_base: float = HALF_L * side
	var z_inner: float = (HALF_L - PENALTY_AREA_D) * side
	var half_w: float = PENALTY_AREA_W / 2.0
	# 横線（ゴールラインから離れた側）
	_add_line(Vector3(0.0, 0.0, z_inner), PENALTY_AREA_W, LINE_WIDTH)
	# 縦線2本
	_add_line_z(Vector3(-half_w, 0.0, (z_base + z_inner) / 2.0), PENALTY_AREA_D, LINE_WIDTH)
	_add_line_z(Vector3(half_w, 0.0, (z_base + z_inner) / 2.0), PENALTY_AREA_D, LINE_WIDTH)

func _build_goal_area(side: float) -> void:
	var z_base: float = HALF_L * side
	var z_inner: float = (HALF_L - GOAL_AREA_D) * side
	var half_w: float = GOAL_AREA_W / 2.0
	_add_line(Vector3(0.0, 0.0, z_inner), GOAL_AREA_W, LINE_WIDTH)
	_add_line_z(Vector3(-half_w, 0.0, (z_base + z_inner) / 2.0), GOAL_AREA_D, LINE_WIDTH)
	_add_line_z(Vector3(half_w, 0.0, (z_base + z_inner) / 2.0), GOAL_AREA_D, LINE_WIDTH)

func _build_goal(side: float) -> void:
	var z: float = HALF_L * side + GOAL_DEPTH * 0.5 * side
	var half_w: float = GOAL_WIDTH / 2.0

	# 左ポスト
	_add_post(Vector3(-half_w, GOAL_HEIGHT / 2.0, z), GOAL_POST_R, GOAL_HEIGHT)
	# 右ポスト
	_add_post(Vector3(half_w, GOAL_HEIGHT / 2.0, z), GOAL_POST_R, GOAL_HEIGHT)
	# クロスバー
	_add_crossbar(Vector3(0.0, GOAL_HEIGHT, z), GOAL_WIDTH, GOAL_POST_R)
	# ネット（簡易表現: 半透明の板）
	var net_mat := StandardMaterial3D.new()
	net_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.3)
	net_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# 背面ネット
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(GOAL_WIDTH, GOAL_HEIGHT, 0.05)
	var back_mi := MeshInstance3D.new()
	back_mi.mesh = back_mesh
	back_mi.material_override = net_mat
	back_mi.position = Vector3(0.0, GOAL_HEIGHT / 2.0, HALF_L * side + GOAL_DEPTH * side)
	add_child(back_mi)

func _build_penalty_spots() -> void:
	_add_spot(Vector3(0.0, 0.0, HALF_L - 6.0))   # +Z 側
	_add_spot(Vector3(0.0, 0.0, -(HALF_L - 6.0))) # -Z 側

func _build_center_spot() -> void:
	_add_spot(Vector3(0.0, 0.0, 0.0))

# --- ヘルパー ---

func _add_line(center: Vector3, length_x: float, width_z: float) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(length_x, LINE_HEIGHT, width_z)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _white_mat
	mi.position = Vector3(center.x, LINE_HEIGHT / 2.0, center.z)
	add_child(mi)

func _add_line_z(center: Vector3, length_z: float, width_x: float) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width_x, LINE_HEIGHT, length_z)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _white_mat
	mi.position = Vector3(center.x, LINE_HEIGHT / 2.0, center.z)
	add_child(mi)

func _add_line_between(p1: Vector3, p2: Vector3) -> void:
	var mid := (p1 + p2) / 2.0
	var diff := p2 - p1
	var length: float = diff.length()
	var angle: float = atan2(diff.x, diff.z)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(LINE_WIDTH, LINE_HEIGHT, length)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _white_mat
	mi.position = Vector3(mid.x, LINE_HEIGHT / 2.0, mid.z)
	mi.rotation.y = angle
	add_child(mi)

func _add_post(pos: Vector3, radius: float, height: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _goal_mat
	mi.position = pos
	add_child(mi)

func _add_crossbar(pos: Vector3, width: float, radius: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = width
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _goal_mat
	mi.position = pos
	mi.rotation.z = PI / 2.0
	add_child(mi)

func _add_spot(pos: Vector3) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.15
	mesh.bottom_radius = 0.15
	mesh.height = LINE_HEIGHT
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _white_mat
	mi.position = Vector3(pos.x, LINE_HEIGHT / 2.0, pos.z)
	add_child(mi)
