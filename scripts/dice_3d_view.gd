class_name Dice3DView
extends SubViewportContainer

var _dice_body: Dice3DBody

func _ready() -> void:
	stretch = true
	var viewport := SubViewport.new()
	viewport.size = Vector2i(300, 300)
	viewport.own_world_3d = true
	add_child(viewport)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.13, 0.13, 0.16)
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
	## 위에서 거의 수직으로 내려다보면 옆면이 거의 안 보여 입체감이 사라지므로, 3/4 각도(아이소메트릭 느낌)로 배치
	camera.look_at_from_position(Vector3(1.8, 2.2, 2.2), Vector3(0, 0.4, 0), Vector3.UP)

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
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.2, 0.45, 0.25)
	floor_mesh.material_override = floor_material
	floor_body.add_child(floor_mesh)

	_dice_body = Dice3DBody.new()
	viewport.add_child(_dice_body)
	_dice_body.position = Vector3(0, 1.2, 0)

## 3D 주사위를 굴리고, 물리적으로 완전히 멈춘 뒤 윗면 눈금 값을 반환한다
func roll() -> int:
	return await _dice_body.roll_physics()
