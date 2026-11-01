extends Node

var game: Node
var elapsed := 0.0
var next_event := 26.0
var flicker_time := 0.0
var apparition_time := 0.0
var interference := 0.0
var ringing := false
var ring_timer := 0.0
var ring_age := 0.0
var phone_done := false
var outage_done := false
var knock_done := false
var storage_danger := 0.0
var events: Array[String] = []
var customer_event_cooldown := 0.0
var tension := 0.0
var event_cooldown := 0.0
var event_cooldowns: Dictionary = {}
var last_event := ""
var reflection_time := 0.0
var footsteps_left := 0
var footsteps_time := 0.0
var apparition_observed := 0.0
var silence_time := 0.0
var previous_dialogue := ""
var shelf_motion := false

func reset() -> void:
	elapsed = 0
	next_event = 26
	flicker_time = 0
	apparition_time = 0
	interference = 0
	ringing = false
	ring_age = 0
	phone_done = false
	outage_done = false
	knock_done = false
	storage_danger = 0
	events.clear()
	customer_event_cooldown = 0
	tension = 0
	event_cooldown = 12
	event_cooldowns.clear()
	last_event = ""
	reflection_time = 0
	footsteps_left = 0
	apparition_observed = 0
	silence_time = 0
	previous_dialogue = ""
	shelf_motion = false
	game.world.detail.mirror_figure.visible = false
	game.world.detail.flash_time = 0
	game.world.detail.tick(0)
	game.world.apparition.visible = false

func _process(delta: float) -> void:
	if game.mode not in ["playing", "cameras"]:
		return
	advance(delta)

func advance(delta: float) -> void:
	elapsed += delta
	var target: float = 8.0 + (game.night - 1) * 8.0 + minf(20, elapsed / 18)
	if not game.world.powered:
		target += 25
	if ringing or storage_danger > 0:
		target += 20
	if is_instance_valid(game.active_customer) and game.active_customer.state == "waiting":
		target += 10
	tension = move_toward(tension, clampf(target, 0, 100), delta * 3)
	silence_time = maxf(0, silence_time - delta)
	event_cooldown = maxf(0, event_cooldown - delta)
	for event in event_cooldowns:
		event_cooldowns[event] = maxf(0, event_cooldowns[event] - delta)
	game.world.detail.tick(delta)
	customer_event_cooldown = maxf(0, customer_event_cooldown - delta)
	if game.night >= 3 and elapsed > 48 and not phone_done and event_cooldown <= 0:
		phone_done = true
		trigger("phone")
	if game.night >= 4 and elapsed > 105 and not outage_done and event_cooldown <= 0 and not ringing:
		outage_done = true
		trigger("outage")
	if game.night >= 4 and elapsed > 160 and not knock_done and event_cooldown <= 0 and game.world.powered:
		knock_done = true
		trigger("storage")
	if elapsed > next_event and event_cooldown <= 0 and storage_danger <= 0 and not ringing:
		next_event = elapsed + randf_range(28, 46) - tension * 0.08
		var choices := ["window", "forest", "thunder"]
		if tension >= 25:
			choices.append_array(["flicker", "shadow", "shelf_shadow", "reflection", "whisper"])
		if tension >= 50:
			choices.append_array(["door", "interference", "footsteps", "silence"])
		if tension >= 65:
			choices.append_array(["monitor_face", "vanish", "echo"])
		choices = choices.filter(func(candidate): return event_available(candidate))
		var event: String = choices.pick_random()
		request_event(event)
	if flicker_time > 0:
		flicker_time -= delta
		if game.world.powered:
			for light in game.world.lights:
				if light.get_meta("indoor"):
					var factor := 0.7 if game.settings.reduced_flashes else (0.12 if sin(elapsed * 31) < -0.35 else 1.0)
					light.light_energy = float(light.get_meta("base_energy")) * factor
			if flicker_time <= 0:
				game.world.set_power(true)
	if apparition_time > 0:
		apparition_time -= delta
		if shelf_motion:
			game.world.apparition.position.z = lerpf(1.3, -1.4, 1.0 - clampf(apparition_time / 2.4, 0, 1))
		var point: Vector3 = game.world.apparition.global_position + Vector3(0, 1.8, 0)
		if is_observed(point):
			apparition_observed += delta
		else:
			apparition_observed = 0
		if apparition_observed > 0.25:
			apparition_time = 0
		if apparition_time <= 0:
			game.world.apparition.visible = false
			shelf_motion = false
	reflection_time = maxf(0, reflection_time - delta)
	game.world.detail.mirror_figure.visible = reflection_time > 0
	if footsteps_left > 0:
		footsteps_time -= delta
		if footsteps_time <= 0:
			footsteps_time = 0.65
			footsteps_left -= 1
			game.sound.play_at("step", game.player.position + game.player.transform.basis.z * (3.0 + footsteps_left), -12)
	interference = maxf(0, interference - delta)
	if storage_danger > 0:
		storage_danger -= delta
		if storage_danger <= 0:
			game.ui.toast("The knocking stops. Storage is safe to enter.")
	if ringing:
		ring_timer -= delta
		ring_age += delta
		if ring_timer <= 0:
			game.sound.play_at("ring", Vector3(-3.5, 1, -8.4), -9)
			ring_timer = 3.0
		if ring_age > 35:
			ringing = false
			game.ui.toast("The caller hangs up. Some questions are better left unanswered.")

