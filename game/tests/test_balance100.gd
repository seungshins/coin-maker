extends SceneTree
var failures:=0
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize()->void:call_deferred("run")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	g.store.path="user://test_balance100.json";g.save_blocked=false
	var p:Dictionary=g.rules.new_profile()
	for act in range(7):
		p.stage_id=act;p.tier=0
		var zones:int=g.stages[act].centers.size()
		for zone in range(zones):
			g.rules.add_xp(p,int(22*(1+act*1.4)*4))
			g.rules.add_xp(p,g.rules.campaign_xp(p,zone,zones))
		print("Act %d target result: Lv.%d"%[act+1,p.level])
	check(p.level==30,"campaign rare route ends at level30")
	check(g.rules.campaign_xp(p,2,3)==0,"quest XP cannot be farmed twice")
	g.rules.add_xp(p,100000000)
	check(p.level==100 and p.xp==0,"level100 cap")
	p.level=1;p.tier=0
	var rng:=RandomNumberGenerator.new();rng.seed=912
	for i in range(5000):check(g.rules.weighted(rng,g.rules.gacha_weights(p,49 if i%50==49 else 0))<=1,"early rarity cap even with pity")
	check(g.rules.gacha_cost(p)==50,"level1 price")
	p.level=30;p.tier=1;check(g.rules.gacha_cost(p)==317,"early endgame price")
	p.level=100;p.tier=16;check(g.rules.gacha_cost(p)==1402,"late endgame price")
	check(g.rules.gacha_weights(p)[4]>0 and g.rules.gacha_weights(p)[5]>0,"late chase rarity available")
	check(g.rules.gem_level(4)==65 and g.rules.gem_level(5)==85,"rescaled gem requirements")
	g.profile=g.rules.new_profile();g.profile.tier=1;g.start_run()
	var low:Dictionary={"p":g.player+Vector2(150,0),"kind":"item","rarity":0,"value":g.rules.item_roll(rng,0,30)}
	var high:Dictionary={"p":g.player+Vector2(150,0),"kind":"item","rarity":2,"value":g.rules.item_roll(rng,2,30)}
	g.drops.assign([low,high]);var owned:int=g.profile.items.size()
	g._physics_process(0)
	check(g.profile.items.size()==owned+1 and g.drops.size()==1,"160-radius pickup respects endgame filter")
	g.profile.loot_min_rank=0;g.pickup(0)
	check(g.drops.is_empty(),"filtered loot retained for filter change")
	g.profile.level=100
	check(g.save_now(),"100-level save")
	check(g.store.load_profile().level==100,"100-level reload")
	if failures==0:print("PASS: campaign30/cap100, early gacha bounds, scaled costs, gem gates, filtered pickup and save")
	g.queue_free();await process_frame;quit(failures)
