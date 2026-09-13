extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	root.size=Vector2i(1280,720)
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.profile=game.rules.new_profile()
	game.start_run()
	game.view3d.set_process(false)
	game.player=game.world.centers[0]+Vector2(-180,90)
	game.effects.append({"kind":"slash","p":game.player,"angle":0.0,"arc":150,"radius":126,"life":.2})
	for lighting in range(3):
		game.ambience=lighting
		game.view3d.refresh(0)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("E:/workspace/.runtime/v0210-light%d.png"%lighting)
	game.enemies.clear()
	game.effects.clear()
	game.view3d.refresh(0)
	game.view3d.camera.size=4
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/v0210-hero.png")
	game.queue_free()
	await process_frame
	quit()
