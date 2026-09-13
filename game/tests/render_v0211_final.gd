extends SceneTree
func _initialize()->void:call_deferred("run")
func shot(name_:String)->void:
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/v0211-final-"+name_+".png")
func run()->void:
	root.size=Vector2i(1280,720)
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game);game.set_physics_process(false)
	game.profile=game.rules.new_profile();game.start_run()
	game.show_hub();game.display_settings.zoom_factor=1.25;await shot("shore")
	game.rules.award_primary(game.profile,"bow",4);game.rules.award_primary(game.profile,"slash",2)
	game.profile.level=35
	game.show_skills();game.camp_ui.skill_panel.category=0;game.camp_ui.skill_panel.show_panel();await shot("skills")
	game.shop_tab=1;game.show_shop();await shot("purchase")
	game.shop_tab=2;game.profile.items.append({"name":"전설 확인용 검","slot":0,"rarity":4,"value":10,"unique":true,"effect":"wrath"})
	game.show_shop();game.camp_ui.confirm_sale(1);await shot("popup")
	for node in game.ui.get_children():
		if node is ConfirmationDialog:node.queue_free()
	game.display_settings.show_panel(game.show_hub);await shot("settings")
	game.display_settings.display_mode=1;game.display_settings.apply(0,false)
	for i in range(3):await process_frame
	print("Borderless: ",root.borderless," / ",root.size)
	game.display_settings.display_mode=2;game.display_settings.apply(0,false)
	for i in range(3):await process_frame
	print("Fullscreen mode: ",root.mode)
	game.display_settings.display_mode=0;game.display_settings.apply(0,false)
	game.queue_free();await process_frame;quit()
