extends RefCounted
const Math = preload("res://src/domain/combat_math.gd")
var data: Dictionary

func _init() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json"))

func new_profile() -> Dictionary:
	return {"schema": 1, "gold": 100, "level": 1, "xp": 0, "attributes": [0, 0, 0], "skill": "slash", "skills": ["slash", "bow"], "gems": [{"id": "power", "rarity": 0}], "supports": [0], "items": [{"name": "귀향자의 검", "slot": 0, "rarity": 0, "value": 3, "unique": false}], "equipment": [0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1], "shards": 0, "pity": [0, 0], "cleared": [], "intro_seen": false, "voyages": 0}

func slots(profile: Dictionary) -> int:
	var level := int(profile.level)
	return 1 + int(level >= 5) + int(level >= 15) + int(level >= 30) + int(level >= 60) + int(level >= 85)

func xp_needed(level: int) -> int:
	return roundi((100 + 40 * (level-1) + 8 * (level-1)*(level-1))*(1+.035*maxi(0,level-60)))

func add_xp(profile: Dictionary, amount: int) -> bool:
	var leveled := false
	profile.xp += amount
	while profile.level < int(data.level_cap) and profile.xp >= xp_needed(int(profile.level)):
		profile.xp -= xp_needed(int(profile.level))
		profile.level += 1
		leveled = true
	if profile.level >= int(data.level_cap):
		profile.xp = 0
	return leveled

func item_value(item:Dictionary)->float:
	return float(item.value) * [1.0,1.15,1.4,1.8,2.5,3.3][clampi(int(item.rarity),0,5)]

func stats(profile: Dictionary) -> Dictionary:
	var result := {"hp": 100.0 + (profile.level - 1) * 5 + profile.attributes[0] * 1, "damage": 0.0, "speed": 1.0 + profile.attributes[1] * 0.0005, "armor":0.0, "move": 290.0 * (1 + profile.attributes[1] * 0.00025)}
	for index in profile.equipment:
		if int(index) >= 0 and int(index) < profile.items.size():
			var item: Dictionary = profile.items[int(index)]
			if item.slot == 0:
				if str(item.get("weapon_type","sword"))==required_weapon(str(profile.skill)):result.damage += item_value(item)
			elif item.slot == 1:
				result.hp += item_value(item)
			elif int(item.slot) in [3,4]:result.armor+=item_value(item)
			elif int(item.slot)==5:result.move*=1.0+minf(.3,item_value(item)*.0015)
			else:
				result.speed += item_value(item) * (0.0006 if int(item.slot)>=6 else 0.001)
	result.armor_reduction=minf(.35,result.armor/(result.armor+100.0+profile.level*12.0))
	result.mana = 80.0 + (profile.level - 1) * 1.5 + profile.attributes[2]
	result.mana_regen = (9.0 + profile.attributes[2] * 0.04) * (1.0 + effect_value(profile, "mana_regen"))
	result.speed = minf(2.0, result.speed)
	if "wind" in profile.get("buffs", []): result.move *= 1.0 + buff_value(profile,"wind")
	return result

