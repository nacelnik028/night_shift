extends Node3D

const P = preload("res://scripts/palette.gd")
var lights: Array[OmniLight3D] = []
var doors: Dictionary = {}
var stains: Array[Node3D] = []
var tubes: Array[MeshInstance3D] = []
var camera_positions := [Vector3(-11, 7, 20), Vector3(4, 3, 6), Vector3(7.5, 2.9, 0), Vector3(1, 3, -9.3)]
var camera_targets := [Vector3(0, 0, 12), Vector3(0, 1, 7.5), Vector3(5, 1.2, 4), Vector3(4, 1, -5)]
var env: Environment
var apparition: Node3D
var powered := true
var rng := RandomNumberGenerator.new()
var mat: Dictionary
var detail: Node3D
var service: Node3D
var clock_hands: Node3D
var clock_minute := -1
var scan_strip: MeshInstance3D
var scan_feedback := 0.0
var restock_packages: Node3D

func _ready() -> void:
	rng.seed = 42027
	mat = {
		"wall": P.material(Color("67746e")), "dark": P.material(Color("111d23")),
		"tile": P.material(Color("79857c"), 0.36), "white": P.material(Color("c2ccc0")),
		"red": P.material(Color("9e352c")), "teal": P.material(Color("206a69")),
		"metal": P.material(Color("34454a"), 0.28), "wood": P.material(Color("554337")),
		"asphalt": P.material(Color("161e23"), 0.28), "glow": P.material(Color("a1f3d5"), 0.5, 1.8),
		"amber": P.material(Color("c49b55"), 0.6, 0.12), "black": P.material(Color("080e12")),
		"green": P.material(Color("38895c"), 0.6, 0.3)
	}
	detail = preload("res://scripts/atmosphere.gd").new()
	$AtmosphereDetails.add_child(detail)
	detail.prepare(self)
	build_environment()
	build_station()
	build_furniture()
	build_details()
	build_grounds()
	build_weather()
	service = preload("res://scripts/station_extension.gd").new()
	$ServiceWing.add_child(service)
	service.build(self)
	detail.build()
	if "--no-static-batching" not in OS.get_cmdline_user_args():
		preload("res://scripts/static_batch.gd").build(self)

func build_environment() -> void:
	var environment := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0b141d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("668398")
	env.ambient_light_energy = 0.28
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("172d38")
	env.fog_density = 0.012
	env.fog_sky_affect = 1.0
	environment.environment = env
	add_child(environment)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-32, -28, 0)
	moon.light_color = Color("6486b0")
	moon.light_energy = 0.3
	moon.shadow_enabled = true
	add_child(moon)

