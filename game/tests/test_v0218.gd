extends SceneTree
const Storage=preload("res://src/domain/storage_rules.gd")
var failures:=0
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;printerr(message)
func _initialize()->void:call_deferred("run")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);await process_frame
	g.profile=g.rules.new_profile();Storage.ensure(g.profile);g.store.path="user://v18-test.json";g.save_blocked=false
	var p:Dictionary=g.profile
	check(p.gacha_left==3,"three initial opportunities")
	p.gacha_left=0;Storage.ensure(p);check(p.gacha_left==0,"opening market cannot refill")
	p.level=2;Storage.ensure(p);check(p.gacha_left==3,"level grants three opportunities")
	p.gacha_left=0;p.gold=100000;var before:int=p.gold;g.gacha(0);check(g.profile.gold==before,"no opportunity means no payment")
	p.level=100;p.skills=g.rules.data.skills.keys();Storage.ensure(p)
	for type in ["spear","wand","bow"]:
		var item:Dictionary=g.rules.item_roll(g.rng,0,1,type);p.items.append(item);p.equipment[g.rules.equip_slot(p,item)]=p.items.size()-1
	check(g.rules.weapon_allows(p,"slash") and not g.rules.weapon_allows(p,"bow"),"only primary weapon permits direct skill")
	p.primary_weapon="bow";check(g.rules.weapon_allows(p,"bow") and not g.rules.weapon_allows(p,"slash"),"switching weapon changes restrictions")
	for id in preload("res://src/application/support_expansion.gd").IDS:
		check(not g.rules.support_numbers({"id":id,"rarity":5}).is_empty(),"numeric tooltip: "+id)
	check(not g.rules.support_compatible("life_leech","bolt") and g.rules.support_compatible("life_leech","bow"),"leech attack tags")
	check(g.rules.support_compatible("archmage","bolt") and not g.rules.support_compatible("archmage","slash"),"archmage spell tags")
	p.skill="bolt";p.gems=[{"id":"archmage","rarity":0}];p.skill_supports.bolt=[0];p.supports=[0]
	var spec:Dictionary=g.rules.skill_spec(p);g.mana=100;g.aim=Vector2.RIGHT;g.bolts.clear();g.attack(spec)
	check(is_equal_approx(g.mana,(100-spec.mana)*.2),"archmage consumes eighty percent after base cost")
	check(g.bolts[0].support_context.archmage_damage>0,"projectile captures mana-funded bonus")
	p.skill="slash";p.supports=[];p.skill_supports.slash=[];var damage:float=g.rules.skill_spec(p).damage
	p.skill_upgrades.slash=10;check(is_equal_approx(g.rules.skill_spec(p).damage,damage*1.2),"upgrade cap20 percent")
	g.health=1;g.mana=1;g.enemies.clear();g.spawn_enemy(g.player+Vector2(50,0),0,"satyr",100000,1)
	var e:Dictionary=g.enemies[0]
	for i in range(10):g.support_expansion.on_hit({"life_leech":5,"mana_leech":5},e,100000)
	var stats:Dictionary=g.rules.stats(p)
	check(g.health<=1+stats.hp*.08+.01 and g.mana<=1+stats.mana*.12+.01,"leech recovery bounded per second")
	p.trigger_skills.bow="sword_wave";g.pending_repeats.clear();g.proc_cooldowns.clear();g.rng.seed=2
	for i in range(100):g.support_expansion.on_hit({"id":"bow","trigger":5},e,1)
	check(g.pending_repeats.size()==1 and g.pending_repeats[0].spec.support_context.is_empty(),"trigger cooldown and recursion guard")
	check(g.pending_repeats[0].spec.id=="sword_wave","cross weapon trigger target")
	check(g.store.save_profile(p),"expanded profile saves")
	var restored:Dictionary=g.store.load_profile();check(restored.primary_weapon=="bow" and restored.skill_upgrades.slash==10 and restored.trigger_skills.bow=="sword_wave","new fields persist")
	g.camp_ui.show_inventory();await process_frame;g.show_skills();await process_frame;g.display_settings.show_panel(g.show_title);await process_frame
	g.queue_free();await process_frame
	if failures==0:print("PASS v18: gacha budget, weapon restriction, supports, mana, leech cap, triggers, upgrades, save and UI")
	quit(failures)
