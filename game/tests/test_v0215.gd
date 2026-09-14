extends SceneTree
var failures:=0
func check(value:bool,message:String)->void:
	if not value:failures+=1;printerr(message)
func _initialize()->void:call_deferred("run")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);await process_frame
	g.profile=g.rules.new_profile();g.store.path="user://test_v0215.json";g.save_blocked=false;g.start_run()
	var p:Dictionary=g.profile
	for pair in [[1,1],[30,4],[59,4],[60,5],[84,5],[85,6],[100,6]]:
		p.level=pair[0];check(g.rules.slots(p)==pair[1],"support unlock threshold")
	p.level=85
	var before:int=p.shards
	g.rules.award_gem(p,{"id":"power","rarity":0});g.rules.award_primary(p,"slash",0)
	check(p.shards==before,"field duplicates never award shards")
	g.rules.award_gem(p,{"id":"power","rarity":0},true);g.rules.award_primary(p,"slash",0,true)
	check(p.shards==before+2,"gacha duplicates award shards")
	for id in ["minion_guard","minion_haste","minion_blast","minion_splash"]:
		check(g.rules.support_compatible(id,"siren_summon") and not g.rules.support_compatible(id,"slash"),"summon-only tag")
		check(not g.rules.support_numbers({"id":id,"rarity":5}).is_empty(),"support numeric description")
	g.rules.award_primary(p,"siren_summon",0);p.skill="siren_summon";p.gems=[];p.skill_supports.siren_summon=[]
	for id in ["minion_guard","minion_haste","minion_blast","minion_splash"]:
		p.gems.append({"id":id,"rarity":5});p.skill_supports.siren_summon.append(p.gems.size()-1)
	var spec:Dictionary=g.rules.skill_spec(p)
	check(spec.minion_hp==3.3 and spec.minion_speed==1.5 and spec.minion_splash==105,"summon support mechanics")
	g.enemies.clear();g.spawn_enemy(g.player+Vector2(75,0),0,"satyr",99999,123)
	var enemy:Dictionary=g.enemies[0];enemy.hp=99999;enemy.max_hp=99999;enemy.affix=""
	g.battle_extras.summon(spec);var m:Dictionary=g.minions[0];m.p=g.player
	g.battle_extras.minion_combat.cast(m,enemy)
	check(enemy.get("slow_time",0)>0 and enemy.hp<99999,"siren slowing attack")
	var snapshot:Dictionary=preload("res://src/infrastructure/run_snapshot.gd").capture(g)
	g.minions.clear();preload("res://src/infrastructure/run_snapshot.gd").restore(g,snapshot)
	check(g.minions[0].type=="siren_summon" and g.minions[0].blast==2.5,"summon support state survives save")
	g.battle_extras.minion_combat.update(8.1);check(g.minions.is_empty(),"bomb expires once")
	g.minions.clear();spec.id="hydra_summon";spec.minion_blast=0;g.battle_extras.summon(spec)
	g.battle_extras.minion_combat.cast(g.minions[0],g.enemies[0]);check(g.fields.any(func(f):return f.kind=="venom"),"hydra poison skill")
	g.profile.skill="trinity_spear";var thrust:Dictionary=g.rules.data.skills.trinity_spear.duplicate(true);thrust.id="trinity_spear"
	g.bolts.clear();g.combat_procs.trinity(thrust)
	check(g.bolts.size()==3 and g.bolts[0].skill_id=="fire_spear" and g.bolts[2].skill_id=="lightning_spear","three elemental branches")
	check(g.combat_procs.roll("test",1,2) and not g.combat_procs.roll("test",1,2),"proc internal cooldown")
	g.proc_cooldowns.clear();g.profile.items.append({"slot":1,"rarity":5,"value":1,"name":"test","unique":true,"effect":"curse_hit"});g.profile.equipment[1]=g.profile.items.size()-1;g.rng.seed=45
	for i in range(100):g.combat_procs.on_hit(g.enemies[0],1)
	check(g.enemies[0].get("curse",0)>0,"on hit curse triggers")

	g.spawn_enemy(g.enemies[0].p+Vector2(35,0),0,"satyr",99999,456)
	for effect in ["shockwave_hit","random_boon"]:
		g.profile.items.back().effect=effect;g.proc_cooldowns.clear()
		for i in range(200):g.combat_procs.on_hit(g.enemies[0],10)
		check(g.proc_cooldowns.get(effect,0)>0,"proc activates with cooldown: "+effect)
	check(not g.burst_timers.is_empty(),"random boon creates timed buff")
	g.profile.skill="slash";g.profile.attributes=[100,0,100];g.profile.items.back().effect=""
	var baseline:float=g.rules.skill_spec(g.profile).damage
	for effect in ["strength_damage","intelligence_damage"]:
		g.profile.items.back().effect=effect
		check(is_equal_approx(g.rules.skill_spec(g.profile).damage/baseline,1.15),"attribute unique damage scaling")
	for i in range(60):g.update_bolts(1.0/60)

	g.minions.clear();g.fields.clear();g.enemies.clear();g.profile.cleared=[0]
	g.spawn_enemy(g.player+Vector2(65,0),0,"satyr",10000,777)
	var old_enemy:Dictionary=g.enemies[0];old_enemy.hp=10000;old_enemy.affix=""
	g.spawn_enemy(g.player+Vector2(15,0),2,"satyr",10000,778)
	var locked:Dictionary=g.enemies[1];locked.hp=10000;locked.affix=""
	g.battle_extras.summon({"id":"summon","damage":10})
	for minion in g.minions:minion.p=g.player
	g.battle_extras.minion_combat.update(.15)
	var first_hp:float=old_enemy.hp
	for i in range(12):g.battle_extras.minion_combat.update(.1)
	check(old_enemy.hp<first_hp and first_hp<10000,"summons keep attacking surviving enemies in completed zones")
	check(locked.hp==10000,"summons do not target locked future zones")
	check(g.minions[0].has("facing") and g.minions[0].has("attack_flash"),"minions own facing and attack animation")
	g.queue_free();await process_frame
	if failures==0:print("PASS: six links, duplicate sources, summon skills/supports/save, trinity and proc cooldowns")
	quit(failures)
