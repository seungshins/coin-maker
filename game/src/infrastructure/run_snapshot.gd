extends RefCounted
const FIELDS = ["petrify_time","proc_cooldowns","chests","player", "aim", "health", "enemies", "bolts", "effects", "drops", "rocks", "clock", "cooldown", "guard", "attack_flash", "hurt_time", "dodge", "dodge_cd", "dodge_dir", "potions", "potion_cd", "attack_id", "curse_cd", "mana", "mana_potions", "mana_potion_cd", "fields", "ability_cooldowns", "cooldown_totals", "burst_timers", "pending_repeats", "minions", "stolen_affixes", "ambience", "potion_progress", "mana_potion_progress", "hp_recovery", "mp_recovery", "hp_recovery_rate", "mp_recovery_rate"]

static func encode(value: Variant) -> Variant:
	if value is Vector2: return {"vector2": [value.x, value.y]}
	if value is Array:
		var output: Array = []
		for item in value: output.append(encode(item))
		return output
	if value is Dictionary:
		var output := {}
		for key in value: output[key] = encode(value[key])
		return output
	return value

static func decode(value: Variant) -> Variant:
	if value is Dictionary:
		if value.has("vector2") and value.size() == 1: return Vector2(value.vector2[0], value.vector2[1])
		var output := {}
		for key in value: output[key] = decode(value[key])
		return output
	if value is Array:
		var output: Array = []
		for item in value: output.append(decode(item))
		return output
	return value

static func capture(game) -> Dictionary:
	var snapshot := {"version": 1, "layout_revision": game.active_stage().get("layout_revision", 0), "checkpoint": game.checkpoint.duplicate(true)}
	snapshot.checkpoint.erase("run_state")
	for key in FIELDS: snapshot[key] = encode(game.get(key))
	return snapshot

static func restore(game, snapshot: Dictionary) -> void:
	for key in FIELDS:
		if not snapshot.has(key): continue
		var value: Variant = decode(snapshot[key])
		if game.get(key) is Array:
			game.get(key).clear()
			game.get(key).assign(value)
		else: game.set(key, value)
	game.checkpoint = snapshot.checkpoint.duplicate(true)
