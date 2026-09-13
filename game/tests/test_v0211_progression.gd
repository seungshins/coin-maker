extends SceneTree
var failures:=0
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize()->void:call_deferred("run")
func run()->void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game);game.set_physics_process(false)
	game.store.path="user://test_v0211_progression.json";game.save_blocked=false
	game.profile=game.rules.new_profile();game.start_run()
	check(game.potions==2 and game.mana_potions==2,"full initial charges")
	game.health=20;game.mana=0;game.use_potion();game.use_mana_potion()
	check(game.health==20 and game.mana==0,"no instant potion heal")
	game.update_potions(2)
	check(game.health==40 and game.mana==20,"half recovery after two seconds")
	game.update_potions(2)
	check(game.health==60 and game.mana==40,"bounded four-second heal")
	game.potion_cd=0;game.mana_potion_cd=0;game.use_potion();game.use_mana_potion()
	for i in range(12):game.recharge_potions(.08)
	check(game.potions==0 and game.mana_potions==0,"twelve normal kills not full")
	game.recharge_potions(.08)
	check(game.potions==1 and game.mana_potions==1,"thirteenth kill grants charge")
	check(game.save_now(),"recovery state saved")
	game.profile=game.store.load_profile();game.start_run()
	check(is_equal_approx(game.potion_progress,.04) and game.hp_recovery>0,"partial charge and remaining heal restored")
	game.recharge_potions(10)
	check(game.potions==2 and game.potion_progress==0,"charges capped")
	var p:Dictionary=game.rules.new_profile()
	game.rules.award_primary(p,"bow",4)
	check(p.skill_versions.bow==[0,4] and game.rules.skill_rank(p,"bow")==0,"low version retained and used below requirement")
	p.level=65
	check(game.rules.skill_rank(p,"bow")==4,"high rank unlocks at required level")
	p.selected_skill_rarities.bow=0
	check(game.rules.skill_rank(p,"bow")==0,"manual lower rank selection")
	game.rules.award_primary(p,"bow",2)
	check(p.skill_versions.bow==[0,2,4],"new lower rank kept rather than discarded")
	p.level=1;p.skill="bow";p.gems=[{"id":"split","rarity":4}];p.supports=[0];p.skill_supports.bow=[0]
	check(game.rules.skill_spec(p).projectiles==3,"locked support has no gameplay effect")
	p.level=65
	check(game.rules.skill_spec(p).projectiles==11,"support activates at required level")
	p.level=1;p.tier=0
	var early:Array=game.rules.loot_weights(p)
	p.tier=16;p.level=100
	var late:Array=game.rules.loot_weights(p)
	check(early[4]<late[4] and late[4]==20 and late[5]==5,"endgame high-tier weights")
	game.profile=game.rules.new_profile()
	game.profile.items.append({"name":"rare","slot":0,"rarity":2,"value":3,"unique":false})
	game.profile.items.append({"name":"rare equipped","slot":0,"rarity":2,"value":4,"unique":false})
	game.profile.equipment[0]=2
	game.sell_items(2)
	check(game.profile.items.size()==2 and game.profile.equipment[0]==1 and game.profile.gold==128,"bulk sale excludes equipped and remaps index")
	game.rules.award_primary(game.profile,"bow",4)
	check(game.commit(game.profile.duplicate(true)),"versions save")
	check(game.store.load_profile().skill_versions.bow.size()==2,"versions survive serialization")
	game.display_settings.show_panel(game.show_hub)
	game.queue_free();await process_frame
	print("PASS: progressive potions, per-grade gem storage/gates, loot weights, bulk sale" if failures==0 else "FAILURES: %d"%failures)
	quit(failures)
