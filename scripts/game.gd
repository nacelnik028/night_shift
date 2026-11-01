extends Node3D

const WorldScene = preload("res://scenes/station.tscn")
const PlayerScene = preload("res://scenes/player.tscn")
const InterfaceScript = preload("res://scripts/interface.gd")
const SoundScript = preload("res://scripts/audio.gd")
const CustomerScene = preload("res://scenes/customer.tscn")
const DirectorScript = preload("res://scripts/horror_director.gd")
const SecurityScript = preload("res://scripts/security.gd")
var security: Node
var director: Node
var scare_model: Node3D
var scare_timer := 0.0
var finale_timer := 0.0
var save_path := "user://night_shift.json"
var dawn_notice := false
var complaints := 0
var death_is_scary := true
var spawn_timer := 8.0
var roster: Array[String] = []
var visitor_serial := 0
var night_start_money := 0
var world: Node3D
var player: CharacterBody3D
var ui: CanvasLayer
var sound: Node
var mode := "menu"
var night := 1
var unlocked_night := 1
var money := 0
var completed_nights: Array = []
var has_save := false
const WINDOW_RESOLUTIONS := [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]
const DEFAULT_SETTINGS := {"volume": 0.7, "sensitivity": 0.0022, "head_bob": true, "reduced_flashes": false, "fullscreen": false, "exclusive_fullscreen": false, "window_width": 1280, "window_height": 720, "low_graphics": false, "fov": 76.0}
var settings := DEFAULT_SETTINGS.duplicate()
var save_notice := ""
var shift_time := 0.0
var shift_duration := 180.0
var customers_done := 0
var customer_total := 5
var correct_decisions := 0
var active_customer: Node3D
var held_product := ""
var carrying_crate := false
var cleaned: Array = []
var restocked := false
var camera_checked := false
var work_timer := 0.0
var work_action := ""
var work_position := Vector3.ZERO
var death_reason := ""
var last_won := false
var test_mode := false
var windowed_size := Vector2i(1280, 720)
var windowed_position := Vector2i.ZERO
var windowed_mode := Window.MODE_WINDOWED

func _ready() -> void:
	setup_inputs()
	test_mode = "--night-shift-test" in OS.get_cmdline_user_args()
	if test_mode:
		save_path = "user://night_shift.test.json"
	get_window().content_scale_size = Vector2i(1280, 720)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	get_window().min_size = Vector2i(960, 540)
	sound = SoundScript.new()
	sound.game = self
	add_child(sound)
	world = WorldScene.instantiate()
	world.name = "NorthstarStation"
	add_child(world)
	player = PlayerScene.instantiate()
	player.game = self
	add_child(player)
	player.position = Vector3(5, 0.1, 0)
	player.rotation.y = PI
	ui = InterfaceScript.new()
	ui.game = self
	add_child(ui)
	director = DirectorScript.new()
	director.game = self
	add_child(director)
	security = SecurityScript.new()
	security.game = self
	add_child(security)
	var collision_debug := preload("res://scripts/collision_debug.gd").new()
	collision_debug.name = "CollisionDebug"
	collision_debug.game = self
	add_child(collision_debug)
	load_progress()
	if not test_mode:
		set_window_resolution(Vector2i(settings.window_width, settings.window_height))
	apply_settings()
	show_menu_view()
	ui.main_menu()

func setup_inputs() -> void:
	var bindings := {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D, "sprint": KEY_SHIFT, "crouch": KEY_CTRL, "jump": KEY_SPACE, "interact": KEY_E, "flashlight": KEY_F, "tasks": KEY_TAB, "pause": KEY_ESCAPE, "camera_next": KEY_RIGHT, "camera_previous": KEY_LEFT}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = bindings[action]
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)

