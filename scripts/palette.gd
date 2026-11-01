extends RefCounted
class_name NightPalette
static var print_materials: Dictionary = {}

static func print_material(index: int) -> StandardMaterial3D:
	if print_materials.has(index):
		return print_materials[index]
	var result := material(Color.WHITE, 0.95)
	result.albedo_texture = load("res://assets/art/northstar_print_atlas.png")
	result.uv1_scale = Vector3(0.496, 0.496, 1)
	result.uv1_offset = Vector3((index % 2) * 0.5 + 0.002, floori(index / 2.0) * 0.5 + 0.002, 0)
	print_materials[index] = result
	return result

static func print_quad(parent: Node3D, pos: Vector3, size: Vector2, index: int, yaw: float = 0.0) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = size
	result.mesh = quad
	result.material_override = print_material(index)
	result.position = pos
	result.rotation.y = yaw
	result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(result)
	return result

static func material(color: Color, roughness: float = 0.8, emission: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m

static func box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, solid: bool = false, action: String = "", prompt: String = "") -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = mat
	mesh.position = pos
	mesh.name = ("Solid" if solid else "Detail") + "_%d_%d_%d" % [roundi(pos.x * 100), roundi(pos.y * 100), roundi(pos.z * 100)]
	parent.add_child(mesh)
	if solid or not action.is_empty():
		# Layer 1 is physical scenery; layer 4 is ray-only interaction areas.
		# An action must never turn a non-solid marker into a walking obstacle.
		var body: CollisionObject3D = StaticBody3D.new() if solid else Area3D.new()
		body.collision_layer = 1 if solid else 4
		body.collision_mask = 0
		body.name = "Body"
		if body is Area3D:
			body.monitoring = false
			body.monitorable = false
		mesh.add_child(body)
		var col := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		col.shape = box_shape
		body.add_child(col)
		if not action.is_empty():
			body.name = action.replace(":", "_")
			body.set_meta("action", action)
			body.set_meta("prompt", prompt)
	return mesh

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material, top: float = -1.0) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.bottom_radius = radius
	shape.top_radius = radius if top < 0.0 else top
	shape.height = height
	shape.radial_segments = 8
	mesh.mesh = shape
	mesh.material_override = mat
	mesh.position = pos
	parent.add_child(mesh)
	return mesh

static func label(parent: Node3D, words: String, pos: Vector3, size: int = 40, tint: Color = Color.WHITE, rotation_y: float = 0.0) -> Label3D:
	var sign_text := Label3D.new()
	sign_text.text = words
	sign_text.font_size = size
	sign_text.pixel_size = 0.007
	sign_text.modulate = tint
	sign_text.position = pos
	sign_text.rotation.y = rotation_y
	sign_text.outline_size = 3
	sign_text.double_sided = false
	parent.add_child(sign_text)
	return sign_text

static func ellipsoid(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radial_segments = 12
	shape.rings = 6
	shape.radius = 0.5
	shape.height = 1.0
	mesh.mesh = shape
	mesh.material_override = mat
	mesh.position = pos
	mesh.scale = size
	parent.add_child(mesh)
	return mesh
