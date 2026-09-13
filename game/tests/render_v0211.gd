extends SceneTree
func _initialize()->void:call_deferred("run")
func shot(name_:String)->void:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/v0211-"+name_+".png")
func run()->void:
	root.size=Vector2i(1280,720)
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game);game.set_physics_process(false)
	game.profile=game.rules.new_profile();game.start_run()
	game.profile.skill="blade_orbit"
	game.cast_field(game.player,game.rules.skill_spec(game.profile))
	game.profile.skill="tidal_aura"
	game.cast_field(game.player,game.rules.skill_spec(game.profile))
	game.ambience=0;game.health=62;game.mana=46
	await shot("hud")
	game.show_hub();await shot("town")
	game.camp_ui.show_codex();await shot("codex")
	game.camp_ui.use_shards=true;game.shop_tab=0;game.show_shop();await shot("shop")
	game.clear_modal();game.mode="play";game.potions=1;game.mana_potions=1
	game.display_settings.apply(3,false)
	for frame in range(8):await process_frame
	await shot("qhd")
	print("QHD window: ",root.size," texture: ",root.get_texture().get_size()," image: ",root.get_texture().get_image().get_size())
	game.queue_free();await process_frame;quit()
