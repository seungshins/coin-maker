extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.combat_audio.muted = true
	game.profile = game.rules.new_profile()
	game.start_run()
	game.player = game.world.centers[0]
	game.camera.position = game.player
	game.camera.reset_smoothing()
	game.aim = Vector2.RIGHT
	game.clock = 0.8
	game.fields.clear()
	game.bolts.clear()
	for id in ["ice_arrow", "lightning_arrow", "fire_arrow", "lava_wave"]:
		game.profile.skill = id
		game.mana = 100
		game.attack(game.rules.skill_spec(game.profile))
		for bolt in game.bolts:
			if bolt.get("skill_id", "") == id: bolt.p += Vector2(80, 0)
	game.profile.skill = "arrow_rain"
	game.cast_field(game.player + Vector2(-80, -100), game.rules.skill_spec(game.profile))
	game.elemental_hit({"skill_id": "ice_arrow", "damage": 50, "attack": 800}, game.enemies[0])
	game.effects.append({"kind": "chain", "p": game.player, "to": game.player + Vector2(190, 80), "life": 0.2})
	game.effects.append({"kind": "travel", "p": game.player - Vector2(120, 0), "to": game.player, "life": 0.2, "leap": true})
	game.world.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/newskills.png")
	quit()
