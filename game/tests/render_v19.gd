extends SceneTree
func _initialize()->void:call_deferred("run")
func shot(g,name_:String)->void:
	for i in range(6):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/v19-"+name_+".png")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);await process_frame
	g.profile=g.rules.new_profile();g.profile.level=100;g.profile.skills=g.rules.data.skills.keys();preload("res://src/domain/storage_rules.gd").ensure(g.profile)
	g.display_settings.display_mode=0;g.display_settings.apply(0,false)
	g.camp_ui.show_inventory();await shot(g,"inventory")
	g.profile.gems=[{"id":"trigger","rarity":3}];g.profile.skill_supports.slash=[0];g.profile.loadout[0]="slash";g.camp_ui.selected_slot=0
	g.show_skills();await shot(g,"skills")
	g.camp_ui.skill_panel.show_trigger_picker("slash");await shot(g,"picker")
	g.clear_modal();g.mode="town";g.town.visible=true
	for facing in [Vector2.DOWN,Vector2.UP]:
		g.town.facing=facing;g.view3d.refresh(0);await shot(g,"front" if facing==Vector2.DOWN else "back")
	var v=g.view3d;var started:int=Time.get_ticks_usec();var a:Node3D=v.actor("enemy_perf_a",Color.WHITE,false,"satyr");var cold:int=Time.get_ticks_usec()-started
	started=Time.get_ticks_usec();var b:Node3D=v.actor("enemy_perf_b",Color.WHITE,false,"satyr");var warm:int=Time.get_ticks_usec()-started
	print("Model CPU creation us cold=",cold," cached=",warm," shared mesh=",a.get_node("Model").get_child(0).mesh==b.get_node("Model").get_child(0).mesh)
	g.queue_free();await process_frame;quit()
