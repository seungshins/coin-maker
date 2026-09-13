extends SceneTree
const Storage = preload("res://src/domain/storage_rules.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; printerr("FAIL: " + message)
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in range(4): await process_frame
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.store.path = "user://test_ui_curses.json"
	game.profile = game.rules.new_profile()
	Storage.ensure(game.profile)
	game.save_blocked = false
	game.show_hub()
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	for screen in [game.show_shop, game.show_skills, game.camp_ui.show_stash, game.show_destinations]:
		screen.call()
		await settle()
		game._input(esc)
		check(game.mode == "town" and game.modal == null, "Escape cancels NPC screen once")
	game.profile.level = 30
	for rarity in range(6):
		for id in game.rules.data.supports: game.rules.award_gem(game.profile, {"id": id, "rarity": rarity})
	game.show_skills()
	game.camp_ui.skill_panel.category = 4
	game.show_skills()
	await settle()
	game.camp_ui.skill_panel.list_scroll.scroll_vertical = 480
	await settle()
	var position: int = game.camp_ui.skill_panel.list_scroll.scroll_vertical
	check(position > 0, "scroll fixture has overflow")
	game.toggle_support(0)
	await settle()
	check(absi(game.camp_ui.skill_panel.list_scroll.scroll_vertical - position) <= 1, "support toggle preserves scroll")
	game.start_run()
	game.enemies.clear()
	game.rocks.clear()
	game.player = game.world.centers[0]
	game.spawn_enemy(game.player + Vector2(100, 0), 0, "satyr", 500, 55)
	var enemy: Dictionary = game.enemies[0]
	enemy.cd = 1.0
	game.profile.selected_curse = "chains"
	game.mana = 80
	game.cast_curse_at(enemy.p)
	check(enemy.chains == 5 and enemy.curse == 0 and game.mana == 64, "chains applies with mana cost")
	game.update_enemies(0.1)
	check(is_equal_approx(enemy.cd, 0.93), "chains slows attack timer by 30 percent")
	check(is_equal_approx(game.enemy_action_rate(enemy), 0.7), "normal action rate")
	enemy.kind = "boss"
	check(is_equal_approx(game.enemy_action_rate(enemy), 0.85), "boss slow limit")
	game.curse_cd = 0
	game.profile.selected_curse = "frailty"
	game.cast_curse_at(enemy.p)
	check(enemy.chains == 0 and enemy.frailty == 6 and is_equal_approx(game.enemy_damage_rate(enemy), 0.85), "curse replacement and boss damage reduction")
	game.mode = "pause"
	check(game.save_now(), "curse snapshot saves")
	game.profile = game.store.load_profile()
	game.start_run()
	check(game.profile.selected_curse == "frailty" and game.enemies[0].frailty == 6, "selected curse and enemy status restore")
	game.queue_free()
	await settle()
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists("user://test_ui_curses.json" + suffix): DirAccess.remove_absolute("user://test_ui_curses.json" + suffix)
	print("PASS: NPC Escape, scroll continuity, curse rates/replacement/save" if failures == 0 else "FAILURES: %d" % failures)
	quit(0 if failures == 0 else 1)
