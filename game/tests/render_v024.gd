extends SceneTree
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/v024-" + name + ".png")
func run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.combat_audio.muted = true
	game.characters.directory = "user://preview_v024"
	game.characters.legacy = "user://preview_v024_missing.json"
	var paths: Array = []
	for name in ["오디세우스", "페넬로페"]: paths.append(game.characters.create_character(name, game.rules.new_profile()))
	game.show_title()
	await shot("characters")
	game.create_character_dialog()
	var dialog: ConfirmationDialog = game.ui.get_child(game.ui.get_child_count() - 1)
	dialog.confirmed.emit()
	await shot("name")
	dialog.queue_free()
	game.profile = game.rules.new_profile()
	game.profile.level = 30
	game.profile.buffs = ["might", "ward"]
	game.profile.loadout = ["whirl", "summon", "curse:chains", "move:blink", "burst:rage", "thunder"]
	for id in game.rules.data.skills: game.rules.award_primary(game.profile, id, 2)
	game.show_hub()
	game.show_inventory()
	await shot("equipment")
	game.show_skills()
	await shot("skills")
	game.start_run()
	game.player = game.world.centers[0]
	game.camera.position = game.player
	game.camera.reset_smoothing()
	game.profile.skill = "summon"
	game.battle_extras.summon(game.rules.skill_spec(game.profile))
	game.channeling = true
	game.clock = 0.5
	game.stolen_affixes = {"titan": 8.0}
	for i in range(4): game.effects.append({"kind": "death", "p": game.player + Vector2(110 + (i % 2) * 105, -60 + (i / 2) * 115), "element": ["fire", "ice", "lightning", "physical"][i], "life": 0.35})
	game.world.queue_redraw()
	await shot("battle")
	for path in paths: game.characters.delete_character(path)
	game.queue_free()
	await process_frame
	quit()
