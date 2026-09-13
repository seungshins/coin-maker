extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);await process_frame
	g.profile=g.rules.new_profile();g.profile.level=85;g.start_run();g.clear_modal();g.enemies.clear();g.display_settings.display_mode=0;g.display_settings.apply(0,false)
	for id in ["summon","siren_summon","hydra_summon"]:
		var spec:Dictionary=g.rules.data.skills[id].duplicate(true);spec.id=id;g.battle_extras.summon(spec)
	for i in range(g.minions.size()):g.minions[i].p=g.player+Vector2(-170+i*110,-80)
	g.spawn_enemy(g.player+Vector2(180,70),0,"satyr",10000,100)
	for m in g.minions:g.battle_extras.minion_combat.cast(m,g.enemies[0])
	var thrust:Dictionary=g.rules.data.skills.trinity_spear.duplicate(true);thrust.id="trinity_spear";g.combat_procs.trinity(thrust)
	g.view3d.refresh(0)
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/v0215-summons.png")
	g.rules.award_primary(g.profile,"siren_summon",0);g.profile.loadout[0]="siren_summon";g.profile.skill="siren_summon"
	for id in ["minion_guard","minion_haste","minion_blast","minion_splash"]:g.rules.award_gem(g.profile,{"id":id,"rarity":5})
	g.show_skills();g.camp_ui.skill_panel.category=4;g.camp_ui.skill_panel.show_panel()
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/v0215-supports.png")
	g.queue_free();await process_frame;quit()
