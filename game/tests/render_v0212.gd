extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_physics_process(false)
	g.profile=g.rules.new_profile();g.profile.tier=12;g.start_run()
	g.player=g.world.centers[6];g.view3d.refresh(0)
	for i in range(5):await process_frame
	g.view3d.camera.size=70
	g.view3d.camera.position=Vector3(30,55,65)
	g.view3d.camera.look_at(Vector3(30,0,30))
	g.view3d.set_process(false)
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/v0212-island.png")
	g.queue_free();await process_frame;quit()
