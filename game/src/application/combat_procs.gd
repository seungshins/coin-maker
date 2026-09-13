extends RefCounted
var game
func _init(g)->void:game=g
func roll(id:String,probability:float,cooldown:float)->bool:
	if probability<=0 or float(game.proc_cooldowns.get(id,0))>0:return false
	if game.rng.randf()>=probability:return false
	game.proc_cooldowns[id]=cooldown
	return true
func on_hit(enemy:Dictionary,damage:float)->void:
	var rules=game.rules
	if roll("curse_hit",rules.effect_value(game.profile,"curse_hit"),2):
		enemy.curse=3.0
		game.effects.append({"kind":"curse","p":enemy.p,"radius":60,"life":.4})
	if roll("random_boon",rules.effect_value(game.profile,"random_boon"),8):
		var id:String=["burst:rage","burst:haste","burst:volley"][game.rng.randi_range(0,2)]
		game.burst_timers[id]=maxf(float(game.burst_timers.get(id,0)),3)
	if roll("shockwave_hit",rules.effect_value(game.profile,"shockwave_hit"),1.5):
		game.effects.append({"kind":"slash","p":enemy.p,"radius":110,"arc":360,"angle":0,"life":.23})
		for other in game.enemies:
			if other!=enemy and not other.dead and other.p.distance_to(enemy.p)<110:game.hit_enemy(other,damage*.35,false,"physical",12,false)
func trinity(spec:Dictionary)->void:
	game.guard=.35
	game.effects.append({"kind":"slash","p":game.player,"radius":spec.reach,"angle":game.aim.angle(),"arc":spec.arc,"life":.23})
	for e in game.enemies:
		var offset:Vector2=e.p-game.player
		if not e.dead and offset.length()<spec.reach and absf(game.aim.angle_to(offset))<deg_to_rad(spec.arc*.5):game.hit_enemy(e,spec.damage*.7,true)
	for i in range(3):
		game.bolts.append({"p":game.player,"v":game.aim.rotated((i-1)*.28)*620,"life":.85,"damage":spec.damage*.45,"friendly":true,"attack":game.attack_id,"skill_id":["fire_spear","ice_spear","lightning_spear"][i],"pierce":2,"hits":[],"chain_count":1,"return_multiplier":0,"knockback":12})
