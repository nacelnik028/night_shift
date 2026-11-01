extends SceneTree

var game: Node3D
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error("FAIL: " + message)
		quit(1)
		assert(condition, message)
	checks += 1
	print("PASS: " + message)

func ready_visitor(kind: String) -> void:
	if is_instance_valid(game.active_customer):
		game.active_customer.free()
	game.active_customer = null
	game.spawn_customer(kind)
	game.active_customer.position = Vector3(5, 0, 4)
	game.active_customer.state = "waiting"

func run() -> void:
	if "--night-shift-test" not in OS.get_cmdline_user_args():
		push_error("Tests require --night-shift-test to isolate campaign saves.")
		quit(1)
		return
	game = load("res://scenes/night_shift.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.new_game()
	game.clock_in()
	check(game.mode == "playing", "Clock-in enables gameplay")
	ready_visitor("human")
	game.decide(true)
	check(game.active_customer.state == "waiting", "Unscanned human sale is blocked")
	game.held_product = "wrong"
	game.scan_product()
	check(not game.active_customer.scanned, "Wrong product is rejected")
	game.held_product = game.active_customer.product
	game.scan_product()
	game.decide(true)
	check(game.money > 0 and game.customers_done == 1, "Correct scanned sale earns money")
	ready_visitor("red_eyes")
	game.decide(false)
	check(game.mode == "playing" and game.customers_done == 2, "Rejecting a monster is safe")
	ready_visitor("human")
	game.money = 20
	game.decide(false)
	check(game.money == 12, "Rejecting a human incurs the defined penalty")
	ready_visitor("absent")
	game.decide(true)
	check(game.mode in ["gameover", "scare"], "Accepting a monster ends the shift")
	game._process(2.2)
	check(game.mode == "gameover", "Jumpscare transitions to retry screen")
	game.next_or_retry()
	check(game.money == game.night_start_money, "Retry restores checkpoint money")
	game.clock_in()
	game.player.enabled = false
	game.interact("clean:0")
	game.player.position.x += 1
	game._process(0.1)
	check(game.cleaned.is_empty() and game.work_timer == 0, "Moving cancels cleaning")
	for i in range(3):
		game.interact("clean:" + str(i))
		game._process(2.1)
	check(game.cleaned.size() == 3 and not game.world.stains[2].visible, "All three spills can be cleaned")
	game.interact("restock")
	check(not game.restocked, "Restocking requires a crate")
	game.interact("supplies")
	game.interact("restock")
	game._process(2.1)
	check(game.restocked and not game.carrying_crate, "Crate is consumed to restock")
	game.player.battery = 2
	game.interact("battery")
	check(game.player.battery == 100, "Charger restores flashlight battery")
	game.director.trigger("outage")
	game.security.open()
	check(not game.world.powered and game.mode == "playing", "Power failure blocks camera access")
	game.interact("breaker")
	game.security.open()
	check(game.world.powered and game.mode == "cameras", "Breaker restores live cameras")
	for index in range(4):
		game.security.select(index)
		check(game.security.index == index, "Camera channel %d switches" % index)
	game.security.select(4)
	check(game.security.index == 0, "Camera selection wraps safely")
	game.close_overlay()
	ready_visitor("absent")
	var mesh: MeshInstance3D = game.active_customer.model.get_child(0)
	check(mesh.layers == 2 and game.security.camera.cull_mask == 1, "Camera-invisible monster is excluded from CCTV only")
	check(game.player.camera.cull_mask & 2 != 0, "Player can still see camera-invisible visitor")
	game.set_mode("pause")
	var old_time: float = game.shift_time
	var old_patience: float = game.active_customer.patience
	game._process(10)
	game.active_customer._process(10)
	check(game.shift_time == old_time and game.active_customer.patience == old_patience, "Pause freezes clock and customer patience")
	game.resume_game()
	game.director.trigger("phone")
	game.interact("phone")
	check(game.mode == "phone", "Ringing telephone opens the call")
	game.answer_phone(false)
	check(game.mode == "playing", "Hanging up on the caller is safe")
	game.director.trigger("phone")
	game.interact("phone")
	game.answer_phone(true)
	check(game.mode == "scare", "Inviting the caller triggers a loss")
	game.finish_game_over()
	game.next_or_retry()
	game.clock_in()
	game.director.trigger("storage")
	game.interact("door:storage")
	check(game.mode == "scare", "Opening storage during the warned knock is dangerous")
	game.finish_game_over()
	game.next_or_retry()
	game.clock_in()
	game.director.trigger("storage")
	game.director.advance(15)
	game.interact("door:storage")
	check(game.mode == "playing" and game.world.doors.storage.open, "Storage becomes safe after knocking ends")
	# Exercise the actual movement/collision and interaction ray through physics ticks.
	game.player.position = Vector3(7.2, 0.02, 0)
	game.player.rotation = Vector3(0, -PI / 2, 0)
	game.player.camera.rotation = Vector3.ZERO
	game.player.enabled = true
	Input.action_press("forward")
	for i in range(35):
		await physics_frame
	Input.action_release("forward")
	check(game.player.position.x < 7.6, "Solid station wall blocks player movement")
	game.player.position = Vector3(-5.5, 0.02, -3.8)
	game.player.rotation = Vector3.ZERO
	game.player.velocity = Vector3.ZERO
	game.world.set_door("office", false)
	Input.action_press("forward")
	for i in range(25):
		await physics_frame
	Input.action_release("forward")
	check(game.player.position.z > -4.8, "Closed office door blocks player")
	game.world.set_door("office", true)
	await create_timer(0.6).timeout
	Input.action_press("forward")
	for i in range(30):
		await physics_frame
	Input.action_release("forward")
	check(game.player.position.z < -5.2, "Opened office door permits entry")
	game.player.enabled = false
	game.player.position = Vector3(4.6, 0.02, 0.4)
	game.player.rotation = Vector3.ZERO
	game.player.camera.look_at(Vector3(4.6, 1.2, 2))
	await physics_frame
	game.player.ray.force_raycast_update()
	check(game.player.interaction().get("action", "") == "scan", "First-person ray can target the product scanner")
	var interaction_points := [
		[Vector3(-1.5, 0.03, 0), Vector3(-2.6, 1.1, 0), "product:chips"],
		[Vector3(0, 0.03, -2), Vector3(0, 1.3, -4), "product:water"],
		[Vector3(-5.8, 0.03, 4.8), Vector3(-7, 1.6, 4.8), "product:coffee"],
		[Vector3(6.3, 0.03, 0.6), Vector3(6.3, 1.3, 2.05), "register"],
		[Vector3(5.55, 0.03, 0.55), Vector3(5.55, 1.19, 1.72), "accept"],
		[Vector3(5.95, 0.03, 0.55), Vector3(5.95, 1.19, 1.72), "reject"],
		[Vector3(-5, 0.03, -6.7), Vector3(-5, 1.35, -8.5), "cameras"],
		[Vector3(-3.5, 0.03, -7), Vector3(-3.5, 0.89, -8.4), "phone"],
		[Vector3(-6.5, 0.03, -7.4), Vector3(-6.5, 0.88, -8.25), "battery"],
		[Vector3(4.7, 0.03, -7.5), Vector3(3.2, 1, -7.5), "supplies"],
		[Vector3(6.5, 0.03, -6.3), Vector3(7.73, 1.6, -6.4), "breaker"],
		[Vector3(0.5, 0.03, 3), Vector3(-0.5, 0.08, 3), "clean:0"],
		[Vector3(-2.6, 0.03, 4), Vector3(-2.6, 0.08, 2.7), "restock"]
	]
	for entry in interaction_points:
		game.player.position = entry[0]
		game.player.camera.look_at(entry[1])
		await physics_frame
		game.player.ray.force_raycast_update()
		check(game.player.interaction().get("action", "") == entry[2], "World interaction is reachable: " + entry[2])
	game.new_game()
	game.clock_in()
	for i in range(3):
		ready_visitor("human")
		game.decide(false)
	check(game.mode == "gameover" and not game.death_is_scary, "Rejecting every human cannot bypass the inspection game")
	game.next_or_retry()
	game.clock_in()
	if is_instance_valid(game.active_customer):
		game.active_customer.free()
	game.active_customer = null
	game.spawn_customer("human")
	for i in range(500):
		if game.active_customer.state == "waiting":
			break
		game.active_customer.advance(0.1)
	check(game.active_customer.state == "waiting" and game.active_customer.position.distance_to(Vector3(5, 0, 4)) < 0.2, "Customer walks from outside through the entrance to the counter")
	# Complete all real rosters, including all monster types and task gates.
	game.completed_nights = []
	game.money = 0
	for n in range(1, 6):
		game.night = n
		game.start_night()
		game.clock_in()
		game.player.enabled = false
		check(game.roster.size() == 4 + n, "Night %d has the expected visitor count" % n)
		game.shift_time = game.shift_duration
		game.check_shift_complete()
		check(game.mode == "playing", "Night %d cannot complete before duties" % n)
		for i in range(3):
			game.interact("clean:" + str(i))
			game.work_timer = 0
			game.finish_work()
		game.interact("supplies")
		game.interact("restock")
		game.work_timer = 0
		game.finish_work()
		game.security.open()
		game.close_overlay()
		var kinds: Array = game.roster.duplicate()
		for kind in kinds:
			ready_visitor(kind)
			if kind == "human":
				game.interact("product:" + game.active_customer.product)
				game.scan_product()
				game.decide(true)
			else:
				check(not game.active_customer.clue.is_empty(), "Night %d %s has a discoverable clue" % [n, kind])
				game.decide(false)
			check(game.active_customer.state == "leaving", "Night %d %s exits after decision" % [n, kind])
			var visitor: Node3D = game.active_customer
			for i in range(350):
				if game.active_customer == null:
					break
				visitor.advance(0.1)
			check(game.active_customer == null, "Visitor completes departure path")
		game.shift_time = game.shift_duration
		game.check_shift_complete()
		if n < 5:
			check(game.mode == "complete" and game.unlocked_night == n + 1, "Night %d unlocks next shift" % n)
		else:
			check(game.mode == "finale", "Fifth night starts the final horror sequence")
			for i in range(13):
				game.advance_finale(1)
				if game.mode == "victory":
					break
			check(game.mode == "victory", "Final dawn reaches the victory ending")
	check(game.completed_nights.size() == 5, "All five nights are recorded as complete")
	var saved_money: int = game.money
	game.settings.volume = 0.37
	game.save_progress()
	game.money = 0
	game.completed_nights.clear()
	game.settings.volume = 1
	game.load_progress(true)
	check(game.money == saved_money and game.completed_nights.size() == 5 and game.unlocked_night == 5, "Progress round-trips through a real user-directory save")
	check(is_equal_approx(game.settings.volume, 0.37), "Settings survive save and reload")
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(game.save_path + suffix):
			DirAccess.remove_absolute(game.save_path + suffix)
	print("GAMEPLAY TESTS PASSED: ", checks)
	game.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	quit(0)
