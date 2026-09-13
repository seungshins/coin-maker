extends SceneTree
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/workspace/.runtime/todo-" + name + ".png")
func run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.combat_audio.muted = true
	game.profile = game.rules.new_profile()
	preload("res://src/domain/storage_rules.gd").ensure(game.profile)
	game.characters.directory = "user://preview_empty"
	game.characters.legacy = "user://preview_missing.json"
	game.show_title()
	game.notify("이름을 입력하세요.")
	await shot("characters")
	game.profile.level = 30
	game.profile.gold = 2500
	game.profile.character_name = "오디세우스"
	for id in game.rules.data.skills: game.rules.award_primary(game.profile, id, 2)
	for rarity in range(6):
		for id in game.rules.data.supports: game.rules.award_gem(game.profile, {"id": id, "rarity": rarity})
		game.profile.items.append(game.rules.item_roll(game.rng, rarity, 20))
	game.show_hub()
	await shot("town")
	game.profile.items.append({"name": "포세이돈의 창", "slot": 0, "rarity": 4, "value": 42, "unique": true, "effect": "area"})
	game.profile.equipment[0] = game.profile.items.size() - 1
	game.show_inventory()
	await shot("inventory")
	game.show_skills()
	await shot("slots")
	await process_frame
	await process_frame
	game.modal.get_child(0).scroll_vertical = 950
	await shot("gems")
	var probe = preload("res://src/presentation/icon_card.gd").new()
	probe.ink = Color("ffad60")
	var tip = probe._make_custom_tooltip("전설 · 거대화\n근접 및 지면 마법 반경 증가\n범위 반경 +50%\n현재 연결: 일반 · 반경 +15%")
	game.ui.add_child(tip)
	tip.position = Vector2(740, 280)
	await shot("tooltip")
	tip.queue_free()
	probe.free()
	game.shop_tab = 1
	game.show_shop()
	await shot("shop")
	game.start_run()
	game.set_physics_process(false)
	game.combat_audio.muted = true
	game.player = Vector2(810, 950)
	game.camera.position = game.player
	game.camera.reset_smoothing()
	game.profile.skill = "blizzard"
	game.cast_field(game.player + Vector2(100, 0), game.rules.skill_spec(game.profile))
	game.world.queue_redraw()
	await shot("coast")
	game.profile.skill = "slash"
	game.fields.clear()
	game.effects.clear()
	game.aim = Vector2.RIGHT
	game.attack(game.rules.skill_spec(game.profile))
	for effect in game.effects:
		if effect.kind == "slash": effect.life = 0.12
	game.world.queue_redraw()
	await shot("slash")
	game.profile.stage_id = 6
	game.profile.cleared = []
	game.start_run()
	game.set_physics_process(false)
	game.combat_audio.muted = true
	await shot("ithaca")
	quit()