func build_station() -> void:
	P.box(self, Vector3(0, -0.25, -1.5), Vector3(16.5, 0.5, 18), mat.tile, true)
	P.box(self, Vector3(-8, 1.8, -1.5), Vector3(0.3, 3.6, 17), mat.wall, true)
	P.box(self, Vector3(8, 1.8, -1.5), Vector3(0.3, 3.6, 17), mat.wall, true)
	# Rear exit replaces only its matching wall opening; the storage route is clear.
	P.box(self, Vector3(-1.8, 1.8, -10), Vector3(12.4, 3.6, 0.3), mat.wall, true)
	P.box(self, Vector3(6.9, 1.8, -10), Vector3(2.2, 3.6, 0.3), mat.wall, true)
	P.box(self, Vector3(5.1, 3.15, -10), Vector3(1.4, 0.9, 0.3), mat.wall, true)
	add_door("rear_exit", Vector3(4.4, 0, -10), 1.4, "Rear service exit")
	P.box(self, Vector3(0, 3.65, -1.5), Vector3(16.6, 0.25, 18), mat.dark, true)
	for side in [-1, 1]:
		P.box(self, Vector3(side * 4.65, 0.55, 7), Vector3(6.7, 1.1, 0.25), mat.teal, true)
		P.box(self, Vector3(side * 4.65, 3.15, 7), Vector3(6.7, 0.9, 0.25), mat.dark, true)
		var glass: Material = detail.glass
		P.box(self, Vector3(side * 4.65, 1.9, 7), Vector3(6.7, 1.6, 0.06), glass, true)
		for x in [1.3, 4.6, 7.9]:
			P.box(self, Vector3(side * x, 1.9, 7), Vector3(0.08, 2.1, 0.15), mat.metal)
	add_door("entrance", Vector3(-1.25, 0, 7), 2.5, "Entrance door")
	for segment in [[-7.3, 1.4], [-2.5, 4.1], [2.5, 4.1], [7.3, 1.4]]:
		P.box(self, Vector3(segment[0], 1.8, -5), Vector3(segment[1], 3.6, 0.2), mat.wall, true)
	for x in [-5.5, 5.5]:
		P.box(self, Vector3(x, 3.15, -5), Vector3(2.2, 0.9, 0.25), mat.wall, true)
	add_door("office", Vector3(-6.6, 0, -5), 2.2, "Security office")
	add_door("storage", Vector3(4.4, 0, -5), 2.2, "Storage room")
	P.box(self, Vector3(0, 1.8, -7.5), Vector3(0.2, 3.6, 5), mat.wall, true)
	P.label(self, "SECURITY", Vector3(-5.5, 2.9, -4.85), 28, Color("d2ddce"))
	P.label(self, "STORAGE", Vector3(5.5, 2.9, -4.85), 28, Color("d2ddce"))
	P.label(self, "EXIT", Vector3(0, 2.95, 6.8), 30, Color("70ffc1"), PI)
	P.box(self, Vector3(0, 3.55, 7.19), Vector3(16.5, 0.8, 0.2), mat.teal)
	P.label(self, "N O R T H S T A R   /   2 4 H", Vector3(0, 3.57, 7.34), 55, Color("c3f6db"))
	for z in [-8, -2, 4]:
		for x in [-5, 5]:
			P.box(self, Vector3(x, 3.43, z), Vector3(2.5, 0.10, 0.32), mat.metal)
			tubes.append(P.box(self, Vector3(x, 3.35, z), Vector3(2.25, 0.04, 0.18), mat.glow))
			lamp(Vector3(x, 2.9, z), Color("ead7ad") if z == 4 else Color("b6cec7"), 1.05, 7.3, true)
	# Tiled wall bands, skirting and ceiling service conduits.
	for x in [-7.8, 7.8]:
		P.box(self, Vector3(x, 0.16, -1.5), Vector3(0.08, 0.3, 17), mat.dark)
		P.box(self, Vector3(x, 2.5, -1.5), Vector3(0.06, 0.15, 17), mat.teal)
	P.box(self, Vector3(0, 3.4, -1.5), Vector3(0.12, 0.12, 17), mat.metal)
	var ceiling_shadow := SpotLight3D.new()
	ceiling_shadow.position = Vector3(1.5, 3.3, 1)
	ceiling_shadow.rotation_degrees.x = -90
	ceiling_shadow.spot_angle = 78
	ceiling_shadow.spot_range = 11
	ceiling_shadow.light_energy = 0.6
	ceiling_shadow.light_color = Color("bee7d0")
	ceiling_shadow.shadow_enabled = true
	ceiling_shadow.name = "CeilingShadow"
	add_child(ceiling_shadow)

