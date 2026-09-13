extends SceneTree
var failures:=0
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;printerr(message)
func _initialize()->void:call_deferred("run")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	g.profile=g.rules.new_profile();g.store.path="user://test_v0213.json";g.save_blocked=false;g.start_run()
	check(g.rules.buff_scale(1)==.5 and g.rules.buff_scale(100)==1.25,"buff growth")
	check(g.rules.move_range({"level":1},"move:blink")==140 and g.rules.move_range({"level":100},"move:blink")==330,"movement growth")
	var p:Dictionary=g.rules.new_profile();p.tier=1;p.level=22
	check(g.rules.xp_rate(p)==1,"eight-level above full XP")
	p.level=21;check(g.rules.xp_rate(p)<1,"too low XP reduction")
	p.level=36;check(g.rules.xp_rate(p)<1,"overlevel XP reduction")
	p.level=30;p.xp=1000;var loss:int=g.rules.death_xp(p)
	check(loss==roundi(g.rules.xp_needed(30)*.1) and p.level==30,"10 percent death penalty")
	p.xp=3;g.rules.death_xp(p);check(p.xp==0 and p.level==30,"no delevel")
	check(g.rules.weapon_allows(g.profile,"slash") and not g.rules.weapon_allows(g.profile,"bow"),"legacy sword requirement")
	for pair in [["bow","bow"],["wand","bolt"],["spear","fire_spear"],["sword","sword_wave"]]:
		g.profile.items[0].weapon_type=pair[0];g.profile.primary_weapon=pair[0]
		check(g.rules.weapon_allows(g.profile,pair[1]),"weapon compatibility")
	g.enemies.clear();g.spawn_enemy(g.player,0,"satyr",100,1)
	for id in ["fire_spear","ice_spear"]:g.elemental_hit({"skill_id":id,"damage":100,"attack":1},g.enemies[0])
	check(g.fields.any(func(f):return f.kind=="fire_zone") and g.fields.any(func(f):return f.kind=="ice_zone"),"elemental ground zones")
	g.update_fields(.01);check(g.enemies[0].slow_time>0,"ice slow")
	g.profile.tier=6;g.profile.level=50;g.start_run()
	g.chests.assign([{"p":g.player,"zone":0,"state":"sealed","guard_ids":[]}])
	check(g.chest_events.interact(),"chest opens guardians")
	check(g.chests[0].guard_ids.size()==4,"four guardians")
	g.save_now();g.profile=g.store.load_profile();g.start_run()
	check(g.chests[0].state=="guarded","chest resume")
	g.drops.clear()
	for e in g.enemies:
		if e.get("chest_guard",false):e.dead=true
	g.chest_events.update();check(g.drops.size()==3 and g.chests[0].state=="claimed","chest payout")
	g.chest_events.update();check(g.drops.size()==3,"no repeat payout")
	g.profile=g.store.load_profile();g.start_run();check(g.chests[0].state=="claimed","claimed persists")
	var stat:Dictionary=g.rules.new_profile();stat.level=5;stat.gold=100
	check(g.rules.allocate_attributes(stat,0,5)==5 and g.rules.allocate_attributes(stat,1,10)==3,"bulk stats clamp to available points")
	check(g.rules.reset_attributes(stat) and stat.gold==40 and g.rules.free_attributes(stat)==8,"paid reset refunds all points")
	check(not g.rules.reset_attributes(stat) and stat.gold==40,"empty reset costs nothing")
	if failures==0:print("PASS: XP/penalty, buff/move growth, weapons/elements, chest save and once-only payout")
	g.queue_free();await process_frame;quit(failures)
