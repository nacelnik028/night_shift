extends RefCounted
## Shared serrated conifer crowns: irregular boughs instead of stacked cones.
static func crown(seed_value: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rings: Array[PackedVector3Array] = []
	for level in range(16):
		var ring := PackedVector3Array()
		var y := float(level) / 15.0
		var radius := (1.0 - y) * (1.0 if level % 2 == 0 else 0.57)
		for spoke in range(9):
			var angle := spoke / 9.0 * TAU + level * 0.11
			var reach := radius * rng.randf_range(0.83, 1.12)
			ring.append(Vector3(cos(angle) * reach, y + rng.randf_range(-0.025, 0.025), sin(angle) * reach))
		rings.append(ring)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for level in range(rings.size() - 1):
		for spoke in range(9):
			var next := (spoke + 1) % 9
			for vertex in [rings[level][spoke], rings[level + 1][spoke], rings[level][next], rings[level][next], rings[level + 1][spoke], rings[level + 1][next]]:
				surface.add_vertex(vertex)
	surface.generate_normals()
	surface.index()
	return surface.commit()

static func build(world: Node3D) -> void:
	var groups: Array[Array] = []
	for i in range(6):
		groups.append([])
	for i in range(160):
		var x: float = world.rng.randf_range(-42, 42)
		var z: float = world.rng.randf_range(-35, 38)
		if absf(x) < 18 and z > -13:
			continue
		if z > 27 and z < 35:
			continue
		var height: float = world.rng.randf_range(4, 10)
		NightPalette.cylinder(world, Vector3(x, height * 0.31, z), 0.14, height * 0.62, world.mat.wood)
		var shade: float = world.rng.randf_range(0.07, 0.15)
		var index := clampi(roundi((shade - 0.07) / 0.016), 0, 5)
		var basis := Basis(Vector3.UP, float(i) * 2.39).scaled(Vector3(height * 0.25, height * 0.76, height * 0.25))
		groups[index].append(Transform3D(basis, Vector3(x, height * 0.24, z)))
	for i in range(groups.size()):
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = crown(811 + i * 17)
		instances.instance_count = groups[i].size()
		for j in range(groups[i].size()):
			instances.set_instance_transform(j, groups[i][j])
		var foliage := MultiMeshInstance3D.new()
		foliage.name = "ConiferCrowns_%d" % i
		foliage.multimesh = instances
		foliage.material_override = NightPalette.material(Color(0.025, 0.07 + i * 0.016, 0.09))
		world.add_child(foliage)