func night_data() -> Dictionary:
	var data := [
		{"title": "INDUCTION", "brief": "Your predecessor left without collecting their pay. Serve the late arrivals and complete the chores. The first visitor is human. Later visitors may have glowing red eyes. Inspect before you accept."},
		{"title": "BLIND SPOTS", "brief": "Some visitors no longer appear on camera. Use the security office monitor and switch to STORE while a visitor waits. If the counter is empty on a clear live feed, refuse service. Check eyes too."},
		{"title": "THE CALLER", "brief": "The phone may sound familiar. Never invite a caller inside. New imitations have arms that reach their knees and speak about wearing human bodies. Watch the face, the feed, and the words."},
		{"title": "AFTER HOURS", "brief": "Expect a power outage. The breaker is inside storage. If a voice starts knocking, stay out until it stops. Restore power before judging a missing camera image. They have learned your routines."},
		{"title": "LAST LIGHT", "brief": "Nine visitors remain. All known imitations may arrive. The last will carry several tells. Complete your duties, refuse the final imitation, and hold on until dawn. Your car is still outside."}
	]
	return data[night - 1]

func new_game() -> void:
	night = 1
	money = 0
	completed_nights = []
	unlocked_night = 1
	start_night()

func continue_game() -> void:
	load_progress(true)
	night = unlocked_night
	start_night()

func start_night() -> void:
	security.close()
	director.reset()
	if is_instance_valid(scare_model):
		scare_model.queue_free()
	ui.flash.color.a = 0
	if is_instance_valid(active_customer):
		active_customer.queue_free()
	active_customer = null
	night_start_money = money
	correct_decisions = 0
	complaints = 0
	spawn_timer = 8
	visitor_serial = 0
	roster = make_roster()
	dawn_notice = false
	shift_duration = 180 + (night - 1) * 20
	shift_time = 0
	customers_done = 0
	customer_total = 4 + night
	cleaned.clear()
	restocked = false
	camera_checked = false
	held_product = ""
	carrying_crate = false
	work_timer = 0
	world.reset_jobs()
	player.position = Vector3(5, 0.1, 0)
	player.rotation.y = PI
	player.rotation.x = 0
	player.rotation.z = 0
	player.camera.position.y = 1.62
	player.camera.rotation = Vector3.ZERO
	player.stamina = 100
	player.battery = 100
	player.reset_controller()
	set_mode("briefing")
	ui.hud.visible = false
	ui.briefing()
	save_progress()

func clock_in() -> void:
	set_mode("playing")
	ui.clear_modal()
	ui.hud.visible = true
	ui.tasks_open = true
	ui.toast("Midnight. Read your assignment sheet. The first visitor will be here soon.", 7)

func set_mode(value: String) -> void:
	mode = value
	ui.hud.visible = value in ["playing", "finale"]
	player.enabled = value == "playing"
	player.flashlight_model.visible = value in ["playing", "pause", "register", "phone", "cameras"]
	player.torch.visible = player.torch_enabled and player.battery > 0 and value in ["playing", "pause", "register", "phone", "cameras"]
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if player.enabled else Input.MOUSE_MODE_VISIBLE

func show_menu_view() -> void:
	player.position = Vector3(-13, 1.0, 24)
	player.camera.position.y = 1.62
	player.look_at(Vector3(0, 1.7, 4))
	player.camera.rotation = Vector3.ZERO
	player.flashlight_model.visible = false
	player.torch.visible = false

func return_menu() -> void:
	if mode not in ["complete", "victory", "menu"]:
		money = night_start_money
	security.close()
	director.reset()
	world.set_power(true)
	world.service.reset()
	world.apparition.visible = false
	if is_instance_valid(active_customer):
		active_customer.queue_free()
	active_customer = null
	set_mode("menu")
	show_menu_view()
	ui.main_menu()

func resume_game() -> void:
	set_mode("playing")
	ui.clear_modal()

func close_overlay() -> void:
	security.close()
	resume_game()

func _input(event: InputEvent) -> void:
	# Handle before focused Buttons/OptionButtons consume Enter in a menu.
	handle_display_shortcut(event)

