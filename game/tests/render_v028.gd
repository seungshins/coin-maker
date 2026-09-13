extends SceneTree
func _initialize() -> void: call_deferred("run")
func shot(name_:String)->void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/v028-"+name_+".png")
func run()->void:
	root.size=Vector2i(1280,720)
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.combat_audio.muted=true
	game.profile=game.rules.new_profile()
	game.start_run()
	game.player=game.world.centers[0]
	game.view3d.refresh(0)
	game.view3d.set_process(false)
	for i in range(3): game.view3d.elements.draw("sample%d"%i,game.view3d.point(game.player+Vector2((i-1)*150,-120),1),["fire","ice","lightning"][i],Vector2(1,2))
	await shot("field")
	game.show_hub()
	game.show_inventory()
	await shot("inventory")
	game.camp_ui.show_stash()
	await shot("stash")
	game.queue_free()
	await process_frame
	quit()
