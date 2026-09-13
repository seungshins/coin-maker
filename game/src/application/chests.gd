extends RefCounted
var game
func _init(g)->void:game=g
func generate()->void:
	game.chests.clear()
	if int(game.profile.get("tier",0))<=0:return
	for zone in range(game.zone_count()-1):
		if zone in game.profile.cleared or game.rng.randf()>.35:continue
		game.chests.append({"p":game.world.centers[zone]+Vector2(100,0),"zone":zone,"state":"sealed","guard_ids":[]})
func interact(target:Vector2=Vector2.INF)->bool:
	for c in game.chests:
		if c.state!="sealed" or c.zone>game.profile.cleared.size():continue
		if game.player.distance_to(c.p)>180 or (target!=Vector2.INF and target.distance_to(c.p)>90):continue
		c.state="guarded"
		for i in range(4):
			var id:int=70000+int(c.zone)*10+i
			var pos:Vector2=c.p+Vector2.from_angle(i*TAU/4)*75
			if not game.world.walkable(pos):pos=c.p
			game.spawn_enemy(pos,c.zone,"satyr",120*game.difficulty().hp,id)
			var enemy:Dictionary=game.enemies.back()
			enemy["chest_guard"]=true;enemy.elite=i==0
			enemy.affix="fury" if i==0 else ""
			c.guard_ids.append(id)
		game.save_now();game.notify("봉인된 보물 · 수호자 네 마리를 처치하세요")
		return true
	return false
func update()->void:
	for c in game.chests:
		if c.state!="guarded":continue
		var alive:bool=game.enemies.any(func(e):return int(e.id) in c.guard_ids and not e.dead)
		if alive:continue
		c.state="claimed"
		for i in range(3):
			var rank:int=game.rules.weighted(game.rng,game.rules.loot_weights(game.profile,true))
			var value:Dictionary=game.rules.item_roll(game.rng,rank,game.profile.level) if i<2 else {"id":game.rules.data.supports.keys()[game.rng.randi_range(0,game.rules.data.supports.size()-1)],"rarity":rank}
			game.drops.append({"p":c.p+Vector2((i-1)*30,0),"kind":"item" if i<2 else "gem","rarity":rank,"value":value})
		game.save_now();game.notify("봉인 해제 · 장비 2개와 보조 젬 1개")
