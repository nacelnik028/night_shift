extends Node3D
## Camera-relative rig. Never writes player rotation or movement state.
const P = preload("res://scripts/palette.gd")
var kind := "red_eyes"
var skull: Node3D
var jaw: Node3D
var arms: Array[Node3D] = []
var eyes: Array[Node3D] = []
var key_light: OmniLight3D
var finger_joints: Array[Node3D] = []
var mouth: MeshInstance3D

func facial_weight(point: Vector3, center: Vector2, spread: Vector2) -> float:
	return exp(-pow((point.x - center.x) / spread.x, 2) - pow((point.y - center.y) / spread.y, 2))

func sculpted_head() -> ArrayMesh:
	# Shape brow, cheeks and bridge in one continuous surface so the close-up
	# reads as a face rather than a collection of floating spheres.
	var sphere := SphereMesh.new()
	sphere.radial_segments = 32
	sphere.rings = 22
	var arrays := sphere.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors := PackedColorArray()
	for i in range(vertices.size()):
		var raw := vertices[i]
		var point := Vector3(raw.x * 0.61, raw.y * 0.73 + 0.08, raw.z * 0.42)
		var front := smoothstep(0.02, 0.12, point.z)
		var eyes_weight := facial_weight(point, Vector2(-0.145, 0.15), Vector2(0.075, 0.055)) + facial_weight(point, Vector2(0.145, 0.15), Vector2(0.075, 0.055))
		var nose := facial_weight(point, Vector2(0, 0.075), Vector2(0.045, 0.15)) * 0.035 + facial_weight(point, Vector2(0, 0.01), Vector2(0.055, 0.045)) * 0.065
		var brow := facial_weight(point, Vector2(-0.145, 0.225), Vector2(0.11, 0.045)) + facial_weight(point, Vector2(0.145, 0.225), Vector2(0.11, 0.045))
		point.z += front * (nose + brow * 0.018 - eyes_weight * 0.035)
		var color := Color("d2d1bb").lerp(Color("706d74"), clampf(eyes_weight * front * 0.6, 0, 0.6))
		var scalp := point.y > 0.34 or (point.z < -0.06 and point.y > 0.03) or (absf(point.x) > 0.24 and point.y > 0.21)
		if scalp:
			color = Color("252b28")
		vertices[i] = point
		colors.append(color)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var surface := SurfaceTool.new()
	surface.create_from(mesh, 0)
	surface.generate_normals()
	return surface.commit()

