extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/title-preview.png")
	game.show_story(0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/story-preview.png")
	game.profile = game.rules.new_profile()
	game.start_run()
	game.set_physics_process(false)
	game.world.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/coast-preview.png")
	game.player = Vector2(2160, 1050)
	game.camera.position = game.player
	game.camera.reset_smoothing()
	game.world.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/boss-preview.png")
	quit()