func build_furniture() -> void:
	restock_packages = Node3D.new()
	restock_packages.name = "RestockedPackages"
	add_child(restock_packages)
	restock_packages.visible = false
	# Counter: the customer stands on the south side, clerk on the north.
	P.box(self, Vector3(5.2, 0.53, 2.1), Vector3(4.5, 1.06, 0.95), mat.teal, true).name = "SalesCounter"
	P.box(self, Vector3(5.2, 1.09, 2.1), Vector3(4.7, 0.12, 1.15), mat.white, true)
	P.box(self, Vector3(5.2, 0.2, 2.61), Vector3(4.1, 0.07, 0.03), mat.glow)
	P.box(self, Vector3(6.3, 1.25, 2.05), Vector3(0.7, 0.26, 0.55), mat.dark, true, "register", "Register · customer decision")
	var screen := P.box(self, Vector3(6.3, 1.53, 2.18), Vector3(0.65, 0.36, 0.07), mat.black)
	screen.rotation_degrees.x = -12
	P.label(self, "NORTHSTAR\nPOINT OF SALE", Vector3(6.3, 1.53, 2.12), 13, Color("67e7b0"), PI)
	P.box(self, Vector3(4.6, 1.18, 2.0), Vector3(0.65, 0.08, 0.5), mat.black, true, "scan", "Scan held product")
	scan_strip = P.box(self, Vector3(4.6, 1.225, 2), Vector3(0.48, 0.01, 0.025), mat.red)
	P.box(self, Vector3(5.55, 1.19, 1.72), Vector3(0.29, 0.08, 0.23), mat.green, true, "accept", "ACCEPT · complete sale")
	P.box(self, Vector3(5.95, 1.19, 1.72), Vector3(0.29, 0.08, 0.23), mat.red, true, "reject", "REJECT · refuse service")
	P.label(self, "SCAN", Vector3(4.6, 1.17, 1.5), 15, Color.WHITE, PI)
	P.label(self, "REFUSE     SERVE", Vector3(5.8, 1.17, 1.5), 12, Color.WHITE, PI)
	P.label(self, "PLEASE WAIT HERE", Vector3(5, 0.03, 3.6), 25, Color("c8caa9")).rotation.x = -PI / 2
	# Two double-sided stocked aisles.
	var snack_materials := [P.material(Color("cba84c")), P.material(Color("a24839")), P.material(Color("4e8c87"))]
	for x in [-5.6, -2.6]:
		var rack_collision := P.box(self, Vector3(x, 0.8, 0), Vector3(1, 1.6, 3.5), mat.metal, true, "product:chips", "Take chips · $4")
		rack_collision.visible = false
		rack_collision.name = "SnackShelf_%d" % roundi(x * 10)
		rack_collision.set_meta("collision_proxy", true)
		P.box(self, Vector3(x, 0.8, 0), Vector3(0.07, 1.6, 3.5), mat.metal)
		for z in [-1.75, 1.75]:
			for offset in [-0.5, 0.5]:
				P.box(self, Vector3(x + offset, 0.8, z), Vector3(0.055, 1.65, 0.06), mat.metal)
		for height in [0.24, 0.72, 1.2, 1.67]:
			P.box(self, Vector3(x, height, 0), Vector3(1.16, 0.055, 3.7), mat.white)
			for z in range(7):
				for side in [-1, 1]:
					var tint: Material = snack_materials[rng.randi_range(0, 2)]
					var product_parent: Node3D = restock_packages if is_equal_approx(height, 0.72) and z >= 4 else self
					P.box(product_parent, Vector3(x + side * 0.35, height + 0.18, -1.45 + z * 0.46), Vector3(0.24, 0.30, 0.25), tint)
					P.box(product_parent, Vector3(x + side * 0.35, height + 0.335, -1.45 + z * 0.46), Vector3(0.245, 0.025, 0.25), mat.amber)
					P.box(product_parent, Vector3(x + side * 0.475, height + 0.19, -1.45 + z * 0.46), Vector3(0.006, 0.08, 0.17), mat.white)
					P.print_quad(product_parent, Vector3(x + side * 0.479, height + 0.18, -1.45 + z * 0.46), Vector2(0.24, 0.29), 1, side * PI / 2)
		P.box(self, Vector3(x, 1.9, 1.795), Vector3(1.05, 0.23, 0.035), mat.dark)
		P.label(self, "SNACKS   /   04", Vector3(x, 1.9, 1.82), 22, Color("e9ddaa"))
	# Fridge bank, drinks and lit strips.
	for x in [-3, -1.5, 0, 1.5]:
		P.box(self, Vector3(x, 1.15, -4.35), Vector3(1.35, 2.3, 0.9), mat.dark, true, "product:water", "Take cold water · $3")
		P.box(self, Vector3(x, 1.18, -3.88), Vector3(1.18, 1.92, 0.02), mat.metal)
		P.box(self, Vector3(x - 0.57, 1.3, -3.84), Vector3(0.035, 1.9, 0.03), mat.glow)
		for y in [0.45, 1.0, 1.55]:
			P.box(self, Vector3(x, y - 0.04, -3.73), Vector3(1.15, 0.035, 0.3), mat.white)
			for offset in [-0.4, 0, 0.4]:
				P.cylinder(self, Vector3(x + offset, y + 0.16, -3.72), 0.09, 0.3, mat.teal)
				P.print_quad(self, Vector3(x + offset, y + 0.16, -3.625), Vector2(0.13, 0.15), 3)
		P.label(self, "ICE COLD", Vector3(x, 2.17, -3.85), 17, Color("a4e7da"))
	P.box(self, Vector3(-7, 0.6, 4.8), Vector3(1.1, 1.2, 1.1), mat.wood, true)
	P.box(self, Vector3(-7, 1.55, 4.8), Vector3(0.65, 0.7, 0.65), mat.metal, true, "product:coffee", "Pour coffee · $5")
	P.cylinder(self, Vector3(-7, 1.65, 5.15), 0.15, 0.3, mat.black)
	P.label(self, "FRESH COFFEE\n$5", Vector3(-7, 2.3, 4.9), 27, Color("ffce83"))
	# Security office.
	P.box(self, Vector3(-5, 0.75, -8.6), Vector3(4, 0.15, 1.2), mat.wood, true)
	for x in [-6.6, -3.4]:
		P.box(self, Vector3(x, 0.35, -8.6), Vector3(0.12, 0.7, 0.8), mat.metal, true)
	P.box(self, Vector3(-5, 1.35, -8.65), Vector3(1.7, 1.0, 0.25), mat.dark, true, "cameras", "Security monitor · view live cameras")
	P.box(self, Vector3(-5, 1.37, -8.5), Vector3(1.48, 0.78, 0.02), mat.glow)
	P.label(self, "NORTHSTAR CCTV\n[E] CONNECT", Vector3(-5, 1.4, -8.47), 21, Color("112e28"))
	P.box(self, Vector3(-3.5, 0.89, -8.4), Vector3(0.55, 0.18, 0.4), mat.red, true, "phone", "Telephone · answer / hang up")
	P.box(self, Vector3(-3.5, 1.02, -8.4), Vector3(0.67, 0.1, 0.17), mat.dark)
	P.box(self, Vector3(-6.5, 0.88, -8.25), Vector3(0.5, 0.09, 0.28), mat.amber, true, "battery", "Charger · refill flashlight")
	P.label(self, "CHARGE", Vector3(-6.5, 1.15, -8.4), 15, Color("ffd293"))
	P.box(self, Vector3(-5, 0.47, -7.3), Vector3(0.75, 0.12, 0.65), mat.dark, true)
	P.box(self, Vector3(-5, 0.88, -6.98), Vector3(0.75, 0.9, 0.1), mat.dark, true)
	P.box(self, Vector3(-7.8, 1.7, -7), Vector3(0.13, 1.7, 2.0), mat.wood, false, "note:rules", "Read employee notice")
	P.label(self, "EMPLOYEE NOTICE\n\nCHECK EVERY CUSTOMER.\nSCAN BEFORE SERVING.\nTRUST THE CAMERA.\n\nNever invite a caller inside.", Vector3(-7.69, 1.7, -7), 17, Color("eadab3"), PI / 2)
	# Storage supplies and breaker.
	for x in [2, 3.2, 6.8]:
		for z in [-8.8, -7.5]:
			for y in [0.35, 1.05]:
				P.box(self, Vector3(x, y, z), Vector3(0.95, 0.7, 0.95), mat.wood, true, "supplies", "Take restock crate")
	P.box(self, Vector3(7.73, 1.6, -6.4), Vector3(0.25, 0.8, 0.65), mat.metal, true, "breaker", "Circuit breaker · restore power")
	P.label(self, "MAIN\nBREAKER", Vector3(7.56, 2.3, -6.4), 22, Color("ffce83"), -PI / 2)
	P.box(self, Vector3(-2.6, 0.05, 2.7), Vector3(1.3, 0.08, 0.8), mat.teal, false, "restock", "Restock shelf · requires crate")
	P.label(self, "RESTOCK", Vector3(-2.6, 0.2, 2.9), 18, Color("e7dcac"))
	for pos in [Vector3(-0.5, 0.02, 3), Vector3(-6.8, 0.02, -2.5), Vector3(2.3, 0.02, -1.3)]:
		var stain := P.cylinder(self, pos, 0.48, 0.018, P.material(Color("282e25"), 0.15))
		stain.scale.z = 0.7
		var trigger := P.box(stain, Vector3(0, 0.05, 0), Vector3(1, 0.12, 0.8), mat.black, false, "clean:" + str(stains.size()), "Clean spill · hold still")
		trigger.visible = false
		stain.set_meta("interaction_area", trigger.get_child(0))
		stains.append(stain)
	P.label(self, "NORTHSTAR\nSERVICE WITH A SMILE\nSINCE 1978", Vector3(7.8, 2, -0.8), 30, Color("c9d5bb"), -PI / 2)

