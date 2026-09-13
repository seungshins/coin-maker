extends RefCounted
var game
func _init(owner_game) -> void: game = owner_game

func assign(slot: int, id: String) -> bool:
	if slot < 0 or slot >= 6 or id.begins_with("aura:"): return false
	if not game.rules.weapon_allows(game.profile,id):game.notify("필요 무기: "+game.rules.weapon_name(game.rules.required_weapon(id)));return false
	if game.rules.data.skills.has(id) and game.rules.skill_rank(game.profile,id)<0:return false
	if not id.is_empty() and not game.rules.owns_ability(game.profile, id): return false
	var next: Dictionary = game.profile.duplicate(true)
	var previous: String = next.loadout[slot]
	var other: int = next.loadout.find(id)
	if not id.is_empty() and other >= 0 and other != slot: next.loadout[other] = previous
	next.loadout[slot] = id
	if game.rules.data.skills.has(id): next.skill = id
	return game.commit(next)

func use_slot(slot: int) -> bool:
	if game.mode != "play" or slot < 0 or slot >= 6: return false
	var id: String = game.profile.loadout[slot]
	if id.is_empty() or not game.rules.owns_ability(game.profile, id): return false
	if not game.rules.weapon_allows(game.profile,id):return false
	if float(game.ability_cooldowns.get(id, 0)) > 0: return false
	var rules = game.rules
	var info: Dictionary = rules.ability_info(id)
	if rules.data.skills.has(id):
		if rules.skill_rank(game.profile,id)<0:return false
		if game.dodge > 0: return false
		if game.mana < info.get("mana", 0): return false
		var original: String = game.profile.skill
		game.profile.skill = id
		var spec: Dictionary = rules.skill_spec(game.profile)
		if float(game.burst_timers.get("burst:rage", 0)) > 0: spec.damage *= 1.0+.35*rules.buff_scale(game.profile.level)
		if float(game.burst_timers.get("burst:volley", 0)) > 0 and not spec.melee and not spec.get("area", false): spec.projectiles += maxi(1,roundi(3*rules.buff_scale(game.profile.level)))
		if float(game.stolen_affixes.get("fury", 0)) > 0: spec.damage *= 1.25
		if float(game.stolen_affixes.get("titan", 0)) > 0 and spec.melee: spec.reach *= 1.2
		game.visual_weapon=rules.required_weapon(id)
		game.attack(spec)
		game.profile.skill = original
		game.ability_cooldowns[id] = spec.interval
		game.cooldown_totals[id]=spec.interval
		return true
	if id.begins_with("aura:"): return false
	if id.begins_with("curse:"):
		if game.curse_cd > 0 or game.mana < info.mana: return false
		game.profile.selected_curse = id.trim_prefix("curse:")
		game.cast_curse_at(game.mouse_target())
		game.ability_cooldowns[id] = rules.data.curse.cooldown
		game.cooldown_totals[id]=rules.data.curse.cooldown
		return true
	if game.mana < info.mana: return false
	if id.begins_with("move:"):
		if not move_to(id, game.mouse_target()): return false
	else:
		game.burst_timers[id] = info.duration
		game.effects.append({"kind": "curse", "p": game.player, "radius": 45.0, "life": 0.4})
	game.mana -= info.mana
	game.ability_cooldowns[id] = info.cooldown
	game.cooldown_totals[id]=info.cooldown
	game.combat_audio.play_effect("curse")
	return true

func move_to(id: String, target: Vector2) -> bool:
	var old: Vector2 = game.player
	var delta: Vector2 = (target - old).limit_length(game.rules.move_range(game.profile,id))
	for step in range(10, 0, -1):
		var destination: Vector2 = old + delta * step / 10.0
		if destination.distance_to(old) < 25 or not game.can_move(destination): continue
		game.player = destination
		game.effects.append({"kind": "travel", "p": old, "to": destination, "life": 0.3, "leap": id == "move:leap"})
		game.dodge = 0.18
		game.dodge_dir = Vector2.ZERO
		if id == "move:leap":
			game.effects.append({"kind": "slash", "p": destination, "angle": 0.0, "arc": 360.0, "radius": 100.0, "life": 0.23})
			for enemy in game.enemies:
				if not enemy.dead and enemy.p.distance_to(destination) < 100: game.hit_enemy(enemy, 70 + game.rules.stats(game.profile).damage, true)
		return true
	return false
