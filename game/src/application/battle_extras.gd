extends RefCounted
const Math = preload("res://src/domain/combat_math.gd")
var game
func _init(owner_game) -> void: game = owner_game

func element(id: String) -> String:
	if id=="tidal_aura": return "water"
	if id in ["fire_arrow", "lava_wave","fire_spear","fire_zone"]: return "fire"
	if id in ["ice_arrow", "blizzard", "ice_zone","ice_spear"]: return "ice"
	if id in ["bolt", "thunder", "lightning_arrow","lightning_spear"]: return "lightning"
	return "physical"

func update(delta: float) -> void:
	for key in game.stolen_affixes.keys():
		game.stolen_affixes[key] -= delta
		if game.stolen_affixes[key] <= 0: game.stolen_affixes.erase(key)
	for i in range(game.pending_repeats.size() - 1, -1, -1):
		var entry: Dictionary = game.pending_repeats[i]
		entry.delay -= delta
		if entry.delay > 0: continue
		game.pending_repeats.remove_at(i)
		var previous: String = game.profile.skill
		var old_aim: Vector2 = game.aim
		game.profile.skill = entry.spec.id
		game.aim = entry.aim
		game.attack(entry.spec, true, entry.target)
		game.profile.skill = previous
		game.aim = old_aim
	for i in range(game.minions.size() - 1, -1, -1):
		var m: Dictionary = game.minions[i]
		m.life -= delta
		m.cd = maxf(0, m.cd - delta)
		if m.life <= 0 or m.hp <= 0: game.minions.remove_at(i); continue
		var target: Dictionary = {}
		var nearest := 420.0
		for e in game.enemies:
			if e.dead or e.zone != mini(game.profile.cleared.size(), game.zone_count() - 1): continue
			var distance: float = m.p.distance_to(e.p)
			if distance < nearest: target = e; nearest = distance
		var destination: Vector2 = game.player
		if not target.is_empty():
			destination = target.p
			if nearest < 65 and m.cd <= 0:
				m.cd = 0.8
				game.effects.append({"kind": "chain", "p": m.p, "to": target.p, "life": 0.18})
				game.hit_enemy(target, m.damage, false, "physical", m.get("knockback", 0))
		if m.p.distance_to(destination) > 44:
			var direction: Vector2 = (destination - m.p).normalized()
			for angle in [0.0, 0.8, -0.8, 1.5, -1.5]:
				var step: Vector2 = m.p + direction.rotated(angle) * 195 * delta
				if game.can_move(step): m.p = step; break
		if m.p.distance_to(game.player) > 600: m.p = game.player

func summon(spec: Dictionary) -> void:
	for i in range(2):
		if game.minions.size() >= 4: game.minions.pop_front()
		var p: Vector2 = game.player + Vector2(-28 if i == 0 else 28, 25)
		if not game.can_move(p): p = game.player
		var hp: float = game.rules.stats(game.profile).hp * 0.65
		game.minions.append({"p": p, "hp": hp, "max_hp": hp, "damage": spec.damage, "knockback": spec.get("knockback", 0), "life": 15.0, "cd": 0.1})
		game.effects.append({"kind": "curse", "p": p, "radius": 35, "life": 0.5})
	game.combat_audio.play_effect("curse")

func enemy_focus(e: Dictionary) -> Vector2:
	var focus: Vector2 = game.player
	var distance: float = e.p.distance_to(focus)
	for m in game.minions:
		if m.hp > 0 and m.p.distance_to(e.p) < distance:
			focus = m.p
			distance = m.p.distance_to(e.p)
	return focus

func enemy_strike(e: Dictionary, damage: float) -> void:
	var radius := 115.0 if e.kind == "boss" else 58.0
	if game.player.distance_to(e.target) < radius: game.hurt(damage)
	for m in game.minions:
		if m.p.distance_to(e.target) < radius: m.hp -= damage

func intercept(from: Vector2, to: Vector2, damage: float) -> bool:
	for m in game.minions:
		if m.hp > 0 and Math.segment_hits(from, to, m.p, 18): m.hp -= damage; return true
	return false

func push(enemy: Dictionary, distance: float) -> void:
	var direction: Vector2 = (enemy.p - game.player).normalized()
	# Small steps cannot push targets through rocks, closed gates or shore edges.
	for i in range(int(ceil(distance / 4.0))):
		var p: Vector2 = enemy.p + direction * minf(4.0, distance - i * 4.0)
		if not game.can_move(p): break
		enemy.p = p

func on_kill(enemy: Dictionary, damage_element: String) -> void:
	game.combat_audio.play_effect("death_" + damage_element)
	game.effects.append({"kind": "death", "p": enemy.p + Vector2(0, -32), "element": damage_element, "life": 0.65})
	var affix := str(enemy.get("affix", ""))
	if (not enemy.get("elite",false) and enemy.get("kind","") != "boss") or affix.is_empty() or game.rules.effect_value(game.profile, "headhunter") <= 0: return
	game.stolen_affixes[affix] = 12.0
	game.notify("권능 탈취 12초 · " + affix_name(affix))

func affix_name(id: String) -> String:
	return {"swift": "질주: 이동 +25%", "fury": "격노: 피해 +25%", "titan": "거인: 몸집 +20% · 근접 반경 +20%"}.get(id, id)

func hero_scale() -> float:
	return 1.0 + game.rules.effect_value(game.profile, "giant") + (0.2 if float(game.stolen_affixes.get("titan", 0)) > 0 else 0.0)

func special_attack(enemy: Dictionary) -> void:
	var model: String = enemy.get("model", "satyr")
	var rays := 5 if model in ["gorgon", "hydra", "harpy"] else 8
	var base: float = (enemy.target - enemy.p).angle()
	for i in range(rays):
		var angle := base + (i - 2) * 0.22 if rays == 5 else i * TAU / rays
		game.bolts.append({"p": enemy.p, "v": Vector2.from_angle(angle) * 210, "life": 2.0, "damage": (7 if enemy.get("elite", false) else 11) * game.difficulty().damage, "friendly": false, "attack": -1, "skill_id": "fire_arrow" if model in ["talos", "automaton"] else "bolt"})
