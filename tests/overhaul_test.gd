extends SceneTree

var game: Node3D
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func write_file(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(value)
	file.close()

func clear_saves() -> void:
	for suffix in ["", ".tmp", ".bak", ".bak.tmp"]:
		if FileAccess.file_exists(game.save_path + suffix):
			DirAccess.remove_absolute(game.save_path + suffix)

func physics_ticks(count: int) -> void:
	for i in range(count):
		await physics_frame

func run() -> void:
	if "--night-shift-test" not in OS.get_cmdline_user_args():
		push_error("Tests require --night-shift-test to isolate campaign saves.")
		quit(1)
		return
	game = load("res://scenes/night_shift.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.save_path = "user://night_shift.overhaul.test.json"
	clear_saves()
	game.new_game()
	game.clock_in()
	game.set_process(false)
	game.director.set_process(false)
	game.security.set_process(false)
	game.player.enabled = false
	for n in range(1, 6):
		game.night = n
		game.ui.briefing()
		await process_frame
		var description: Label = game.ui.modal.find_child("Description", true, false)
		check(description.size.x <= 1050 and description.get_global_rect().end.x <= 1210, "Night %d briefing text stays inside the modal" % n)
	game.night = 1
	game.ui.clear_modal()

	# Preferences must affect the live world and retain the readable detection clues.
	game.settings.low_graphics = true
	game.settings.fov = 90
	game.settings.volume = 0
	game.apply_settings()
	check(game.world.detail.rain.amount == 220, "Low preset reduces rain particle count")
	check(game.security.viewport.size == Vector2i(512, 288), "Low preset reduces CCTV resolution")
	check(game.world.detail.glass.get_shader_parameter("animate_rain") == false, "Low preset stops window animation")
	check(game.player.camera.fov == 90, "FOV preference applies to the player")
	check(AudioServer.is_bus_mute(0), "Zero master volume actually mutes")
	game.settings.low_graphics = false
	game.settings.volume = 0.7
	game.apply_settings()
	check(game.world.detail.rain.amount == 700 and game.security.viewport.size == Vector2i(768, 432), "Standard preset restores weather and CCTV")
	check(not AudioServer.is_bus_mute(0), "Raising master volume unmutes")
	game.world.detail.lightning(false)
	game.world.detail.tick(0.1)
	check(game.world.detail.storm.light_energy > 0, "Storm produces a rendered lighting cue")
	game.settings.reduced_flashes = true
	game.apply_settings()
	check(game.world.detail.storm.light_energy == 0 and not game.ui.noise.visible, "Reduced effects immediately stops lightning and grain")
	game.world.detail.lightning(true)
	check(game.world.detail.flash_time == 0, "Reduced effects prevents new lightning")

	# Live feeds must explicitly distinguish a missing visitor from a failed signal.
	game.security.open()
	check(not game.security.signal_clear() and game.security.signal_status() == "[CONNECTING]", "Camera switch is labelled unreliable")
	game.security._process(0.4)
	check(game.security.signal_clear(), "Camera settles to a clear live feed")
	check(game.security.viewport.render_target_update_mode == SubViewport.UPDATE_ONCE, "CCTV schedules throttled frames")
	game.director.trigger("interference")
	check(not game.security.signal_clear(), "Static cannot be mistaken for absence")
	game.director.interference = 0
	game.director.trigger("monitor_face")
	check(not game.security.signal_clear(), "Monitor apparition invalidates the feed")
	game.security._process(1.3)
	check(game.security.signal_clear(), "Monitor apparition recovers to clear video")
	game.world.set_power(false)
	game.security._process(0.1)
	check(game.mode == "playing" and game.security.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "Power failure disconnects live rendering")
	game.world.set_power(true)
	game.security.close()

	# Horror pacing and observation must preserve fair decision opportunities.
	game.director.reset()
	game.director.event_cooldown = 0
	check(game.director.request_event("window"), "Ready ambient event can trigger")
	check(not game.director.request_event("forest"), "Global cooldown blocks overlapping events")
	game.director.event_cooldown = 0
	check(not game.director.request_event("window"), "Repeated event is suppressed")
	check(game.director.request_event("forest"), "A different cooled event can trigger")
	game.director.reset()
	game.night = 5
	game.world.set_power(false)
	game.director.ringing = true
	game.director.advance(20)
	check(game.director.tension >= 50, "Late-night darkness and ringing raise tension")
	game.director.reset()
	game.world.set_power(true)
	game.night = 1
	game.spawn_customer("absent")
	game.active_customer.state = "waiting"
	game.active_customer.position = Vector3(5, 0, 4)
	game.active_customer.set_process(false)
	game.director.trigger("vanish")
	check(game.active_customer.model.visible and game.active_customer.state == "waiting", "Vanish never removes an undecided customer")
	game.active_customer.state = "leaving"
	game.active_customer.position.z = 10
	game.director.trigger("vanish")
	check(not game.active_customer.model.visible, "Departing Shadow can disappear")
	game.active_customer.free()
	game.active_customer = null
	game.player.position = Vector3(5, 0.05, 0)
	game.player.camera.look_at(Vector3(12, 1.67, 0))
	await physics_ticks(2)
	check(not game.director.is_observed(Vector3(12, 1.67, 0)), "Solid wall blocks observation of a figure")
	game.player.position = Vector3(3, 0.05, 4)
	game.player.camera.look_at(Vector3(3, 1.67, 9))
	await physics_ticks(2)
	check(game.director.is_observed(Vector3(3, 1.67, 9)), "Front glass permits observation")
	game.player.position = Vector3(5.5, 0.05, -6)
	game.director.trigger("storage")
	check(game.director.storage_danger == 0, "Storage hazard does not trap an employee already inside")
	for i in range(80):
		game.director.trigger("interference")
	check(game.director.events.size() == 64, "Event history remains bounded")

	# The four encounter rigs run without corrupting the player's view transform.
	game.player.position = Vector3(5, 0.05, 0)
	game.player.camera.rotation = Vector3(-0.15, 0.2, 0)
	var original_rotation: Vector3 = game.player.camera.rotation
	for kind in ["red_eyes", "mimic", "absent", "final"]:
		game.spawn_customer(kind)
		game.active_customer.set_process(false)
		game.game_over("Regression encounter")
		check(game.scare_model.kind == kind, "Attack selects the " + kind + " rig")
		for t in [0.0, 0.2, 0.6, 1.2, 1.9]:
			game.scare_model.animate(t, false)
			game.scare_model.animate(t, true)
		game.ui._process(0)
		check(not game.ui.scare_effect.visible, "Reduced effects suppresses " + kind + " distortion")
		check(game.player.camera.rotation == original_rotation, "Attack preserves player view: " + kind)
		game.finish_game_over()
		game.active_customer.free()
		game.active_customer = null
		await process_frame

	# Exercise actual physics for jumping and standing under a low obstruction.
	game.start_night()
	game.clock_in()
	game.director.set_process(false)
	game.player.position = Vector3(1, 0.04, 0)
	game.player.rotation = Vector3.ZERO
	await physics_ticks(8)
	var floor_y: float = game.player.position.y
	Input.action_press("jump")
	await physics_ticks(1)
	Input.action_release("jump")
	await physics_ticks(8)
	check(game.player.position.y > floor_y + 0.2, "Space jumps through the real CharacterBody controller")
	await physics_ticks(55)
	check(absf(game.player.position.y - floor_y) < 0.06, "Jump lands on the station floor")
	Input.action_press("crouch")
	await physics_ticks(4)
	var obstacle := preload("res://scripts/palette.gd").box(game.world, Vector3(1, 1.5, 0), Vector3(1.4, 0.2, 1.4), game.world.mat.dark, true)
	await physics_ticks(3)
	Input.action_release("crouch")
	await physics_ticks(4)
	check(game.player.crouching and is_equal_approx(game.player.body_collision.shape.height, 1.1), "Releasing crouch beneath an obstruction cannot expand into it")
	obstacle.queue_free()
	await physics_ticks(5)
	check(not game.player.crouching and game.player.body_collision.shape.height == 1.75, "Player stands when clearance is restored")
	game.player.velocity = Vector3(3, 4, 5)
	game.player.torch_enabled = false
	game.player.crouching = true
	game.start_night()
	check(game.player.velocity == Vector3.ZERO and not game.player.crouching and game.player.torch_enabled, "Retry resets velocity, stance and flashlight")
	var binding_count := InputMap.action_get_events("jump").size()
	game.setup_inputs()
	check(InputMap.action_get_events("jump").size() == binding_count, "Input setup does not duplicate bindings")

	# Real filesystem corruption and legacy loading, isolated from campaign saves.
	clear_saves()
	game.mode = "briefing"
	game.money = 42
	game.unlocked_night = 3
	game.completed_nights = [1, 2]
	check(game.save_progress(), "Checkpoint writes successfully")
	game.money = 99
	check(game.save_progress(), "Checkpoint replacement succeeds")
	write_file(game.save_path, "{broken")
	game.money = 0
	game.load_progress(true)
	check(game.money == 42 and game.unlocked_night == 3 and game.has_save, "Corrupted primary recovers the last valid backup")
	check(not game.save_notice.is_empty(), "Recovery is explained to the player")
	game.save_progress()
	check(game.read_checkpoint(game.save_path + ".bak").money == 42, "Saving after recovery never backs up corruption")
	clear_saves()
	var legacy := {"version": 1, "unlocked": 4, "money": 80, "completed": [1, 2, 2, 3, 9, "bad"], "has_save": true, "settings": {"volume": 0.37, "sensitivity": true, "head_bob": "false", "fov": 999, "low_graphics": true}}
	game.settings = game.DEFAULT_SETTINGS.duplicate()
	write_file(game.save_path, JSON.stringify(legacy))
	game.load_progress(true)
	check(game.unlocked_night == 4 and game.money == 80 and game.completed_nights == [1, 2, 3], "Version-one campaign loads and filters invalid completed nights")
	check(is_equal_approx(game.settings.volume, 0.37) and game.settings.low_graphics, "Valid old and new preferences load")
	check(game.settings.sensitivity == 0.0022 and game.settings.head_bob == true and game.settings.fov == 100, "Settings reject incorrect types and clamp FOV")
	clear_saves()
	write_file(game.save_path + ".tmp", JSON.stringify(legacy))
	game.load_progress(true)
	check(game.has_save and game.money == 80, "Interrupted first save recovers a validated temporary checkpoint")
	clear_saves()
	for invalid in ["[]", "null", "{}", '{"version":1,"unlocked":[],"money":0,"completed":[],"has_save":true}']:
		write_file(game.save_path, invalid)
		game.load_progress(true)
		check(not game.has_save and game.unlocked_night == 1, "Malformed checkpoint is rejected safely: " + invalid)
	clear_saves()
	check(game.read_checkpoint(game.save_path).is_empty(), "Missing checkpoint is handled safely")
	print("OVERHAUL TESTS PASSED: ", checks - failures, " / ", checks)
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	quit(0 if failures == 0 else 1)
