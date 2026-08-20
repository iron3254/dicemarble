class_name Dice3DBody
extends RigidBody3D

## 각 면의 로컬 방향(±X/±Y/±Z)에 대응하는 눈금 값. 마주보는 면의 합이 7이 되도록 배치(실제 주사위 규칙)
const FACE_VALUES := {"+X": 1, "-X": 6, "+Y": 2, "-Y": 5, "+Z": 3, "-Z": 4}

## 아래 값들은 Dice3DView가 만들 때 채워준다(Dice3DView의 Inspector에서 디자인을 바꿀 수 있음)
var half_size := 0.5
var face_color := Color(0.95, 0.95, 0.92)
var pip_color := Color(0.15, 0.15, 0.15)

func _ready() -> void:
	_build_visual_and_collision()

## 무작위 힘을 가해 주사위를 굴리고, 완전히 멈추면 윗면 눈금 값을 반환한다
func roll_physics() -> int:
	freeze = false
	sleeping = false
	position = Vector3(0, 1.2, 0)
	rotation = Vector3(randf_range(0, TAU), randf_range(0, TAU), randf_range(0, TAU))
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	apply_impulse(Vector3(randf_range(-1.0, 1.0), randf_range(2.5, 3.5), randf_range(-1.0, 1.0)))
	apply_torque_impulse(Vector3(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0), randf_range(-5.0, 5.0)))

	## 바운스 도중 순간적으로 속도가 0 근처로 떨어지는 지점을 "완전히 멈췄다"고 오판하지 않도록,
	## 일정 시간(0.3초) 동안 연속으로 느려진 상태가 유지되어야 정지로 판정한다
	const REQUIRED_STILL_TIME := 0.3
	const MAX_WAIT := 4.0
	await get_tree().physics_frame
	var still_time := 0.0
	var elapsed := 0.0
	while elapsed < MAX_WAIT:
		var dt := get_physics_process_delta_time()
		if linear_velocity.length() < 0.05 and angular_velocity.length() < 0.05:
			still_time += dt
			if still_time >= REQUIRED_STILL_TIME:
				break
		else:
			still_time = 0.0
		await get_tree().physics_frame
		elapsed += dt

	return _read_top_value()

## 정지한 주사위의 6개 면 방향 중 월드 위쪽(Vector3.UP)에 가장 가까운 면의 값을 읽는다
func _read_top_value() -> int:
	var b := global_transform.basis
	var candidates := [
		[b.x, FACE_VALUES["+X"]], [-b.x, FACE_VALUES["-X"]],
		[b.y, FACE_VALUES["+Y"]], [-b.y, FACE_VALUES["-Y"]],
		[b.z, FACE_VALUES["+Z"]], [-b.z, FACE_VALUES["-Z"]],
	]
	var best_value := 1
	var best_dot := -INF
	for c in candidates:
		var dir: Vector3 = c[0]
		var dot: float = dir.dot(Vector3.UP)
		if dot > best_dot:
			best_dot = dot
			best_value = c[1]
	return best_value

## 정육면체 메시를 면마다 다른 눈금 텍스처로 직접 만들고, 충돌 모양도 붙인다
func _build_visual_and_collision() -> void:
	var mesh := ArrayMesh.new()
	var faces := _face_definitions()
	var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	for face in faces:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var verts: Array = face["verts"]
		var normal: Vector3 = face["normal"]
		for idx in [0, 1, 2, 0, 2, 3]:
			st.set_normal(normal)
			st.set_uv(uvs[idx])
			st.add_vertex(verts[idx])
		mesh = st.commit(mesh)

	for i in range(faces.size()):
		var material := StandardMaterial3D.new()
		material.albedo_texture = DiceFaceTexture.make(faces[i]["value"], face_color, pip_color)
		## 손으로 만든 메시라 감기 방향이 엔진 기준과 어긋나도 면이 사라지지 않도록 컬링을 끔
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh.surface_set_material(i, material)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	add_child(mesh_instance)

	var shape := BoxShape3D.new()
	shape.size = Vector3.ONE * (half_size * 2)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)

## 각 면을 이루는 네 꼭짓점(시계 반대 방향, 바깥쪽 법선)과 그 면의 눈금 값
func _face_definitions() -> Array:
	var h := half_size
	var a := Vector3(-h, -h, -h)
	var b := Vector3(h, -h, -h)
	var c := Vector3(h, h, -h)
	var d := Vector3(-h, h, -h)
	var e := Vector3(-h, -h, h)
	var f := Vector3(h, -h, h)
	var g := Vector3(h, h, h)
	var hh := Vector3(-h, h, h)
	return [
		{"verts": [e, f, g, hh], "value": FACE_VALUES["+Z"], "normal": Vector3(0, 0, 1)},
		{"verts": [a, d, c, b], "value": FACE_VALUES["-Z"], "normal": Vector3(0, 0, -1)},
		{"verts": [b, c, g, f], "value": FACE_VALUES["+X"], "normal": Vector3(1, 0, 0)},
		{"verts": [a, e, hh, d], "value": FACE_VALUES["-X"], "normal": Vector3(-1, 0, 0)},
		{"verts": [d, hh, g, c], "value": FACE_VALUES["+Y"], "normal": Vector3(0, 1, 0)},
		{"verts": [a, b, f, e], "value": FACE_VALUES["-Y"], "normal": Vector3(0, -1, 0)},
	]
