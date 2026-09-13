extends SceneTree
const Storage = preload("res://src/domain/storage_rules.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; printerr("FAIL: " + message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.store.path = "user://test_v025.json"
	game.profile = game.rules.new_profile()
	game.save_blocked = false
	Storage.ensure(game.profile)
	game.start_run()
	game.enemies.clear()
	game.player = game.world.centers[0]
	game.profile.loadout = ["slash", "bow", "", "", "", ""]
	game.mana = 100
	check(game.actions.use_slot(0), "left skill fires")
	game.profile.items[0].weapon_type="bow";game.profile.primary_weapon="bow"
	check(game.cooldown > 0 and game.actions.use_slot(1), "right skill fires during left cooldown")
	check(not game.actions.use_slot(0) and not game.actions.use_slot(1), "individual cooldowns still enforced")
	check(game.mana == 92 and game.bolts.size() == 3, "simultaneous skills pay both costs")
	game.profile.gems.append({"id": "returning", "rarity": 0})
	game.profile.skill_supports.bow = [1]
	game.profile.skill = "bow"
	game.camp_ui.rarity_filter = 4
	check(1 in game.camp_ui.ordered_gems(game.profile.gems), "return gem visible despite legendary primary filter")
	game.clear_support_link(0)
	check(game.profile.skill_supports.bow.is_empty() and game.profile.gems.size() == 2 and game.profile.skill_supports.slash.size() == 1, "explicit clear removes only link and keeps owned gem")
	check(game.store.load_profile().skill_supports.bow.is_empty(), "clear persists")
	game.start_run()
	game.enemies.clear()
	game.profile.xp = 99
	game.spawn_enemy(game.player + Vector2(50, 0), 0, "satyr", 1, 17)
	game.hit_enemy(game.enemies[0], 100, false)
	check(game.profile.level == 2 and game.effects.any(func(fx): return fx.kind == "level_up"), "level up creates visible effect")
	check(game.combat_audio.clips.has("level_up"), "level up has sound")
	game.view3d.refresh(0)
	check(game.view3d.active() and game.world.modulate.a == 0, "act1 uses true3D presentation")
	for target in [game.player, game.player + Vector2(100, 80), game.player - Vector2(90, 60)]:
		var screen: Vector2 = game.view3d.camera.unproject_position(game.view3d.point(target))
		check(game.view3d.screen_to_world(screen).distance_to(target) < 0.1, "3D cursor ray maps to gameplay plane")
	game.profile.stage_id = 1
	game.start_run()
	game.view3d.refresh(0)
	check(game.view3d.active() and game.world.modulate.a == 0, "later acts use expanded 3D presentation")
	game.show_hub()
	game.view3d.refresh(0)
	check(game.view3d.active(), "town switches to3D")
	game.town.position_in_town = game.town.places[0].p
	game.town.interact()
	check(game.mode == "hub", "3D town NPC opens existing shop")
	game.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists("user://test_v025.json" + suffix): DirAccess.remove_absolute("user://test_v025.json" + suffix)
	print("PASS: v025 concurrent skills, gem clear/filter, level FX and 3D mapping" if failures == 0 else "FAILURES: %d" % failures)
	quit(0 if failures == 0 else 1)