func build_grounds() -> void:
	P.box(self, Vector3(0, -0.4, 0), Vector3(90, 0.5, 85), P.material(Color("142321")), true)
	P.box(self, Vector3(0, -0.11, 17), Vector3(33, 0.18, 23), mat.asphalt, true)
	P.box(self, Vector3(0, -0.12, 31), Vector3(90, 0.2, 7), mat.asphalt, true)
	for x in range(-40, 42, 6):
		P.box(self, Vector3(x, -0.008, 31), Vector3(3.1, 0.012, 0.1), mat.white)
	for x in [-12, -8, 8, 12]:
		P.box(self, Vector3(x, 0.008, 10), Vector3(0.09, 0.01, 4.3), mat.white)
	for x in [-6, 6]:
		P.box(self, Vector3(x, 0.1, 19), Vector3(2.8, 0.25, 3.8), mat.wall, true)
		P.box(self, Vector3(x, 0.7, 19), Vector3(1.0, 1.2, 0.8), mat.red, true)
		P.box(self, Vector3(x, 1.65, 19), Vector3(1.2, 0.9, 0.9), mat.white, true)
		P.box(self, Vector3(x, 1.73, 19.46), Vector3(0.85, 0.3, 0.025), mat.black)
		P.label(self, "87   /   95\n$ 3.89", Vector3(x, 1.7, 19.49), 16, Color("8df4c5"))
		P.cylinder(self, Vector3(x + 0.74, 1.3, 19), 0.045, 1.4, mat.black)
		P.box(self, Vector3(x + 0.65, 1.9, 19), Vector3(0.15, 0.1, 0.1), mat.black)
		for z in [17.5, 20.5]:
			P.cylinder(self, Vector3(x + 1, 0.55, z), 0.09, 1.0, mat.amber)
	for x in [-9, 9]:
		P.box(self, Vector3(x, 2.75, 19), Vector3(0.25, 5.5, 0.25), mat.teal, true)
	P.box(self, Vector3(0, 5.4, 19), Vector3(21, 0.5, 7), mat.dark, true)
	P.box(self, Vector3(0, 5.38, 22.55), Vector3(21, 0.25, 0.05), mat.glow)
	P.label(self, "N O R T H S T A R", Vector3(0, 5.45, 22.61), 40, Color("b7f7e0"))
	for x in [-6, 6]:
		lamp(Vector3(x, 4.8, 19), Color("74d8ce"), 2.2, 9, false)
	for x in [-15, 15]:
		P.cylinder(self, Vector3(x, 3.4, 10), 0.1, 6.8, mat.metal)
		P.box(self, Vector3(x, 6.7, 10), Vector3(1.2, 0.15, 0.5), mat.amber)
		lamp(Vector3(x, 6.4, 10), Color("ffb466"), 2.3, 13, false)
	# Roadside totem.
	P.box(self, Vector3(14, 3, 25), Vector3(0.25, 6, 0.25), mat.metal)
	P.box(self, Vector3(14, 5.8, 25), Vector3(3.5, 2.4, 0.3), mat.teal)
	P.label(self, "NORTHSTAR\nOPEN 24 H\nGAS • FOOD\n3.89", Vector3(14, 5.8, 25.18), 33, Color("baf3d6"))
	# Player's car, curb, trash and a distant forest silhouette.
	car(Vector3(-11, 0, 11), Color("45656a"))
	for x in [-7.5, 7.5]:
		P.cylinder(self, Vector3(x, 0.52, 8), 0.35, 1.0, mat.metal)
	preload("res://scripts/forest.gd").build(self)
	# Road boundary is physical, with clear atmosphere rather than a fall into void.
	for pos_size in [[Vector3(-38, 2, 0), Vector3(1, 5, 80)], [Vector3(38, 2, 0), Vector3(1, 5, 80)], [Vector3(0, 2, -31), Vector3(80, 5, 1)], [Vector3(0, 2, 36), Vector3(80, 5, 1)]]:
		var boundary := P.box(self, pos_size[0], pos_size[1], mat.black, true)
		boundary.visible = false
		boundary.name = "MapBoundary"
		boundary.set_meta("collision_proxy", true)
	apparition = Node3D.new()
	add_child(apparition)
	P.cylinder(apparition, Vector3(0, 1.20, 0), 0.22, 0.85, mat.black, 0.29)
	P.ellipsoid(apparition, Vector3(0, 1.91, 0), Vector3(0.29, 0.42, 0.28), mat.black)
	P.cylinder(apparition, Vector3(0, 1.66, 0), 0.075, 0.28, mat.black)
	for side in [-1, 1]:
		P.cylinder(apparition, Vector3(side * 0.12, 0.43, 0), 0.085, 0.84, mat.black)
		var arm := P.cylinder(apparition, Vector3(side * 0.34, 1.04, 0), 0.065, 1.15, mat.black)
		arm.rotation.z = side * 0.08
		P.ellipsoid(apparition, Vector3(side * 0.38, 0.43, 0), Vector3(0.09, 0.22, 0.09), mat.black)
	for x in [-0.1, 0.1]:
		P.box(apparition, Vector3(x * 0.7, 1.96, -0.13), Vector3(0.023, 0.014, 0.015), mat.glow)
	apparition.position = Vector3(-6, 0, 9)
	apparition.visible = false