func handle_display_shortcut(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed)):
		settings.fullscreen = not settings.fullscreen
		apply_window_mode()
		save_progress()
		get_viewport().set_input_as_handled()
		return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if handle_display_shortcut(event):
		return
	if event.is_action_pressed("pause"):
		if mode == "playing":
			set_mode("pause")
			ui.pause_menu()
		elif mode in ["pause", "register", "cameras", "note"]:
			close_overlay()
		elif mode == "phone":
			answer_phone(false)
	if mode == "cameras":
		if event.is_action_pressed("camera_next"):
			security.select(security.index + 1)
		if event.is_action_pressed("camera_previous"):
			security.select(security.index - 1)
	if event.is_action_pressed("tasks") and mode == "playing":
		ui.tasks_open = not ui.tasks_open

func _process(delta: float) -> void:
	if mode == "finale":
		advance_finale(delta)
		return
	if mode == "scare":
		scare_timer -= delta
		if is_instance_valid(scare_model):
			scare_model.animate(2.0 - scare_timer, settings.reduced_flashes)
		ui.flash.color = Color(0.005, 0.008, 0.01, 1.0 - smoothstep(0.0, 0.55, scare_timer))
		if scare_timer <= 0:
			finish_game_over()
		return
	if mode not in ["playing", "cameras"]:
		return
	shift_time += delta
	world.update_clock(mini(359, int(shift_time / shift_duration * 360)))
	world.service.tick(delta)
	world.tick_feedback(delta)
	update_customers(delta)
	check_shift_complete()
	if mode not in ["playing", "cameras"]:
		return
	if work_timer > 0:
		if player.position.distance_to(work_position) > 0.6:
			work_timer = 0
			ui.toast("Work cancelled. Stay in place to finish.")
		else:
			work_timer -= delta
			if work_timer <= 0:
				finish_work()

func clock_text() -> String:
	var minutes := mini(360 if duties_complete() else 359, int(shift_time / shift_duration * 360))
	var hour := int(minutes / 60.0)
	return "%02d:%02d AM" % [12 if hour == 0 else hour, minutes % 60]

func task_text() -> String:
	return "%s Clean spills (%d / 3)\n%s Restock the snack shelf\n%s Process visitors (%d / %d)%s" % ["✓" if cleaned.size() == 3 else "○", cleaned.size(), "✓" if restocked else "○", "✓" if customers_done >= customer_total else "○", customers_done, customer_total, "\n%s Inspect the security feed" % ("✓" if camera_checked else "○") if night >= 2 else ""]

func order_summary() -> String:
	if not is_instance_valid(active_customer) or active_customer.state != "waiting":
		return "NO CUSTOMER AT THE COUNTER"
	return "%s / %s\n\"%s\"\n\nORDER: %s   •   %s\nPATIENCE: %ds" % [active_customer.visitor_name.to_upper(), "VISITOR %02d" % visitor_serial, active_customer.dialogue, active_customer.product.to_upper(), "SCANNED ✓" if active_customer.scanned else "NOT SCANNED", int(active_customer.patience)]

func interact(action: String) -> void:
	if mode != "playing" or work_timer > 0:
		return
	if action.begins_with("note:"):
		set_mode("note")
		ui.note_screen(action.get_slice(":", 1))
	elif action.begins_with("door:"):
		if action == "door:storage" and director.storage_danger > 0:
			game_over("You opened storage for the false voice before the knocking stopped.")
			return
		var id := action.get_slice(":", 1)
		var was_open: bool = world.doors[id].open
		world.toggle_door(id)
		if world.doors[id].open == was_open:
			ui.toast("Step clear of the door's swing, then try again.", 3)
		else:
			sound.play_at("door", world.doors[id].pivot.position + Vector3.UP, -18)
	elif action.begins_with("product:"):
		held_product = action.get_slice(":", 1)
		sound.play_effect("click")
		ui.toast("Picked up " + held_product + ". Use the scanner on the counter.")
	elif action.begins_with("clean:"):
		var index := int(action.get_slice(":", 1))
		if index not in cleaned:
			begin_work(action)
	elif action == "supplies":
		carrying_crate = true
		ui.toast("Crate collected. Bring it to the RESTOCK marker at the snack aisle.")
	elif action == "restock":
		if carrying_crate and not restocked:
			begin_work("restock")
		else:
			ui.toast("Shelf is full." if restocked else "Get a supply crate from storage first.")
	elif action == "battery":
		player.battery = 100
		ui.toast("Flashlight recharged.")
	elif action == "breaker":
		world.set_power(true)
		ui.toast("Power restored.")
	elif action == "register":
		set_mode("register")
		ui.register_menu()
	elif action == "accept":
		decide(true)
	elif action == "reject":
		decide(false)
	elif action == "cameras":
		security.open()
	elif action == "phone":
		if director.ringing:
			director.ringing = false
			set_mode("phone")
			ui.phone_screen()
		else:
			ui.toast("Only the sound of rain on the line.")
	elif action == "scan":
		scan_product()

