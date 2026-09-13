extends RefCounted

static func ensure(p: Dictionary) -> void:
	if not p.has("primary_weapon"):p.primary_weapon="sword"
	if not p.has("skill_upgrades"):p.skill_upgrades={}
	if not p.has("trigger_skills"):p.trigger_skills={}
	if not p.has("gacha_level") or int(p.gacha_level)<int(p.level):p.gacha_level=int(p.level);p.gacha_left=3
	if not p.has("gacha_left"):p.gacha_left=3
	if not p.has("stash_items"): p.stash_items = []
	if not p.has("stash_gems"): p.stash_gems = []
	if not p.has("loadout"):
		p.loadout = [p.skill, p.skills[1] if p.skills.size() > 1 else "", "", "curse:" + str(p.get("selected_curse", "vulnerability")), "move:blink", "burst:rage"]
	# Retire aura bindings without switching off previously active buffs.
	for slot in range(p.loadout.size()):
		if str(p.loadout[slot]).begins_with("aura:"): p.loadout[slot] = ""
	if not p.has("skill_supports"):
		p.skill_supports = {}
		for id in p.skills: p.skill_supports[id] = p.supports.duplicate()
	for id in p.skills:
		if not p.skill_supports.has(id): p.skill_supports[id] = []
	# JSON numbers decode as floats; normalize references before membership checks.
	for links in p.skill_supports.values():
		for i in range(links.size()): links[i] = int(links[i])
	while p.equipment.size()<12:p.equipment.append(-1)
	var old_weapon:int=int(p.equipment[0])
	if old_weapon>=0 and old_weapon<p.items.size():
		var target:int={"sword":0,"spear":9,"wand":10,"bow":11}.get(str(p.items[old_weapon].get("weapon_type","sword")),0)
		if target!=0 and int(p.equipment[target])<0:p.equipment[target]=old_weapon;p.equipment[0]=-1
	for i in range(p.equipment.size()): p.equipment[i] = int(p.equipment[i])
	p.supports = p.skill_supports.get(p.skill, [])
	if not p.has("selected_curse"): p.selected_curse = "vulnerability"
	if not p.has("buffs"): p.buffs = []
	if not p.has("skill_rarities"): p.skill_rarities = {}
	for id in p.skills:
		if not p.skill_rarities.has(id): p.skill_rarities[id] = 0
	if not p.has("skill_versions"):
		p.skill_versions={}
		for id in p.skills: p.skill_versions[id]=[0] if int(p.skill_rarities[id])==0 else [0,int(p.skill_rarities[id])]
	if not p.has("selected_skill_rarities"):p.selected_skill_rarities={}
	for id in p.skills:
		if not p.skill_versions.has(id):p.skill_versions[id]=[int(p.skill_rarities[id])]
		for i in range(p.skill_versions[id].size()):p.skill_versions[id][i]=int(p.skill_versions[id][i])
	while p.pity.size() < 3: p.pity.append(0)
	if not p.has("stage_id"): p.stage_id = 0
	if not p.has("stage_unlocked"): p.stage_unlocked = 1 if p.voyages > 0 or p.cleared.size() == 3 else 0
	if not p.has("stage_progress"): p.stage_progress = {}
	if not p.has("tier"): p.tier = 0
	if not p.has("tier_unlocked"): p.tier_unlocked = 1
	if not p.has("campaign_complete"): p.campaign_complete = false

static func transfer(p: Dictionary, gems: bool, deposit: bool, index: int) -> String:
	ensure(p)
	var bag_key := "gems" if gems else "items"
	var stash_key := "stash_gems" if gems else "stash_items"
	var source: Array = p[bag_key if deposit else stash_key]
	var target: Array = p[stash_key if deposit else bag_key]
	if index < 0 or index >= source.size(): return "선택한 물건이 없습니다."
	if target.size() >= 100: return "목적지 보관 공간이 가득 찼습니다."
	var equipped: Array = linked_indices(p) if gems else p.equipment
	if deposit and index in equipped: return "장착 중입니다. 먼저 해제하세요."
	if not deposit and gems:
		for gem in target:
			if gem.id == source[index].id and gem.rarity == source[index].rarity:
				return "같은 젬이 가방에 있습니다. 기존 젬을 보관한 뒤 꺼내세요."
	target.append(source[index])
	source.remove_at(index)
	if deposit and gems:
		for links in p.skill_supports.values():
			for i in range(links.size()):
				if int(links[i]) > index: links[i] = int(links[i]) - 1
		p.supports = p.skill_supports.get(p.skill, [])
	elif deposit:
		for i in range(equipped.size()):
			if int(equipped[i]) > index: equipped[i] = int(equipped[i]) - 1
	return ""

static func linked_indices(p: Dictionary) -> Array:
	var result: Array = []
	for links in p.get("skill_supports", {"legacy": p.supports}).values():
		for index in links:
			if index not in result: result.append(index)
	return result
