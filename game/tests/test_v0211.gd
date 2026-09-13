extends SceneTree
var failures:=0
func check(ok:bool,msg:String)->void:
	if not ok:failures+=1;printerr("FAIL: "+msg)
func _initialize()->void:call_deferred("run")
func run()->void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.store.path="user://test_v0211.json"
	game.save_blocked=false
	game.profile=game.rules.new_profile()
	game.start_run()
	var base:float=game.rules.skill_spec(game.profile).damage
	game.profile.level=100
	check(is_equal_approx(game.rules.skill_spec(game.profile).damage/base,2.782),"level growth L1 to L100")
	check(game.rules.item_value({"value":20,"rarity":4})==50,"legendary item multiplier")
	game.profile.shards=33
	game.profile.pity=[49,49,49]
	var gold:int=game.profile.gold
	for kind in range(3): game.gacha(kind,true)
	check(game.profile.shards==0 and game.profile.gold==gold,"three shard gachas debit shards only")
	check(game.store.load_profile().shards==0,"shard reward transaction saved")
	game.gacha(0,true)
	check(game.profile.shards==0,"insufficient shards refused")
	game.profile.gems=[{"id":"fan","rarity":2},{"id":"chain","rarity":2},{"id":"duration","rarity":2}]
	game.profile.skills.append_array(["spear_thrust","spear_throw","blade_orbit","tidal_aura"])
	game.profile.skill="spear_thrust"
	game.profile.skill_supports.spear_thrust=[0]
	game.profile.supports=[0]
	check(game.rules.skill_spec(game.profile).arc==165,"fan widens spear arc")
	game.profile.skill="spear_throw"
	game.profile.skill_supports.spear_throw=[1]
	game.enemies.clear();game.bolts.clear()
	for i in range(3):game.spawn_enemy(game.player+Vector2(80+i*80,0),0,"satyr",5000,71+i)
	game.elemental_hit({"skill_id":"spear_throw","chain_count":2,"damage":100,"attack":909},game.enemies[0])
	check(game.enemies[1].hp==4940 and game.enemies[2].hp==4940,"chain hits two distinct targets with reduced damage")
	game.profile.skill="blade_orbit"
	game.profile.skill_supports.blade_orbit=[2]
	game.fields.clear()
	var spec:Dictionary=game.rules.skill_spec(game.profile)
	game.cast_field(game.player,spec)
	check(is_equal_approx(game.fields[0].life,5.2),"duration support extends orbit")
	game.cast_field(game.player,spec)
	check(game.fields.size()==1,"orbit refresh cannot stack")
	game.player+=Vector2(20,0)
	game.update_fields(.01)
	check(game.fields[0].p==game.player and game.enemies[0].hp<5000,"orbit follows and damages")
	game.mode="play"
	check(game.save_now(),"new follow field saves")
	game.profile=game.store.load_profile();game.start_run()
	check(game.fields[0].get("follow",false),"follow field restores")
	var probe:Dictionary=game.rules.new_profile()
	for pair in [["slash",0],["bow",1],["bolt",2]]:
		probe.skill=pair[0];probe.attributes=[0,0,0]
		var before:float=game.rules.skill_spec(probe).damage
		probe.attributes[pair[1]]=10
		check(is_equal_approx(game.rules.skill_spec(probe).damage/before,1.1),"attribute damage scales correct skill family")
	game.display_settings.path="user://test_v0211_display.cfg"
	game.display_settings.apply(3)
	game.display_settings.apply(0,false)
	game.display_settings.restore()
	check(game.display_settings.selected==3,"resolution preference saved and restored")
	game.display_settings.apply(0,false)
	for category in range(3):
		game.camp_ui.codex_tab=category
		game.camp_ui.show_codex()
	game.camp_ui.show_codex()
	await process_frame
	check(not game.modal.get_children().is_empty(),"codex builds including missing powers")
	game.queue_free();await process_frame
	print("PASS: v0211 growth, shards, fan/chain/duration/orbit, save, codex" if failures==0 else "FAILURES: %d"%failures)
	quit(failures)
