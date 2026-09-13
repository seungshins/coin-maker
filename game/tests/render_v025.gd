extends SceneTree
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/v025-" + name + ".png")
func run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.combat_audio.muted = true
	game.profile = game.rules.new_profile()
	preload("res://src/domain/storage_rules.gd").ensure(game.profile)
	game.show_hub()
	game.town.position_in_town = game.town.places[0].p + Vector2(0, 70)
	await shot("town")
	game.start_run()
	game.player = game.world.centers[0]
	game.effects.append({"kind": "level_up", "p": game.player, "life": 1.1})
	await shot("coast")
	game.profile.gems.append({"id": "returning", "rarity": 0})
	game.profile.skill = "bow"
	game.profile.skill_supports.bow = [1]
	game.show_hub()
	game.show_skills()
	await shot("links")
	game.queue_free()
	await process_frame
	quit()