func build_details() -> void:
	# Small, readable props make the workplace feel inhabited.
	P.box(self, Vector3(3.45, 1.19, 2.1), Vector3(0.5, 0.12, 0.36), mat.wood)
	for i in range(7):
		P.box(self, Vector3(3.25 + i * 0.065, 1.34, 2.1), Vector3(0.04, 0.22, 0.2), mat.red if i % 2 == 0 else mat.amber)
	P.label(self, "GUM  $1", Vector3(3.45, 1.22, 2.3), 11, Color("e8e4c9"))
	P.box(self, Vector3(7.15, 1.19, 2.0), Vector3(0.3, 0.1, 0.3), mat.dark)
	P.cylinder(self, Vector3(7.15, 1.35, 2.0), 0.13, 0.22, mat.white)
	P.label(self, "TIPS", Vector3(7.15, 1.36, 2.14), 11, Color("46564e"))
	for i in range(4):
		P.box(self, Vector3(3.8, 1.16 + i * 0.008, 1.87), Vector3(0.21, 0.007, 0.28), mat.white)
	# Coffee cups, stirrers and the folded county newspaper.
	for x in [-7.35, -6.7]:
		P.cylinder(self, Vector3(x, 1.32, 5.05), 0.085, 0.22, mat.white, 0.11)
	P.box(self, Vector3(-6.98, 1.215, 5.25), Vector3(0.65, 0.012, 0.2), mat.white)
	P.label(self, "COUNTY NEWS\nFIFTH DISAPPEARANCE", Vector3(-6.98, 1.225, 5.25), 9, Color("26382e")).rotation.x = -PI / 2
	# Wall clock, safety cabinet and a faded local poster.
	P.cylinder(self, Vector3(7.75, 2.75, 4.5), 0.36, 0.08, mat.dark).rotation.z = PI / 2
	P.label(self, "12\n9     •     3\n6", Vector3(7.69, 2.75, 4.5), 17, Color("cad7c3"), -PI / 2)
	clock_hands = Node3D.new()
	clock_hands.name = "ClockHands"
	clock_hands.position = Vector3(7.675, 2.75, 4.5)
	clock_hands.rotation.y = -PI / 2
	add_child(clock_hands)
	for length_value in [0.17, 0.25]:
		var hand := Node3D.new()
		clock_hands.add_child(hand)
		P.box(hand, Vector3(0, length_value / 2, 0), Vector3(0.018, length_value, 0.009), mat.white)
	update_clock(0)
	P.box(self, Vector3(-7.75, 1.1, 5.8), Vector3(0.17, 0.9, 0.4), mat.red)
	P.label(self, "FIRE", Vector3(-7.65, 1.7, 5.8), 18, Color("f0d7c4"), PI / 2)
	P.box(self, Vector3(7.81, 1.9, -2.8), Vector3(0.03, 1.25, 0.9), mat.amber, false, "note:missing", "Read missing-person notice")
	P.print_quad(self, Vector3(7.775, 1.9, -2.8), Vector2(0.86, 1.21), 2, -PI / 2)
	P.print_quad(self, Vector3(-7.795, 2.05, 3.6), Vector2(0.98, 1.30), 0, PI / 2)
	P.print_quad(self, Vector3(7.795, 1.9, 5.25), Vector2(0.85, 1.1), 1, -PI / 2)
	# Convex mirror and visible CCTV housings.
	for pos in camera_positions:
		if pos.y > 4:
			continue
		P.box(self, pos + Vector3(0, 0.12, 0), Vector3(0.32, 0.2, 0.48), mat.white)
		P.box(self, pos + Vector3(0, 0.1, 0.25), Vector3(0.12, 0.12, 0.02), mat.black)
	# Taped cartons carry printed inventory marks.
	for x in [2, 3.2, 6.8]:
		P.box(self, Vector3(x, 1.405, -7.5), Vector3(0.15, 0.01, 0.94), mat.amber)
		P.label(self, "NORTHSTAR\nDRY GOODS ↑", Vector3(x, 1.05, -7.015), 15, Color("c8b68e"))
	# Scuffed paint around the back room and an employee coat hook.
	for i in range(15):
		P.box(self, Vector3(rng.randf_range(-3.8, 3.8), rng.randf_range(0.2, 0.6), -4.88), Vector3(rng.randf_range(0.08, 0.3), 0.015, 0.009), mat.dark)
	P.box(self, Vector3(-7.6, 1.95, -9.6), Vector3(0.4, 0.7, 0.15), mat.teal)
	P.label(self, "EMPLOYEE\nOF THE MONTH\n\nVACANT", Vector3(-5.3, 2.4, -9.81), 23, Color("cabf9a"))

