class_name Dice3DView
extends SubViewportContainer

## 주사위 디자인 — Inspector에서 바로 바꿀 수 있음
@export var dice_face_color: Color = Color(0.95, 0.95, 0.92)
@export var dice_pip_color: Color = Color(0.15, 0.15, 0.15)
@export var dice_half_size: float = 0.5
@export var floor_color: Color = Color(0.2, 0.45, 0.25)
@export var background_color: Color = Color(0.13, 0.13, 0.16)

var _dice_body: Dice3DBody
var _floor_material: StandardMaterial3D

func _ready() -> void:
	stretch = true
	var viewport := SubViewport.new()
	viewport.size = Vector2i(300, 300)
	viewport.own_world_3d = true
	add_child(viewport)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = background_color
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.55, 0.55)
	env.ambient_light_energy = 0.6
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	viewport.add_child(world_env)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	light.light_energy = 1.4
	viewport.add_child(light)

	var camera := Camera3D.new()
	viewport.add_child(camera)
	## look_at()는 트리에 이미 들어가 있어야 동작하므로, 위치와 방향을 한 번에 정하는 버전을 사용
	## 정확히 위에서 내려다보면 방향 벡터가 UP과 평행해져 계산이 깨지므로 up 기준을 FORWARD로 사용
	camera.look_at_from_position(Vector3(0.001, 3.0, 0.001), Vector3(0, 0.4, 0), Vector3.FORWARD)

	var floor_body := StaticBody3D.new()
	viewport.add_child(floor_body)
	floor_body.position = Vector3(0, -0.1, 0)

	var box := BoxShape3D.new()
	box.size = Vector3(4, 0.2, 4)
	var floor_shape := CollisionShape3D.new()
	floor_shape.shape = box
	floor_body.add_child(floor_shape)

	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(4, 0.2, 4)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = box_mesh
	_floor_material = StandardMaterial3D.new()
	_floor_material.albedo_color = floor_color
	floor_mesh.material_override = _floor_material
	floor_body.add_child(floor_mesh)

	## 바닥 가장자리에 눈에 안 보이는 벽을 세워 주사위가 굴러 떨어지지 않게 막는다
	var wall_height := 1.4
	var wall_thickness := 0.2
	var half := 2.0
	_add_wall(viewport, Vector3(0, wall_height / 2.0, -half), Vector3(4, wall_height, wall_thickness))
	_add_wall(viewport, Vector3(0, wall_height / 2.0, half), Vector3(4, wall_height, wall_thickness))
	_add_wall(viewport, Vector3(-half, wall_height / 2.0, 0), Vector3(wall_thickness, wall_height, 4))
	_add_wall(viewport, Vector3(half, wall_height / 2.0, 0), Vector3(wall_thickness, wall_height, 4))

	_dice_body = Dice3DBody.new()
	_dice_body.face_color = dice_face_color
	_dice_body.pip_color = dice_pip_color
	_dice_body.half_size = dice_half_size
	viewport.add_child(_dice_body)
	_dice_body.position = Vector3(0, 1.2, 0)

func _add_wall(viewport: Node, pos: Vector3, size: Vector3) -> void:
	var wall := StaticBody3D.new()
	viewport.add_child(wall)
	wall.position = pos
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	wall.add_child(collision)

## 3D 주사위를 굴리고, 물리적으로 완전히 멈춘 뒤 윗면 눈금 값을 반환한다
func roll() -> int:
	return await _dice_body.roll_physics()

## 바닥 색을 바꾼다(전투에서 내 턴/상대 턴 구분 등에 사용)
func set_floor_color(color: Color) -> void:
	_floor_material.albedo_color = color
