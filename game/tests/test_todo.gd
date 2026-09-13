extends SceneTree
const Rules = preload("res://src/domain/game_rules.gd")
const Storage = preload("res://src/domain/storage_rules.gd")
const Store = preload("res://src/infrastructure/save_store.gd")
const Characters = preload("res://src/infrastructure/characters.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; printerr("FAIL: " + message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var rules := Rules.new()
	var p := rules.new_profile()
	p.level = 10
	rules.add_xp(p, rules.xp_needed(10))
	check(p.level == 11, "level 10 barrier removed")
	var store := Store.new()
	store.path = "user://test_todo.json"
	check(store.save_profile(p) and store.load_profile().level == 11, "level 11 saves")
	rules.add_xp(p, 100000000)
	check(p.level == 100 and p.xp == 0 and rules.slots(p) == 6, "level cap 100 and final support slots")
	var chars := Characters.new()
	chars.directory = "user://test_todo_characters"
	chars.legacy = "user://test_todo_legacy.json"
	var first := chars.create_character("첫 항해", rules.new_profile())
	var second := chars.create_character("두 번째", rules.new_profile())
	check(not first.is_empty() and first != second and chars.entries().size() == 2, "independent character creation")
	store.path = first
	p = store.load_profile()
	p.gold = 456
	check(store.save_profile(p), "character update")
	store.path = second
	check(store.load_profile().gold == 100, "character saves isolated")
	check(chars.delete_character(first) and chars.entries().size() == 1 and not FileAccess.file_exists(first + ".bak"), "delete includes recovery backup")
	check(chars.delete_character(second), "second test character cleanup")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.store.path = "user://test_todo.json"
	game.profile = rules.new_profile()
	Storage.ensure(game.profile)
	game.save_blocked = false
	game.start_run()
	game.enemies.clear()
	game.mana = 0
	game.attack(rules.skill_spec(game.profile))
	check(game.effects.is_empty(), "empty mana denies attack")
	game.mana_potions = 2
	game.use_mana_potion()
	check(game.mana == 0 and game.mana_potions == 1, "potion starts recovery without burst heal")
	game.update_potions(1.0)
	check(game.mana > 0, "potion recovers gradually")
	game.use_mana_potion()
	check(game.mana_potions == 1, "potion cooldown")
	game.mana = 80
	game.attack(rules.skill_spec(game.profile))
	check(game.mana == 76, "skill mana cost")
	game.profile.skill = "thunder"
	game.spawn_enemy(game.player + Vector2(50, 0), 0, "satyr", 500, 123)
	game.cast_field(game.enemies[0].p, rules.skill_spec(game.profile))
	game.update_fields(0.15)
	check(game.enemies[0].hp == 500, "thunder telegraph delay")
	game.update_fields(0.16)
	check(game.enemies[0].hp < 500 and game.fields.is_empty(), "thunder lands once")
	game.profile.skill = "blizzard"
	game.cast_field(game.enemies[0].p, rules.skill_spec(game.profile))
	game.update_fields(0.1)
	check(game.enemies[0].slow_time > 0, "blizzard applies slow")
	game.mode = "pause"
	check(game.save_now(), "mana and field snapshot save")
	game.profile = game.store.load_profile()
	game.start_run()
	check(game.mana == 76 and game.mana_potions == 1 and game.fields.size() == 1, "snapshot restores mana potion and ground spell")
	game.rocks.append({"p": game.player, "r": 32.0})
	game.mode = "pause"
	check(game.save_now(), "blocked-position save fixture")
	game.profile = game.store.load_profile()
	game.start_run()
	check(game.spawn_clear(game.player), "saved position embedded in rock is recovered")
	for clip in game.combat_audio.clips.values():
		check(clip.data.size() > 1000 and clip.mix_rate == 22050, "synthesized audio has PCM samples")
		var peak := 0
		for sample in range(0, clip.data.size(), 2): peak = maxi(peak, absi(clip.data.decode_s16(sample)))
		check(peak > 100 and peak < 30000, "audio is non-silent and bounded")
	game.profile = rules.new_profile()
	Storage.ensure(game.profile)
	game.profile.skill = "knives"
	game.mana = 80
	game.player = Vector2(450, 1000)
	game.aim = Vector2.RIGHT
	game.enemies.clear()
	game.bolts.clear()
	game.rocks.clear()
	for i in range(3): game.spawn_enemy(game.player + Vector2(50 + i * 60, 0), 0, "satyr", 500, 200 + i)
	game.attack(rules.skill_spec(game.profile))
	for i in range(30): game.update_bolts(1.0 / 60)
	check(game.enemies.all(func(e): return e.hp < 500), "thrown blades pierce three enemies")
	game.profile = rules.new_profile()
	Storage.ensure(game.profile)
	for stage in range(7):
		game.select_stage(stage)
		check(game.profile.stage_id == stage, "campaign stage selectable")
		check_map(game)
		for boss in game.enemies:
			if boss.kind == "boss": check(is_equal_approx(boss.max_hp, 1150 * game.difficulty().hp), "actual boss HP follows difficulty")
		clear_map(game)
		check(game.profile.stage_unlocked == mini(6, stage + 1), "campaign sequential unlock")
	check(game.profile.campaign_complete and game.mode == "complete", "Ithaca ending opens endgame")
	var previous_hp := 0.0
	for tier in range(1, 17):
		game.select_tier(tier)
		check(game.profile.tier == tier and game.difficulty().hp > previous_hp, "tier HP increases")
		previous_hp = game.difficulty().hp
		check_map(game)
		clear_map(game)
		check(game.profile.tier_unlocked == mini(16, tier + 1), "tier unlock persists")
		game.profile.voyages += 1
	game.profile.gold = 10000
	var expected_gold:int=10000-game.rules.gacha_cost(game.profile)
	game.profile.pity[2] = 49
	game.gacha(2)
	check(game.store.load_profile().gold == expected_gold and game.profile.pity[2] == 0, "expanded primary gacha debit saved")
	game.camp_ui.rarity_filter = 2
	check(game.camp_ui.ordered([{"rarity": 0}, {"rarity": 2}, {"rarity": 5}]) == [1], "rarity filter preserves source index")
	for screen in [game.show_inventory, game.show_skills, game.camp_ui.show_stash]: screen.call()
	game.shop_tab = 0
	game.show_shop()
	game.shop_tab = 1
	game.show_shop()
	game.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists("user://test_todo.json" + suffix): DirAccess.remove_absolute("user://test_todo.json" + suffix)
	DirAccess.remove_absolute(chars.directory)
	print("PASS: TODO progression, characters, resources, skills, maps, tiers and UI" if failures == 0 else "FAILURES: %d" % failures)
	quit(0 if failures == 0 else 1)

func clear_map(game) -> void:
	for zone in range(game.zone_count()):
		for enemy in game.enemies:
			if int(enemy.zone) == zone: game.hit_enemy(enemy, 999999, true)
		game.check_zones()

func check_map(game) -> void:
	check(game.spawn_clear(game.player), "entry spawn has eight-direction movement clearance")
	for enemy in game.enemies:
		check(game.world.walkable(enemy.p), "enemy spawns on land")
	# Walk the entire actual route in small steps, including its narrow bends.
	var old: Array = game.profile.cleared.duplicate()
	for zone in range(game.zone_count()):
		game.profile.cleared = range(zone)
		check(game.spawn_clear(game.safe_spawn(zone)), "every checkpoint has a clear spawn")
	game.profile.cleared = range(game.zone_count() - 1)
	for road in game.active_stage().roads:
		for i in range(road.size() - 1):
			var a := Vector2(road[i][0], road[i][1])
			var b := Vector2(road[i + 1][0], road[i + 1][1])
			for step in range(31): check(game.can_move(a.lerp(b, step / 30.0)), "route remains traversable")
	game.profile.cleared = old
