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
	game.store.path = "user://test_v024.json"
	game.save_blocked = false
	game.profile = game.rules.new_profile()
	game.profile.loadout = ["slash", "bow", "aura:might", "curse:chains", "move:blink", "burst:rage"]
	game.profile.buffs = ["might"]
	Storage.ensure(game.profile)
	check(game.profile.loadout[2] == "" and game.profile.buffs == ["might"], "legacy aura binding retired; active buff retained")
	check(game.profile.skill_supports.slash == [0] and game.profile.skill_supports.bow == [0], "legacy support migrated to owned primaries")
	game.profile.skill_supports.slash.clear()
	check(game.profile.skill_supports.bow == [0], "support links independent")
	check(not Storage.transfer(game.profile, true, true, 0).is_empty(), "gem protected by other skill link")
	for pair in [["spell_echo", "thunder", true], ["spell_echo", "summon", false], ["melee_echo", "slash", true], ["melee_echo", "whirl", false], ["power", "curse:chains", false], ["split", "summon", false]]:
		check(game.rules.support_compatible(pair[0], pair[1]) == pair[2], "tag compatibility: " + pair[0] + "/" + pair[1])
	game.profile.skills = game.rules.data.skills.keys()
	Storage.ensure(game.profile)
	game.profile.buffs = []
	game.profile.level = 30
	game.profile.gems = [{"id": "melee_echo", "rarity": 0}, {"id": "spell_echo", "rarity": 0}, {"id": "split", "rarity": 0}]
	game.profile.skill_supports = {"slash": [0], "thunder": [1], "bow": [2]}
	Storage.ensure(game.profile)
	game.start_run()
	game.enemies.clear()
	game.rocks.clear()
	game.player = game.world.centers[0]
	game.aim = Vector2.RIGHT
	game.profile.skill = "slash"
	var spec: Dictionary = game.rules.skill_spec(game.profile)
	game.spawn_enemy(game.player + Vector2(55, 0), 0, "satyr", 1000, 7)
	game.mana = 100
	game.attack(spec)
	game.battle_extras.update(0.23)
	check(is_equal_approx(game.enemies[0].hp, 1000 - spec.damage * 2), "melee echo exactly two reduced hits")
	check(game.mana == 96 and game.pending_repeats.is_empty(), "echo pays once and cannot recurse")
	game.battle_extras.update(0.5)
	check(is_equal_approx(game.enemies[0].hp, 1000 - spec.damage * 2), "no third echo")
	game.profile.skill = "thunder"
	spec = game.rules.skill_spec(game.profile)
	game.attack(spec, false, game.player)
	game.battle_extras.update(0.23)
	check(game.fields.size() == 2 and game.fields[0].p == game.fields[1].p, "spell echo repeats ground target")
	game.fields.clear()
	game.profile.items.append({"name": "히드라", "slot": 0, "rarity": 4, "value": 3, "unique": true, "effect": "double_projectiles"})
	game.profile.equipment[0] = 1
	game.profile.skill = "bow"
	check(game.rules.skill_spec(game.profile).projectiles == 10, "unique doubles base plus support projectiles")
	game.profile.items.append({"name": "프로테우스", "slot": 2, "rarity": 4, "value": 3, "unique": true, "effect": "headhunter"})
	game.profile.equipment[2] = 2
	game.enemies.clear()
	for i in range(3):
		game.spawn_enemy(game.player + Vector2(70, i * 30), 0, "satyr", 1, 30 + i)
		game.enemies[i].elite = true
		game.enemies[i].affix = ["swift", "fury", "titan"][i]
		game.hit_enemy(game.enemies[i], 50, false, ["fire", "ice", "lightning"][i])
	check(game.stolen_affixes.size() == 3, "all three monster affixes can be stolen")
	check(game.effects.filter(func(fx): return fx.kind == "death").size() == 3, "elemental death effects created")
	game.battle_extras.on_kill(game.enemies[0], "physical")
	check(game.stolen_affixes.size() == 3 and game.stolen_affixes.swift == 12, "same affix refreshes without stacking")
	game.profile.skill = "summon"
	spec = game.rules.skill_spec(game.profile)
	game.battle_extras.summon(spec)
	game.battle_extras.summon(spec)
	game.battle_extras.summon(spec)
	check(game.minions.size() == 4, "summon cap four")
	game.enemies.clear()
	game.spawn_enemy(game.player + Vector2(40, 25), 0, "satyr", 500, 77)
	game.battle_extras.update(0.2)
	check(game.enemies[0].hp < 500, "summons independently attack")
	check(game.battle_extras.enemy_focus(game.enemies[0]) != game.player, "enemy targets closer summon")
	game.enemies[0].target = game.minions[0].p
	game.battle_extras.enemy_strike(game.enemies[0], 10)
	check(game.minions[0].hp < game.minions[0].max_hp, "summons take enemy damage")
	game.profile.skill = "slash"
	game.mana = 100
	game.attack(game.rules.skill_spec(game.profile))
	game.mode = "pause"
	check(game.save_now(), "new runtime and links save")
	game.profile = game.store.load_profile()
	game.start_run()
	check(game.minions.size() == 4 and game.stolen_affixes.size() == 3 and game.pending_repeats.size() == 1, "runtime restores minions, stolen affixes and pending repeat")
	check(game.profile.skill_supports.slash.size() == 1 and int(game.profile.skill_supports.slash[0]) == 0 and game.profile.skill_supports.thunder.size() == 1 and int(game.profile.skill_supports.thunder[0]) == 1, "per-skill links persist")
	game.battle_extras.update(16)
	check(game.minions.is_empty() and game.stolen_affixes.is_empty(), "finite durations expire")
	game.profile.skill = "slash"
	game.toggle_support(0)
	check(game.profile.skill_supports.slash.is_empty() and game.profile.skill_supports.thunder.size() == 1, "UI toggle edits selected skill only")
	var bag: Dictionary = game.rules.new_profile()
	bag.gems.append({"id": "area", "rarity": 0})
	Storage.ensure(bag)
	bag.skill_supports = {"slash": [1], "bow": [1]}
	check(Storage.transfer(bag, true, true, 0).is_empty(), "unlinked gem can be stored")
	check(bag.skill_supports.slash == [0] and bag.skill_supports.bow == [0], "stash removal reindexes every skill link")
	game.show_hub()
	game.camp_ui.show_inventory()
	await process_frame
	game.camp_ui.show_skills()
	await process_frame
	game.show_title()
	game.create_character_dialog()
	await process_frame
	game.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists("user://test_v024.json" + suffix): DirAccess.remove_absolute("user://test_v024.json" + suffix)
	print("PASS: v0.2.4 links, echo, uniques, summons, death and save" if failures == 0 else "FAILURES: %d" % failures)
	quit(0 if failures == 0 else 1)
