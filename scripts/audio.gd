extends Node

var ambient: AudioStreamPlayer
var rng := RandomNumberGenerator.new()
var clips: Dictionary = {}
var game: Node
var wind: AudioStreamPlayer
var drone: AudioStreamPlayer
var hum: AudioStreamPlayer3D

func _ready() -> void:
	rng.seed = 8491
	for effect in ["click", "scan", "knock", "ring", "scare", "step", "chime", "power", "whisper", "breath", "door", "cash", "thunder", "joint"]:
		clips[effect] = synth(effect)
	ambient = AudioStreamPlayer.new()
	ambient.stream = synth("rain")
	ambient.volume_db = -16
	add_child(ambient)
	ambient.play()
	wind = loop_2d("wind", -32)
	drone = loop_2d("drone", -60)
	hum = AudioStreamPlayer3D.new()
	hum.stream = synth("hum")
	hum.volume_db = -29
	hum.unit_size = 5
	hum.max_distance = 18
	add_child(hum)
	hum.position = Vector3(0, 2.5, -3.5)
	hum.play()

func loop_2d(kind: String, volume: float) -> AudioStreamPlayer:
	var voice := AudioStreamPlayer.new()
	voice.stream = synth(kind)
	voice.volume_db = volume
	add_child(voice)
	voice.play()
	return voice

func _process(delta: float) -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.player) or not is_instance_valid(game.director):
		return
	var inside: bool = absf(game.player.position.x) < 8 and game.player.position.z < 7
	var silent: bool = game.director.silence_time > 0 and game.mode in ["playing", "cameras"]
	ambient.volume_db = lerpf(ambient.volume_db, -80.0 if silent else (-24.0 if inside else -16.0), minf(1, delta * 3))
	wind.volume_db = lerpf(wind.volume_db, -80.0 if silent else (-37.0 if inside else -28.0), minf(1, delta * 3))
	var active: bool = game.mode in ["playing", "cameras", "finale"]
	drone.volume_db = lerpf(drone.volume_db, -55.0 + game.director.tension * 0.24 if active and not silent else -80.0, minf(1, delta * 3))
	hum.volume_db = lerpf(hum.volume_db, -29.0 if game.world.powered and not silent else -80.0, minf(1, delta * 3))

func synth(kind: String) -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.16
	match kind:
		"rain", "wind", "hum", "drone": duration = 4.0
		"ring": duration = 1.5
		"knock": duration = 0.8
		"scare": duration = 2.0
		"chime": duration = 0.7
		"power", "whisper": duration = 1.3
		"breath": duration = 2.5
		"door": duration = 0.85
		"cash": duration = 0.55
		"thunder": duration = 3.0
		"joint": duration = 0.35
	var data := PackedByteArray()
	data.resize(int(rate * duration) * 2)
	var filtered := 0.0
	for i in range(int(data.size() / 2.0)):
		var t := float(i) / rate
		var noise := rng.randf_range(-1, 1)
		filtered = lerpf(filtered, noise, 0.12)
		var envelope := pow(maxf(0, 1.0 - t / duration), 2)
		var sample := 0.0
		match kind:
			"rain": sample = filtered * 0.65 + noise * 0.08 + sin(t * TAU * 48) * 0.025
			"scan": sample = sin(t * TAU * 1400) * envelope * 0.3
			"click": sample = noise * exp(-t * 80) * 0.3
			"step": sample = filtered * exp(-t * 25) * 0.9
			"knock": sample = sin(t * TAU * 95) * exp(-fmod(t, 0.25) * 45) * 0.65
			"ring": sample = (sin(t * TAU * 780) + sin(t * TAU * 1030)) * 0.17 * (1 if fmod(t, 0.5) < 0.3 else 0)
			"scare": sample = (noise * 0.5 + sin(t * TAU * (75 + 80 * t)) * 0.5) * envelope * 0.9
			"chime": sample = sin(t * TAU * (880 if t < 0.3 else 660)) * envelope * 0.35
			"power": sample = (sin(t * TAU * (60 - t * 25)) + filtered) * envelope * 0.4
			"whisper": sample = filtered * sin(t * 32) * envelope * 0.8
			"wind": sample = filtered * 0.4 * (0.55 + 0.25 * sin(t * TAU / 4)) + sin(t * TAU * 110) * 0.025
			"hum": sample = sin(t * TAU * 60) * 0.16 + sin(t * TAU * 120) * 0.05
			"drone": sample = sin(t * TAU * 43) * 0.19 + sin(t * TAU * 44.5) * 0.13 + sin(t * TAU * 87) * 0.04
			"breath": sample = filtered * pow(sin(t / duration * PI), 2) * (0.25 + 0.1 * sin(t * 27))
			"door": sample = (sin(t * TAU * (185 - t * 42)) * 0.12 + filtered * 0.08) * sin(t / duration * PI)
			"cash": sample = (sin(t * TAU * 2200) * exp(-t * 12) + filtered * exp(-absf(t - 0.15) * 30)) * 0.3
			"thunder": sample = (filtered * 0.6 + sin(t * TAU * 38) * 0.18) * sin(t / duration * PI) * envelope
			"joint": sample = filtered * exp(-t * 22) * 0.6 + sin(t * TAU * 130) * exp(-t * 35) * 0.2
		if kind not in ["rain", "wind", "hum", "drone"]:
			sample *= minf(1, t * 200) * minf(1, (duration - t) * 100)
		data.encode_s16(i * 2, int(clampf(sample, -1, 1) * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	if kind in ["rain", "wind", "hum", "drone"]:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = int(data.size() / 2.0)
	return stream

func play_effect(kind: String, volume: float = -8.0) -> void:
	if not clips.has(kind) or get_child_count() >= 20:
		return
	var voice := AudioStreamPlayer.new()
	voice.stream = clips[kind]
	voice.volume_db = minf(volume, -13) if kind == "scare" else volume
	add_child(voice)
	voice.finished.connect(voice.queue_free)
	voice.play()

func _exit_tree() -> void:
	for voice in get_children():
		if voice is AudioStreamPlayer or voice is AudioStreamPlayer3D:
			voice.stop()
			voice.stream = null
	clips.clear()

func play_at(kind: String, location: Vector3, volume: float = -8.0) -> void:
	if not clips.has(kind) or get_child_count() >= 20:
		return
	var voice := AudioStreamPlayer3D.new()
	voice.stream = clips[kind]
	voice.volume_db = volume
	voice.unit_size = 9
	voice.max_distance = 32
	add_child(voice)
	voice.global_position = location
	voice.finished.connect(voice.queue_free)
	voice.play()