func begin_work(action: String) -> void:
	work_action = action
	work_timer = 2.0
	work_position = player.position
	sound.play_effect("step")

func finish_work() -> void:
	if work_action.begins_with("clean:"):
		var index := int(work_action.get_slice(":", 1))
		cleaned.append(index)
		world.stains[index].visible = false
		world.stains[index].get_meta("interaction_area").collision_layer = 0
		ui.toast("Spill cleaned.")
	elif work_action == "restock":
		restocked = true
		world.restock_packages.visible = true
		carrying_crate = false
		ui.toast("Shelf restocked.")
	sound.play_effect("scan")

func decide(accept: bool) -> void:
	close_overlay()
	if not is_instance_valid(active_customer) or active_customer.state != "waiting":
		ui.toast("There is nobody waiting at the counter.")
		return
	if accept and active_customer.is_monster():
		game_over("You accepted an imitation. " + active_customer.clue)
		return
	if accept and not active_customer.scanned:
		ui.toast("Collect the requested product, then use the counter scanner first.")
		return
	if accept:
		var price: int = {"coffee": 5, "chips": 4, "water": 3}[active_customer.product]
		money += price
		correct_decisions += 1
		ui.toast("Sale complete. +$%d. Safe travels." % price)
		sound.play_effect("cash", -14)
	elif active_customer.is_monster():
		correct_decisions += 1
		ui.toast("Service refused. " + active_customer.clue, 6)
		sound.play_effect("whisper", -15)
	else:
		money = maxi(0, money - 8)
		complaints += 1
		ui.toast("That was a human. −$8. Complaint %d / 3." % complaints, 6)
	customers_done += 1
	held_product = ""
	active_customer.react_to_decision(accept)
	active_customer.leave()
	if complaints >= 3:
		game_over("Three customer complaints ended your shift. Inspect every visitor and serve the humans before they lose patience.", false)

func make_roster() -> Array[String]:
	var lists := [
		["human", "red_eyes", "human", "red_eyes", "human"],
		["human", "absent", "red_eyes", "human", "absent", "human"],
		["human", "mimic", "absent", "human", "red_eyes", "mimic", "human"],
		["absent", "human", "mimic", "human", "absent", "red_eyes", "human", "mimic"],
		["human", "absent", "mimic", "human", "absent", "mimic", "human", "red_eyes", "final"]
	]
	var result: Array[String] = []
	result.assign(lists[night - 1])
	# Shuffle the middle so replays retain uncertainty, preserving the tutorial and finale.
	if night > 1:
		for i in range(1, result.size() - 2):
			var j := randi_range(i, result.size() - 2)
			var swap := result[i]
			result[i] = result[j]
			result[j] = swap
	return result

func update_customers(delta: float) -> void:
	if is_instance_valid(active_customer) or customers_done >= customer_total:
		return
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_customer(roster[customers_done])

