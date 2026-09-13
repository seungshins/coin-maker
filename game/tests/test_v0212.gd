extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
	if not ok:failures+=1;printerr(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_physics_process(false)
	g.store.path="user://test_v0212.json";g.save_blocked=false
	for tier in [1,6,12,16]:
		g.profile=g.rules.new_profile();g.profile.tier=tier;g.profile.campaign_complete=true;g.start_run()
		var expected:int=4 if tier>=12 else (2 if tier>=6 else 1)
		var bosses:=0
		for e in g.enemies:
			if e.kind=="boss":bosses+=1
			check(g.world.walkable(e.p),"enemy outside terrain")
		check(bosses==expected,"boss count T%d"%tier)
		check(g.spawn_clear(g.player),"safe player spawn")
		for step in range(501):
			var t:float=step/500.0*(g.zone_count()-1.0)/g.zone_count()
			var point:Vector2=Vector2(3000,3000)+Vector2.from_angle(float(g.active_stage().curve_total)*t)*(2350-1450*t)
			if step>0 and step<500:check(g.world.walkable(point),"continuous curved route T%d"%tier)
		check(g.save_now(),"save journey")
		g.profile=g.store.load_profile();g.start_run()
		check(g.enemies.filter(func(e):return e.kind=="boss").size()==expected,"resume bosses")

	for map in range(6):
		g.profile=g.rules.new_profile();g.profile.tier=12;g.profile.map_index=map;g.start_run()
		check(not g.enter_boss_portal(),"locked portal")
		for e in g.enemies:check(g.world.walkable(e.p),"variant spawn %d"%map)
		for road in g.active_stage().roads:
			var a:=Vector2(road[0][0],road[0][1]);var end:=Vector2(road[1][0],road[1][1])
			for step in range(101):check(g.world.walkable(a.lerp(end,step/100.0)),"variant corridor")
		for zone in range(g.zone_count()-1):
			for e in g.enemies:
				if int(e.zone)==zone and (e.get("elite",false) or e.kind=="boss"):e.dead=true
			g.check_zones()
		check(g.enemies.any(func(e):return not e.dead and e.kind!="boss" and not e.get("elite",false)),"normal mobs can remain alive")
		check(g.portal_ready() and int(g.profile.tier_unlocked)<13,"only field clear does not unlock tier")
		g.player=g.portal_position()
		check(g.enter_boss_portal() and g.player.x>9000,"portal arena travel")
		g.profile=g.store.load_profile();g.start_run()
		check(g.player.x>9000,"arena resume")
		for e in g.enemies:e.dead=true
		g.check_zones()
		check(int(g.profile.tier_unlocked)==13,"final boss unlock")
	g.profile.items.append({"name":"test","slot":2,"rarity":4,"value":3,"unique":true,"effect":"headhunter"})
	g.profile.equipment[2]=g.profile.items.size()-1
	for spec in [[false,"satyr",false],[true,"satyr",true],[false,"boss",true]]:
		g.stolen_affixes.clear()
		g.battle_extras.on_kill({"p":Vector2.ZERO,"elite":spec[0],"kind":spec[1],"affix":"swift"},"physical")
		check(g.stolen_affixes.has("swift")==spec[2],"affix eligibility")
	if failures==0:print("PASS: journey routes/spawns, T1/T6/T12/T16 bosses, save and affix restrictions")
	g.queue_free();await process_frame;quit(failures)