func skill_spec(profile: Dictionary) -> Dictionary:
	var spec: Dictionary = data.skills[profile.skill].duplicate(true)
	spec.id = profile.skill
	spec.repeat = false
	spec.pierce_bonus = 0
	spec.knockback = 12.0 if effect_value(profile,"gauntlet_impact")>0 else 0.0
	var s := stats(profile)
	spec.damage = (spec.damage + s.damage) * (1.0 + profile.attributes[0 if spec.melee else (2 if "spell" in spec.tags else 1)] * float(data.progression.attribute_damage))
	spec.interval = maxf(0.1, spec.interval / s.speed)
	spec.projectiles = int(spec.get("base_projectiles", 1))
	spec.return_multiplier = 0.0
	spec.damage *= 1.0 + effect_value(profile,"wrath") + effect_value(profile,"precision") + minf(.3,profile.attributes[0]*effect_value(profile,"strength_damage")) + minf(.3,profile.attributes[2]*effect_value(profile,"intelligence_damage"))
	spec.damage *= 1.0 + float(data.progression.skill_per_level) * (clampi(int(profile.level),1,100)-1)
	var rank:int=skill_rank(profile,profile.skill)
	spec.damage *= (1.0 + 0.08*rank) if rank>=0 else 0.0
	if "might" in profile.get("buffs", []): spec.damage *= 1.0 + buff_value(profile,"might")
	for index in profile.get("skill_supports", {}).get(profile.skill, profile.supports).slice(0, slots(profile)):
		if int(index) < 0 or int(index) >= profile.gems.size():
			continue
		var gem: Dictionary = profile.gems[int(index)]
		var rarity := int(gem.rarity)
		if int(profile.level)<gem_level(rarity):continue
		if not support_compatible(str(gem.id), str(profile.skill)): continue
		match gem.id:
			"minion_guard":spec.minion_hp=data.minion_guard_hp[rarity];spec.minion_dr=data.minion_guard_dr[rarity]
			"minion_haste":spec.minion_speed=data.minion_haste[rarity]
			"minion_blast":spec.minion_blast=data.minion_blast[rarity]
			"minion_splash":spec.minion_splash=data.minion_splash[rarity]
			"spell_echo", "melee_echo":
				spec.repeat = true
				spec.damage *= data.support_echo[rarity]
			"homing":spec.homing=data.support_homing[rarity];spec.damage*=.85
			"pierce": spec.pierce_bonus += int(data.support_pierce[rarity])
			"impact": spec.knockback += data.support_impact[rarity]
			"fan":
				spec.arc = minf(360, spec.arc + data.support_fan[rarity])
				spec.damage *= 0.9
			"chain": spec.chain_count = int(data.support_chain[rarity])
			"duration": spec.duration = float(spec.get("duration",3)) * data.support_duration[rarity]
			"power": spec.damage *= data.support_power[rarity]
			"area":
				if spec.melee or spec.get("area", false): spec.reach *= data.support_area[rarity]
			"split":
				if not spec.melee and not spec.get("area", false):
					spec.projectiles += data.support_split[rarity]
					spec.damage *= 0.85
			"returning":
				if not spec.melee and not spec.get("area", false): spec.return_multiplier = data.support_return[rarity]
	if spec.melee or spec.get("area", false): spec.reach *= 1.0 + effect_value(profile, "area") + (effect_value(profile,"insight") if "spell" in spec.tags else 0.0)
	if "projectile" in spec.tags and effect_value(profile, "double_projectiles") > 0: spec.projectiles *= 2
	if effect_value(profile, "giant") > 0 and spec.melee: spec.reach *= 1.3
	return spec

func weighted(rng: RandomNumberGenerator, weights: Array) -> int:
	var sum := 0.0
	for w in weights: sum += float(w)
	var roll := rng.randf() * sum
	for i in range(weights.size()):
		roll -= float(weights[i])
		if roll < 0: return i
	return weights.size() - 1

func item_roll(rng: RandomNumberGenerator, rarity: int, level: int, weapon_filter:String="") -> Dictionary:
	var slot:int = [0,1,2,3,4,5,6,8][rng.randi_range(0,7)]
	var weapon_type:String=["sword","spear","wand","bow"][rng.randi_range(0,3)]
	if weapon_filter in ["sword","spear","wand","bow"]:slot=0;weapon_type=weapon_filter
	var unique := rarity >= 4 or (rarity == 3 and rng.randf() < 0.2)
	var names := ["청동 "+weapon_name(weapon_type), "청동 흉갑", "바람의 부적", "청동 투구", "청동 장갑", "가죽 신발", "청동 반지", "청동 반지", "청동 목걸이"]
	var effect := ""
	if unique and slot>=3:
		var special:Array={3:["아테나의 통찰","insight","헤스티아의 관","mana_regen"],4:["헤라클레스의 주먹","gauntlet_impact","아르테미스의 손길","precision"],5:["헤르메스의 발걸음","dodge"],6:["아폴론의 인장","precision"],8:["아테나의 펜던트","mana_regen"]}[slot]
		var pick:int=rng.randi_range(0,special.size()/2-1)*2
		names[slot]=special[pick];effect=special[pick+1]
	elif unique:
		var variants := [["아레스의 유산", "heal", "포세이돈의 창", "area", "히드라의 송곳니", "double_projectiles", "아레스의 전쟁창", "wrath", "헤라클레스의 맹세", "strength_damage", "헤카테의 지혜", "intelligence_damage", "하데스의 심판", "curse_hit", "포세이돈의 진동", "shockwave_hit"], ["아킬레우스의 갑주", "guard", "보레아스의 외투", "frost", "아틀라스의 어깨", "giant", "티케의 변덕", "random_boon"], ["헤르메스의 날개", "dodge", "아테나의 부엉이", "mana_regen", "프로테우스의 사슬", "headhunter"]]
		var choice := rng.randi_range(0, (variants[slot].size()/2-1) if rarity >= 4 else 1) * 2
		names[slot] = variants[slot][choice]
		effect = variants[slot][choice + 1]
	return {"name": names[slot], "weapon_type":weapon_type, "slot": slot, "rarity": rarity, "value": (3 + rarity * 3 + int(ceil(level*.5)) + rng.randi_range(0, 3)) * (3 if slot == 1 else 1), "unique": unique, "effect": effect}

