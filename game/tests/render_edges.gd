extends SceneTree
func _initialize()->void:call_deferred("run")
func shot(file:String)->void:
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/"+file+".png")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_physics_process(false)
	g.profile=g.rules.new_profile();g.profile.tier=12;g.start_run()
	g.profile.buffs=["might","ward"];g.burst_timers={"burst:rage":5.0,"burst:haste":6.0};g.stolen_affixes={"swift":12.0}
	g.display_settings.choose_resolution(3)
	await shot("v0212-edge-qhd")
	g.show_shop();await shot("v0212-actions")
	g.show_hub();await shot("v0212-town-guide")
	g.controls.show_panel(g.show_hub);await shot("v0212-keys")
	g.display_settings.choose_resolution(0);g.clear_modal();g.mode="play"
	await shot("v0212-edge-720")
	g.queue_free();await process_frame;quit()
