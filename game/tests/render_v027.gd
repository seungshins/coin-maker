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
	game.player = game.world.centers[2] - Vector2(90,0)
	game.enemies[-1].hp *= 0.65
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/v027-boss.png")
	game.queue_free()
	await process_frame
	quit()
