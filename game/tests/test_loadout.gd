extends SceneTree
const Storage = preload("res://src/domain/storage_rules.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; printerr("FAIL: " + message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.store.path = "user://test_loadout.json"
	game.profile = game.rules.new_profile()
	Storage.ensure(game.profile)
	check(game.profile.loadout.size() == 6, "legacy profile gets six bindings")
	game.profile.skills = game.rules.data.skills.keys()
	Storage.ensure(game.profile)
	game.save_blocked = false
	game.profile.items[0].weapon_type="bow"
	check(game.actions.assign(0, "ice_arrow"), "assign owned primary")
	check(not game.actions.assign(2, "invalid"), "unknown skill denied")
	check(game.actions.assign(1, "ice_arrow") and game.profile.loadout[0] != "ice_arrow", "duplicate binding swaps instead of copies")
	check(game.actions.assign(1, "") and game.profile.loadout[1] == "", "clear slot stays empty")
	for entry in [[0, "bow"], [1, "fire_arrow"], [2, "burst:rage"], [3, "curse:chains"], [4, "move:blink"], [5, "burst:volley"]]: game.actions.assign(entry[0], entry[1])
	check(game.store.load_profile().loadout == game.profile.loadout, "six bindings persist")
	game.start_run()
	game.enemies.clear()
	game.rocks.clear()
	game.player = game.world.centers[0]
	game.aim = Vector2.RIGHT
	check(not game.actions.assign(2, "aura:might"), "maintained aura cannot occupy key slot")
	check(game.rules.toggle_buff(game.profile, "might").is_empty() and "might" in game.profile.buffs, "equipment aura toggles on")
	game.ability_cooldowns.clear()
	check(game.rules.toggle_buff(game.profile, "might").is_empty() and "might" not in game.profile.buffs, "equipment aura toggles off")
	check(game.actions.use_slot(5) and game.burst_timers["burst:volley"] == 4, "instant volley buff")
	check(not game.actions.use_slot(5), "burst cannot bypass cooldown")
	game.cooldown = 0
	check(game.actions.use_slot(0) and game.bolts.size() == 5, "bow base three plus low-level burst two")
	game.profile.skill = "bow"
	game.profile.gems = [{"id": "split", "rarity": 4}, {"id": "returning", "rarity": 2}]
	game.profile.level = 65
	game.profile.skill_supports.bow = [0, 1]
	Storage.ensure(game.profile)
	var spec: Dictionary = game.rules.skill_spec(game.profile)
	check(spec.projectiles == 11 and is_equal_approx(spec.return_multiplier, 0.58), "legendary split and returning combine")
	game.bolts.clear()
	game.effects.clear()
	game.spawn_enemy(game.player + Vector2(120, 0), 0, "satyr", 500, 55)
	spec.projectiles = 1
	spec.damage = 50.0
	game.mana = 100
	game.attack(spec)
	for frame in range(180): game.update_bolts(1.0 / 60.0)
	check(is_equal_approx(game.enemies[0].hp, 421), "return leg deals exactly one reduced second hit")
	game.fields.clear()
	game.elemental_hit({"skill_id": "ice_arrow", "damage": 50, "attack": 200}, game.enemies[0])
	game.update_fields(0.01)
	check(game.fields[0].kind == "ice_zone" and game.enemies[0].slow_time > 0, "ice arrow creates damaging slowing ground")
	for i in range(3): game.spawn_enemy(game.player + Vector2(210 + i * 85, 0), 0, "satyr", 500, 60 + i)
	game.elemental_hit({"skill_id": "lightning_arrow", "damage": 50, "attack": 201}, game.enemies[0])
	check(game.enemies.slice(1).all(func(e): return e.hp < e.max_hp), "lightning chains to three distinct enemies")
	var old: Vector2 = game.player
	check(game.actions.move_to("move:blink", old + Vector2(120, 0)) and game.can_move(game.player), "blink lands on valid terrain")
	game.mode = "pause"
	check(game.save_now(), "runtime skill state saves")
	game.profile = game.store.load_profile()
	game.start_run()
	check(game.burst_timers["burst:volley"] == 4 and game.ability_cooldowns["burst:volley"] > 0, "buff duration and cooldown restored")
	check(game.stages.any(func(stage): return stage.centers.size() == 6), "six-room dungeon exists")
	check(game.stages.any(func(stage): return stage.connections.size() >= stage.centers.size()), "loop route exists")
	game.mode = "pause"
	game.save_now()
	game.profile = game.store.load_profile()
	var gold: int = game.profile.gold
	game.profile.stage_id = 1
	game.profile.run_state.layout_revision = -1
	game.start_run()
	check(game.zone_count() == 4 and game.enemies.any(func(e): return e.kind == "boss" and e.zone == 3), "old snapshot rebuilds changed dungeon boss roster")
	check(game.profile.gold == gold, "layout migration preserves earned rewards")
	game.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists("user://test_loadout.json" + suffix): DirAccess.remove_absolute("user://test_loadout.json" + suffix)
	print("PASS: six slots, buffs, return/elemental arrows, movement and save" if failures == 0 else "FAILURES: %d" % failures)
	quit(0 if failures == 0 else 1)
