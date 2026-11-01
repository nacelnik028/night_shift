extends RefCounted
## Group repeated static primitives without changing their physical/interaction bodies.
## Dynamic doors, clues, power fixtures and job targets are deliberately excluded.
static func build(world: Node3D) -> void:
	var excluded: Array[Node] = [world.apparition, world.detail.mirror_figure]
	excluded.append(world.clock_hands)
	excluded.append(world.scan_strip)
	excluded.append(world.restock_packages)
	excluded.append_array(world.service.dynamic_nodes)
	excluded.append_array(world.stains)
	excluded.append_array(world.tubes)
	for door in world.doors.values():
		excluded.append(door.pivot)
	var groups: Dictionary = {}
	for node in world.find_children("*", "MeshInstance3D", true, false):
		if not node.is_visible_in_tree():
			continue
		var skip := false
		for branch in excluded:
			if branch == node or branch.is_ancestor_of(node):
				skip = true
				break
		if skip:
			continue
		var primitive := ""
		if node.mesh is BoxMesh:
			primitive = "box"
		elif node.mesh is QuadMesh:
			primitive = "quad"
		elif node.mesh is CylinderMesh:
			primitive = "cylinder:%s:%s" % [node.mesh.top_radius / maxf(0.001, node.mesh.bottom_radius), node.mesh.radial_segments]
		else:
			continue
		if not node.material_override:
			continue
		# Bake dimensions into each transform. Different-sized boxes can share one
		# unit mesh; 12m cells retain useful culling for forest and interior batches.
		var cell := Vector2i(floori(node.global_position.x / 12), floori(node.global_position.z / 12))
		var key := primitive + ":" + str(cell) + ":" + str(node.material_override.get_rid()) + ":" + str(node.layers) + ":" + str(node.cast_shadow)
		if not groups.has(key):
			groups[key] = []
		groups[key].append(node)
	var batched := 0
	for members in groups.values():
		if members.size() < 4:
			continue
		var first: MeshInstance3D = members[0]
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		if first.mesh is BoxMesh:
			instances.mesh = BoxMesh.new()
			instances.mesh.size = Vector3.ONE
		elif first.mesh is QuadMesh:
			instances.mesh = QuadMesh.new()
			instances.mesh.size = Vector2.ONE
		else:
			instances.mesh = CylinderMesh.new()
			instances.mesh.height = 1.0
			instances.mesh.bottom_radius = 1.0
			instances.mesh.top_radius = first.mesh.top_radius / first.mesh.bottom_radius
			instances.mesh.radial_segments = first.mesh.radial_segments
		instances.instance_count = members.size()
		var batch := MultiMeshInstance3D.new()
		batch.name = "StaticBatch"
		batch.multimesh = instances
		batch.material_override = first.material_override
		batch.cast_shadow = first.cast_shadow
		batch.layers = first.layers
		world.add_child(batch)
		for i in range(members.size()):
			var source: MeshInstance3D = members[i]
			var dimensions := Vector3.ONE
			if source.mesh is BoxMesh:
				dimensions = source.mesh.size
			elif source.mesh is QuadMesh:
				dimensions = Vector3(source.mesh.size.x, source.mesh.size.y, 1)
			else:
				dimensions = Vector3(source.mesh.bottom_radius, source.mesh.height, source.mesh.bottom_radius)
			instances.set_instance_transform(i, world.global_transform.affine_inverse() * source.global_transform * Transform3D(Basis.from_scale(dimensions), Vector3.ZERO))
			source.set_meta("collision_proxy", true)
			source.visible = false
			batched += 1
	world.set_meta("batched_meshes", batched)
