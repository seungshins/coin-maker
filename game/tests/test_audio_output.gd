extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var audio = preload("res://src/presentation/combat_audio.gd").new()
	root.add_child(audio)
	audio.play_effect("thunder")
	await create_timer(0.05).timeout
	var started: bool = audio.voices[0].playing
	audio.toggle()
	var stopped: bool = not audio.voices[0].playing
	audio.queue_free()
	await create_timer(0.15).timeout
	print("PASS: live audio start and mute" if started and stopped else "FAIL: audio playback state")
	quit(0 if started and stopped else 1)