func award_gem(profile: Dictionary, gem: Dictionary, from_gacha:bool=false) -> String:
	for owned in profile.gems:
		if owned.id == gem.id and owned.rarity == gem.rarity:
			if not from_gacha:return "이미 보유한 젬 · 필드 중복은 조각으로 환원되지 않습니다."
			profile.shards += int(gem.rarity) + 1
			return "중복 젬 → 조각 +%d" % (int(gem.rarity) + 1)
	profile.gems.append(gem)
	return "%s %s 획득" % [data.rarity_names[int(gem.rarity)], data.supports[gem.id].name]

func award_primary(profile:Dictionary,id:String,rarity:int,from_gacha:bool=false)->String:
	preload("res://src/domain/storage_rules.gd").ensure(profile)
	var owned:Array=profile.skill_versions.get(id,[])
	if rarity in owned:
		if not from_gacha:return "이미 보유한 주스킬 · 필드 중복은 조각으로 환원되지 않습니다."
		profile.shards+=rarity+1
		return "중복 주스킬 → 조각 +%d"%(rarity+1)
	owned.append(rarity);owned.sort()
	profile.skill_versions[id]=owned
	if id not in profile.skills:profile.skills.append(id)
	profile.skill_rarities[id]=maxi(int(profile.skill_rarities.get(id,0)),rarity)
	return "%s %s 획득 · 필요 Lv.%d"%[data.rarity_names[rarity],data.skills[id].name,gem_level(rarity)]

func gem_level(rarity:int)->int:return int(data.progression.gem_levels[clampi(rarity,0,5)])
func skill_rank(profile:Dictionary,id:String)->int:
	var owned:Array=profile.get("skill_versions",{}).get(id,[int(profile.get("skill_rarities",{}).get(id,0))])
	var choice:int=int(profile.get("selected_skill_rarities",{}).get(id,-1))
	if choice in owned and int(profile.level)>=gem_level(choice):return choice
	var best:=-1
	for rank in owned:
		if int(profile.level)>=gem_level(int(rank)):best=maxi(best,int(rank))
	return best
func loot_weights(profile:Dictionary,boss:bool=false)->Array:
	var level:int=int(profile.level)
	var tier:int=int(profile.get("tier",0))
	var progress:float=clampf((level-1)/29.0,0,1)
	var weights:Array=[]
	var early:Array=[90,10,0,0,0,0]
	var late:Array=[40,40,18,2,0,0]
	if tier>0:
		early=[15,35,38,11,1,0]
		late=[1,4,25,45,20,5]
		progress=clampf((tier-1)/15.0,0,1)
	for rank in range(6):
		var weight:float=lerpf(early[rank],late[rank],progress)
		if level<int(data.progression.drop_levels[rank]):weight=0
		if boss and rank>=3:weight*=1.5
		weights.append(weight)
	return weights

func gacha_cost(profile:Dictionary,shards:bool=false)->int:
	if shards:return 5+int((int(profile.level)-1)/15)
	return int(data.progression.gacha_base)+int(data.progression.gacha_level)*(int(profile.level)-1)+int(data.progression.gacha_tier)*int(profile.get("tier",0))

func gacha_weights(profile:Dictionary,pity:int=0)->Array:
	var weights:Array=loot_weights(profile)
	for rank in range(2,6):weights[rank]*=[1,1,.7,.5,.4,.3][rank]
	if pity>=49:
		var floor_rank:int=3 if int(profile.level)>=40 else (2 if int(profile.level)>=20 else 1)
		for rank in range(floor_rank):weights[rank]=0
	return weights

