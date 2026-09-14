extends RefCounted
const Math = preload("res://src/domain/combat_math.gd")
var minion_combat
var game
func _init(owner_game) -> void:
	game = owner_game
	minion_combat=preload("res://src/application/minion_combat.gd").new(game)

func element(id: String) -> String:
	if id=="venom":return "poison"
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
	for id in game.proc_cooldowns:game.proc_cooldowns[id]=maxf(0,game.proc_cooldowns[id]-delta)
	minion_combat.update(delta)

func summon(spec:Dictionary)->void:minion_combat.summon(spec)

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
		if m.p.distance_to(e.target) < radius: minion_combat.receive_damage(m,damage)

func intercept(from: Vector2, to: Vector2, damage: float) -> bool:
	for m in game.minions:
		if m.hp > 0 and Math.segment_hits(from, to, m.p, 18): minion_combat.receive_damage(m,damage); return true
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
