extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.profile = game.rules.new_profile()
	preload("res://src/domain/storage_rules.gd").ensure(game.profile)
	game.profile.gems.append({"id": "power", "rarity": 2})
	game.profile.gems.append({"id": "split", "rarity": 1})
	game.profile.skills.append("bow")
	game.show_hub()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/town.png")
	game.show_inventory()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/inventory.png")
	game.show_skills()
	await process_frame
	await RenderingServer.frame_post_draw
	var scroll = game.modal.get_child(0)
	scroll.scroll_vertical = 900
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/gems.png")
	quit()