func spawn_customer(kind: String) -> void:
	var customer: Node3D = CustomerScene.instantiate()
	customer.game = self
	customer.kind = kind
	customer.appearance_seed = night * 100 + visitor_serial * 19 + randi_range(0, 18)
	customer.product = ["coffee", "chips", "water"][visitor_serial % 3]
	customer.visitor_name = ["Traveler", "Truck driver", "Local", "Night worker", "Motorist"][visitor_serial % 5]
	var lines := ["Long drive tonight. Just something for the road.", "I finish work at two. This rain never stops.", "The next town is a long way. Thanks for staying open.", "My family is waiting up. I should get going.", "The radio stopped working near the forest. Bad reception, I guess.", "You work here alone? My brother used to do nights.", "Saw a deer on the shoulder. Nearly hit the poor thing.", "The heater in my truck is broken. Needed somewhere warm."]
	customer.dialogue = lines[customer.appearance_seed % lines.size()]
	if kind == "mimic":
		customer.dialogue = "Your body is warm. I would like to wear it home."
	elif kind == "final":
		customer.dialogue = "We have practiced your smile for five nights. Let us take your place."
	elif kind == "red_eyes":
		customer.dialogue = "A long night. Look me in the eyes when you serve me."
	customer.position = Vector3(12, 0, 24)
	active_customer = customer
	add_child(customer)
	visitor_serial += 1

func customer_ready(_customer: Node3D) -> void:
	sound.play_effect("chime")
	ui.toast("A visitor is waiting. Inspect them before deciding.")

func customer_departed(customer: Node3D) -> void:
	if customer.kind == "human":
		director.previous_dialogue = customer.dialogue
	if active_customer == customer:
		active_customer = null
		spawn_timer = randf_range(maxf(6, 13 - night), maxf(10, 21 - night))
	world.set_door("entrance", false)

func customer_timeout() -> void:
	if not is_instance_valid(active_customer) or active_customer.state != "waiting":
		return
	money = maxi(0, money - 10)
	complaints += 1
	customers_done += 1
	held_product = ""
	active_customer.leave()
	ui.toast("The visitor left unserved. −$10. Complaint %d / 3." % complaints)
	if complaints >= 3:
		game_over("Three visitors were refused or left unserved. Check the field guide in the pause menu and try the shift again.", false)

func scan_product() -> void:
	if not world.powered:
		ui.toast("Scanner offline. Restore the breaker in storage.")
	elif not is_instance_valid(active_customer) or active_customer.state != "waiting":
		ui.toast("Wait for a customer to place an order.")
	elif held_product != active_customer.product:
		ui.toast("Wrong item. The visitor requested " + active_customer.product + ".")
	else:
		active_customer.scanned = true
		world.scan_feedback = 0.7
		held_product = ""
		sound.play_effect("scan")
		ui.toast("Product scanned. Inspect, then use the register to ACCEPT or REJECT.")

func answer_phone(invite: bool) -> void:
	close_overlay()
	if invite:
		game_over("You gave the voice permission to enter. The employee notice warned against invitations.")
	else:
		sound.play_effect("click")
		ui.toast("You hang up. Something outside exhales.", 5)

func game_over(reason: String, scary: bool = true) -> void:
	death_reason = reason
	death_is_scary = scary
	last_won = false
	security.close()
	if not scary:
		finish_game_over()
		return
	set_mode("scare")
	ui.clear_modal()
	ui.hud.visible = false
	scare_timer = 2.0
	sound.play_effect("scare")
	build_scare()

func build_scare() -> void:
	scare_model = preload("res://scripts/encounter.gd").new()
	scare_model.kind = active_customer.kind if is_instance_valid(active_customer) and active_customer.is_monster() else "final"
	player.camera.add_child(scare_model)

func finish_game_over() -> void:
	if is_instance_valid(scare_model):
		scare_model.queue_free()
	ui.flash.color.a = 0
	set_mode("gameover")
	ui.result_screen(false)

func next_or_retry() -> void:
	if last_won:
		night = mini(5, night + 1)
	else:
		money = night_start_money
	start_night()

func duties_complete() -> bool:
	return customers_done >= customer_total and cleaned.size() == 3 and restocked and (camera_checked or night == 1) and world.powered

func check_shift_complete() -> void:
	if shift_time < shift_duration:
		return
	if duties_complete() and not is_instance_valid(active_customer):
		if night == 5:
			begin_finale()
		else:
			complete_night()
	elif not dawn_notice and customers_done >= customer_total:
		dawn_notice = true
		ui.toast("Almost dawn. Finish your assignment sheet and restore power to clock out.", 9)

