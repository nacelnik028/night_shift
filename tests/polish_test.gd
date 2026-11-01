extends SceneTree
var game: Node3D
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: ", message)

func ticks(count: int) -> void:
	for i in range(count):
		await physics_frame

func travel(start: Vector3, finish: Vector3, title: String) -> void:
	game.player.position = start
	game.player.velocity = Vector3.ZERO
	var direction := finish - start
	game.player.rotation = Vector3(0, atan2(-direction.x, -direction.z), 0)
	await ticks(3)
	game.player.enabled = true
	Input.action_press("forward")
	var count := ceili(Vector2(direction.x, direction.z).length() / 3.5 * 60) + 5
	await ticks(count)
	Input.action_release("forward")
	game.player.enabled = false
	var achieved := Vector2(game.player.position.x - start.x, game.player.position.z - start.z).length()
	check(achieved > Vector2(direction.x, direction.z).length() - 0.25, title + " (travelled %.2fm)" % achieved)

func run() -> void:
	if "--night-shift-test" not in OS.get_cmdline_user_args():
		quit(1)
		return
	Engine.physics_ticks_per_second = 120
	Engine.time_scale = 2
	game = load("res://scenes/night_shift.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.save_path = "user://night_shift.polish.test.json"
	game.new_game()
	game.clock_in()
	game.set_process(false)
	game.director.set_process(false)
	game.player.enabled = false
	for body in game.world.find_children("*", "CollisionObject3D", true, false):
		if body is Area3D:
			check(body.collision_layer == 4 and body.collision_mask == 0, "Interaction area is isolated from physical movement: " + str(body.name))
		elif body is StaticBody3D:
			var mesh: Node3D = body.get_parent()
			if not mesh.is_visible_in_tree():
				check(mesh.get_meta("collision_proxy", false), "Hidden physical body is an intentional proxy: " + str(mesh.name))
	check(game.player.ray.collide_with_areas and game.player.collision_mask == 1, "Player detects interaction areas without colliding with them")
	for entry in [
		[Vector3(-1.8, 0.04, 3), Vector3(0.8, 0.04, 3), "Walk across front spill"],
		[Vector3(-7.2, 0.04, -3.2), Vector3(-6.4, 0.04, -2.1), "Walk across aisle spill"],
		[Vector3(1.4, 0.04, -1.3), Vector3(3.2, 0.04, -1.3), "Walk across counter-side spill"],
		[Vector3(-3.7, 0.04, 2.7), Vector3(-1.5, 0.04, 2.7), "Walk across restock marker"],
		[Vector3(-4.1, 0.04, 2.8), Vector3(-4.1, 0.04, -2.7), "Walk between stocked shelves"],
		[Vector3(-7, 0.04, 2.5), Vector3(-7, 0.04, -3.3), "Walk through left aisle"],
		[Vector3(-1.4, 0.04, 0), Vector3(-1.4, 0.04, -3), "Walk toward refrigerators"],
		[Vector3(3.4, 0.04, 0.5), Vector3(7, 0.04, 0.5), "Walk behind counter and scan zone"],
		[Vector3(2.3, 0.04, 3.5), Vector3(7, 0.04, 3.5), "Walk along visitor side of counter"],
		[Vector3(0, -0.02, 12), Vector3(0, -0.02, 23), "Walk between gas pump islands"],
		[Vector3(3.7, -0.02, 16), Vector3(3.7, -0.02, 22), "Walk beside gas pump"],
		[Vector3(8, -0.02, 10), Vector3(13, -0.02, 10), "Walk across parking lot"]
	]:
		await travel(entry[0], entry[1], entry[2])
	for id in ["entrance", "office", "storage"]:
		game.world.set_door(id, false)
		await create_timer(0.6).timeout
		var x: float = {"entrance": 0.0, "office": -5.5, "storage": 5.5}[id]
		var z := 7.0 if id == "entrance" else -5.0
		game.player.position = Vector3(x, 0.04, z + 1.1)
		game.player.velocity = Vector3.ZERO
		game.player.rotation = Vector3.ZERO
		await ticks(3)
		game.player.enabled = true
		Input.action_press("forward")
		await ticks(30)
		Input.action_release("forward")
		game.player.enabled = false
		check(game.player.position.z > z + 0.25, "Closed " + id + " door blocks passage")
		game.world.set_door(id, true)
		await create_timer(0.6).timeout
		await travel(Vector3(x, 0.04, z + 1.1), Vector3(x, 0.04, z - 1), "Open " + id + " door permits passage")
		await travel(Vector3(x, 0.04, z - 1), Vector3(x, 0.04, z + 1.1), "Return through " + id + " without snagging")
	# Interaction still reaches floor targets, and completed spills stop stealing focus.
	game.player.position = Vector3(0.5, 0.04, 3)
	game.player.camera.look_at(Vector3(-0.5, 0.08, 3))
	await ticks(2)
	check(game.player.interaction().get("action") == "clean:0", "Ray finds non-blocking spill area")
	game.interact("clean:0")
	game.finish_work()
	check(game.world.stains[0].get_meta("interaction_area").collision_layer == 0, "Completed spill disables its interaction layer")
	game.player.position = Vector3(5.5, 0.04, -3.5)
	game.player.camera.look_at(Vector3(5.5, 1.6, -8))
	game.world.set_door("storage", false)
	await create_timer(0.6).timeout
	await ticks(2)
	check(game.player.interaction().get("action", "").begins_with("door:") or game.player.interaction().is_empty(), "Ray cannot interact with supplies through a closed door")
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(game.save_path + suffix):
			DirAccess.remove_absolute(game.save_path + suffix)
	print("POLISH TESTS PASSED: ", checks - failures, " / ", checks)
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	quit(0 if failures == 0 else 1)