func trigger(event: String) -> void:
	events.append(event)
	if events.size() > 64:
		events.pop_front()
	last_event = event
	event_cooldown = 16.0 if event not in ["phone", "outage", "storage"] else 25.0
	event_cooldowns[event] = 65.0
	match event:
		"flicker":
			flicker_time = 2.2
			game.sound.play_effect("power", -20)
		"window":
			game.sound.play_at("knock", Vector3(-4, 1.5, 7), -6)
			game.ui.toast("Three taps against the front window.", 3)
		"shadow", "apparition", "forest":
			shelf_motion = false
			game.world.apparition.position = Vector3(-5.5 if event == "shadow" else 5.5, 0, 9)
			if event == "forest":
				game.world.apparition.position = Vector3(-20, 0, 15)
			game.world.apparition.visible = true
			face_apparition()
			apparition_observed = 0
			apparition_time = 3.2 if event == "shadow" else 5.0
			game.sound.play_at("whisper", game.world.apparition.position + Vector3(0, 1.5, 0), -12)
		"shelf_shadow":
			shelf_motion = true
			game.world.apparition.position = Vector3(-4.1, 0, 1.3)
			game.world.apparition.visible = true
			face_apparition()
			apparition_time = 2.4
			apparition_observed = 0
		"door":
			if storage_danger <= 0:
				game.world.set_door("office", true, 3.0)
			game.sound.play_at("door", Vector3(-5.5, 1, -5), -16)
		"interference":
			interference = 3
		"monitor_face":
			# Never overlay the visitor while declaring a feed clear.
			game.security.face_time = 0.65
			game.security.blackout_time = 1.2
		"reflection":
			reflection_time = 4.0
		"whisper":
			game.sound.play_at("whisper", game.player.position + game.player.transform.basis.z * 1.8 + Vector3.UP, -17)
		"footsteps":
			footsteps_left = 4
			footsteps_time = 0
		"thunder":
			game.world.detail.lightning(game.settings.reduced_flashes)
			game.sound.play_at("thunder", Vector3(-18, 8, 22), -17)
		"vanish":
			# Only a departing imitation can vanish; never remove an undecided order.
			if is_instance_valid(game.active_customer) and game.active_customer.kind == "absent" and game.active_customer.state == "leaving" and game.active_customer.position.z > 8:
				game.active_customer.model.visible = false
		"silence":
			silence_time = 4.5
		"echo":
			if event_available("echo"):
				game.active_customer.dialogue = previous_dialogue + " ... " + game.active_customer.dialogue
				game.active_customer.set_meta("echoed", true)
		"phone":
			ringing = true
			ring_timer = 0
			ring_age = 0
			game.ui.toast("The security office phone is ringing. Remember: never invite a caller inside.", 8)
		"outage":
			game.world.set_power(false)
			game.sound.play_effect("power")
			game.ui.toast("Power lost. Use your flashlight. The breaker is on the right wall inside storage.", 9)
		"storage":
			# Never trap the player inside the threatened room.
			if game.player.position.z < -5 and game.player.position.x > 0:
				knock_done = false
				return
			game.world.set_door("storage", false)
			storage_danger = 14
			game.sound.play_at("knock", Vector3(5.5, 1.5, -5), -5)
			game.ui.toast("A voice behind storage: 'It's me. Open up.' DO NOT open storage until the knocking stops.", 12)

func customer_event(kind: String) -> bool:
	if customer_event_cooldown > 0 or event_cooldown > 0 or storage_danger > 0 or ringing:
		return false
	customer_event_cooldown = 32
	event_cooldown = 16
	match kind:
		"red_eyes": trigger("flicker")
		"mimic": game.sound.play_at("breath", game.active_customer.position + Vector3.UP, -19)
		"absent": trigger("shadow")
		"final": game.sound.play_at("joint", game.active_customer.position + Vector3.UP, -19)
	return true

func request_event(event: String) -> bool:
	if event_cooldown > 0 or event_cooldowns.get(event, 0.0) > 0 or event == last_event or storage_danger > 0 or ringing or not event_available(event):
		return false
	trigger(event)
	return true

func event_available(event: String) -> bool:
	if event == "vanish":
		return is_instance_valid(game.active_customer) and game.active_customer.kind == "absent" and game.active_customer.state == "leaving" and game.active_customer.position.z > 8 and not is_observed(game.active_customer.global_position + Vector3.UP)
	if event == "echo":
		return not previous_dialogue.is_empty() and is_instance_valid(game.active_customer) and game.active_customer.kind == "mimic" and game.active_customer.state == "waiting" and not game.active_customer.has_meta("echoed")
	if event == "door":
		return not game.world.doors.office.open
	if event == "monitor_face":
		return game.mode == "cameras" and game.world.powered
	return true

func face_apparition() -> void:
	var direction: Vector3 = game.player.global_position - game.world.apparition.global_position
	game.world.apparition.rotation.y = atan2(-direction.x, -direction.z)

func tension_level() -> int:
	return clampi(1 + floori(tension / 20), 1, 5)

func is_observed(point: Vector3) -> bool:
	var camera: Camera3D = game.player.camera
	var direction := (point - camera.global_position).normalized()
	if camera.is_position_behind(point) or (-camera.global_basis.z).dot(direction) <= 0.96:
		return false
	# Looking toward a figure through a solid wall must not dismiss it.
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, point, 1, [game.player.get_rid()])
	var hit: Dictionary = game.world.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	# Front windows and entrance glass are physically solid but visually transparent.
	var location: Vector3 = hit.position
	return absf(location.z - 7.0) < 0.15 and location.y > 1.1 and location.y < 2.7

func tension_band() -> String:
	if tension >= 75: return "critical"
	if tension >= 50: return "high"
	if tension >= 25: return "medium"
	return "low"
