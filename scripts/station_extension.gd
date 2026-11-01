extends Node3D
## Service-room additions share the original world's materials and collision rules.
const P = preload("res://scripts/palette.gd")
var world: Node3D
var dynamic_nodes: Array[Node] = []
var traffic: Node3D
var traffic_time := 0.0
var traffic_wait := 45.0
var rng := RandomNumberGenerator.new()

func build(station: Node3D) -> void:
	world = station
	rng.seed = 9616
	var m: Dictionary = world.mat
	var porcelain := P.material(Color("c9cbb9"), 0.23)
	name = "ServiceDetails"
	# A separate restroom occupies the previously empty eastern office corner.
	P.box(self, Vector3(-2.8, 1.4, -8.5), Vector3(0.12, 2.8, 2.9), m.wall, true).name = "RestroomPartition"
	P.box(self, Vector3(-2.73, 1.4, -7), Vector3(0.26, 2.8, 0.12), m.wall, true)
	P.box(self, Vector3(-0.725, 1.4, -7), Vector3(1.25, 2.8, 0.12), m.wall, true)
	P.box(self, Vector3(-1.975, 2.73, -7), Vector3(1.25, 0.14, 0.12), m.wall, true)
	world.add_door("restroom", Vector3(-2.6, 0, -7), 1.25, "Employee restroom")
	P.label(self, "STAFF WC", Vector3(-1.98, 2.46, -6.91), 16, Color("d7decf"))
	P.box(self, Vector3(-1.3, 0.22, -9.18), Vector3(0.30, 0.44, 0.40), porcelain, true).name = "ToiletBase"
	P.box(self, Vector3(-1.3, 0.48, -9.08), Vector3(0.44, 0.17, 0.62), porcelain, true)
	P.ellipsoid(self, Vector3(-1.3, 0.54, -9.05), Vector3(0.55, 0.26, 0.76), porcelain)
	P.ellipsoid(self, Vector3(-1.3, 0.67, -9.05), Vector3(0.39, 0.025, 0.52), m.dark)
	P.box(self, Vector3(-1.3, 0.86, -9.51), Vector3(0.56, 0.52, 0.20), m.white, true)
	P.box(self, Vector3(-1.05, 0.92, -9.39), Vector3(0.06, 0.025, 0.035), m.metal)
	P.box(self, Vector3(-0.45, 0.84, -7.93), Vector3(0.60, 0.18, 0.67), m.white, true).name = "Washbasin"
	P.ellipsoid(self, Vector3(-0.50, 0.94, -7.93), Vector3(0.40, 0.025, 0.43), m.metal)
	P.cylinder(self, Vector3(-0.24, 1.02, -7.93), 0.025, 0.25, m.metal)
	P.box(self, Vector3(-0.32, 1.14, -7.93), Vector3(0.20, 0.03, 0.035), m.metal)
	P.box(self, Vector3(-0.13, 1.52, -7.93), Vector3(0.02, 0.70, 0.56), m.metal)
	P.box(self, Vector3(-0.40, 1.0, -7.52), Vector3(0.10, 0.15, 0.12), m.teal)
	P.label(self, "WASH YOUR HANDS", Vector3(-2.72, 1.75, -8.5), 10, Color("c3cdbb"), PI / 2)
	world.lamp(Vector3(-1.45, 2.65, -8.4), Color("c1cdb2"), 0.5, 3.1, true)
	P.box(self, Vector3(-1.45, 2.78, -8.4), Vector3(0.65, 0.06, 0.22), m.metal)
	world.tubes.append(P.box(self, Vector3(-1.45, 2.73, -8.4), Vector3(0.55, 0.03, 0.15), m.glow))
	# The exit opens between the existing stock piles; a visible shallow ramp
	# bridges the actual slab height so walking back in does not require jumping.
	P.label(self, "SERVICE EXIT", Vector3(5.1, 2.91, -9.81), 21, Color("9ae0bd"))
	P.label(self, "STAFF ONLY", Vector3(5.1, 1.9, -10.09), 17, Color("b6c6b6"), PI)
	var ramp := P.box(self, Vector3(5.1, -0.105, -10.78), Vector3(1.85, 0.10, 0.90), m.metal, true)
	ramp.name = "ServiceExitRamp"
	ramp.rotation.x = -0.17
	P.box(self, Vector3(5.1, -0.17, -11.55), Vector3(2.5, 0.07, 1.0), m.asphalt, true)
	world.lamp(Vector3(5.1, 2.8, -10.5), Color("dcb77a"), 0.7, 4.0, false)
	P.box(self, Vector3(5.1, 2.85, -10.2), Vector3(0.45, 0.15, 0.18), m.amber)
	# Housekeeping equipment, a pegboard and handover notes avoid all routes.
	P.cylinder(self, Vector3(0.55, 1.05, -8.8), 0.025, 2.0, m.wood).rotation.z = 0.12
	P.box(self, Vector3(0.67, 0.09, -8.8), Vector3(0.45, 0.13, 0.20), m.dark)
	P.cylinder(self, Vector3(0.6, 0.24, -9.35), 0.23, 0.45, m.teal)
	# Visible rack rails surround the original, physically tested restock crates.
	for x in [1.40, 3.80]:
		for z in [-9.32, -8.20]:
			P.box(self, Vector3(x, 0.80, z), Vector3(0.055, 1.60, 0.055), m.metal)
	for height_value in [0.0, 0.70, 1.43]:
		P.box(self, Vector3(2.60, height_value, -8.78), Vector3(2.45, 0.035, 1.15), m.metal)
	P.label(self, "DRY STOCK / COUNT BEFORE DAWN", Vector3(2.60, 1.54, -8.17), 11, Color("c6c9b4"))
	P.box(self, Vector3(1.1, 0.46, -9.35), Vector3(0.07, 0.12, 0.08), m.amber)
	P.box(self, Vector3(-7.80, 2.1, -6.2), Vector3(0.03, 0.7, 0.65), m.wood, false, "note:handover", "Read the previous clerk's handover")
	P.label(self, "HANDOVER / 21 OCT\n\nNo deliveries after midnight.\nIgnore the voice in the stockroom.\nLeave the back light on.\n\n- D.", Vector3(-7.76, 2.1, -6.2), 10, Color("d3cfb6"), PI / 2)
	for i in range(4):
		P.box(self, Vector3(-7.77, 2.30 - i * 0.13, -6.1), Vector3(0.04, 0.02, 0.02), m.metal)
	# Fire extinguisher replaces the old cabinet's flat silhouette.
	P.cylinder(self, Vector3(-7.53, 1.07, 5.8), 0.15, 0.58, m.red)
	P.cylinder(self, Vector3(-7.53, 1.42, 5.8), 0.045, 0.16, m.metal)
	P.box(self, Vector3(-7.53, 1.51, 5.8), Vector3(0.08, 0.03, 0.26), m.black)
	P.box(self, Vector3(-7.34, 1.15, 5.8), Vector3(0.025, 0.48, 0.04), m.black)
	# Curb paint and discarded paper are visual only, never invisible blockers.
	for x in [-9.0, 9.0]:
		for i in range(5):
			P.box(self, Vector3(x, 0.01, 7.7 + i * 0.42), Vector3(0.45, 0.014, 0.16), m.amber)
	for pos in [Vector3(9.2, -0.008, 11.5), Vector3(-8.8, -0.008, 12.2), Vector3(12.0, -0.008, 22)]:
		P.box(self, pos, Vector3(0.21, 0.006, 0.28), m.white).rotation.y = pos.x
	build_traffic()

