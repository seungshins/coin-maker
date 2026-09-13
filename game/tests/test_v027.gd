extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; printerr("FAIL: " + message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.profile = game.rules.new_profile()
	game.start_run()
	game.view3d.refresh(0)
	check(game.view3d.actors.hero.has_node("Model"), "directional hero geometry")
	check(is_equal_approx(game.view3d.camera.size,12*game.display_settings.zoom_factor), "wide field camera")
	for enemy in game.enemies:
		check(game.view3d.actors["enemy%d" % enemy.id].has_node("Model"), "enemy model geometry")
	check(game.view3d.health_markers.any(func(m): return m.key.begins_with("boss")), "boss health overlay marker")
	game.enemies[0].hp *= 0.5
	game.view3d.refresh(0)
	var marker: Array = game.view3d.health_markers.filter(func(m): return m.key == "hp%d" % game.enemies[0].id)
	check(marker.size() == 1 and is_equal_approx(marker[0].ratio, 0.5), "health marker follows exact damage ratio")
	var cards := HBoxContainer.new()
	game.ui.add_child(cards)
	var existing := preload("res://src/presentation/character_card.gd").new()
	existing.character_name = "오디세우스"
	cards.add_child(existing)
	var create := preload("res://src/presentation/character_card.gd").new()
	create.create_new = true
	cards.add_child(create)
	await process_frame
	await process_frame
	check(existing.size == create.size and existing.size == Vector2(285,285), "existing/new cards have equal actual dimensions")
	check(existing.get_child(0).get_child(1) is TextureRect, "portrait centered inside existing card")
	check(existing.get_child(0).get_child(1).mouse_filter == Control.MOUSE_FILTER_IGNORE, "portrait does not intercept continue click")
	game.queue_free()
	await process_frame
	print("PASS: v027 reused art, field ratio, HP data and equal portrait cards" if failures == 0 else "FAILURES: %d" % failures)
	quit(0 if failures == 0 else 1)
