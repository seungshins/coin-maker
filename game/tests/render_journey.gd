extends SceneTree
func _initialize()->void:call_deferred("run")
func shot(file:String)->void:
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/"+file+".png")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	g.store.path="user://render_journey.json";g.save_blocked=false
	for variant in [0,3,4,5]:
		g.profile=g.rules.new_profile();g.profile.tier=12;g.profile.map_index=variant;g.start_run();g.enemies.clear();g.view3d.refresh(0)
		g.ui.visible=false
		g.view3d.camera.size=70;g.view3d.camera.position=Vector3(30,55,65);g.view3d.camera.look_at(Vector3(30,0,30))
		await shot("v0212-map%d"%variant)
	g.ui.visible=true;g.profile.cleared=range(g.zone_count()-1);g.player=g.portal_position();g.view3d.refresh(0)
	await shot("v0212-portal")
	g.enter_boss_portal();g.view3d.refresh(0);await shot("v0212-arena")
	g.queue_free();await process_frame;quit()
