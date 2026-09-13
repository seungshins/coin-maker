extends SceneTree
func _initialize()->void:call_deferred("run")
func shot(name_:String)->void:
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/v0213-"+name_+".png")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	g.profile=g.rules.new_profile();g.profile.level=60;g.profile.gold=500;g.start_run()
	g.display_settings.display_mode=0;g.display_settings.choose_resolution(0)
	g.show_inventory();await shot("stats")
	for id in g.rules.data.supports: g.profile.gems.append({"id":id,"rarity":0})
	g.camp_ui.show_skills();g.camp_ui.skill_panel.category=4;g.camp_ui.skill_panel.show_panel();await shot("support")
	g.clear_modal();g.mode="play";g.enemies.clear();g.profile.items[0].weapon_type="spear"
	g.chests.assign([{"p":g.player+Vector2(100,60),"zone":0,"state":"sealed","guard_ids":[]}])
	g.fields.assign([{"kind":"fire_zone","p":g.player+Vector2(170,0),"radius":85.0,"damage":10,"life":2,"tick":0},{"kind":"ice_zone","p":g.player+Vector2(-170,0),"radius":85.0,"damage":10,"life":2,"tick":0}])
	g.effects.assign([{"kind":"slash","p":g.player,"angle":0,"arc":80.0,"radius":180.0,"life":.12}])
	g.attack_flash=.12;g.view3d.refresh(0);await shot("spear")
	g.profile.items[0].weapon_type="sword";g.bolts.assign([{"p":g.player+Vector2(50,0),"v":Vector2(370,0),"attack":1,"skill_id":"sword_wave","friendly":true,"wave":true}]);g.view3d.refresh(0);await shot("sword")
	g.profile.items[0].weapon_type="wand";g.view3d.refresh(0);await shot("wand")
	g.bolts.clear();g.effects.assign([{"kind":"thunder","p":g.player+Vector2(80,0),"radius":100,"life":.3},{"kind":"chain","p":g.player,"to":g.player+Vector2(250,50),"life":.2}]);g.view3d.refresh(0);await shot("lightning")
	g.queue_free();await process_frame;quit()
