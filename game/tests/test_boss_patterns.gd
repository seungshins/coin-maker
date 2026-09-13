extends SceneTree
var failures:=0
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;printerr(message)
func _initialize()->void:call_deferred("run")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);await process_frame
	g.profile=g.rules.new_profile();g.start_run();g.enemies.clear();g.spawn_enemy(g.player+Vector2(180,0),0,"boss",10000,99)
	var e:Dictionary=g.enemies[0];e.model="cyclops";g.health=1000;g.hurt_time=0
	g.boss_combat.prepare(e,g.player);var target:Vector2=e.target
	g.player+=Vector2(0,180);g.boss_combat.update(e,1.2,g.player)
	check(g.health==1000 and e.target==target and e.recovery>0,"slam target locks and moving away avoids damage")
	e.pattern=1;g.boss_combat.prepare(e,e.p+Vector2(100,0))
	check(g.boss_combat.contains(e,e.p+Vector2(100,0)) and not g.boss_combat.contains(e,e.p-Vector2(100,0)),"sweep only hits forward cone")
	e.model="gorgon";e.pattern=0;g.bolts.clear();g.boss_combat.prepare(e,e.p+Vector2(200,0));g.boss_combat.update(e,1.6,e.p+Vector2(0,200))
	check(g.bolts.size()==5 and g.bolts[2].v.x>0,"medusa fan uses locked direction")
	e.pattern=1;g.player=e.p+Vector2(200,0);g.hurt_time=0;g.dodge=0;g.boss_combat.prepare(e,g.player);g.boss_combat.strike(e)
	check(g.health<1000 and g.petrify_time>0,"medusa gaze damage and temporary slow")
	check(not g.boss_combat.contains(e,e.p+Vector2(0,250)),"gaze side escape")
	var snapshot:Dictionary=preload("res://src/infrastructure/run_snapshot.gd").capture(g)
	preload("res://src/infrastructure/run_snapshot.gd").restore(g,snapshot)
	check(g.enemies[0].boss_attack=="gaze" and g.petrify_time>0,"boss pattern state persists")
	g.queue_free();await process_frame
	if failures==0:print("PASS: boss locked aim, dodgeable slam/sweep, medusa fan/gaze and save")
	quit(failures)
