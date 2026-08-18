extends SceneTree

func _init() -> void:
	var body := Dice3DBody.new()
	root.add_child(body)
	await process_frame

	var mesh_instance: MeshInstance3D = body.get_node("MeshInstance3D") if body.has_node("MeshInstance3D") else null
	if mesh_instance == null:
		for child in body.get_children():
			if child is MeshInstance3D:
				mesh_instance = child
	var mesh: ArrayMesh = mesh_instance.mesh
	print("surface_count=", mesh.get_surface_count())
	print("aabb=", mesh.get_aabb())
	for i in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(i)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		print("surface %d: vertex_count=%d verts=%s" % [i, verts.size(), verts])
	quit()
