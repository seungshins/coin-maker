extends RefCounted
const IDS=["archmage","life_leech","mana_leech","added_fire","added_ice","added_lightning","attack_haste","cast_haste","penetration","trigger"]
static func compatible(id:String,tags:Array)->bool:
	if "summon" in tags:return false
	if id in ["archmage","cast_haste"]:return "spell" in tags
	if id in ["life_leech","mana_leech","attack_haste"]:return "spell" not in tags
	return true
static func describe(id:String,r:int)->String:
	match id:
		"archmage":return "마법 전용 · 기본 비용 후 남은 마나 80%% 추가 소비 · 소비 마나 ×%.2f 번개 추가 피해 (기본 피해의 400%% 한도)"%(.4+.08*r)
		"life_leech":return "공격 명중 피해의 %.1f%% 체력 흡수 · 초당 최대 체력 8%% 한도"%(.4+.3*r)
		"mana_leech":return "공격 명중 피해의 %.1f%% 마나 흡수 · 초당 최대 마나 12%% 한도"%(.3+.2*r)
		"attack_haste","cast_haste":return "공격/시전 속도 +%d%% · 마나 비용 +10%%"%(12+r*5)
		"penetration":return "원소 저항 관통 %d%% · 원소 피해에만 적용"%(5+r*3)
		"trigger":return "명중 시 %d%%로 연결한 주스킬 발동 · 피해 50%% · 내부 재사용 1초 · 무기 제한 무시 · 연쇄 발동 불가"%(10+r*3)
	return "해당 원소로 기본 피해의 %d%% 추가"%(8+r*4)
static func configure(rules,profile:Dictionary,spec:Dictionary)->void:
	var context:Dictionary={"id":profile.skill}
	for index in profile.get("skill_supports",{}).get(profile.skill,profile.supports).slice(0,rules.slots(profile)):
		if int(index)<0 or int(index)>=profile.gems.size():continue
		var gem:Dictionary=profile.gems[int(index)];var r:int=gem.rarity
		if gem.id not in IDS or profile.level<rules.gem_level(r) or not compatible(gem.id,spec.tags):continue
		if gem.id=="trigger" and profile.get("skill_supports",{}).get(profile.skill,profile.supports).size()+1>rules.slots(profile):continue
		context[gem.id]=r
		if gem.id in ["attack_haste","cast_haste"]:spec.interval=maxf(.08,spec.interval/(1.12+r*.05));spec.mana*=1.1
	spec.support_context=context
	spec.damage*=1.0+.02*clampi(int(profile.get("skill_upgrades",{}).get(profile.skill,0)),0,10)
static func prepare(game,spec:Dictionary,repeated:bool)->void:
	var context:Dictionary=spec.get("support_context",{})
	if context.has("archmage") and not repeated:
		var spent:float=game.mana*.8;game.mana-=spent
		context=context.duplicate(true);context.archmage_damage=minf(spec.damage*4,spent*(.4+.08*int(context.archmage)));spec.support_context=context
var game
var budget_second:=-1
var hp_used:=0.0
var mp_used:=0.0
func _init(g)->void:game=g
func bonus(context:Dictionary,damage:float)->float:
	var extra:=float(context.get("archmage_damage",0))
	for element in ["fire","ice","lightning"]:
		if context.has("added_"+element):extra+=damage*(.08+.04*int(context["added_"+element]))
	return extra
func on_hit(context:Dictionary,enemy:Dictionary,dealt:float)->void:
	if context.is_empty():return
	for element in ["fire","ice","lightning"]:
		if context.has("added_"+element) or (element=="lightning" and context.has("archmage")):
			game.effects.append({"kind":"impact","element":element,"p":enemy.p,"life":.22})
	var second:int=Time.get_ticks_msec()/1000
	if second!=budget_second:budget_second=second;hp_used=0;mp_used=0
	var stats:Dictionary=game.rules.stats(game.profile)
	if context.has("life_leech"):
		var amount:float=minf(maxf(0,stats.hp*.08-hp_used),dealt*(.004+.003*int(context.life_leech)));hp_used+=amount;game.health=minf(stats.hp,game.health+amount)
	if context.has("mana_leech"):
		var amount:float=minf(maxf(0,stats.mana*.12-mp_used),dealt*(.003+.002*int(context.mana_leech)));mp_used+=amount;game.mana=minf(stats.mana,game.mana+amount)
	if context.has("trigger") and game.proc_cooldowns.get("linked_trigger",0)<=0 and game.rng.randf()<.10+.03*int(context.trigger):
		var id:String=game.profile.get("trigger_skills",{}).get(str(context.get("id","")),"")
		if id not in game.profile.skills or not game.rules.data.skills.has(id) or game.rules.skill_rank(game.profile,id)<0:return
		game.proc_cooldowns.linked_trigger=1.0
		var original:String=game.profile.skill;var old_aim:Vector2=game.aim
		game.profile.skill=id;game.aim=(enemy.p-game.player).normalized()
		var spec:Dictionary=game.rules.skill_spec(game.profile);spec.damage*=.5;spec.support_context={};spec.repeat=false
		# Defer until the current hit/enemy iteration completes.
		game.pending_repeats.append({"delay":.01,"spec":spec,"aim":game.aim,"target":enemy.p})
		game.profile.skill=original;game.aim=old_aim
