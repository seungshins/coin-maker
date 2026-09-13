extends SceneTree
var failures:=0
func check(value:bool,message:String)->void:
	if not value:failures+=1;printerr(message)
func _initialize()->void:call_deferred("run")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	await process_frame
	g.profile=g.rules.new_profile();g.store.path="user://test_v0214.json";g.save_blocked=false
	var p:Dictionary=g.profile
	p.equipment=[0,-1,-1];preload("res://src/domain/storage_rules.gd").ensure(p)
	check(p.equipment.size()==12 and p.equipment[0]==0,"legacy slots migrate without loss")
	for slot in [3,4,5,6,6,8]:
		var item:Dictionary={"slot":slot,"rarity":2,"value":20,"name":"test","unique":false}
		p.items.append(item);p.equipment[g.rules.equip_slot(p,item)]=p.items.size()-1
	check(p.equipment[6]!=p.equipment[7] and p.equipment[7]>=0,"two distinct rings")
	check(g.store.save_profile(p) and g.store.load_profile().equipment==p.equipment,"twelve slot save restore")
	var stats:Dictionary=g.rules.stats(p)
	check(stats.armor>0 and stats.armor_reduction>0 and stats.move>290 and stats.speed>1,"slot-specific properties")
	for weapon in ["sword","spear","wand","bow"]:
		for rarity in range(6):
			for i in range(25):
				var item:Dictionary=g.rules.item_roll(g.rng,rarity,50,weapon)
				check(item.slot==0 and item.weapon_type==weapon and item.rarity==rarity,"target gacha preserves weapon and rarity")

	for weapon in ["spear","wand","bow"]:
		var item:Dictionary=g.rules.item_roll(g.rng,0,1,weapon)
		p.items.append(item);p.equipment[g.rules.equip_slot(p,item)]=p.items.size()-1
	for id in ["slash","spear_throw","bolt","bow"]:check(g.rules.weapon_allows(p,id),"all four weapon skills available together")
	var sword_damage:float=g.rules.skill_spec(p).damage
	var bow_index:int=g.rules.weapon_index(p,"bow");p.items[bow_index].value=9999
	check(is_equal_approx(g.rules.skill_spec(p).damage,sword_damage),"inactive bow does not add sword damage")
	g.profile.gold=5000;var gold:int=g.profile.gold;var cost:int=g.rules.gacha_cost(p)
	g.gacha(0,false,"spear")
	check(g.profile.gold==gold-cost and g.profile.items.back().weapon_type=="spear","targeted gacha charges once")
	g.sell_items(0);check(g.profile.equipment.size()==12 and g.profile.equipment[7]>=0,"bulk sale preserves second ring")
	for weapon in ["sword","spear","wand","bow"]:check(g.rules.weapon_index(g.profile,weapon)>=0,"all equipped weapons excluded from sale")
	g.start_run();g.enemies.clear();g.spawn_enemy(g.player+Vector2(100,0),0,"satyr",9999,123)
	var enemy:Dictionary=g.enemies[0];enemy.hp=10000;enemy.max_hp=10000;enemy.affix=""
	g.profile.buffs=["fire","ice"];var before:float=enemy.hp;g.hit_enemy(enemy,100,false)
	check(is_equal_approx(before-enemy.hp,110),"two level-one elemental buffs additive 10 percent")
	check(g.effects.any(func(f):return f.get("element","")=="fire") and g.effects.any(func(f):return f.get("element","")=="ice"),"elemental hit visual effects")
	g.cooldown_totals={"move:blink":6.0};g.ability_cooldowns={"move:blink":3.0}
	var snapshot:Dictionary=preload("res://src/infrastructure/run_snapshot.gd").capture(g)
	g.cooldown_totals.clear();preload("res://src/infrastructure/run_snapshot.gd").restore(g,snapshot)
	check(g.cooldown_totals.get("move:blink",0)==6.0,"cooldown duration survives resume")
	g.display_settings.path="user://test_display_v0214.cfg"
	for mode in range(3):
		g.display_settings.display_mode=mode;g.display_settings.selected=2;g.display_settings.save_config()
		var settings=load("res://src/presentation/display_settings.gd").new(g);settings.path=g.display_settings.path;settings.restore()
		check(settings.selected==2 and settings.display_mode==mode,"display mode and resolution reload")
	g.queue_free();await process_frame
	if failures==0:print("PASS: equipment migration, rings, targeted gacha, elemental buffs, display persistence")
	quit(failures)
