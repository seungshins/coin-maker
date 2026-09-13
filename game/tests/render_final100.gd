extends SceneTree
func _initialize()->void:call_deferred("run")
func shot(name_:String)->void:
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/v0212-"+name_+".png")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	g.profile=g.rules.new_profile();g.start_run();g.display_settings.display_mode=0;g.display_settings.choose_resolution(3)
	g.shop_tab=0;g.show_shop();await shot("gacha100")
	g.profile.level=30;g.rules.award_primary(g.profile,"bow",4);g.profile.gems.append({"id":"split","rarity":4})
	g.show_skills();g.camp_ui.skill_panel.category=0;g.camp_ui.skill_panel.show_panel();await shot("locked100")
	g.camp_ui.skill_panel.category=4;g.camp_ui.skill_panel.show_panel();await shot("locked-support100")
	g.show_loot_filter(g.show_hub);await shot("filter100")
	g.clear_modal();g.mode="play";g.enemies.clear()
	g.drops.assign([{"p":g.player+Vector2(180,0),"kind":"item","rarity":4,"value":{"name":"프로테우스의 사슬","slot":2,"rarity":4,"value":20,"unique":true}}])
	g.view3d.refresh(0);await shot("drop100")
	g.queue_free();await process_frame;quit()