func car(pos: Vector3, color: Color) -> void:
	var body := Node3D.new()
	add_child(body)
	body.position = pos
	P.box(body, Vector3(0, 0.65, 0), Vector3(1.8, 0.65, 3.8), P.material(color, 0.3), true)
	P.box(body, Vector3(0, 1.15, -0.15), Vector3(1.65, 0.55, 1.85), mat.dark, true)
	for x in [-0.92, 0.92]:
		for z in [-1.15, 1.15]:
			var wheel := P.cylinder(body, Vector3(x, 0.4, z), 0.34, 0.2, mat.black)
			wheel.rotation.z = PI / 2
	for x in [-0.62, 0.62]:
		P.box(body, Vector3(x, 0.7, 1.91), Vector3(0.35, 0.2, 0.03), mat.amber)

func build_weather() -> void:
	# Rain only over open sky; no particles fall through the station ceiling.
	var rain := CPUParticles3D.new()
	detail.rain = rain
	rain.amount = 700
	rain.lifetime = 1.5
	rain.preprocess = 1.5
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(19, 0.1, 11)
	# Keep drops out of the solid pump canopy as well as the station itself.
	var rain_points := PackedVector3Array()
	var rain_rng := RandomNumberGenerator.new()
	rain_rng.seed = 7719
	for i in range(600):
		var point := Vector3(rain_rng.randf_range(-19, 19), 0, rain_rng.randf_range(-11, 11))
		if absf(point.x) < 11 and point.z > -5 and point.z < 3.5:
			continue
		rain_points.append(point)
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINTS
	rain.emission_points = rain_points
	rain.position = Vector3(0, 11, 20)
	rain.direction = Vector3(-0.15, -1, 0.06)
	rain.spread = 2
	rain.initial_velocity_min = 9
	rain.initial_velocity_max = 13
	rain.gravity = Vector3(0, -3, 0)
	var drop := BoxMesh.new()
	drop.size = Vector3(0.013, 0.25, 0.013)
	drop.material = P.material(Color(0.35, 0.55, 0.65, 0.4))
	drop.material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rain.mesh = drop
	add_child(rain)

