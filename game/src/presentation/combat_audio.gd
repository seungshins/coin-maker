extends Node
# Short synthesized effects: no downloads, licensed recordings, or runtime files.
var voices: Array[AudioStreamPlayer] = []
var clips := {}
var last_played := {}
var muted := false
var voice_index := 0

func _ready() -> void:
	for i in range(8):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -15.0
		add_child(voice)
		voices.append(voice)
	for kind in ["chain","slash", "whirl", "bow", "bolt", "thunder", "blizzard", "knives", "hit", "hurt", "curse", "death_physical", "death_fire", "death_ice", "death_lightning", "level_up"]:
		clips[kind] = synth(kind)

func play_effect(kind: String) -> void:
	if DisplayServer.get_name() == "headless": return
	if muted or voices.is_empty() or not clips.has(kind): return
	var now := Time.get_ticks_msec()
	if now - int(last_played.get(kind, -1000)) < (90 if kind == "hit" else 65): return
	last_played[kind] = now
	var voice := voices[voice_index]
	voice_index = (voice_index + 1) % voices.size()
	voice.stream = clips[kind]
	voice.play()

func toggle() -> bool:
	muted = not muted
	if muted:
		for voice in voices: voice.stop()
	return muted

func synth(kind: String) -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.18
	if kind in ["thunder", "blizzard", "curse"]: duration = 0.65
	if kind.begins_with("death_"): duration = 0.42
	if kind == "level_up": duration = 0.8
	var count := int(rate * duration)
	var pcm := PackedByteArray()
	pcm.resize(count * 2)
	var noise := RandomNumberGenerator.new()
	noise.seed = kind.hash()
	var filtered := 0.0
	var phase := 0.0
	for i in range(count):
		var t := float(i) / rate
		var progress := t / duration
		var raw := noise.randf_range(-1, 1)
		filtered = lerpf(filtered, raw, 0.22)
		var frequency := 180.0
		var wave := 0.0
		match kind:
			"slash", "whirl", "knives":
				frequency = lerpf(1500, 220, progress)
				wave = raw * 0.5
			"bow":
				frequency = lerpf(420, 110, progress)
				wave = filtered * 0.4
			"chain":
				frequency=1600+sin(t*110)*700
				wave=raw*.8*(.3+.7*absf(sin(t*190)))
			"bolt", "curse":
				frequency = lerpf(950, 190, progress) + sin(t * 80) * 90
				wave = raw * 0.15
			"thunder":
				frequency = lerpf(90, 35, progress)
				wave = filtered * 1.3 + raw * 0.15 * exp(-t * 30)
			"blizzard":
				frequency = 1700 + sin(t * 60) * 350
				wave = filtered * 0.9
			"level_up":
				frequency = [523.25, 659.25, 783.99, 1046.5][mini(3, int(progress * 4))]
				wave = sin(t * TAU * frequency * 2) * 0.1
			"death_physical", "death_fire":
				frequency = lerpf(120, 32, progress)
				wave = filtered * (1.3 if kind == "death_fire" else 0.65)
			"death_ice":
				frequency = lerpf(2700, 700, progress)
				wave = raw * 0.5 * absf(sin(t * 85))
			"death_lightning":
				frequency = 900 + sin(t * 110) * 600
				wave = raw * 0.4 * absf(sin(t * 130))
			"hit", "hurt":
				frequency = lerpf(180, 55, progress)
				wave = raw * 0.35 * exp(-t * 35)
		phase += TAU * frequency / rate
		wave += sin(phase) * (0.09 if kind == "blizzard" else 0.28)
		var envelope := minf(1.0, t / 0.006) * pow(1.0 - progress, 2.0)
		var sample := int(clampf(wave * envelope, -0.9, 0.9) * 32767)
		pcm.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = pcm
	return stream

func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
