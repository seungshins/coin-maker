extends RefCounted
var game
func _init(g)->void:game=g
func prepare(e:Dictionary,focus:Vector2)->void:
	var index:int=int(e.get("pattern",0));e.pattern=index+1
	var caster:bool=e.get("model","")in ["gorgon","empusa"]
	e.boss_attack=("gaze" if index%2 else "poison_fan") if caster else ("sweep" if index%2 else "slam")
	if e.get("model","")=="empusa":e.boss_attack="slam" if index%2 else "flame_fan"
	e.attack_origin=e.p;e.target=focus;e.attack_dir=(focus-e.p).normalized()
	if e.attack_dir==Vector2.ZERO:e.attack_dir=Vector2.RIGHT
	e.windup=1.5 if caster else (1.15 if e.boss_attack=="slam" else 1.3)
	e.windup_total=e.windup;e.recovery=0.0
func contains(e:Dictionary,p:Vector2)->bool:
	if e.get("boss_attack","")=="slam":return p.distance_to(e.target)<=110
	var offset:Vector2=p-e.get("attack_origin",e.p)
	var radius:float=420 if e.get("boss_attack","")=="gaze" else 220
	return offset.length()<=radius and absf(e.get("attack_dir",Vector2.RIGHT).angle_to(offset))<=deg_to_rad(60 if e.get("boss_attack","")=="gaze" else 70)
func update(e:Dictionary,delta:float,focus:Vector2)->void:
	if not e.has("boss_attack"):e.windup=0.0
	e.recovery=maxf(0,float(e.get("recovery",0))-delta)
	if e.windup>0:
		e.windup-=delta
		if e.windup<=0:strike(e);e.recovery=.75;e.cd=1.6
		return
	if e.recovery>0:return
	var range_:float=370 if e.get("model","")=="gorgon" else 235
	if e.p.distance_to(focus)<range_ and e.cd<=0:prepare(e,focus);return
	if e.p.distance_to(focus)>range_*.65:
		var direction:Vector2=(focus-e.p).normalized()
		for angle in [0.0,.7,-.7]:
			var p:Vector2=e.p+direction.rotated(angle)*80*game.difficulty().speed*delta
			if game.can_move(p):e.p=p;break
func strike(e:Dictionary)->void:
	var damage:float=35*game.difficulty().damage*game.enemy_damage_rate(e)
	if e.boss_attack in ["poison_fan","flame_fan"]:
		for i in range(5):game.bolts.append({"p":e.p,"v":e.attack_dir.rotated((i-2)*.22)*245,"life":2.3,"damage":damage*.6,"friendly":false,"attack":-1,"skill_id":"fire_arrow" if e.boss_attack=="flame_fan" else "venom"})
		game.combat_audio.play_effect("curse");return
	if contains(e,game.player):
		game.hurt(damage*(1.15 if e.boss_attack=="slam" else .9))
		if e.boss_attack=="gaze" and game.dodge<=0:
			game.petrify_time=2.5;game.notify("석화 · 2.5초 동안 이동 속도 45% 감소")
	for m in game.minions:
		if contains(e,m.p):game.battle_extras.minion_combat.receive_damage(m,damage)
	game.effects.append({"kind":"slash" if e.boss_attack=="sweep" else "curse","p":e.p if e.boss_attack=="sweep" else e.target,"radius":220 if e.boss_attack=="sweep" else 110,"arc":140,"angle":e.attack_dir.angle(),"life":.35})
	game.combat_audio.play_effect("thunder" if e.boss_attack=="slam" else "curse")