func _ready() -> void:
	var pale := P.material(Color("9fa693"), 0.88)
	pale.vertex_color_use_as_albedo = true
	var black := P.material(Color("060b0e"))
	var bone := P.material(Color("aaa48c"), 0.94)
	var bruise := P.material(Color("485152"), 0.96)
	var eye := P.material(Color("ed231a"), 0.5, 0.7)
	eye.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if kind == "absent":
		pale.albedo_color = Color("18232d")
		eye.albedo_color = Color("c6e8df")
		eye.emission = eye.albedo_color
	elif kind == "mimic":
		eye.albedo_color = Color("cfca9d")
		eye.emission = eye.albedo_color
	skull = Node3D.new()
	add_child(skull)
	var face := MeshInstance3D.new()
	face.mesh = sculpted_head()
	face.material_override = pale
	skull.add_child(face)
	mouth = P.ellipsoid(skull, Vector3(0, -0.13, 0.202), Vector3(0.24, 0.12, 0.008), black)
	jaw = Node3D.new()
	jaw.position = Vector3(0, -0.23, 0.01)
	skull.add_child(jaw)
	P.ellipsoid(jaw, Vector3(0, 0, 0.02), Vector3(0.37, 0.14, 0.28), pale)
	for side in [-1, 1]:
		var eye_y: float = 0.16 + (0.05 if side == 1 and kind in ["mimic", "final"] else 0.0)
		P.ellipsoid(skull, Vector3(side * 0.145, eye_y, 0.182), Vector3(0.115, 0.060, 0.014), black)
		eyes.append(P.ellipsoid(skull, Vector3(side * 0.145, eye_y, 0.194), Vector3(0.027, 0.025, 0.011), eye))
		P.ellipsoid(skull, Vector3(side * 0.29, 0.02, 0), Vector3(0.09, 0.2, 0.13), pale)
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.48, -0.4, -0.1)
		add_child(arm)
		arms.append(arm)
		P.cylinder(arm, Vector3(0, 0.26, 0), 0.055, 0.55, pale)
		P.ellipsoid(arm, Vector3(0, 0.57, 0), Vector3(0.16, 0.24, 0.09), pale)
		for i in range(4):
			var finger := Node3D.new()
			finger.position = Vector3(-0.06 + i * 0.04, 0.67, 0)
			arm.add_child(finger)
			P.cylinder(finger, Vector3(0, 0.06, 0), 0.013, 0.12, pale, 0.011)
			var joint := Node3D.new()
			joint.position.y = 0.12
			finger.add_child(joint)
			finger_joints.append(joint)
			P.cylinder(joint, Vector3(0, 0.055, 0), 0.011, 0.11 + i * 0.008, pale, 0.008)
			P.cylinder(joint, Vector3(0, 0.122 + i * 0.008, 0), 0.006, 0.045, bruise, 0)
	for i in range(8):
		if i == 2:
			continue
		P.cylinder(skull, Vector3(-0.12 + i * 0.035, -0.10, 0.208), 0.0, 0.028 + (i % 3) * 0.005, bone, 0.009)
		P.cylinder(jaw, Vector3(-0.12 + i * 0.035, 0.066, 0.15), 0.009, 0.028 + (i % 2) * 0.005, bone, 0)
	key_light = OmniLight3D.new()
	key_light.position = Vector3(0.7, 0.4, 0.8)
	key_light.omni_range = 3
	key_light.light_energy = 1.4
	key_light.light_color = Color("b5d0cf") if kind == "absent" else Color("dbb69a")
	add_child(key_light)
	position.z = -2.8
	animate(0, false)

func animate(elapsed: float, reduced: bool) -> void:
	var t := clampf(elapsed, 0, 2)
	var lunge := smoothstep(0.12, 0.55, t)
	position.z = lerpf(-2.8, -0.78, lunge)
	position.x = 0
	position.y = 0
	rotation = Vector3.ZERO
	skull.rotation = Vector3.ZERO
	match kind:
		"mimic":
			position.x = (1.0 - lunge) * 0.9
			skull.rotation.z = lerpf(0.5, -0.15, lunge)
			jaw.position.y = -0.23 - smoothstep(0.35, 0.85, t) * 0.10
		"absent":
			position.z = lerpf(-3.5, -0.85, smoothstep(0.3, 0.72, t))
			position.y = (1 - lunge) * -0.35
			skull.scale.y = 1.15
			jaw.position.y = -0.3
		"final":
			position.y = (1.0 - lunge) * 0.7
			skull.rotation.z = lerpf(-0.9, 0.3, lunge)
			skull.scale.y = 1.25
			jaw.position.y = -0.23 - smoothstep(0.1, 0.5, t) * 0.18
		_:
			jaw.position.y = -0.23 - smoothstep(0.4, 0.65, t) * 0.10
	mouth.scale.y = 0.12 * (1.0 + maxf(0, -jaw.position.y - 0.23) * 5.0)
	mouth.position.y = -0.13 - maxf(0, -jaw.position.y - 0.23) * 0.35
	for i in range(arms.size()):
		arms[i].rotation.z = (1 if i == 0 else -1) * lerpf(0.75, -0.22, lunge)
		arms[i].position.z = lunge * 0.2
	for i in range(finger_joints.size()):
		finger_joints[i].rotation.x = 0.35 + lunge * 0.45 + sin(t * 4 + i) * (0.02 if reduced else 0.06)
	var shake := sin(t * 41) * (0.003 if reduced else 0.018) * (1.0 - smoothstep(1.1, 1.6, t))
	position.x += shake
	rotation.z = shake * 0.5
	key_light.light_energy = 1.4 * (1.0 - smoothstep(1.35, 1.9, t))
