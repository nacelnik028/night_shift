extends SceneTree

var game: Node3D

func _initialize() -> void:
	call_deferred("run")

func capture(filename: String) -> void:
	if game.mode == "cameras":
		await create_timer(0.4).timeout
	for i in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("res://artifacts/" + filename + ".png")
	print("CAPTURE ", filename, " ", error)

func run() -> void:
	if "--night-shift-test" not in OS.get_cmdline_user_args():
		push_error("Tests require --night-shift-test to isolate campaign saves.")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/night_shift.tscn").instantiate()
	root.add_child(game)
	await capture("01_menu")
	game.ui.settings_menu("menu")
	await capture("14_settings")
	game.ui.main_menu()
	game.new_game()
	game.clock_in()
	game.player.enabled = false
	game.player.position = Vector3(0.5, 0.1, 5.5)
	game.player.rotation = Vector3(0, -0.35, 0)
	game.ui.tasks_open = false
	await capture("02_store")
	game.player.position = Vector3(-4.1, 0.04, 3.5)
	game.player.rotation = Vector3.ZERO
	game.player.camera.rotation.x = -0.08
	await capture("20_retail_remaster")
	game.world.restock_packages.visible = true
	await capture("26_restocked_display")
	game.world.restock_packages.visible = false
	game.director.trigger("shelf_shadow")
	game.player.camera.look_at(Vector3(-4.1, 1.5, 0))
	await capture("27_shelf_shadow")
	game.director.apparition_time = 0
	game.world.apparition.visible = false
	game.world.set_door("office", true)
	game.world.set_door("restroom", true)
	await create_timer(0.6).timeout
	game.player.position = Vector3(-1.8, 0.04, -6)
	game.player.camera.look_at(Vector3(-1.2, 1.25, -9))
	await capture("21_restroom")
	game.interact("note:handover")
	await capture("25_handover_note")
	game.close_overlay()
	game.player.enabled = false
	game.world.set_door("rear_exit", true)
	await create_timer(0.6).timeout
	game.player.position = Vector3(5.1, 0.04, -8.5)
	game.player.camera.look_at(Vector3(5.1, 1.3, -12))
	await capture("22_service_exit")
	game.player.position = Vector3(0, 0.04, 24)
	game.player.camera.look_at(Vector3(0, 1.0, 32.6))
	game.world.service.traffic_wait = 0
	game.world.service.traffic_time = 4.3
	game.world.service.tick(0)
	await capture("23_distant_traffic")
	game.world.service.reset()
	game.player.camera.rotation = Vector3.ZERO
	game.player.position = Vector3(5, 0.1, 0.4)
	game.player.rotation = Vector3(0, PI, 0)
	for product in ["coffee", "chips", "water"]:
		game.held_product = product
		await capture("24_held_" + product)
	game.held_product = ""
	game.spawn_customer("red_eyes")
	game.active_customer.position = Vector3(5, 0, 4)
	game.active_customer.state = "waiting"
	await capture("03_customer")
	for kind in ["human", "mimic", "final"]:
		game.active_customer.free()
		game.active_customer = null
		game.spawn_customer(kind)
		game.active_customer.position = Vector3(5, 0, 4)
		game.active_customer.state = "waiting"
		await capture("15_visitor_" + kind)
	game.security.open()
	game.security.select(2)
	await capture("04_camera")
	game.close_overlay()
	game.set_mode("register")
	game.ui.register_menu()
	await capture("07_register")
	game.close_overlay()
	game.active_customer.free()
	game.active_customer = null
	game.spawn_customer("absent")
	game.active_customer.position = Vector3(5, 0, 4)
	game.active_customer.state = "waiting"
	game.security.open()
	game.security.select(2)
	await capture("08_absent_camera")
	game.director.trigger("interference")
	await capture("16_camera_static")
	game.director.interference = 0
	game.settings.low_graphics = true
	game.apply_settings()
	await capture("17_camera_low")
	game.settings.low_graphics = false
	game.apply_settings()
	game.close_overlay()
	game.player.enabled = false
	game.world.set_door("office", true)
	game.player.position = Vector3(-5.5, 0.1, -5.8)
	game.player.rotation = Vector3.ZERO
	game.player.camera.rotation = Vector3(-0.1, 0, 0)
	await create_timer(0.5).timeout
	await capture("09_office")
	game.director.trigger("phone")
	game.interact("phone")
	await capture("10_phone")
	game.answer_phone(false)
	game.ui.hud.visible = false
	game.player.enabled = false
	game.player.position = Vector3(16, 1.1, 27)
	game.player.look_at(Vector3(0, 1.7, 2))
	await capture("05_exterior")
	game.game_over("Visual verification of the jumpscare.")
	game.scare_timer = 1.2
	await capture("06_scare")
	game.finish_game_over()
	for kind in ["red_eyes", "mimic", "final"]:
		game.active_customer.kind = kind
		game.game_over("Rendered encounter verification.")
		game.scare_timer = 1.2
		await capture("18_attack_" + kind)
		game.finish_game_over()
	game.settings.reduced_flashes = true
	game.apply_settings()
	game.game_over("Reduced-effects verification.")
	game.scare_timer = 1.2
	await capture("19_attack_reduced")
	game.finish_game_over()
	game.settings.reduced_flashes = false
	game.apply_settings()
	game.night = 5
	game.completed_nights = [1, 2, 3, 4]
	game.start_night()
	await capture("11_briefing")
	game.clock_in()
	game.shift_time = game.shift_duration
	game.customers_done = game.customer_total
	game.cleaned = [0, 1, 2]
	game.restocked = true
	game.camera_checked = true
	game.begin_finale()
	for i in range(80):
		game.advance_finale(0.1)
	await capture("12_dawn")
	game.complete_night()
	await capture("13_victory")
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(game.save_path + suffix):
			DirAccess.remove_absolute(game.save_path + suffix)
	print("RENDERED VISUAL CHECK COMPLETE")
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	quit()
