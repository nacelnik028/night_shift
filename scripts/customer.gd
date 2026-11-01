extends Node3D

const P = preload("res://scripts/palette.gd")
var game: Node
var kind := "human"
var product := "coffee"
var visitor_name := "Visitor"
var dialogue := "Long drive tonight. Just something for the road."
var state := "arriving"
var scanned := false
var age := 0.0
var patience := 100.0
var route: Array[Vector3] = [Vector3(11, 0, 14), Vector3(0, 0, 9), Vector3(0, 0, 4.4), Vector3(5, 0, 4.0)]
var route_index := 0
var model: Node3D
var head: Node3D
var limbs: Array[Node3D] = []
var appearance_seed := 1
var clue := ""
var archetype := "Human"
var jaw: Node3D
var eyelids: Array[Node3D] = []
var eye_meshes: Array[Node3D] = []
var reveal := 0.0
var gesture_age := 0.0
var rejected := false
var event_done := false
var head_height := 1.67
var elbows: Array[Node3D] = []
var knees: Array[Node3D] = []
var gait_phase := 0.0
var watcher_twitch := 0.0
var next_twitch := 12.0

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = appearance_seed
	var skin_colors := [Color("bd977e"), Color("88624b"), Color("d4b698"), Color("664936")]
	var coats := [Color("634f39"), Color("39595e"), Color("6b3435"), Color("3f4b34"), Color("44425c")]
	var skin := P.material(skin_colors[rng.randi_range(0, 3)])
	var cloth := P.material(coats[rng.randi_range(0, 4)])
	cloth.roughness = 0.96
	var pants := P.material(Color("202d34"))
	var dark := P.material(Color("10171c"))
	archetype = {"human": "Human", "red_eyes": "The Watcher", "mimic": "The Mimic", "absent": "The Shadow", "final": "The Broken One"}.get(kind, "Imitation")
	if kind in ["red_eyes", "mimic", "final"]:
		skin.albedo_color = Color("b9beb0") if kind != "final" else Color("9baba3")
	if kind == "absent":
		skin.albedo_color = Color("343c44")
		cloth.albedo_color = Color("111820")
	model = Node3D.new()
	add_child(model)
	P.cylinder(model, Vector3(0, 1.13, 0), 0.28, 0.65, cloth, 0.34)
	P.box(model, Vector3(0, 0.83, 0), Vector3(0.48, 0.12, 0.3), dark)
	P.box(model, Vector3(0, 1.18, -0.265), Vector3(0.025, 0.54, 0.02), dark)
	P.box(model, Vector3(0.16, 1.22, -0.275), Vector3(0.16, 0.15, 0.02), pants)
	# Clothing is fitted to the existing rig; AI routes and clue proportions stay intact.
	var shirt := P.material(Color("a59e88"))
	for side in [-1, 1]:
		P.ellipsoid(model, Vector3(side * 0.27, 1.39, 0), Vector3(0.24, 0.20, 0.30), cloth)
		P.box(model, Vector3(side * 0.075, 1.43, -0.23), Vector3(0.09, 0.14, 0.03), shirt).rotation.z = side * 0.3
	for i in range(4):
		P.box(model, Vector3(0.035, 0.98 + i * 0.10, -0.269), Vector3(0.018, 0.018, 0.012), dark)
	for side in [-1, 1]:
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.14, 0.85, 0)
		model.add_child(leg)
		P.cylinder(leg, Vector3(0, -0.19, 0), 0.105, 0.38, pants, 0.13)
		var knee := Node3D.new()
		knee.position.y = -0.38
		leg.add_child(knee)
		knees.append(knee)
		P.cylinder(knee, Vector3(0, -0.18, 0), 0.085, 0.36, pants, 0.105)
		P.box(knee, Vector3(0, -0.38, -0.07), Vector3(0.22, 0.15, 0.35), dark)
		P.box(knee, Vector3(0, -0.445, -0.07), Vector3(0.225, 0.035, 0.36), pants)
		for lace in range(3):
			P.box(knee, Vector3(0, -0.297, -0.09 - lace * 0.04), Vector3(0.13, 0.01, 0.013), cloth)
		limbs.append(leg)
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.37, 1.4, 0)
		model.add_child(arm)
		var arm_length := 0.95 if kind in ["mimic", "final"] else 0.57
		P.cylinder(arm, Vector3(0, -arm_length * 0.27, 0), 0.10, arm_length * 0.54, cloth, 0.13)
		var elbow := Node3D.new()
		elbow.position.y = -arm_length * 0.54
		arm.add_child(elbow)
		elbows.append(elbow)
		P.cylinder(elbow, Vector3(0, -arm_length * 0.23, 0), 0.078, arm_length * 0.46, cloth, 0.10)
		P.cylinder(elbow, Vector3(0, -arm_length * 0.46 + 0.025, 0), 0.085, 0.075, pants)
		P.ellipsoid(elbow, Vector3(0, -arm_length * 0.46 - 0.06, -0.015), Vector3(0.13, 0.19, 0.11), skin)
		P.ellipsoid(elbow, Vector3(-side * 0.06, -arm_length * 0.46 - 0.025, -0.03), Vector3(0.05, 0.09, 0.055), skin)
		limbs.append(arm)
	var neck_length := 0.39 if kind == "final" else 0.12
	P.cylinder(model, Vector3(0, 1.49, 0), 0.09, neck_length, skin)
	head = Node3D.new()
	head.position = Vector3(0, 1.67 + neck_length - 0.12, 0)
	head_height = head.position.y
	model.add_child(head)
	P.ellipsoid(head, Vector3(0, 0.025, 0), Vector3(rng.randf_range(0.335, 0.37), 0.43, 0.34), skin)
	P.ellipsoid(head, Vector3(0, 0.17, 0.055), Vector3(0.37, 0.17, 0.31), dark)
	P.ellipsoid(head, Vector3(0, -0.008, -0.17), Vector3(rng.randf_range(0.06, 0.085), 0.125, rng.randf_range(0.085, 0.12)), skin).rotation.x = -0.12
	jaw = Node3D.new()
	jaw.position = Vector3(0, -0.115, -0.015)
	head.add_child(jaw)
	P.ellipsoid(jaw, Vector3(0, -0.035, 0), Vector3(0.27, 0.16, 0.28), skin)
	P.box(jaw, Vector3(0, 0.025, -0.134), Vector3(0.16, 0.02, 0.018), dark)
	if is_monster():
		P.box(head, Vector3(0, -0.09, -0.11), Vector3(0.22, 0.12, 0.035), dark)
		for i in range(6):
			P.box(head, Vector3(-0.085 + i * 0.034, -0.074, -0.137), Vector3(0.022, 0.035, 0.015), P.material(Color("c2baa0")))
	var eyes := P.material(Color(1, 0.003, 0.001), 0.5, 0.7) if kind in ["red_eyes", "final"] else P.material(Color("d1d2bc"))
	if kind in ["red_eyes", "final"]:
		eyes.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for side in [-1, 1]:
		var eye_y := 0.045 + (0.022 if kind in ["mimic", "final"] and side == 1 else 0.0)
		var human := kind == "human"
		P.ellipsoid(head, Vector3(side * 0.09, eye_y, -0.145), Vector3(0.098, 0.052, 0.055) if human else Vector3(0.125, 0.09, 0.065), dark)
		eye_meshes.append(P.ellipsoid(head, Vector3(side * 0.09, eye_y, -0.173), Vector3(0.061, 0.026, 0.024) if human else Vector3(0.072, 0.046, 0.033), eyes))
		if kind not in ["red_eyes", "final"]:
			P.box(head, Vector3(side * 0.09, eye_y, -0.193), Vector3(0.018, 0.023, 0.01) if human else Vector3(0.024, 0.032, 0.01), dark)
		var lid := P.box(head, Vector3(side * 0.09, eye_y, -0.202), Vector3(0.085, 0.055, 0.012), skin)
		lid.visible = false
		eyelids.append(lid)
		P.box(head, Vector3(side * 0.09, eye_y + 0.065, -0.156), Vector3(0.1, 0.025, 0.02), dark).rotation.z = side * (-0.18 if kind == "human" else 0.25)
		P.ellipsoid(head, Vector3(side * 0.18, -0.01, 0), Vector3(0.065, 0.12, 0.07), skin)
		if kind in ["mimic", "final"]:
			for i in range(3):
				P.box(head, Vector3(side * (0.085 + i * 0.015), -0.02 - i * 0.025, -0.16), Vector3(0.008, 0.04, 0.01), dark).rotation.z = side * 0.3
	if rng.randf() > 0.5 and kind == "human":
		P.ellipsoid(head, Vector3(0, 0.235, 0.02), Vector3(0.39, 0.20, 0.36), cloth)
		P.box(head, Vector3(0, 0.19, -0.2), Vector3(0.38, 0.045, 0.2), cloth)
	if kind == "human":
		var hair := P.material([Color("29231e"), Color("685647"), Color("8a806a")][appearance_seed % 3])
		for side in [-1, 1]:
			P.ellipsoid(head, Vector3(side * 0.14, 0.14, 0.04), Vector3(0.10, 0.18, 0.28), hair)
		P.ellipsoid(head, Vector3(0, 0.19, 0.03), Vector3(0.35, 0.12, 0.30), hair)
		model.scale = Vector3(rng.randf_range(0.88, 1.08), rng.randf_range(0.94, 1.07), rng.randf_range(0.93, 1.08))
		head.scale = Vector3(0.78, 0.80, 0.83)
		# Jacket seams and pocket flaps read at inspection distance.
		for side in [-1, 1]:
			P.box(model, Vector3(side * 0.17, 1.17, -0.278), Vector3(0.16, 0.035, 0.018), cloth)
			P.box(model, Vector3(side * 0.17, 0.98, -0.255), Vector3(0.14, 0.16, 0.025), cloth)
		if rng.randf() > 0.5:
			for side in [-1, 1]:
				P.box(head, Vector3(side * 0.09, 0.078, -0.207), Vector3(0.095, 0.008, 0.02), dark)
			P.box(head, Vector3(0, 0.05, -0.207), Vector3(0.08, 0.008, 0.02), dark)
	elif kind == "final":
		limbs[1].scale.y = 1.25
		limbs[3].scale.y = 1.45
		model.rotation.z = -0.09
	elif kind == "red_eyes":
		model.scale = Vector3(0.93, 1.05, 0.95)
	if kind == "absent":
		set_camera_layer(model)
	match kind:
		"red_eyes": clue = "The Watcher never blinked. Its eyes glowed red."
		"absent": clue = "The Shadow was missing from the clear live STORE camera."
		"mimic": clue = "The Mimic's arms reached its knees. Its words described you as a body."
		"final": clue = "The Broken One had red eyes, an elongated neck and impossible speech."
	patience = 115.0 - game.night * 7
	next_twitch = rng.randf_range(11, 18)
	game.world.set_door("entrance", true)