func campaign_xp(profile:Dictionary,zone:int,zones:int)->int:
	if int(profile.get("tier",0))>0:return 0
	var act:int=clampi(int(profile.get("stage_id",0)),0,6)
	var key:String=str(act)+":"+str(zone)
	if not profile.has("quest_xp_claimed"):profile.quest_xp_claimed=[]
	if key in profile.quest_xp_claimed:return 0
	profile.quest_xp_claimed.append(key)
	var previous:int=1 if act==0 else int(data.progression.act_end_levels[act-1])
	var target:int=floori(lerpf(previous,int(data.progression.act_end_levels[act]),float(zone+1)/zones))
	var amount:int=-int(profile.xp)
	for level in range(int(profile.level),target):amount+=xp_needed(level)
	return maxi(0,amount)

func support_numbers(gem: Dictionary) -> String:
	var rarity := int(gem.rarity)
	match gem.id:
		"minion_guard":return "소환수 체력 +%d%% · 받는 피해 -%d%%"%[roundi((data.minion_guard_hp[rarity]-1)*100),roundi(data.minion_guard_dr[rarity]*100)]
		"minion_haste":return "소환수 공격·시전 속도 +%d%%"%roundi((data.minion_haste[rarity]-1)*100)
		"minion_blast":return "8초간 초당 최대 체력12.5%% 소모 · 사망/만료 시 반경140, 소환 공격 피해 ×%.1f 폭발"%data.minion_blast[rarity]
		"minion_splash":return "소환 공격 범위 반경%d · 피해 ×0.75"%data.minion_splash[rarity]
		"spell_echo", "melee_echo": return "2회 반복 · 각 피해 %d%% · 추가 마나 없음" % roundi(data.support_echo[rarity] * 100)
		"homing":return "투사체 유도 · 회전 초당%d° · 탐색450 · 피해 ×0.85 · 귀환 중 제외"%roundi(rad_to_deg(data.support_homing[rarity]))
		"pierce": return "추가 관통 +%d" % data.support_pierce[rarity]
		"impact": return "밀쳐내기 거리 +%d" % data.support_impact[rarity]
		"fan": return "공격 각도 +%d° · 피해 -10%%" % data.support_fan[rarity]
		"chain": return "%d회 전파 · 전파 피해 60%% · 같은 적 재전파 없음" % data.support_chain[rarity]
		"duration": return "지속시간 +%d%%" % roundi((data.support_duration[rarity]-1)*100)
		"power": return "피해 ×%.2f  (+%d%%)" % [data.support_power[rarity], roundi((data.support_power[rarity] - 1) * 100)]
		"area": return "범위 반경 +%d%%" % roundi((data.support_area[rarity] - 1) * 100)
		"returning": return "귀환 시 피해 %d%% · 왕복 각 1회 적중" % roundi(data.support_return[rarity] * 100)
		"split": return "투사체 +%d\n개별 피해 ×0.85 (-15%%)" % data.support_split[rarity]
	return ""

func toggle_buff(profile: Dictionary, id: String) -> String:
	preload("res://src/domain/storage_rules.gd").ensure(profile)
	if not data.buffs.has(id): return "알 수 없는 버프입니다."
	if id in profile.buffs: profile.buffs.erase(id)
	elif profile.buffs.size() < 2: profile.buffs.append(id)
	else: return "유지형 버프는 최대 2개입니다."
	return ""

func unique_value(profile: Dictionary, slot: int) -> float:
	return effect_value(profile, ["heal", "guard", "dodge"][slot])

func dodge_interval(profile: Dictionary) -> float:
	return 1.5 * (1.0 - unique_value(profile, 2))

func attribute_text(profile: Dictionary, index: int) -> String:
	var points: int = profile.attributes[index]
	match index:
		0: return "1당 체력 +1 · 근접 피해 +1%%\n현재 체력 +%d · 근접 +%.1f%%" % [points, points * 1.0]
		1: return "1당 활·투척 피해 +1%% · 행동 +0.025%% · 이동 +0.025%%\n현재 활·투척 +%.1f%% · 행동 +%.1f%% · 이동 +%.2f%%" % [points * 1.0, points * 0.025, points * 0.025]
		2: return "1당 마법 피해 +1%% · 마나 +1 · 재생 +0.04/초\n현재 마법 피해 +%.1f%%" % (points * 1.0)
	return ""

func item_effect(item: Dictionary) -> String:
	if not item.get("unique", false): return ""
	return str(item.get("effect", (["heal", "guard", "dodge"][int(item.slot)] if int(item.slot)<3 else "")))

