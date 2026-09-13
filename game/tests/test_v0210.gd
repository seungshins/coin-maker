extends SceneTree
var failures:=0
func check(ok:bool,msg:String)->void:
	if not ok: failures+=1;printerr("FAIL: "+msg)
func _initialize()->void:call_deferred("run")
func run()->void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.store.path="user://test_v0210.json"
	game.save_blocked=false
	game.profile=game.rules.new_profile()
	for rarity in range(2,6):
		game.profile.items.append({"name":"sale fixture","slot":0,"rarity":rarity,"value":1,"unique":false})
	game.profile.equipment[0]=4
	check(not game.sell_item(4),"equipped protected")
	for rarity in range(2,5):
		var gold:int=game.profile.gold
		check(game.sell_item(1),"sell rare epic legendary")
		check(game.profile.gold==gold+12+rarity*8,"exact sale gold")
	check(game.profile.equipment[0]==1 and game.profile.items[1].rarity==5,"equipment indices preserved")
	game.profile.equipment[0]=0
	check(game.sell_item(1),"mythic sale")
	check(game.store.load_profile().items.size()==1,"sale persists")
	game.start_run()
	game.ambience=2
	check(game.save_now(),"save ambience")
	game.profile=game.store.load_profile()
	game.ambience=0
	game.start_run()
	check(game.ambience==2,"same light after resume")
	game.view3d.refresh(0)
	check(game.view3d.actors.hero.get_node("Model/LeftLeg").has_node("Knee"),"articulated knee")
	game.queue_free()
	await process_frame
	print("PASS: sale/indices/save, ambience persistence, articulated hero" if failures==0 else "FAILURES: %d"%failures)
	quit(failures)