func lamp(pos: Vector3, color: Color, energy: float, radius: float, indoor: bool) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = radius
	light.omni_attenuation = 1.3
	light.shadow_enabled = false
	light.shadow_bias = 0.15
	light.shadow_normal_bias = 1.5
	light.set_meta("base_energy", energy)
	light.set_meta("indoor", indoor)
	add_child(light)
	lights.append(light)

func add_door(id: String, pos: Vector3, width: float, title: String) -> void:
	var pivot := Node3D.new()
	pivot.position = pos
	add_child(pivot)
	var door_mesh := P.box(pivot, Vector3(width * 0.5, 1.32, 0), Vector3(width, 2.64, 0.12), mat.teal if id != "entrance" else mat.metal, true, "door:" + id, title + " · open / close")
	door_mesh.name = id.capitalize() + "Door"
	door_mesh.set_meta("collision_proxy", true)
	P.box(pivot, Vector3(width - 0.15, 1.1, 0.13), Vector3(0.07, 0.35, 0.06), mat.amber)
	if id == "entrance":
		door_mesh.visible = false
		var glass: Material = detail.glass
		P.box(pivot, Vector3(width / 2, 1.32, 0), Vector3(width - 0.12, 2.5, 0.04), glass)
		for x in [0.04, width - 0.04]:
			P.box(pivot, Vector3(x, 1.32, 0), Vector3(0.08, 2.64, 0.12), mat.metal)
		for y in [0.04, 0.9, 2.6]:
			P.box(pivot, Vector3(width / 2, y, 0), Vector3(width, 0.08, 0.12), mat.metal)
		P.label(pivot, "OPEN\n24 H", Vector3(width / 2, 2.07, 0.08), 22, Color("b9f1d6"))
	doors[id] = {"pivot": pivot, "width": width, "open": false, "tween": null}

