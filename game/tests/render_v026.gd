extends SceneTree
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/v026-" + name + ".png")
func run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.combat_audio.muted = true
	game.profile = game.rules.new_profile()
	game.profile.level = 30
	for id in game.rules.data.skills: game.rules.award_primary(game.profile, id, 2)
	for rarity in range(6):
		for id in game.rules.data.supports: game.rules.award_gem(game.profile, {"id": id, "rarity": rarity})
	game.show_hub()
	await shot("town")
	game.show_skills()
	game.camp_ui.skill_panel.select_slot(1)
	await shot("supports")
	game.camp_ui.skill_panel.category = 0
	game.show_skills()
	await shot("skills")
	for index in [0, 2, 3, 6, 8]:
		game.profile.stage_id = mini(index, 6)
		game.profile.tier = 8 if index == 8 else 0
		game.profile.map_index = index
		game.profile.cleared = []
		game.start_run()
		await shot("map%d" % index)
	game.queue_free()
	await process_frame
	quit()