func effect_value(profile: Dictionary, effect: String) -> float:
	var values := {"curse_hit":.12,"shockwave_hit":.1,"random_boon":.08,"strength_damage":.0015,"intelligence_damage":.0015,"insight":.1,"gauntlet_impact":12.0,"precision":.08,"heal": 3.0, "guard": 0.10, "dodge": 0.20, "area": 0.25, "frost": 0.25, "mana_regen": 0.40, "double_projectiles": 1.0, "giant": 0.35, "headhunter": 12.0}
	for index in profile.equipment:
		if int(index) >= 0 and int(index) < profile.items.size() and item_effect(profile.items[int(index)]) == effect:
			if effect=="wrath":return 0.9 if int(profile.items[int(index)].rarity)==5 else 0.6
			return values.get(effect, 0.0)
	return 0.0

func effect_description(item: Dictionary) -> String:
	if item_effect(item)=="wrath":return "모든 주스킬 피해 +%d%%" % (90 if int(item.get("rarity",4))==5 else 60)
	return {"curse_hit":"명중 시12%로3초 피해 증폭 저주 · 재사용2초", "shockwave_hit":"명중 시10%로 반경110 충격파 · 타격35% 피해 · 재사용1.5초 · 연쇄 발동 없음", "random_boon":"명중 시8%로3초 무작위 격노/가속/다중투사체 · 재사용8초", "strength_damage":"배분한 힘1당 피해+0.15% · 최대30%", "intelligence_damage":"배분한 지능1당 피해+0.15% · 최대30%", "insight":"지면 주문 반경 +10%", "gauntlet_impact":"주스킬 밀치기 +12 · 보스 제외", "precision":"주스킬 피해 +8%", "heal": "처치 시 체력 +3", "guard": "받는 피해 -10%", "dodge": "회피 쿨다운 -20%", "area": "근접·지면 마법 반경 +25%", "frost": "피격 시 주변 150 범위 적 2초간 25% 감속", "mana_regen": "마나 재생 +40%", "double_projectiles": "투사체 수 2배 · 같은 시전은 적 하나에 1회 적중", "giant": "몸집 +35% · 근접 반경 +30% · 충돌 크기는 유지", "headhunter": "희귀·보스 몬스터 처치 시 해당 권능 12초 탈취 · 최대 3종 · 중첩 대신 갱신"}.get(item_effect(item), "기본 속성 장비")

func ability_info(id: String) -> Dictionary:
	if data.skills.has(id): return data.skills[id]
	if id.begins_with("aura:"): return data.buffs.get(id.trim_prefix("aura:"), {})
	if id.begins_with("curse:"): return data.curses.get(id.trim_prefix("curse:"), {})
	return data.utility.get(id, {})

func owns_ability(profile: Dictionary, id: String) -> bool:
	return id in profile.skills or (not ability_info(id).is_empty() and not data.skills.has(id))

func support_compatible(gem_id: String, skill_id: String) -> bool:
	if not data.skills.has(skill_id): return false
	var tags: Array = data.skills[skill_id].get("tags", [])
	if "primary" not in tags: return false
	match gem_id:
		"minion_guard","minion_haste","minion_blast","minion_splash":return "summon" in tags
		"fan": return "melee" in tags and not "duration" in tags
		"chain": return "projectile" in tags
		"duration": return "duration" in tags
		"power", "impact": return true
		"area": return "area" in tags
		"split", "returning", "pierce", "homing": return "projectile" in tags
		"spell_echo": return "spell" in tags and "summon" not in tags
		"melee_echo": return "melee" in tags and "channel" not in tags
	return false

func buff_scale(level:int)->float:return lerpf(.5,1.25,clampf((level-1)/99.0,0,1))
func buff_value(profile:Dictionary,id:String)->float:return float(data.buffs[id].value)*buff_scale(int(profile.level))
func move_range(profile:Dictionary,id:String)->float:return lerpf(140,330,clampf((int(profile.level)-1)/99.0,0,1))*(1.0 if id=="move:blink" else .9)
func area_level(profile:Dictionary,zone:int=0)->int:
	if int(profile.get("tier",0))>0:return mini(95,30+roundi((int(profile.tier)-1)*65.0/15))
	var act:int=clampi(int(profile.get("stage_id",0)),0,6)
	return mini(int(data.progression.act_end_levels[act]),[3,7,11,15,19,24,28][act]+zone)
