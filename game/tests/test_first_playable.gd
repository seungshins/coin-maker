extends SceneTree
const Rules = preload("res://src/domain/game_rules.gd")
const Store = preload("res://src/infrastructure/save_store.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var rules := Rules.new()
	var p := rules.new_profile()
	var melee := rules.skill_spec(p)
	p.skill = "bolt"
	var ranged := rules.skill_spec(p)
	check(melee.damage / melee.interval > ranged.damage / ranged.interval, "melee sustained base damage exceeds ranged")
	p.skill = "slash"
	rules.add_xp(p, 100)
	check(p.level == 2 and p.xp == 0, "level boundary")
	p.level = 5
	check(rules.slots(p) == 2, "level 5 unlock")
	var store := Store.new()
	store.path = "user://test_first_playable.json"
	check(store.save_profile(p), "first save " + store.error)
	p.gold = 432
	check(store.save_profile(p), "overwrite save " + store.error)
	check(store.load_profile().gold == 432, "round trip")
	var damaged := FileAccess.open(store.path, FileAccess.WRITE)
	damaged.store_string("invalid")
	damaged.close()
	check(store.load_profile().gold == 100, "backup recovery")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.store.path = "user://test_arena.json"
	game.profile = rules.new_profile()
	game.checkpoint = game.profile.duplicate(true)
	game.save_blocked = false
	game.start_run()
	game.set_physics_process(false)
	game.player = Vector2(450, 1000)
	game.aim = Vector2.RIGHT
	game.enemies.clear()
	game.spawn_enemy(Vector2(500, 1000), 0, "satyr", 100, 55)
	game.spawn_enemy(Vector2(520, 1020), 0, "satyr", 100, 56)
	game.spawn_enemy(Vector2(380, 1000), 0, "satyr", 100, 57)
	game.attack(rules.skill_spec(game.profile))
	check(game.enemies[0].hp < 100 and game.enemies[1].hp < 100, "melee cleaves multiple targets")
	check(game.enemies[2].hp == 100, "melee respects rear arc")
	check(game.enemies[0].stagger > 0, "melee staggers normal enemies")
	game.health = 100
	game.hurt(10)
	check(is_equal_approx(game.health, 93), "melee guard reduces incoming damage")
	game.profile.gold = 1000
	game.profile.pity[0] = 49
	game.gacha(0)
	check(game.profile.gold == 950 and game.profile.items[-1].rarity == 1, "gacha charge and pity")
	var reloaded: Dictionary = game.store.load_profile()
	check(reloaded.gold == 950 and JSON.stringify(reloaded.items) == JSON.stringify(JSON.parse_string(JSON.stringify(game.profile.items))), "gacha equipment persists")
	game.profile.pity[1] = 49
	game.gacha(1)
	reloaded = game.store.load_profile()
	check(reloaded.gold == 900 and JSON.stringify(reloaded.gems) == JSON.stringify(JSON.parse_string(JSON.stringify(game.profile.gems))) and reloaded.shards == game.profile.shards, "gem reward or duplicate compensation persists")
	var before_failure: Dictionary = game.profile.duplicate(true)
	var rng_before: int = game.rng.state
	game.store.path = "user://missing_parent_for_test/save.json"
	game.gacha(0)
	check(game.profile == before_failure and game.rng.state == rng_before, "failed save rolls back gacha payment reward and RNG")
	game.store.path = "user://test_arena.json"
	var melee_time := kill_time(game, "slash")
	var ranged_time := kill_time(game, "bolt")
	check(melee_time > 0 and melee_time < ranged_time, "melee kills stationary boss faster at equal gear")
	print("Stationary boss kill time: melee %.2fs / lightning %.2fs (includes projectile travel; no enemy attacks)" % [melee_time, ranged_time])
	game.profile = rules.new_profile()
	game.start_run()
	game.set_physics_process(false)
	for zone in range(3):
		for e in game.enemies:
			if e.zone == zone: game.hit_enemy(e, 9999, true)
		game.check_zones()
	check(game.profile.cleared.size() == 3 and game.mode == "complete", "three zones and boss completion")
	check(game.store.load_profile().cleared.size() == 3, "boss checkpoint saved")
	var victory_gold: int = game.profile.gold
	game.profile = game.store.load_profile()
	game.start_run()
	check(game.profile.cleared.is_empty() and game.profile.voyages == 1 and game.enemies.size() > 0, "victory save resumes as new voyage")
	check(game.profile.gold == victory_gold, "resume does not duplicate boss gold")
	game.profile.items.resize(100)
	game.drops.append({"p": Vector2.ZERO, "kind": "item", "rarity": 0, "value": rules.item_roll(game.rng, 0, 1)})
	game.pickup(0)
	check(game.profile.items.size() == 101 and game.drops.is_empty(), "full inventory preserves field reward")
	print("Melee DPS ", melee.damage / melee.interval, " / ranged DPS ", ranged.damage / ranged.interval)
	game.queue_free()
	await process_frame
	for file in ["test_first_playable.json", "test_arena.json"]:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists("user://" + file + suffix): DirAccess.remove_absolute("user://" + file + suffix)
	print("PASS: first playable integration" if failures == 0 else "FAILURES: " + str(failures))
	quit(0 if failures == 0 else 1)

func kill_time(game, skill: String) -> float:
	game.profile = Rules.new().new_profile()
	game.profile.skill = skill
	game.player = Vector2(470, 1000)
	game.aim = Vector2.RIGHT
	game.enemies.clear()
	game.bolts.clear()
	game.rocks.clear()
	game.effects.clear()
	game.spawn_enemy(game.player + Vector2(90 if skill == "slash" else 360, 0), 0, "boss", 1150, 999)
	var spec: Dictionary = game.rules.skill_spec(game.profile)
	game.mana = game.rules.stats(game.profile).mana
	var elapsed := 0.0
	var next_attack := 0.0
	while not game.enemies[0].dead and elapsed < 60:
		if elapsed >= next_attack:
			game.attack(spec)
			next_attack = elapsed + spec.interval
		game.mana = minf(game.rules.stats(game.profile).mana, game.mana + game.rules.stats(game.profile).mana_regen / 60.0)
		game.update_bolts(1.0 / 60.0)
		elapsed += 1.0 / 60.0
	return elapsed
