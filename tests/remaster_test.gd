extends SceneTree
var game: Node3D
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func ticks(count: int) -> void:
	for i in range(count):
		await physics_frame

func walk(start: Vector3, finish: Vector3, title: String) -> void:
	game.player.position = start
	game.player.reset_controller()
	var direction := finish - start
	game.player.rotation = Vector3(0, atan2(-direction.x, -direction.z), 0)
	await ticks(3)
	game.player.enabled = true
	Input.action_press("forward")
	await ticks(ceili(Vector2(direction.x, direction.z).length() / 3.5 * 60) + 8)
	Input.action_release("forward")
	game.player.enabled = false
	check(Vector2(game.player.position.x - finish.x, game.player.position.z - finish.z).length() < 0.45, title + " / " + str(game.player.position))

func run() -> void:
	if "--night-shift-test" not in OS.get_cmdline_user_args():
		quit(1)
		return
	Engine.physics_ticks_per_second = 120
	Engine.time_scale = 2
	game = load("res://scenes/night_shift.tscn").instantiate()
	root.add_child(game)
	game.save_path = "user://night_shift.remaster.test.json"
	game.new_game()
	game.clock_in()
	game.set_process(false)
	game.director.set_process(false)
	game.player.enabled = false
	await ticks(3)
	check(game.world.doors.has("restroom") and game.world.doors.has("rear_exit"), "Service doors exist in the original station")
	for id in ["rules", "missing", "handover"]:
		game.interact("note:" + id)
		check(game.mode == "note" and game.ui.modal.visible and not game.player.enabled, "Environmental note opens safely: " + id)
		game.close_overlay()
		game.player.enabled = false
		check(game.mode == "playing", "Putting down a note resumes the shift")
	for entry in [["restroom", -1.98, -7.0], ["rear_exit", 5.1, -10.0]]:
		var id: String = entry[0]
		var x: float = entry[1]
		var z: float = entry[2]
		game.player.position = Vector3(x, 0.04, z + 0.8)
		game.player.rotation = Vector3.ZERO
		game.player.velocity = Vector3.ZERO
		await ticks(3)
		game.player.enabled = true
		Input.action_press("forward")
		await ticks(30)
		Input.action_release("forward")
		game.player.enabled = false
		check(game.player.position.z > z + 0.2, "Closed " + id + " blocks the capsule")
		game.world.set_door(id, true)
		await create_timer(0.6).timeout
		await walk(Vector3(x, 0.04, z + 0.8), Vector3(x, 0.04, z - 0.8), "Enter " + id)
		await walk(Vector3(x, -0.02 if id == "rear_exit" else 0.04, z - 0.8), Vector3(x, 0.04, z + 0.8), "Return through " + id + " without jumping")
	# Door closure must preserve the player and the door's visual/collision state.
	game.world.set_door("entrance", true)
	await create_timer(0.6).timeout
	game.player.position = Vector3(0, 0.04, 6.85)
	await ticks(3)
	game.world.set_door("entrance", false)
	check(game.world.doors.entrance.open, "An occupied entrance cannot close through the player")
	game.player.position = Vector3(3, 0.04, 5)
	await ticks(3)
	game.world.set_door("entrance", false)
	check(not game.world.doors.entrance.open, "A clear entrance can close normally")
	game.world.set_door("entrance", true)
	await create_timer(0.6).timeout
	game.spawn_customer("human")
	game.active_customer.set_process(false)
	var route: Array[Vector3] = [game.active_customer.position]
	route.append_array(game.active_customer.route)
	game.active_customer.leave()
	route.append_array(game.active_customer.route)
	game.active_customer.free()
	game.active_customer = null
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 1.7
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	for segment in range(route.size() - 1):
		var clear := true
		var samples := ceili(route[segment].distance_to(route[segment + 1]) / 0.25)
		for step in range(samples + 1):
			query.transform.origin = route[segment].lerp(route[segment + 1], step / float(samples)) + Vector3(0, 0.9, 0)
			var hits: Array = game.world.get_world_3d().direct_space_state.intersect_shape(query, 1)
			if not hits.is_empty():
				print("ROUTE BLOCKER: ", hits[0].collider.get_parent().name, " at ", query.transform.origin)
				clear = false
		check(clear, "Customer approach segment %d stays clear of solid decoration" % segment)
	game.world.update_clock(195)
	check(is_equal_approx(game.world.clock_hands.get_child(1).rotation.z, -PI / 2), "Wall clock minute hand reads 03:15")
	check(is_equal_approx(game.world.clock_hands.get_child(0).rotation.z, -195.0 / 720 * TAU), "Wall clock hour hand follows campaign time")
	game.world.service.tick(46)
	check(game.world.service.traffic.visible, "Distant vehicle appears after its cooldown")
	game.world.service.tick(9)
	check(not game.world.service.traffic.visible, "Distant vehicle leaves and resets")
	for value in [0, 20, 40, 60, 80, 100]:
		game.director.tension = value
		check(game.director.tension_level() == mini(5, 1 + int(value / 20.0)), "Five tension levels map correctly at " + str(value))
	game.director.reset()
	game.director.trigger("silence")
	game.sound._process(1)
	check(game.sound.ambient.volume_db <= -79 and game.sound.hum.volume_db <= -79, "Silence event fades environmental loops")
	game.director.advance(5)
	game.sound._process(1)
	check(game.director.silence_time == 0 and game.sound.ambient.volume_db > -40, "Ambience returns after temporary silence")
	game.director.previous_dialogue = "The heater in my truck is broken."
	game.spawn_customer("mimic")
	game.active_customer.state = "waiting"
	game.active_customer.set_process(false)
	game.director.trigger("echo")
	check(game.active_customer.dialogue.begins_with(game.director.previous_dialogue) and game.active_customer.dialogue.contains("wear it home"), "Dialogue echo retains the Mimic's fair explicit clue")
	check(not game.director.event_available("echo"), "A customer cannot repeat the echo indefinitely")
	game.active_customer.free()
	game.active_customer = null
	for kind in ["human", "red_eyes", "mimic", "absent", "final"]:
		game.spawn_customer(kind)
		var visitor: Node3D = game.active_customer
		visitor.set_process(false)
		check(visitor.knees.size() == 2 and visitor.elbows.size() == 2, kind + " retains a complete articulated rig")
		visitor.advance(0.15)
		check(visitor.knees[0].rotation.is_finite() and visitor.elbows[0].rotation.is_finite(), kind + " joint motion stays finite")
		visitor.free()
		game.active_customer = null
	game.held_product = "coffee"
	game.player.sync_held_item()
	check(game.player.held_models.coffee.is_visible_in_tree(), "Collected product has a first-person model")
	var weapon_layers_ok := true
	for mesh in game.player.held_display.find_children("*", "GeometryInstance3D", true, false):
		weapon_layers_ok = weapon_layers_ok and (mesh.layers & game.security.camera.cull_mask) == 0
	check(weapon_layers_ok, "First-person props cannot appear as floating objects on CCTV")
	game.spawn_customer("human")
	game.active_customer.state = "waiting"
	game.active_customer.product = "coffee"
	game.active_customer.set_process(false)
	game.scan_product()
	game.world.tick_feedback(0.1)
	check(game.active_customer.scanned and game.held_product.is_empty() and game.world.scan_strip.material_override == game.world.mat.green, "Scanning consumes the held product and lights the physical scanner")
	game.world.tick_feedback(1)
	check(game.world.scan_strip.material_override == game.world.mat.red, "Scanner feedback returns to idle")
	check(not game.world.restock_packages.visible, "Snack shelf starts with visible stock gaps")
	game.carrying_crate = true
	game.work_action = "restock"
	game.finish_work()
	check(game.world.restock_packages.visible and not game.carrying_crate, "Restocking fills the physical display and consumes the crate")
	for kind in ["red_eyes", "mimic", "absent", "final"]:
		var rig := preload("res://scripts/encounter.gd").new()
		rig.kind = kind
		game.player.camera.add_child(rig)
		var bounded := true
		for step in range(21):
			rig.animate(step / 10.0, false)
			bounded = bounded and rig.mouth.scale.y <= 0.24 and rig.mouth.scale.is_finite()
		check(bounded, kind + " mouth deformation retains its original mesh dimensions")
		rig.free()
	game.active_customer.free()
	game.active_customer = null
	game.set_window_resolution(Vector2i(1600, 900))
	game.settings.fullscreen = true
	game.settings.exclusive_fullscreen = true
	game.save_progress()
	game.settings = game.DEFAULT_SETTINGS.duplicate()
	game.load_progress(true)
	check(game.settings.window_width == 1600 and game.settings.window_height == 900 and game.settings.exclusive_fullscreen, "Resolution and exclusive-mode preference persist")
	var file := FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "unlocked": 3, "money": 50, "completed": [1, 2], "has_save": true, "settings": {"fullscreen": true}}))
	file.close()
	game.settings = game.DEFAULT_SETTINGS.duplicate()
	game.load_progress(true)
	check(game.unlocked_night == 3 and game.settings.fullscreen and not game.settings.exclusive_fullscreen and game.settings.window_width == 1280, "Legacy campaign keeps its progress and defaults to borderless")
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(game.save_path + suffix):
			DirAccess.remove_absolute(game.save_path + suffix)
	print("REMASTER TESTS PASSED: ", checks - failures, " / ", checks)
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures == 0 else 1)