func set_camera_layer(node: Node) -> void:
	if node is VisualInstance3D:
		node.layers = 2
	for child in node.get_children():
		set_camera_layer(child)

func is_monster() -> bool:
	return kind != "human"

func _process(delta: float) -> void:
	if game.mode not in ["playing", "cameras"]:
		return
	advance(delta)

func advance(delta: float) -> void:
	age += delta
	if state in ["arriving", "leaving"]:
		gait_phase += delta * (7.2 if state == "arriving" else 10.0)
		if position.z > 5.5 and position.z < 8.5:
			game.world.set_door("entrance", true)
		var target: Vector3 = route[route_index]
		var direction := target - position
		if direction.length() < 0.12:
			route_index += 1
			if route_index >= route.size():
				if state == "leaving":
					game.customer_departed(self)
					queue_free()
					return
				state = "waiting"
				rotation.y = 0
				game.customer_ready(self)
				game.world.set_door("entrance", false)
				return
		else:
			position = position.move_toward(target, delta * (1.8 if state == "arriving" else 2.8))
			rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1, delta * 8))
		for i in range(limbs.size()):
			var stride := sin(gait_phase + (floori(i / 2.0) + i % 2) * PI) * (0.30 if i % 2 == 0 else 0.22)
			limbs[i].rotation.x = lerpf(limbs[i].rotation.x, stride, minf(1, delta * 12))
			if kind == "final":
				limbs[i].rotation.z = sin(age * 5 + i * 1.7) * 0.14
		for i in range(2):
			var phase := gait_phase + i * PI
			knees[i].rotation.x = maxf(0, -sin(phase)) * 0.48 if kind != "absent" else 0.0
			elbows[i].rotation.x = -0.10 - maxf(0, sin(phase)) * (0.18 if kind == "human" else 0.35)
		model.position.y = absf(sin(gait_phase)) * 0.018
		if kind == "absent":
			model.position.y = 0.04 + sin(age) * 0.02
			for limb in limbs:
				limb.rotation.x *= 0.08
		if rejected and kind == "human":
			head.rotation.y = sin(age * 8) * 0.2
	elif state == "waiting":
		patience -= delta
		for limb in limbs:
			limb.rotation.x = lerpf(limb.rotation.x, 0, minf(1, delta * 6))
		for joint in knees:
			joint.rotation.x = lerpf(joint.rotation.x, 0, minf(1, delta * 6))
		for joint in elbows:
			joint.rotation.x = lerpf(joint.rotation.x, -0.08, minf(1, delta * 6))
		animate_waiting(delta)
		if patience <= 0:
			game.customer_timeout()

