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
	game.store.path = "user://test_v026.json"
	game.profile = game.rules.new_profile()
	game.save_blocked = false
	Storage.ensure(game.profile)
	game.profile.gems.append({"id": "returning", "rarity": 0})
	game.profile.skill_supports.bow = [1]
	game.show_hub()
	game.show_skills()
	game.camp_ui.skill_panel.select_slot(1)
	check(game.profile.skill == "bow" and game.profile.supports == [1], "selected bound bow drives support target")
	check(game.camp_ui.skill_panel.category == 4, "selecting primary opens support inventory")
	game.toggle_support(1)
	check(game.profile.skill_supports.bow.is_empty() and game.profile.skill_supports.slash == [0], "right gem click edits only selected bound skill")
	game.camp_ui.skill_panel.select_slot(0)
	check(game.profile.skill == "slash" and game.profile.supports == [0], "switching bound key restores its links")
	game.camp_ui.skill_panel.select_slot(3)
	check(game.camp_ui.skill_panel.category == 0, "non-primary slot opens skill assignment")
	check(game.rules.stats(game.rules.new_profile()).move == 290, "baseline speed increased")
	for map in range(game.stages.size()):
		game.profile.stage_id = mini(map, 6)
		game.profile.tier = 1 if map >= 7 else 0
		game.profile.map_index = map
		game.profile.cleared = []
		game.start_run()
		game.view3d.refresh(0)
		check(game.view3d.active() and game.view3d.layout == game.active_stage().name, "map layout cache updates: " + game.stages[map].name)
		check(game.view3d.terrain.get_child_count() > 10, "3D geometry generated")
		var pixel: Vector2 = game.view3d.camera.unproject_position(game.view3d.point(game.player))
		check(game.view3d.screen_to_world(pixel).distance_to(game.player) < 0.1, "all-map aiming projection")
		await process_frame
	for tier in range(1, 17):
		game.profile.tier = tier
		game.view3d.refresh(0)
		check(game.view3d.active(), "3D enabled in tier %d" % tier)
	game.mode = "pause"
	check(game.save_now(), "3D endgame saves")
	game.profile = game.store.load_profile()
	game.start_run()
	game.view3d.refresh(0)
	check(int(game.profile.tier) == 16 and game.view3d.active(), "3D endgame restore")
	game.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists("user://test_v026.json" + suffix): DirAccess.remove_absolute("user://test_v026.json" + suffix)
	print("PASS: v026 selected-slot links, speed, nine3D maps and tiers" if failures == 0 else "FAILURES: %d" % failures)
	quit(0 if failures == 0 else 1)