func complete_night() -> void:
	world.update_clock(360)
	last_won = true
	if night not in completed_nights:
		completed_nights.append(night)
	money += 35 + night * 5
	unlocked_night = mini(5, maxi(unlocked_night, night + 1))
	set_mode("victory" if night == 5 else "complete")
	security.close()
	ui.hud.visible = false
	ui.result_screen(true, night == 5)
	sound.play_effect("chime")
	save_progress()

func begin_finale() -> void:
	security.close()
	set_mode("finale")
	ui.clear_modal()
	ui.hud.visible = true
	ui.customer_text.text = ""
	ui.tasks_open = false
	finale_timer = 12
	world.set_door("entrance", false)
	world.set_power(false)
	world.apparition.position = Vector3(0, 0, 9)
	world.apparition.rotation = Vector3.ZERO
	world.apparition.visible = true
	player.position = Vector3(0, 0.1, 4)
	player.rotation = Vector3(0, PI, 0)
	player.camera.rotation = Vector3.ZERO
	ui.toast("05:59 AM. Outside, something wearing your face waits for the door to open.", 30)
	sound.play_effect("whisper")

func advance_finale(delta: float) -> void:
	finale_timer -= delta
	if finale_timer > 5:
		world.apparition.position.z = maxf(7.4, world.apparition.position.z - delta * 0.22)
	elif finale_timer > 1:
		world.apparition.visible = false
		world.set_power(true)
		world.env.ambient_light_energy = lerpf(world.env.ambient_light_energy, 0.85, delta)
		world.env.fog_light_color = world.env.fog_light_color.lerp(Color("718880"), delta * 0.4)
		world.update_clock(360)
		ui.subtitle.text = "06:00 AM. It cannot stay in the light. You made it."
	if finale_timer <= 0:
		complete_night()

func apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.001, float(settings.volume))))
	AudioServer.set_bus_mute(0, settings.volume <= 0)
	player.sensitivity = float(settings.sensitivity)
	player.base_fov = float(settings.fov)
	player.camera.fov = player.base_fov
	world.detail.quality(settings.low_graphics)
	security.apply_quality(settings.low_graphics)
	if settings.reduced_flashes:
		world.detail.flash_time = 0
		world.detail.tick(0)
		world.set_power(world.powered)
	ui.noise.visible = not settings.reduced_flashes
	if not test_mode:
		apply_window_mode()

func apply_window_mode() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var window := get_window()
	var is_fullscreen := window.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]
	var target_mode := Window.MODE_WINDOWED
	if settings.fullscreen:
		target_mode = Window.MODE_EXCLUSIVE_FULLSCREEN if settings.exclusive_fullscreen else Window.MODE_FULLSCREEN
	if (not settings.fullscreen and not is_fullscreen) or window.mode == target_mode:
		return
	if settings.fullscreen:
		if not is_fullscreen:
			windowed_size = window.size
			windowed_position = window.position
			windowed_mode = window.mode
		window.mode = target_mode
	else:
		window.mode = Window.MODE_WINDOWED
		# Apply restoration after the native window finishes changing its style.
		restore_window.call_deferred()
	# Native style changes can release capture on Windows; restore on the next frame.
	refresh_mouse_capture.call_deferred()

func refresh_mouse_capture() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mode == "playing" and player.enabled else Input.MOUSE_MODE_VISIBLE

func set_display_mode(index: int) -> void:
	settings.fullscreen = index != 0
	settings.exclusive_fullscreen = index == 2
	apply_window_mode()

func set_window_resolution(resolution: Vector2i) -> void:
	if resolution not in WINDOW_RESOLUTIONS:
		return
	settings.window_width = resolution.x
	settings.window_height = resolution.y
	windowed_size = resolution
	if DisplayServer.get_name() != "headless" and get_window().mode not in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]:
		windowed_position = get_window().position
		windowed_mode = Window.MODE_WINDOWED
		get_window().mode = Window.MODE_WINDOWED
		restore_window()

