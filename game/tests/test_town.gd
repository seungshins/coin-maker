extends SceneTree
const Rules = preload("res://src/domain/game_rules.gd")
const Storage = preload("res://src/domain/storage_rules.gd")
const Store = preload("res://src/infrastructure/save_store.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; printerr("FAIL: " + message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var rules := Rules.new()
	var p := rules.new_profile()
	Storage.ensure(p)
	check(p.stash_items.is_empty() and p.pity.size() == 3, "old save defaults")
	check(not Storage.transfer(p, false, true, 0).is_empty(), "equipped item cannot be stored")
	p.items.append(p.items[0].duplicate(true))
	p.equipment[0] = 1
	check(Storage.transfer(p, false, true, 0).is_empty() and p.equipment[0] == 0, "item transfer reindexes equipped slot")
	check(Storage.transfer(p, false, false, 0).is_empty() and p.items.size() == 2, "withdraw preserves item")
	p.gems.append({"id": "area", "rarity": 2})
	p.skill_supports = {"slash": [1], "bow": []}
	p.supports = p.skill_supports.slash
	check(Storage.transfer(p, true, true, 0).is_empty() and p.supports == [0], "gem transfer reindexes active support")
	check(Storage.transfer(p, true, false, 0).is_empty(), "gem withdraw")
	check(rules.toggle_buff(p, "might").is_empty(), "enable first buff")
	check(rules.toggle_buff(p, "ward").is_empty(), "enable second buff")
	check(not rules.toggle_buff(p, "wind").is_empty() and p.buffs.size() == 2, "third buff denied")
	rules.award_primary(p, "bow", 3)
	check(p.skill_rarities.bow == 3 and "bow" in p.skills, "rare primary grant")
	var shards_before: int = p.shards
	rules.award_primary(p, "bow", 1)
	check(p.skill_rarities.bow == 3 and p.shards == shards_before and 1 in p.skill_versions.bow, "lower rarity primary cannot downgrade")
	check(rules.support_numbers({"id": "power", "rarity": 2}).contains("1.30"), "support exposes numeric multiplier")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.store.path = "user://test_town_session.json"
	game.profile = p
	game.save_blocked = false
	game.show_hub()
	check(game.mode == "town" and game.town.visible and not game.world.visible, "walkable town entry")
	game.town.position_in_town = game.town.places[2].p
	check(game.town.nearby() == 2, "stash proximity interaction")
	game.town.interact()
	check(game.mode == "hub", "stash opens UI")
	game.profile.gold = 1000
	game.profile.pity[2] = 49
	game.gacha(2)
	var saved: Dictionary = game.store.load_profile()
	check(saved.gold == 950 and saved.pity[2] == 0 and saved.skill_rarities.size() >= 2, "primary gacha payment pity persistence")
	game.profile.skill = "bow"
	game.start_run()
	game.set_physics_process(false)
	game.attack(rules.skill_spec(game.profile))
	check(game.bolts[-1].arrow and game.bolts[-1].v.length() > 800, "bow arrow projectile")
	game.player = game.enemies[0].p - Vector2(50, 0)
	game.cast_curse_at(game.enemies[0].p)
	check(game.enemies[0].curse > 0 and game.curse_cd == 7, "targeted curse duration and cooldown")
	var hp_before: float = game.enemies[0].hp
	game.hit_enemy(game.enemies[0], 10, false)
	check(is_equal_approx(hp_before - game.enemies[0].hp, 12), "curse increases received damage")
	var saved_position: Vector2 = game.player
	game.health = 63
	game.profile.gold = 923
	game.mode = "pause"
	var enemy_hp: float = game.enemies[1].hp
	check(game.save_now(), "mid combat save")
	saved = game.store.load_profile()
	check(saved.has("run_state") and saved.gold == 923 and saved.buffs.size() == 2, "save contains combat and buffs")
	game.profile = saved
	game.player = Vector2.ZERO
	game.enemies.clear()
	game.start_run()
	game.set_physics_process(false)
	check(game.player == saved_position and game.health == 63 and game.enemies[1].hp == enemy_hp, "exact position health enemies restored")
	check(game.curse_cd == 7 and game.bolts.size() > 0, "curse and projectiles restored")
	check(game.profile.stash_items is Array and game.profile.stash_gems is Array, "storage survives reload")
	var unique_profile := rules.new_profile()
	unique_profile.items = [
		{"slot": 0, "rarity": 3, "unique": true, "value": 5, "name": "아레스의 유산"},
		{"slot": 1, "rarity": 4, "unique": true, "value": 20, "name": "아킬레우스의 갑주"},
		{"slot": 2, "rarity": 4, "unique": true, "value": 5, "name": "헤르메스의 날개"}]
	unique_profile.equipment = [0, 1, 2]
	check(rules.unique_value(unique_profile, 0) == 3 and is_equal_approx(rules.dodge_interval(unique_profile), 1.2), "weapon recovery and relic dodge values")
	game.profile = unique_profile
	game.health = 100
	game.hurt_time = 0
	game.guard = 0
	game.dodge = 0
	game.hurt(10)
	check(is_equal_approx(game.health, 91), "unique armor reduces actual damage")
	game.profile = rules.new_profile()
	Storage.ensure(game.profile)
	game.select_stage(1)
	check(game.profile.stage_id == 0, "locked destination denied")
	for stage_id in range(3):
		game.select_stage(stage_id)
		game.set_physics_process(false)
		check(game.profile.stage_id == stage_id and game.world.centers[1].y == game.stages[stage_id].centers[1][1], "selected map layout applied")
		for zone in range(game.zone_count()):
			for enemy in game.enemies:
				if int(enemy.zone) == zone: game.hit_enemy(enemy, 99999, true)
			game.check_zones()
		check(game.mode == "complete" and game.store.load_profile().stage_unlocked == mini(6, stage_id + 1), "stage completion unlock persists")
	game.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists("user://test_town_session.json" + suffix): DirAccess.remove_absolute("user://test_town_session.json" + suffix)
	print("PASS: town, storage, buffs, curse, primary gacha, bow and combat resume" if failures == 0 else "FAILURES: %d" % failures)
	quit(0 if failures == 0 else 1)
