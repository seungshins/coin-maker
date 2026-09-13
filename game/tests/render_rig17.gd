extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);await process_frame
	g.profile=g.rules.new_profile();g.start_run();g.clear_modal();g.enemies.clear();g.view3d.refresh(0)
	g.process_mode=Node.PROCESS_MODE_DISABLED
	var v=g.view3d
	for child in v.get_children():
		if child is Node3D and not child is Camera3D and not child is Light3D:child.visible=false
	var hero:Node3D=v.actor("hero",Color.WHITE,false,"hero");hero.visible=true;hero.position=Vector3(-1.3,0,0);hero.rotation=Vector3.ZERO
	var satyr:Node3D=v.actor("enemy_show_satyr",Color.WHITE,false,"satyr");satyr.position=Vector3(0,0,0)
	var boss:Node3D=v.actor("enemy_show_cyclops",Color.WHITE,true,"cyclops");boss.position=Vector3(1.4,0,0);boss.scale=Vector3.ONE*1.2
	v.camera.position=Vector3(3,2.6,6);v.camera.look_at(Vector3(0,.9,0));v.camera.size=4.4
	var fill:=DirectionalLight3D.new();v.add_child(fill);fill.rotation_degrees=Vector3(-30,-20,0);fill.light_energy=.8
	for kind in ["sword","spear"]:
		g.profile.items.append({"slot":0,"weapon_type":"spear","rarity":0,"value":1,"name":"spear"});g.profile.equipment[9]=g.profile.items.size()-1
		g.visual_weapon=kind;g.attack_flash=.12
		v.models.pose(hero,0,false);v.models.pose(satyr,1.4,false)
		v.boss_pose(boss,{"windup":.2,"windup_total":1.15,"boss_attack":"slam","attack_dir":Vector2.DOWN})
		for i in range(3):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("E:/workspace/.runtime/rig17-"+kind+".png")
	g.queue_free();await process_frame;quit()
