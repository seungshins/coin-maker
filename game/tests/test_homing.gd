extends SceneTree
var failures:=0
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;printerr(message)
func _initialize()->void:call_deferred("run")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);await process_frame
	g.profile=g.rules.new_profile();g.start_run();g.enemies.clear();g.rocks.clear()
	check(g.rules.support_compatible("homing","bow") and g.rules.support_compatible("homing","bolt") and not g.rules.support_compatible("homing","slash"),"projectile-only guide")
	g.profile.skill="bow";g.profile.level=85;g.profile.skill_supports.bow=[]
	var base:float=g.rules.skill_spec(g.profile).damage
	g.profile.gems.append({"id":"homing","rarity":5});g.profile.skill_supports.bow=[g.profile.gems.size()-1]
	var spec:Dictionary=g.rules.skill_spec(g.profile)
	check(is_equal_approx(spec.damage/base,.85) and spec.homing==3.2,"guide tradeoff and rank")
	g.spawn_enemy(g.player+Vector2(220,90),0,"satyr",10000,81);var enemy:Dictionary=g.enemies[0];enemy.hp=10000;enemy.max_hp=10000;enemy.affix=""
	var b:Dictionary={"p":g.player,"v":Vector2(300,0),"life":2.0,"homing":3.2,"friendly":true,"hits":[],"damage":10,"attack":100,"skill_id":"bow","pierce":1}
	g.combat_procs.guide(b,.1)
	check(b.v.y>0 and is_equal_approx(b.v.length(),300),"turns toward target without changing speed")
	var velocity:Vector2=b.v;b.returning=true;g.combat_procs.guide(b,.2);check(b.v==velocity,"return excludes guide")
	b.returning=false;b.hits=[81];b.v=Vector2(300,0);g.combat_procs.guide(b,.2);check(b.v==Vector2(300,0),"pierced target excluded")
	b.hits=[];b.p=g.player;b.v=Vector2(300,0);g.bolts.assign([b])
	for i in range(100):g.update_bolts(.02)
	check(enemy.hp<10000,"guided arrow actually hits off-axis target")
	g.queue_free();await process_frame
	if failures==0:print("PASS: guide tags, rarity, damage tradeoff, turning, return exclusion, actual hit")
	quit(failures)
