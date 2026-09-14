extends RefCounted
var game
func _init(g)->void:game=g
func summon(spec:Dictionary)->void:
	var type:String=str(spec.get("id","summon"))
	for i in range(2 if type=="summon" else 1):
		if game.minions.size()>=4:game.minions.pop_front()
		var p:Vector2=game.player+Vector2(-28 if i==0 else 28,25)
		if not game.can_move(p):p=game.player
		var hp:float=game.rules.stats(game.profile).hp*float(game.rules.data.minion_base_hp)*float(spec.get("minion_hp",1))
		var life:float=8.0 if spec.get("minion_blast",0)>0 else float(spec.get("duration",15))
		game.minions.append({"type":type,"p":p,"hp":hp,"max_hp":hp,"damage":spec.damage,"might_snapshot":might_multiplier(),"life":life,"cd":.1,"dr":1.0-(1.0-float(game.rules.data.minion_base_dr))*(1.0-float(spec.get("minion_dr",0))),"speed":spec.get("minion_speed",1),"blast":spec.get("minion_blast",0),"splash":spec.get("minion_splash",0),"knockback":spec.get("knockback",0)})
		game.effects.append({"kind":"curse","p":p,"radius":45,"life":.4})
	game.combat_audio.play_effect("curse")
func update(delta:float)->void:
	for i in range(game.minions.size()-1,-1,-1):
		var m:Dictionary=game.minions[i]
		m.life-=delta;m.cd=maxf(0,m.cd-delta)
		m.attack_flash=maxf(0,float(m.get("attack_flash",0))-delta)
		if m.get("blast",0)>0:m.hp-=m.max_hp*delta/8.0
		if m.life<=0 or m.hp<=0:
			if m.get("blast",0)>0:
				game.effects.append({"kind":"death","element":"fire","p":m.p,"life":.65})
				game.combat_audio.play_effect("death_fire")
				for e in game.enemies:
					if not e.dead and int(e.zone)<=mini(game.profile.cleared.size(),game.zone_count()-1) and e.p.distance_to(m.p)<140:game.hit_enemy(e,attack_damage(m)*m.blast,false,"fire",0,false)
			game.minions.remove_at(i);continue
		var target:Dictionary={};var nearest:=450.0
		for e in game.enemies:
			if e.dead or int(e.zone)>mini(game.profile.cleared.size(),game.zone_count()-1):continue
			var distance:float=m.p.distance_to(e.p)
			if distance<nearest:target=e;nearest=distance
		var range_:float=95 if m.get("type","summon")=="summon" else 290
		var destination:Vector2=game.player if target.is_empty() else target.p
		if not target.is_empty():m.facing=(target.p-m.p).normalized()
		if not target.is_empty() and nearest<=range_ and m.cd<=0:
			cast(m,target);m.cd=(1.1 if m.get("type","summon")=="hydra_summon" else .9)/float(m.get("speed",1))
		var old_position:Vector2=m.p
		var should_move:bool=m.p.distance_to(destination)>(44 if target.is_empty() else range_*.8)
		if should_move:
			var direction:Vector2=(destination-m.p).normalized()
			for angle in [0.0,.8,-.8,1.5,-1.5,2.2,-2.2]:
				var step:Vector2=m.p+direction.rotated(angle)*195*move_multiplier()*delta
				if game.can_move(step):m.p=step;break
		m.stuck=float(m.get("stuck",0))+delta if should_move and m.p.distance_to(destination)>=old_position.distance_to(destination)-.1 else 0.0
		if m.p.distance_to(game.player)>600 or float(m.stuck)>1.2:
			m.p=game.player;m.stuck=0.0
func cast(m:Dictionary,target:Dictionary)->void:
	m.attack_flash=.25
	m.facing=(target.p-m.p).normalized()
	var type:String=m.get("type","summon")
	var targets:Array=[target]
	if type=="hydra_summon":
		for e in game.enemies:
			if targets.size()>=3:break
			if not e.dead and int(e.zone)<=mini(game.profile.cleared.size(),game.zone_count()-1) and e!=target and e.p.distance_to(target.p)<160:targets.append(e)
	var victims:Dictionary={}
	for mark in targets:
		var element:String="ice" if type=="siren_summon" else ("poison" if type=="hydra_summon" else "physical")
		game.effects.append({"kind":"slash" if type=="summon" else "travel","p":m.p,"to":mark.p,"leap":false,"angle":(mark.p-m.p).angle(),"radius":95,"arc":110,"life":.23})
		var radius:float=float(m.get("splash",0))
		for e in game.enemies:
			if e.dead or int(e.zone)>mini(game.profile.cleared.size(),game.zone_count()-1) or victims.has(e.id):continue
			var hit:bool=e==mark or (radius>0 and e.p.distance_to(mark.p)<=radius)
			if type=="summon":hit=hit or (e.p.distance_to(m.p)<95 and absf((mark.p-m.p).angle_to(e.p-m.p))<.96)
			if not hit:continue
			victims[e.id]=true
			game.hit_enemy(e,attack_damage(m)*(.75 if radius>0 else 1.0),false,element,m.get("knockback",0),false)
			if type=="siren_summon":e.slow_time=1.3;e.slow=.3
		if type=="hydra_summon":
			game.fields.append({"kind":"venom","p":mark.p,"radius":maxf(48,radius),"damage":attack_damage(m)*.12,"life":1.0,"tick":.5,"minion":true})
	game.combat_audio.play_effect("curse" if type=="siren_summon" else "hit")

func might_multiplier()->float:
	return 1.0+game.rules.buff_value(game.profile,"might") if "might" in game.profile.get("buffs",[]) else 1.0
func attack_damage(m:Dictionary)->float:
	return float(m.damage)*might_multiplier()/float(m.get("might_snapshot",might_multiplier()))
func move_multiplier()->float:
	return 1.0+game.rules.buff_value(game.profile,"wind") if "wind" in game.profile.get("buffs",[]) else 1.0
func receive_damage(m:Dictionary,amount:float)->void:
	var reduction:float=1.0-clampf(float(m.get("dr",0)),0,.65)
	if "ward" in game.profile.get("buffs",[]):reduction*=1.0-game.rules.buff_value(game.profile,"ward")
	m.hp-=maxf(0,amount)*reduction
