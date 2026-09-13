extends SceneTree
var failures:=0
func check(ok:bool,label_:String)->void:
	if not ok: failures+=1; printerr("FAIL: "+label_)
func _initialize()->void: call_deferred("run")
func run()->void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.profile=game.rules.new_profile()
	game.start_run()
	game.enemies.clear()
	game.spawn_enemy(game.player,0,"satyr",100,4)
	var rare:Dictionary=game.enemies[0]
	check(rare.elite and rare.max_hp==200 and not str(rare.affix).is_empty(),"rare health and affix")
	game.battle_extras.special_attack(rare)
	check(game.bolts.size()>=5 and game.bolts.all(func(b):return not b.friendly),"rare attack is hostile")
	var kinds:Dictionary={}
	for stage in game.stages: kinds[stage.boss_model]=true
	check(kinds.size()>=6,"distinct boss forms")
	var h:float=game.view3d.landscapes.height_at(game.player)
	check(absf(h-game.view3d.landscapes.height_at(game.player+Vector2(700,300)))>.01,"terrain relief")
	game.show_inventory()
	await process_frame
	check(game.camp_ui.equipment_layout!=null,"paperdoll and bag connected")
	game.queue_free()
	await process_frame
	print("PASS: v028 rare attacks, boss variety, relief, inventory" if failures==0 else "FAILURES: %d"%failures)
	quit(failures)