func restore_window() -> void:
	if settings.fullscreen:
		return
	var window := get_window()
	var usable := DisplayServer.screen_get_usable_rect(window.current_screen)
	var restored := windowed_size.min(usable.size - Vector2i(16, 48)).max(Vector2i(960, 540))
	window.size = restored
	window.position = Vector2i(clampi(windowed_position.x, usable.position.x, maxi(usable.position.x, usable.end.x - restored.x)), clampi(windowed_position.y, usable.position.y + 30, maxi(usable.position.y + 30, usable.end.y - restored.y)))
	if windowed_mode == Window.MODE_MAXIMIZED:
		window.mode = Window.MODE_MAXIMIZED

func save_progress() -> bool:
	var checkpoint_money := money if mode in ["briefing", "complete", "victory", "menu"] else night_start_money
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if not file:
		return save_failed()
	file.store_string(JSON.stringify({"version": 1, "unlocked": unlocked_night, "money": checkpoint_money, "completed": completed_nights, "settings": settings, "has_save": has_save or mode != "menu"}))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK or read_checkpoint(save_path + ".tmp").is_empty():
		return save_failed()
	# Keep the last valid checkpoint; never replace it with a corrupted primary.
	if not read_checkpoint(save_path).is_empty():
		if DirAccess.copy_absolute(save_path, save_path + ".bak.tmp") != OK:
			return save_failed()
		if DirAccess.rename_absolute(save_path + ".bak.tmp", save_path + ".bak") != OK:
			return save_failed()
	if DirAccess.rename_absolute(save_path + ".tmp", save_path) != OK:
		return save_failed()
	has_save = has_save or mode != "menu"
	save_notice = ""
	return true

func save_failed() -> bool:
	save_notice = "Progress could not be saved. Check available disk space and folder access."
	if is_instance_valid(ui):
		ui.toast(save_notice, 10)
	return false

func read_checkpoint(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file or file.get_length() > 1048576:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		return {}
	var data: Dictionary = parser.data
	for key in ["version", "unlocked", "money"]:
		var value = data.get(key)
		if not (value is int or value is float) or not is_finite(float(value)):
			return {}
	if data.version != 1 or not data.get("has_save") is bool or not data.get("completed") is Array:
		return {}
	return data

func load_progress(force: bool = false) -> void:
	if test_mode and not force:
		return
	var data: Dictionary = {}
	save_notice = ""
	for suffix in ["", ".bak", ".tmp"]:
		data = read_checkpoint(save_path + suffix)
		if not data.is_empty():
			if suffix != "":
				save_notice = "Recovered the last valid checkpoint after a damaged or interrupted save."
			break
	if data.is_empty():
		unlocked_night = 1
		money = 0
		completed_nights.clear()
		has_save = false
		if FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path + ".bak"):
			save_notice = "No valid checkpoint found. You can begin a new shift."
		return
	unlocked_night = clampi(int(data.get("unlocked", 1)), 1, 5)
	money = int(clampf(float(data.money), 0, 1000000))
	completed_nights.clear()
	if data.get("completed") is Array:
		for value in data.completed:
			if (value is int or value is float) and int(value) in range(1, 6) and int(value) not in completed_nights:
				completed_nights.append(int(value))
	has_save = bool(data.get("has_save", false))
	if data.get("settings") is Dictionary:
		for key in settings:
			if data.settings.has(key):
				var value = data.settings[key]
				if key in ["window_width", "window_height"]:
					continue # Validate the resolution as a pair below.
				elif key in ["volume", "sensitivity", "fov"] and (value is float or value is int) and is_finite(float(value)):
					var limits: Array = {"volume": [0.0, 1.0], "sensitivity": [0.0007, 0.005], "fov": [65.0, 100.0]}[key]
					settings[key] = clampf(float(value), limits[0], limits[1])
				elif DEFAULT_SETTINGS[key] is bool and value is bool:
					settings[key] = value
		var width = data.settings.get("window_width", 1280)
		var height = data.settings.get("window_height", 720)
		if (width is float or width is int) and (height is float or height is int) and is_finite(float(width)) and is_finite(float(height)):
			var resolution := Vector2i(int(clampf(width, 0, 10000)), int(clampf(height, 0, 10000)))
			if resolution in WINDOW_RESOLUTIONS:
				settings.window_width = resolution.x
				settings.window_height = resolution.y