func animate_waiting(delta: float) -> void:
	gesture_age += delta
	var local_target: Vector3 = to_local(game.player.camera.global_position)
	var yaw := clampf(atan2(-local_target.x, -local_target.z), -0.8, 0.8)
	var tracking := 3.2 if kind == "red_eyes" else 1.4
	head.rotation.y = lerp_angle(head.rotation.y, yaw, minf(1.0, delta * tracking))
	head.rotation.x = lerpf(head.rotation.x, clampf((head.global_position.y - game.player.camera.global_position.y) * 0.3, -0.2, 0.25), minf(1.0, delta * 3))
	model.position.y = sin(age * 1.8) * (0.002 if kind == "red_eyes" else 0.009)
	var blink := fmod(age + appearance_seed * 0.13, 4.7) < 0.12
	for lid in eyelids:
		lid.visible = blink and kind in ["human", "mimic"]
	if kind == "human":
		limbs[1].rotation.z = sin(age * 0.6) * 0.06
		head.rotation.y += sin(age * 0.7) * 0.035
		model.rotation.z = sin(age * 0.45 + appearance_seed) * 0.012
	elif kind == "red_eyes":
		# Long motionless stretches punctuated by one quick, readable neck correction.
		if gesture_age >= next_twitch:
			next_twitch += 17.0 + appearance_seed % 5
			watcher_twitch = 0.22
		watcher_twitch = maxf(0, watcher_twitch - delta)
		head.rotation.z = sin(watcher_twitch / 0.22 * PI) * (0.10 if game.settings.reduced_flashes else 0.27)
	elif kind == "mimic":
		# A slow, wrong imitation of the clerk's posture; permanent clues remain.
		head.rotation.z = lerpf(head.rotation.z, -game.player.camera.rotation.x * 0.4 + 0.13, minf(1, delta))
		reveal = 0.5 + 0.5 * sin(age * 0.45)
		jaw.position.y = -0.115 - reveal * 0.045
	elif kind == "final":
		head.rotation.z = sin(age * 0.6) * 0.33 + (0.22 if fmod(age, 6) < 0.15 else 0.0)
		head.position.x = sin(age * 0.4) * 0.07
		head.position.y = head_height + sin(age * 0.8) * 0.06
		jaw.position.y = -0.17 - absf(sin(age * 0.9)) * 0.06
	elif kind == "absent":
		head.rotation.y = snappedf(head.rotation.y, 0.04)
	if not event_done and gesture_age > 18 and is_monster():
		event_done = game.director.customer_event(kind)

func react_to_decision(accepted: bool) -> void:
	rejected = not accepted
	if kind == "human" and rejected:
		game.ui.toast(["'Seriously? I'll try the next station.'", "'I've been driving for six hours...'", "'Fine. Keep your coffee.'"][appearance_seed % 3], 4)
	elif is_monster():
		jaw.position.y = -0.23
		head.rotation.z = 0.25 if kind == "mimic" else -0.18

func leave() -> void:
	state = "leaving"
	route = [Vector3(0, 0, 4.4), Vector3(0, 0, 10), Vector3(-13, 0, 15), Vector3(-12, 0, 24)]
	route_index = 0
	game.world.set_door("entrance", true)