func set_door(id: String, opened: bool, duration: float = 0.45, force: bool = false) -> void:
	if not doors.has(id):
		return
	var door: Dictionary = doors[id]
	if door.open == opened:
		return
	if not opened and not force and not door_sweep_clear(id, opened):
		return
	door.open = opened
	if door.tween and door.tween.is_valid():
		door.tween.kill()
	door.tween = create_tween()
	door.tween.tween_property(door.pivot, "rotation:y", PI / 2 if opened else 0.0, duration).set_trans(Tween.TRANS_SINE)

func door_sweep_clear(id: String, opened: bool) -> bool:
	# Test the entire swing against the player's actual capsule, not an oversized
	# invisible keep-out box. A door must never push a clerk into a wall or counter.
	var door: Dictionary = doors[id]
	var shape := BoxShape3D.new()
	shape.size = Vector3(door.width + 0.06, 2.66, 0.18)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 2
	var target := PI / 2 if opened else 0.0
	for step in range(13):
		var angle := lerpf(door.pivot.rotation.y, target, step / 12.0)
		query.transform = global_transform * Transform3D(Basis(Vector3.UP, angle), door.pivot.position) * Transform3D(Basis.IDENTITY, Vector3(door.width * 0.5, 1.32, 0))
		if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			return false
	return true

func toggle_door(id: String) -> void:
	set_door(id, not doors[id].open)

func set_power(value: bool) -> void:
	powered = value
	if is_instance_valid(detail.emergency):
		detail.emergency.visible = not value
	$CeilingShadow.visible = value
	for tube in tubes:
		tube.material_override = mat.glow if value else mat.dark
	for light in lights:
		if light.get_meta("indoor"):
			light.light_energy = light.get_meta("base_energy") if value else 0.025

func reset_jobs() -> void:
	restock_packages.visible = false
	scan_feedback = 0
	scan_strip.material_override = mat.red
	for stain in stains:
		stain.visible = true
		stain.get_meta("interaction_area").collision_layer = 4
	set_power(true)
	apparition.visible = false
	env.ambient_light_energy = 0.28
	env.fog_light_color = Color("172d38")
	for id in doors:
		set_door(id, false, 0.45, true)
	if is_instance_valid(service):
		service.reset()
	update_clock(0)

func update_clock(minutes: int) -> void:
	if minutes == clock_minute or not is_instance_valid(clock_hands):
		return
	clock_minute = minutes
	clock_hands.get_child(0).rotation.z = -float(minutes) / 720 * TAU
	clock_hands.get_child(1).rotation.z = -float(minutes % 60) / 60 * TAU

func tick_feedback(delta: float) -> void:
	if scan_feedback > 0:
		scan_feedback = maxf(0, scan_feedback - delta)
		scan_strip.material_override = mat.green if scan_feedback > 0 else mat.red
