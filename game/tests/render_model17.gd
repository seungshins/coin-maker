extends SceneTree
func _initialize()->void:call_deferred("run")
func shot(name_:String)->void:
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/v0217-"+name_+".png")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);await process_frame
	g.profile=g.rules.new_profile();g.start_run();g.enemies.clear();g.clear_modal();g.ambience=0;g.display_settings.display_mode=0;g.display_settings.apply(0,false)
	g.spawn_enemy(g.player+Vector2(160,0),0,"boss",10000,99);var e:Dictionary=g.enemies[0];e.model="cyclops"
	g.boss_combat.prepare(e,g.player);e.windup=.2;g.view3d.camera.size=5.0
	await shot("slam")
	g.enemies.clear();g.spawn_enemy(g.player+Vector2(200,0),0,"boss",10000,199);e=g.enemies[0];e.model="gorgon";e.pattern=1
	g.boss_combat.prepare(e,g.player);e.windup=.35
	await shot("medusa")
	g.queue_free();await process_frame;quit()
