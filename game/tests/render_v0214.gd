extends SceneTree
func _initialize()->void:call_deferred("run")
func shot(name_:String)->void:
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/v0214-"+name_+".png")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	await process_frame
	g.profile=g.rules.new_profile();g.profile.level=60;g.profile.gold=5000;g.start_run()
	g.display_settings.display_mode=0;g.display_settings.apply(0,false)
	for slot in [1,2,3,4,5,6,6,8]:
		var item:Dictionary={"slot":slot,"rarity":3,"value":20,"name":"검수 장비","unique":false}
		g.profile.items.append(item);g.profile.equipment[g.rules.equip_slot(g.profile,item)]=g.profile.items.size()-1
	for weapon in ["sword","spear","wand","bow"]:
		var item:Dictionary=g.rules.item_roll(g.rng,3,60,weapon)
		g.profile.items.append(item);g.profile.equipment[g.rules.equip_slot(g.profile,item)]=g.profile.items.size()-1
	g.show_inventory();await shot("inventory")
	g.show_skills();await shot("skills")
	g.shop_tab=0;g.show_shop();await shot("shop")
	g.clear_modal();g.mode="play";g.profile.buffs=["fire","lightning"]
	g.ability_cooldowns={"slash":.3,"bow":2,"move:blink":3,"burst:rage":8};g.cooldown_totals={"slash":.6,"bow":3,"move:blink":6,"burst:rage":12}
	await shot("cooldown")
	g.queue_free();await process_frame;quit()