func xp_rate(profile:Dictionary,zone:int=0)->float:
	var gap:int=area_level(profile,zone)-int(profile.level)
	return maxf(.02,pow(.85,gap-8)) if gap>8 else (maxf(.02,pow(.8,-gap-5)) if gap < -5 else 1.0)
func death_xp(profile:Dictionary)->int:
	if int(profile.get("tier",0))<=0:return 0
	var lost:int=mini(int(profile.xp),roundi(xp_needed(int(profile.level))*.1))
	profile.xp-=lost
	return lost

func weapon_name(kind:String)->String:return {"sword":"검","spear":"창","wand":"마법봉","bow":"활","none":"무기 없음"}.get(kind,"검")
func equipped_weapon(profile:Dictionary)->String:
	var needed:String=required_weapon(str(profile.skill))
	if weapon_index(profile,needed)>=0:return needed
	for index in profile.equipment:
		if int(index)>=0 and int(index)<profile.items.size() and int(profile.items[int(index)].slot)==0:return str(profile.items[int(index)].get("weapon_type","sword"))
	return "none"
func required_weapon(id:String)->String:
	if not data.skills.has(id):return ""
	if "spear" in id:return "spear"
	if id=="bow" or "arrow" in id:return "bow"
	if "spell" in data.skills[id].tags:return "wand"
	return "sword"
func weapon_allows(profile:Dictionary,id:String)->bool:
	return required_weapon(id).is_empty() or weapon_index(profile,required_weapon(id))>=0

func free_attributes(profile:Dictionary)->int:return maxi(0,(int(profile.level)-1)*2-int(profile.attributes[0]+profile.attributes[1]+profile.attributes[2]))
func allocate_attributes(profile:Dictionary,index:int,amount:int)->int:
	if index<0 or index>2 or amount<=0:return 0
	var spent:int=mini(amount,free_attributes(profile))
	profile.attributes[index]+=spent
	return spent
func reset_attributes_cost(profile:Dictionary)->int:return 50+int(profile.level)*2
func reset_attributes(profile:Dictionary)->bool:
	if int(profile.attributes[0]+profile.attributes[1]+profile.attributes[2])==0 or int(profile.gold)<reset_attributes_cost(profile):return false
	profile.gold-=reset_attributes_cost(profile);profile.attributes=[0,0,0]
	return true

const EQUIPMENT_NAMES=["검","흉갑","유물","투구","장갑","신발","반지 I","반지 II","목걸이","창","마법봉","활"]
func slot_name(slot:int)->String:return EQUIPMENT_NAMES[clampi(slot,0,11)]
func slot_icon(slot:int)->String:return ["weapon","armor","relic","helmet","gloves","boots","ring","ring","necklace"][clampi(slot,0,8)]
func slot_stat(item:Dictionary)->String:
	var value:float=item_value(item)
	match int(item.slot):
		0:return "피해 +%.1f"%value
		1:return "체력 +%.1f"%value
		3,4:return "방어도 +%.1f"%value
		5:return "이동 속도 +%.1f%%"%(minf(.3,value*.0015)*100)
		6,7,8:return "공격·시전 속도 +%.1f%%"%(value*.06)
	return "공격·시전 속도 +%.1f%%"%(value*.1)
func equip_slot(profile:Dictionary,item:Dictionary)->int:
	if int(item.slot)==0:return {"sword":0,"spear":9,"wand":10,"bow":11}.get(str(item.get("weapon_type","sword")),0)
	if int(item.slot) in [6,7]:return 7 if int(profile.equipment[6])>=0 and int(profile.equipment[7])<0 else 6
	return int(item.slot)
func elemental_bonuses(profile:Dictionary)->Dictionary:
	var result:Dictionary={}
	for id in ["fire","ice","lightning"]:
		if id in profile.get("buffs",[]):result[id]=buff_value(profile,id)
	return result

func item_icon(item:Dictionary)->String:
	if int(item.slot)==0:return {"sword":"slash","spear":"spear_throw","wand":"wand","bow":"bow"}.get(str(item.get("weapon_type","sword")),"slash")
	return slot_icon(int(item.slot))

func weapon_index(profile:Dictionary,type:String)->int:
	for index in profile.equipment:
		if int(index)>=0 and int(index)<profile.items.size():
			var item:Dictionary=profile.items[int(index)]
			if int(item.slot)==0 and str(item.get("weapon_type","sword"))==type:return int(index)
	return -1
