extends Node3D
## Decorative additions do not change the station's tested collision or routes.
const P = preload("res://scripts/palette.gd")
var world: Node3D
var emergency: OmniLight3D
var storm: DirectionalLight3D
var rain: CPUParticles3D
var low_quality := false
var flash_time := 0.0
var glass: ShaderMaterial
var mirror_figure: Node3D

func surface(color: Color, wet: float, scale_value: float = 32.0) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/surface.gdshader")
	material.set_shader_parameter("base_color", color)
	material.set_shader_parameter("wetness", wet)
	material.set_shader_parameter("grain_scale", scale_value)
	return material

func prepare(station: Node3D) -> void:
	world = station
	world.mat.wall = surface(Color("687064"), 0.12, 22)
	world.mat.tile = surface(Color("818273"), 0.48, 54)
	world.mat.tile.set_shader_parameter("tile_surface", true)
	world.mat.asphalt = surface(Color("202a30"), 0.95, 65)
	world.mat.asphalt.shader = preload("res://shaders/wet_asphalt.gdshader")
	glass = ShaderMaterial.new()
	glass.shader = preload("res://shaders/rain_glass.gdshader")

func build() -> void:
	var m: Dictionary = world.mat
	# Suspended ceiling panels, vents, conduit and a service hatch.
	var ceiling := surface(Color("414c47"), 0.0, 40)
	for x in range(-7, 8, 2):
		for z in range(-9, 7, 3):
			P.box(self, Vector3(x, 3.50, z), Vector3(1.94, 0.035, 2.94), ceiling)
	for x in [-3.0, 3.0]:
		P.box(self, Vector3(x, 3.45, 1), Vector3(0.8, 0.06, 0.8), m.metal)
		for i in range(7):
			P.box(self, Vector3(x - 0.3 + i * 0.1, 3.41, 1), Vector3(0.025, 0.02, 0.66), m.black)
	# Thin fixture diffusers, sockets and signs add detail above the walking space.
	for x in [-5.0, 5.0]:
		for z in [-8.0, -2.0, 4.0]:
			for side in [-1, 1]:
				P.box(self, Vector3(x + side * 1.2, 3.32, z), Vector3(0.09, 0.12, 0.3), m.white)
	for z in [-2.4, 2.8]:
		P.box(self, Vector3(7.82, 0.45, z), Vector3(0.035, 0.18, 0.15), m.white)
		P.box(self, Vector3(7.795, 0.45, z), Vector3(0.012, 0.07, 0.035), m.black)
	# Scuffed kick plates stay visual-only and cannot snag the capsule.
	for x in [-7.79, 7.79]:
		for i in range(9):
			P.box(self, Vector3(x, 0.07, -4.5 + i * 1.2), Vector3(0.01, 0.06, 0.33), m.metal)
	# Counter face slats, kick plate, receipt printer and payment keypad.
	for i in range(14):
		P.box(self, Vector3(3.2 + i * 0.3, 0.65, 2.59), Vector3(0.012, 0.65, 0.02), m.metal)
	P.box(self, Vector3(5.2, 0.11, 2.61), Vector3(4.4, 0.16, 0.035), m.dark)
	P.box(self, Vector3(6.95, 1.22, 2.28), Vector3(0.27, 0.18, 0.3), m.metal)
	P.box(self, Vector3(6.95, 1.32, 2.2), Vector3(0.18, 0.015, 0.22), m.white)
	for i in range(9):
		P.box(self, Vector3(6.1 + (i % 3) * 0.1, 1.39, 1.89 + floori(i / 3.0) * 0.07), Vector3(0.065, 0.02, 0.04), m.white)
	# Chiller doors have rain-free glass, handles, vents and bottle caps.
	var fridge_glass := P.material(Color(0.34, 0.57, 0.6, 0.07), 0.16)
	fridge_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for x in [-3.0, -1.5, 0.0, 1.5]:
		P.box(self, Vector3(x, 1.25, -3.52), Vector3(1.15, 1.75, 0.015), fridge_glass)
		P.box(self, Vector3(x + 0.48, 1.25, -3.47), Vector3(0.035, 0.62, 0.05), m.white)
		for y in [0.45, 1.0, 1.55]:
			for offset in [-0.4, 0.0, 0.4]:
				P.cylinder(self, Vector3(x + offset, y + 0.335, -3.72), 0.045, 0.045, m.white)
		for y in [0.12, 0.17, 0.22]:
			P.box(self, Vector3(x, y, -3.87), Vector3(1.05, 0.015, 0.02), m.metal)
	for x in [-5.6, -2.6]:
		P.label(self, "ROAD BITES  /  $4", Vector3(x, 0.73, 1.87), 12, Color("f0dab0"))
	# Electrical cabinet and notices. All additions leave interaction rays clear.
	for z in [-6.6, -6.3, -6.0]:
		P.box(self, Vector3(7.57, 1.7, z), Vector3(0.04, 0.09, 0.08), m.red)
	P.box(self, Vector3(7.8, 2.6, -6.4), Vector3(0.06, 1.3, 0.07), m.metal)
	P.label(self, "DANGER\nHIGH VOLTAGE", Vector3(7.55, 1.16, -6.4), 12, Color("ffbd66"), -PI / 2)
	P.label(self, "NO CREDIT\nNO EXCEPTIONS", Vector3(7.78, 1.8, 1.0), 19, Color("d4c4a2"), -PI / 2)
	# A dark convex safety mirror: an authored false reflection, not a second viewport.
	P.cylinder(self, Vector3(-7.76, 2.65, 3.3), 0.48, 0.08, m.metal).rotation.z = PI / 2
	mirror_figure = Node3D.new()
	add_child(mirror_figure)
	mirror_figure.position = Vector3(-7.69, 2.62, 3.3)
	P.box(mirror_figure, Vector3.ZERO, Vector3(0.015, 0.32, 0.14), m.black)
	P.box(mirror_figure, Vector3(0, 0.2, 0), Vector3(0.02, 0.12, 0.12), m.black)
	mirror_figure.visible = false
	# Forecourt drainage, hose loops and pump stickers.
	for x in [-6.0, 6.0]:
		for i in range(12):
			var a := float(i) / 11 * PI
			P.cylinder(self, Vector3(x + 0.8 + sin(a) * 0.34, 1.65 - cos(a) * 0.65, 19.2), 0.04, 0.17, m.black).rotation.z = a
		P.label(self, "ENGINE OFF\nNO SMOKING", Vector3(x, 0.85, 19.42), 11, Color("ecd4bb"))
		P.label(self, "0%d" % (1 if x < 0 else 2), Vector3(x, 2.0, 19.48), 20, Color("18332e"))
	for x in range(-12, 13, 2):
		P.box(self, Vector3(x, 0.002, 8.7), Vector3(1.8, 0.015, 0.26), m.metal)
		for i in range(8):
			P.box(self, Vector3(x - 0.8 + i * 0.22, 0.014, 8.7), Vector3(0.06, 0.008, 0.22), m.black)
	P.box(self, Vector3(10.5, 0.8, -4), Vector3(2.1, 1.5, 1.25), m.teal, true)
	P.box(self, Vector3(10.5, 1.58, -4), Vector3(2.2, 0.1, 1.35), m.dark)
	P.label(self, "COUNTY WASTE", Vector3(10.5, 1.0, -3.36), 18, Color("b8c4b7"))
	P.cylinder(self, Vector3(-18, 1.6, 27), 0.065, 3.2, m.metal)
	P.box(self, Vector3(-18, 2.75, 27), Vector3(2.6, 0.85, 0.06), m.teal)
	P.label(self, "COUNTY 16  →\nNEXT SERVICES 48 MI", Vector3(-18, 2.75, 27.05), 18, Color("d2ddc4"))
	# Bare branches break up the existing conifer silhouettes.
	for i in range(16):
		var x := -21.0 if i % 2 == 0 else 23.0
		var z := -20.0 + i * 2.8
		var trunk := P.cylinder(self, Vector3(x, 2.8, z), 0.21, 5.6, m.wood, 0.055)
		trunk.rotation.z = sin(i) * 0.08
		for side in [-1, 1]:
			var branch := P.cylinder(self, Vector3(x + side * 0.6, 4.3, z), 0.09, 2.2, m.wood, 0.015)
			branch.rotation.z = side * 0.8
	emergency = OmniLight3D.new()
	emergency.position = Vector3(3.4, 2.8, -4.5)
	emergency.light_color = Color("ee3024")
	emergency.light_energy = 0.65
	emergency.omni_range = 7
	emergency.visible = false
	add_child(emergency)
	P.box(self, Vector3(3.4, 3.05, -4.8), Vector3(0.45, 0.16, 0.18), m.red)
	storm = DirectionalLight3D.new()
	storm.rotation_degrees = Vector3(-65, 20, 0)
	storm.light_color = Color("a3b8df")
	storm.light_energy = 0
	add_child(storm)

func lightning(reduced: bool) -> void:
	if reduced:
		return
	flash_time = 0.6

func tick(delta: float) -> void:
	flash_time = maxf(0, flash_time - delta)
	storm.light_energy = sin(flash_time / 0.6 * PI) * 0.8 if flash_time > 0 else 0.0

func quality(low: bool) -> void:
	low_quality = low
	if is_instance_valid(rain):
		rain.amount = 220 if low else 700
	glass.set_shader_parameter("animate_rain", not low)