func build_traffic() -> void:
	traffic = Node3D.new()
	traffic.name = "DistantTraffic"
	add_child(traffic)
	dynamic_nodes.append(traffic)
	P.box(traffic, Vector3(0, 0.55, 0), Vector3(3.8, 0.65, 1.7), world.mat.dark)
	P.box(traffic, Vector3(0.1, 1.03, 0), Vector3(1.9, 0.45, 1.5), world.mat.black)
	var glass := P.material(Color("293b41"), 0.23)
	for side in [-1, 1]:
		P.box(traffic, Vector3(0.1, 1.06, side * 0.76), Vector3(1.62, 0.29, 0.015), glass)
		P.box(traffic, Vector3(0.0, 1.06, side * 0.775), Vector3(0.06, 0.36, 0.02), world.mat.dark)
		P.box(traffic, Vector3(1.70, 0.66, side * 0.86), Vector3(0.20, 0.10, 0.025), world.mat.glow)
		for x in [-1.18, 1.18]:
			P.cylinder(traffic, Vector3(x, 0.30, side * 0.85), 0.29, 0.16, world.mat.black).rotation.x = PI / 2
			P.cylinder(traffic, Vector3(x, 0.30, side * 0.94), 0.14, 0.018, world.mat.metal).rotation.x = PI / 2
	for side in [-1, 1]:
		P.box(traffic, Vector3(1.93, 0.66, side * 0.58), Vector3(0.03, 0.12, 0.26), world.mat.glow)
		P.box(traffic, Vector3(-1.93, 0.66, side * 0.58), Vector3(0.03, 0.12, 0.26), world.mat.red)
	var lamp := SpotLight3D.new()
	lamp.position = Vector3(2.0, 0.65, 0)
	lamp.rotation.y = -PI / 2
	lamp.spot_range = 13
	lamp.spot_angle = 38
	lamp.light_energy = 1.1
	lamp.light_color = Color("cbd7b8")
	traffic.add_child(lamp)
	reset()

func tick(delta: float) -> void:
	if traffic_wait > 0:
		traffic_wait -= delta
		if traffic_wait > 0:
			return
		delta = -traffic_wait
		traffic_wait = 0
	traffic.visible = true
	traffic_time += delta
	traffic.position = Vector3(-43 + traffic_time * 10, -0.02, 32.6)
	if traffic_time >= 8.6:
		traffic.visible = false
		traffic_time = 0
		traffic_wait = rng.randf_range(48, 85)

func reset() -> void:
	traffic_time = 0
	traffic_wait = 45
	traffic.visible = false
