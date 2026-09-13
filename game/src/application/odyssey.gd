extends Node2D
const Rules = preload("res://src/domain/game_rules.gd")
const Store = preload("res://src/infrastructure/save_store.gd")
const Coast = preload("res://src/presentation/coast.gd")
const Math = preload("res://src/domain/combat_math.gd")
const Town = preload("res://src/presentation/town.gd")
const CampUI = preload("res://src/presentation/camp_ui.gd")
const Storage = preload("res://src/domain/storage_rules.gd")
const Snapshot = preload("res://src/infrastructure/run_snapshot.gd")
const Characters = preload("res://src/infrastructure/characters.gd")
var characters := Characters.new()
var character_selected := false
var mana := 80.0
var mana_potions := 2
var mana_potion_cd := 0.0
var fields: Array[Dictionary] = []
var view3d
var channeling := false
var pending_repeats: Array[Dictionary] = []
var minions: Array[Dictionary] = []
var stolen_affixes := {}
var battle_extras = preload("res://src/application/battle_extras.gd").new(self)
var actions
var petrify_time:=0.0
var boss_combat=preload("res://src/application/boss_combat.gd").new(self)
var proc_cooldowns:Dictionary={}
var combat_procs=preload("res://src/application/combat_procs.gd").new(self)
var visual_weapon:=""
var cooldown_totals:Dictionary={}
var ability_cooldowns := {}
var burst_timers := {}
var shop_tab := -1
var combat_audio: Node
var shake := 0.0
var shake_enabled := true
var curse_cd := 0.0
var town
var camp_ui
var rules := Rules.new()
var stages: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/stages.json"))
var store := Store.new()
var profile: Dictionary
var checkpoint: Dictionary
var rng := RandomNumberGenerator.new()
var world: Node2D
var camera: Camera2D
var ui: Control
var hud: Label
var toast: Label
var modal: PanelContainer
var mode := "title"
var player := Vector2(400, 1030)
var aim := Vector2.RIGHT
var moving := false
var health := 100.0
var enemies: Array[Dictionary] = []
var bolts: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var drops: Array[Dictionary] = []
var rocks: Array[Dictionary] = []
var clock := 0.0
var cooldown := 0.0
var guard := 0.0
var attack_flash := 0.0
var hurt_time := 0.0
var dodge := 0.0
var dodge_cd := 0.0
var dodge_dir := Vector2.RIGHT
var potions := 2
var potion_cd := 0.0
var attack_id := 0
var toast_time := 0.0
var intro_page := 0
var action_lock := false
var save_blocked := false

var controls
var chests:Array[Dictionary]=[]
var chest_events=preload("res://src/application/chests.gd").new(self)
var display_settings

func _ready() -> void:
	controls=preload("res://src/presentation/controls.gd").new(self)
	display_settings=preload("res://src/presentation/display_settings.gd").new(self)

	actions = preload("res://src/application/skill_actions.gd").new(self)
	combat_audio = preload("res://src/presentation/combat_audio.gd").new()
	add_child(combat_audio)
	rng.randomize()
	profile = store.load_profile()
	save_blocked = profile.is_empty() and not store.error.is_empty()
	if profile.is_empty(): profile = rules.new_profile()
	if not str(profile.get("rng_state", "")).is_empty(): rng.state = int(profile.rng_state)
	Storage.ensure(profile)
	checkpoint = profile.duplicate(true)
	world = Coast.new()
	world.game = self
	add_child(world)
	camera = Camera2D.new()
	camera.position = player
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7
	add_child(camera)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Malgun Gothic", "Apple SD Gothic Neo", "Noto Sans CJK KR", "Noto Sans CJK KR"])
	theme.default_font = font
	theme.default_font_size = 18
	ui.theme = theme
	canvas.add_child(ui)
	hud = Label.new()
	hud.position = Vector2(24, 16)
	hud.add_theme_color_override("font_color", Color("ffeac5"))
	ui.add_child(hud)
	toast = Label.new()
	toast.position = Vector2(24, 52)
	toast.size = Vector2(1232, 26)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.add_theme_color_override("font_outline_color", Color("081b22"))
	toast.add_theme_constant_override("outline_size", 6)
	toast.add_theme_font_size_override("font_size", 17)
	toast.add_theme_color_override("font_color", Color("f6d588"))
	ui.add_child(toast)
	town = Town.new()
	town.game = self
	town.visible = false
	add_child(town)
	camp_ui = CampUI.new()
	add_child(camp_ui)
	camp_ui.setup(self)
	get_tree().auto_accept_quit = false
	view3d = preload("res://src/presentation/quarter_view.gd").new()
	view3d.game = self
	add_child(view3d)
	show_title()
	display_settings.call_deferred("restore")

func rarity_color(r: int) -> Color:
	return [Color("dfd8c7"), Color("78b6ff"), Color("f3d770"), Color("c697ff"), Color("ffad60"), Color("ff6767")][clampi(r, 0, 5)]

func notify(text: String) -> void:
	toast.text = text
	toast.move_to_front()
	toast_time = 4.0

func clear_modal() -> void:
	if is_instance_valid(modal):
		modal.hide()
		modal.queue_free()
		modal = null

func panel(title: String, subtitle: String = "") -> VBoxContainer:
	clear_modal()
	modal = PanelContainer.new()
	modal.position = Vector2(150, 65)
	modal.size = Vector2(980, 590)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.052, 0.06, 1.0)
	style.border_color = Color("ac8b51")
	style.set_border_width_all(2)
	style.set_content_margin_all(24)
	modal.add_theme_stylebox_override("panel", style)
	ui.add_child(modal)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(926, 535)
	modal.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 32)
	heading.add_theme_color_override("font_color", Color("efd095"))
	box.add_child(heading)
	if not subtitle.is_empty(): text_line(box, subtitle)
	return box

func text_line(box: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 870
	box.add_child(label)

func button(box: Container, text: String, callback: Callable, disabled: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.icon=preload("res://src/presentation/ui_symbols.gd").for_text(text)
	b.add_theme_constant_override("icon_max_width",22)
	b.custom_minimum_size.y = 40
	b.disabled = disabled
	b.pressed.connect(callback)
	box.add_child(b)
	return b

func commit(candidate: Dictionary) -> bool:
	if save_blocked:
		notify("손상된 저장 원본을 먼저 확인해 주세요. 덮어쓰지 않습니다.")
		return false
	candidate.rng_state = str(rng.state)
	if not store.save_profile(candidate):
		notify(store.error)
		return false
	profile = candidate
	checkpoint = profile.duplicate(true)
	return true

func show_title() -> void:
	town.visible = false
	mode = "title"
	world.visible = false
	character_selected = false
	var box := panel("ODYSSEY · 귀향의 맹세", "캐릭터를 선택하거나 새로운 항해를 시작하세요. 캐릭터별 장비·골드·진행은 따로 저장됩니다.")
	var cards: GridContainer = camp_ui.grid(box, 3)
	for entry in characters.entries():
		var path: String = entry.path
		var column := VBoxContainer.new()
		cards.add_child(column)
		var card := preload("res://src/presentation/character_card.gd").new()
		card.character_name = entry.name
		card.character_level = int(entry.level)
		card.valid_save = entry.valid
		card.disabled = not entry.valid
		card.add_theme_stylebox_override("normal", camp_ui.style(Color("1c3439"), Color("e3c48d")))
		card.pressed.connect(func(): select_character(path))
		column.add_child(card)
		var remove := MenuButton.new()
		remove.text = "캐릭터 관리 ···"
		remove.custom_minimum_size.y = 26
		remove.add_theme_font_size_override("font_size", 13)
		remove.get_popup().add_item("캐릭터 삭제", 0)
		remove.get_popup().id_pressed.connect(func(_id): confirm_delete_character(path))
		column.add_child(remove)
	var create_column := VBoxContainer.new()
	cards.add_child(create_column)
	var create := preload("res://src/presentation/character_card.gd").new()
	create.create_new = true
	create.add_theme_stylebox_override("normal", camp_ui.style(Color("1c3439"), Color("a1c4cd")))
	create.pressed.connect(create_character_dialog)
	create_column.add_child(create)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 26
	create_column.add_child(spacer)
	text_line(box, "WASD 이동 · 좌/우클릭 · Q/E/R/T 스킬 · Space 회피 · 1 체력약 · 2 마나약")

func confirm_delete_character(path: String) -> void:
	var confirm := ConfirmationDialog.new()
	confirm.dialog_text = "이 캐릭터의 진행·장비·보관함을 삭제합니다. 되돌릴 수 없습니다."
	confirm.title = "캐릭터 삭제"
	confirm.confirmed.connect(func():
		if not characters.delete_character(path): notify(characters.error)
		show_title())
	confirm.canceled.connect(confirm.queue_free)
	confirm.confirmed.connect(confirm.queue_free)
	ui.add_child(confirm)
	confirm.popup_centered()

func create_character_dialog() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "새로운 항해"
	dialog.dialog_hide_on_ok = false
	var contents := VBoxContainer.new()
	dialog.add_child(contents)
	var name_input := LineEdit.new()
	name_input.placeholder_text = "캐릭터 이름 (1~20자)"
	name_input.max_length = 20
	name_input.custom_minimum_size = Vector2(340, 42)
	contents.add_child(name_input)
	var error_label := Label.new()
	error_label.add_theme_color_override("font_color", Color("ffb394"))
	contents.add_child(error_label)
	var create := func():
		var path := characters.create_character(name_input.text, rules.new_profile())
		if path.is_empty(): error_label.text = characters.error
		else: dialog.queue_free(); select_character(path)
	dialog.confirmed.connect(create)
	name_input.text_submitted.connect(func(_text): create.call())
	dialog.canceled.connect(dialog.queue_free)
	ui.add_child(dialog)
	dialog.popup_centered(Vector2i(390, 180))
	name_input.grab_focus()

func select_character(path: String) -> void:
	var loader := Store.new()
	loader.path = path
	var loaded := loader.load_profile()
	if loaded.is_empty(): notify(loader.error); return
	store = loader
	profile = loaded
	Storage.ensure(profile)
	checkpoint = profile.duplicate(true)
	save_blocked = false
	character_selected = true
	if profile.has("rng_state"): rng.state = int(profile.rng_state)
	else: rng.randomize()
	if profile.has("run_state"): start_run()
	elif profile.intro_seen: show_hub()
	else: show_story(0)

func show_story(page: int) -> void:
	mode = "story"
	intro_page = page
	var headings := ["전쟁의 끝", "낯선 바다", "귀향의 맹세"]
	var captions := ["트로이의 전쟁은 끝났다.\n오디세우스는 살아남은 동료들과 고향 이타카를 향해 돛을 올렸다.", "그러나 바다는 인간의 뜻대로 길을 내주지 않았다.\n신들의 분노와 이름 모를 괴물들이 귀향길을 가로막았다.", "빼앗긴 길은 스스로 열어야 한다.\n신과 괴물의 힘을 손에 넣어서라도, 그는 이타카로 돌아갈 것이다."]
	var box := panel("%02d  /  %s" % [page + 1, headings[page]])
	var art := TextureRect.new()
	art.texture = load("res://assets/story/departure.png" if page != 1 else "res://assets/story/sea.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.custom_minimum_size = Vector2(870, 330)
	box.add_child(art)
	text_line(box, captions[page])
	button(box, "항해 시작" if page == 2 else "다음", func():
		if page < 2: show_story(page + 1)
		else: finish_story())
	button(box, "건너뛰기", finish_story)

func finish_story() -> void:
	var next := profile.duplicate(true)
	next.intro_seen = true
	if commit(next): show_hub()

func show_hub() -> void:
	clear_modal()
	mode = "town"
	world.visible = false
	town.visible = true
	camera.position = Vector2(640, 360)
	camera.offset = Vector2.ZERO
	camera.reset_smoothing()
	health = rules.stats(profile).hp
	mana = rules.stats(profile).mana
	town.queue_redraw()

func show_skills() -> void:
	camp_ui.show_skills()

func toggle_support(index: int) -> void:
	var next := profile.duplicate(true)
	Storage.ensure(next)
	if index < 0 or index >= next.gems.size(): return
	if index not in next.supports and int(next.level)<rules.gem_level(int(next.gems[index].rarity)):return
	if index not in next.supports and not rules.support_compatible(next.gems[index].id, next.skill): return
	if index in next.supports: next.supports.erase(index)
	else:
		for old in next.supports.duplicate():
			if next.gems[int(old)].id == next.gems[index].id: next.supports.erase(old)
		if next.supports.size() >= rules.slots(next):
			notify("먼저 다른 보조를 해제하세요.")
			return
		next.supports.append(index)
	next.skill_supports[next.skill] = next.supports
	if commit(next): show_skills()

func show_inventory() -> void:
	camp_ui.show_inventory()

func sell_item(index:int) -> bool:
	if index < 0 or index >= profile.items.size() or index in profile.equipment: return false
	var next:Dictionary=profile.duplicate(true)
	next.gold += 12 + int(next.items[index].rarity)*8
	next.items.remove_at(index)
	for slot in range(next.equipment.size()):
		if int(next.equipment[slot]) > index: next.equipment[slot] -= 1
	return commit(next)

func sell_items(rarity:int=-1) -> void:
	var next := profile.duplicate(true)
	var kept: Array = []
	var equip:Array=next.equipment.duplicate();equip.fill(-1)
	for i in range(next.items.size()):
		var item: Dictionary = next.items[i]
		if i not in next.equipment and (item.rarity==rarity if rarity>=0 else item.rarity<=1):
			next.gold += 12 + int(item.rarity) * 8
		else:
			if i in next.equipment: equip[next.equipment.find(i)] = kept.size()
			kept.append(item)
	next.items = kept
	next.equipment = equip
	if commit(next): show_shop()

func show_shop() -> void:
	camp_ui.show_shop()

func gacha(kind: int, shards: bool = false, weapon_filter:String="") -> void:
	Storage.ensure(profile)
	if action_lock or kind < 0 or kind > 2 or weapon_filter not in ["","sword","spear","wand","bow"]: return
	var cost:int=rules.gacha_cost(profile,shards)
	if (profile.shards < cost if shards else profile.gold < cost): return
	if kind == 0 and profile.items.size() >= 100: return
	action_lock = true
	var next := profile.duplicate(true)
	var old_rng := rng.state
	if shards: next.shards -= cost
	else: next.gold -= cost
	var weights: Array = rules.gacha_weights(profile,int(next.pity[kind]))
	var rarity := rules.weighted(rng, weights)
	next.pity[kind] = 0 if rarity >= 3 or int(next.pity[kind])>=49 else int(next.pity[kind]) + 1
	var message := ""
	if kind == 0:
		var item := rules.item_roll(rng, rarity, int(profile.level),weapon_filter)
		next.items.append(item)
		message = "%s %s 획득" % [rules.data.rarity_names[rarity], item.name]
	elif kind == 2:
		message = rules.award_primary(next, rules.data.skills.keys()[rng.randi_range(0, rules.data.skills.size() - 1)], rarity,true)
	else:
		message = rules.award_gem(next, {"id": rules.data.supports.keys()[rng.randi_range(0, rules.data.supports.size() - 1)], "rarity": rarity},true)
	if commit(next):
		show_shop()
		notify(message)
	else: rng.state = old_rng
	action_lock = false

var potion_progress:=0.0
var mana_potion_progress:=0.0
var hp_recovery:=0.0
var mp_recovery:=0.0
var hp_recovery_rate:=0.0
var mp_recovery_rate:=0.0
var ambience: int = 0

func start_run() -> void:
	chests.clear()
	ambience = rng.randi_range(0, 2)
	potion_progress=0;mana_potion_progress=0;hp_recovery=0;mp_recovery=0;hp_recovery_rate=0;mp_recovery_rate=0
	var layout_rebuilt := false
	Storage.ensure(profile)
	if profile.has("run_state") and int(profile.run_state.get("layout_revision", 0)) != int(active_stage().get("layout_revision", 0)):
		# Keep rewards and completed checkpoints; rebuild an outdated encounter roster.
		profile.erase("run_state")
		layout_rebuilt = true
	world.configure()
	town.visible = false
	if profile.has("run_state"):
		var snapshot: Dictionary = profile.run_state
		profile.erase("run_state")
		mana = rules.stats(profile).mana
		fields.clear()
		ability_cooldowns.clear()
		burst_timers.clear()
		pending_repeats.clear()
		minions.clear()
		stolen_affixes.clear()
		Snapshot.restore(self, snapshot)
		# Older saves may be outside the redesigned coastline. Move only invalid positions.
		if not spawn_clear(player): player = safe_spawn(mini(profile.cleared.size(), zone_count() - 1))
		for enemy in enemies:
			if not world.walkable(enemy.p): enemy.p = world.centers[clampi(int(enemy.zone), 0, zone_count() - 1)]
		clear_modal()
		mode = "play"
		world.visible = true
		camera.position = player
		camera.reset_smoothing()
		notify("저장한 전투를 이어갑니다.")
		return
	# A save made on the victory screen must also permit a new voyage.
	if profile.cleared.size() >= zone_count():
		var next := profile.duplicate(true)
		next.cleared = []
		next.voyages += 1
		if not commit(next): return
	clear_modal()
	mode = "play"
	world.visible = true
	health = rules.stats(profile).hp
	potions = 2
	mana_potions = 2
	curse_cd = 0
	potion_cd = 0
	mana_potion_cd = 0
	fields.clear()
	ability_cooldowns.clear()
	burst_timers.clear()
	pending_repeats.clear()
	minions.clear()
	stolen_affixes.clear()
	cooldown = 0
	dodge = 0
	dodge_cd = 0
	guard = 0
	bolts.clear()
	effects.clear()
	drops.clear()
	enemies.clear()
	rocks.clear()
	player = world.centers[mini(profile.cleared.size(), zone_count() - 1)] + Vector2(-280, 0)
	camera.position = player
	camera.reset_smoothing()
	for rock in active_stage().rocks: rocks.append({"p": Vector2(rock[0], rock[1]), "r": float(rock[2])})
	for zone in range(zone_count()):
		if zone in profile.cleared: continue
		var count: int = active_stage().counts[zone] + int(profile.tier / 4)
		for i in range(count):
			var a := float(i) * TAU / count
			var p: Vector2 = world.centers[zone] + Vector2(cos(a) * 255, sin(a) * 190)
			if active_stage().get("journey",false):
				p=preload("res://src/domain/endgame_journey.gd").enemy_position(active_stage(),zone,i,count)
			var kind := "archer" if i % (3 if int(profile.stage_id) > 0 else 4) == 2 else "satyr"
			spawn_enemy(p, zone, kind, (72 + zone * 18) * difficulty().hp, zone * 100 + i)
		if zone == zone_count() - 1 or zone in active_stage().get("miniboss_zones",[]):
			var final_boss:=zone==zone_count()-1
			spawn_enemy(world.centers[zone] + Vector2(95, -45), zone, "boss", (1150 if final_boss else 650) * difficulty().hp, zone * 100 + 99)
			enemies.back()["miniboss"]=not final_boss
			if not final_boss:enemies.back().model=["cyclops","minotaur","gorgon"][zone%3]
	chest_events.generate()
	player = safe_spawn(mini(profile.cleared.size(), zone_count() - 1))
	camera.position = player
	camera.reset_smoothing()
	checkpoint = profile.duplicate(true)
	notify("지도가 갱신되어 현재 구역 입구에서 이어갑니다. 획득 보상은 유지됩니다." if layout_rebuilt else "좌/우클릭 · Q/E/R/T 스킬 · 1 체력약 · 2 마나약")

func spawn_enemy(p: Vector2, zone: int, kind: String, hp: float, id: int) -> void:
	var elite := kind != "boss" and id % 100 % 7 == 4
	if elite: hp *= 2.0
	var model: String = active_stage().get("boss_model", "cyclops") if kind == "boss" else (["satyr", "hoplite", "harpy", "automaton"][posmod(int(profile.stage_id) + id, 4)])
	enemies.append({"p": p, "zone": zone, "kind": kind, "model": model, "elite": elite, "hp": hp, "max_hp": hp, "id": id, "hit": 0.0, "stagger": 0.0, "cd": 0.5, "windup": 0.0, "target": p, "dead": false, "death_time": 0.0, "affix": ["swift", "fury", "titan"][posmod(id / 4, 3)] if elite or kind == "boss" else ""})

func _unhandled_input(event: InputEvent) -> void:
	if mode == "play" and event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_LEFT and chest_events.interact(view3d.screen_to_world(event.position)):return
		if event.button_index==MOUSE_BUTTON_LEFT and portal_ready() and view3d.screen_to_world(event.position).distance_to(portal_position())<110 and enter_boss_portal():return
		if event.button_index == MOUSE_BUTTON_LEFT: actions.use_slot(0)
		elif event.button_index == MOUSE_BUTTON_RIGHT: actions.use_slot(1)
		return
	if not event is InputEventKey or not event.pressed or event.echo: return
	if controls.matches(event,KEY_M):
		notify("효과음 꺼짐" if combat_audio.toggle() else "효과음 켜짐")
		return
	if mode == "town":
		if controls.matches(event,KEY_F): town.interact()
		if controls.matches(event,KEY_I): show_inventory()
		if controls.matches(event,KEY_K): show_skills()
		return
	if mode != "play": return
	if controls.matches(event,KEY_F) and (chest_events.interact() or enter_boss_portal()):return
	for slot in range(4):
		if controls.matches(event,[KEY_Q, KEY_E, KEY_R, KEY_T][slot]): actions.use_slot(slot + 2)
	if controls.matches(event,KEY_2): use_mana_potion()
	if controls.matches(event,KEY_SPACE) and dodge_cd <= 0:
		dodge = 0.25
		dodge_cd = rules.dodge_interval(profile)
		dodge_dir = aim
	if controls.matches(event,KEY_1): use_potion()

func use_potion()->void:
	if mode == "play" and potions > 0 and potion_cd <= 0 and health<rules.stats(profile).hp:
		potions -= 1
		potion_cd = 10
		hp_recovery=rules.stats(profile).hp*.4
		hp_recovery_rate=hp_recovery/4.0
		notify("회복약 사용")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode == "play": pause_game()
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if save_now(): get_tree().quit()

func pause_game() -> void:
	mode = "pause"
	var box := panel("항해 일시정지", "마지막으로 정리한 구역까지 저장되어 있습니다.\n야영지로 돌아가면 현재 구역의 미저장 보상은 되돌아갑니다.")
	button(box, "계속", resume_game)
	button(box,"화면 설정",func():display_settings.show_panel(pause_game))
	button(box, "현재 위치와 전투 저장", save_now)
	button(box, "저장 후 종료", func():
		if save_now(): get_tree().quit())
	button(box, "화면 흔들림: " + ("켜짐" if shake_enabled else "꺼짐"), func():
		shake_enabled = not shake_enabled
		pause_game())
	button(box, "마지막 체크포인트로 돌아가 야영지 열기", func():
		profile = checkpoint.duplicate(true)
		show_hub())

func resume_game() -> void:
	clear_modal()
	mode = "play"

func save_now() -> bool:
	if mode == "title" and not character_selected: return true
	if save_blocked:
		notify("저장 파일 오류로 덮어쓰기를 중단했습니다.")
		return false
	var next: Dictionary = profile.duplicate(true)
	next.rng_state = str(rng.state)
	if mode in ["play", "pause"]: next.run_state = Snapshot.capture(self)
	if not store.save_profile(next):
		notify(store.error)
		return false
	notify("저장 완료 — 다음 실행에서 이어할 수 있습니다.")
	return true

func show_town_menu() -> void:
	mode = "hub"
	var box := panel("항구 메뉴", "마을에서의 장비·젬·보관함 변경은 자동 저장됩니다.")
	button(box, "마을로", show_hub)
	button(box, "지금 저장", save_now)
	button(box, "캐릭터 선택", func():
		if save_now(): show_title())
	button(box, "저장 후 종료", func():
		if save_now(): get_tree().quit())

func _physics_process(delta: float) -> void:
	toast_time -= delta
	toast.visible = toast_time > 0
	hud.visible = mode in ["play", "pause"]
	hud.position.y = 95
	if mode != "play": return
	clock += delta
	update_potions(delta)
	curse_cd = maxf(0, curse_cd - delta)
	shake = maxf(0, shake - delta * 32)
	camera.offset = Vector2(sin(clock * 97), cos(clock * 113)) * shake if shake_enabled else Vector2.ZERO
	for key in ["cooldown", "guard", "attack_flash", "hurt_time", "dodge", "dodge_cd", "potion_cd", "mana_potion_cd"]: set(key, maxf(0, float(get(key)) - delta))
	var spec := rules.skill_spec(profile)
	var stats := rules.stats(profile)
	mana = minf(stats.mana, mana + stats.mana_regen * delta)
	channeling = false
	for slot in range(6):
		if profile.loadout[slot] == "whirl" and slot_held(slot) and mana >= rules.data.skills.whirl.mana and dodge <= 0: channeling = true
	for key in ability_cooldowns.keys(): ability_cooldowns[key] = maxf(0, ability_cooldowns[key] - delta)
	for key in burst_timers.keys(): burst_timers[key] = maxf(0, burst_timers[key] - delta)
	if float(burst_timers.get("burst:haste", 0)) > 0: stats.move *= 1.0+.4*rules.buff_scale(profile.level)
	petrify_time=maxf(0,petrify_time-delta)
	if petrify_time>0:stats.move*=.55
	if float(stolen_affixes.get("swift", 0)) > 0: stats.move *= 1.25
	var movement := Vector2(float(controls.pressed(KEY_D)) - float(controls.pressed(KEY_A)), float(controls.pressed(KEY_S)) - float(controls.pressed(KEY_W))).normalized()
	aim = (mouse_target() - player).normalized()
	moving = movement.length_squared() > 0
	if channeling: movement *= 0.8
	if dodge > 0: movement = dodge_dir * 3.0
	var destination: Vector2 = player + movement * stats.move * delta
	if can_move(destination): player = destination
	else:
		if can_move(Vector2(destination.x, player.y)): player.x = destination.x
		if can_move(Vector2(player.x, destination.y)): player.y = destination.y
	camera.position = player
	for slot in range(6):
		if rules.data.skills.has(profile.loadout[slot]) and slot_held(slot): actions.use_slot(slot)
	battle_extras.update(delta)
	update_fields(delta)
	update_enemies(delta)
	update_bolts(delta)
	for i in range(effects.size() - 1, -1, -1):
		effects[i].life -= delta
		if effects[i].life <= 0: effects.remove_at(i)
	for i in range(drops.size() - 1, -1, -1):
		if drops[i].p.distance_to(player) < 160 and accepts_drop(drops[i]): pickup(i)
	chest_events.update()
	check_zones()
	hud.text = "1 체력약 %d · 2 마나약 %d · Space 회피 · Esc 저장" % [potions, mana_potions]
	world.queue_redraw()

func can_move(p: Vector2) -> bool:
	if not world.walkable(p, mini(profile.cleared.size(), zone_count() - 1)): return false
	for offset in [Vector2(12, 0), Vector2(-12, 0), Vector2(0, 12), Vector2(0, -12)]:
		if not world.walkable(p + offset, mini(profile.cleared.size(), zone_count() - 1)): return false
	for rock in rocks:
		if p.distance_to(rock.p) < rock.r + 12: return false
	return true

func attack(spec: Dictionary, repeated: bool = false, target_override: Variant = null) -> void:
	if not repeated and mana < float(spec.get("mana", 0)):
		cooldown = 0.2
		return
	if not repeated: mana -= float(spec.get("mana", 0))
	var cast_target: Vector2 = mouse_target() if target_override == null else target_override
	if not repeated and spec.get("repeat", false): pending_repeats.append({"delay": 0.22, "spec": spec.duplicate(true), "aim": aim, "target": cast_target})
	combat_audio.play_effect("bow" if profile.skill.ends_with("arrow") or profile.skill == "arrow_rain" else ("thunder" if profile.skill == "lava_wave" else profile.skill))
	if not repeated: cooldown = spec.interval
	attack_flash = 0.22
	attack_id += 1
	if spec.get("summon", false):
		battle_extras.summon(spec)
	elif spec.get("trinity",false):
		combat_procs.trinity(spec)
	elif spec.get("area", false):
		var target := player + (cast_target - player).limit_length(float(spec.cast_range))
		cast_field(target, spec)
	elif spec.get("wave", false):
		guard = 0.42
		bolts.append({"p": player, "v": aim * 370, "life": spec.reach / 370, "damage": spec.damage, "friendly": true, "attack": attack_id, "wave": true, "knockback": maxf(30,spec.get("knockback", 0)) if profile.skill=="sword_wave" else spec.get("knockback",0), "pierce": 99, "hits": [], "skill_id": profile.skill})
	elif spec.melee:
		shake = maxf(shake, 2.0)
		guard = minf(0.42, spec.interval)
		effects.append({"kind": "slash", "p": player, "angle": aim.angle(), "arc": spec.arc, "radius": spec.reach, "life": 0.23})
		for enemy in enemies:
			if enemy.dead: continue
			var offset: Vector2 = enemy.p - player
			if offset.length() <= spec.reach + (26 if enemy.kind == "boss" else 12) and (spec.arc >= 360 or absf(aim.angle_to(offset)) <= deg_to_rad(spec.arc * 0.5)):
				hit_enemy(enemy, spec.damage, true, battle_extras.element(str(spec.get("id", profile.skill))), spec.get("knockback", 0))
	else:
		for i in range(int(spec.projectiles)):
			var angle: float = (float(i) - (spec.projectiles - 1) * 0.5) * 0.16
			var speed := 900.0 if profile.skill == "bow" or spec.get("arrow", false) else 660.0
			bolts.append({"p": player, "v": aim.rotated(angle) * speed, "life": spec.reach / speed, "damage": spec.damage, "friendly": true, "attack": attack_id, "arrow": profile.skill in ["bow", "knives"] or spec.get("arrow", false), "skill_id": profile.skill, "chain_count": spec.get("chain_count", 0), "return_multiplier": spec.get("return_multiplier", 0), "returning": false, "homing":spec.get("homing",0), "knockback": spec.get("knockback", 0), "pierce": (3 if profile.skill == "knives" else 1) + int(spec.get("pierce_bonus", 0)), "hits": []})

func hit_enemy(enemy: Dictionary, damage: float, melee: bool, element: String = "physical", knockback: float = 0.0, allow_proc:bool=true) -> void:
	if enemy.dead: return
	var elemental:Dictionary=rules.elemental_bonuses(profile)
	var bonus:float=0.0
	for kind in elemental:
		bonus+=float(elemental[kind])
		if float(enemy.get("aura_fx_cd",0))<=0:
			effects.append({"kind":"impact","element":kind,"p":enemy.p+Vector2(0,-20),"life":.24})
	if not elemental.is_empty():enemy.aura_fx_cd=.18
	damage*=1.0+bonus
	if float(enemy.get("curse", 0.0)) > 0: damage *= rules.data.curse.damage_multiplier
	combat_audio.play_effect("hit")
	if melee: effects.append({"kind": "cut", "p": enemy.p, "life": 0.22})
	if enemy.get("affix", "") == "titan": damage *= 0.85
	enemy.hp -= damage
	enemy.hit = 0.12
	shake = maxf(shake, 3.5 if melee else 1.5)
	effects.append({"kind": "impact", "p": enemy.p + Vector2(0, -25), "life": 0.18})
	effects.append({"kind": "number", "p": enemy.p, "text": str(int(damage)), "life": 0.55})
	if allow_proc:combat_procs.on_hit(enemy,damage)
	if melee and enemy.kind != "boss":
		enemy.stagger = rules.data.melee_stagger
		enemy.windup = 0.0
		enemy.cd = maxf(enemy.cd, 0.35)
	if enemy.kind != "boss":
		battle_extras.push(enemy, (28.0 if melee else 7.0) + knockback)
	if enemy.hp <= 0:
		enemy.dead = true
		recharge_potions(.5 if enemy.kind=="boss" else (.2 if enemy.get("elite",false) else .08))
		battle_extras.on_kill(enemy, element)
		enemy.death_time = 0.8
		profile.gold += int((80 if enemy.kind == "boss" else 10) * difficulty().reward * (3 if enemy.get("elite", false) else 1))
		var before: float = rules.stats(profile).hp
		if rules.add_xp(profile, int((220 if enemy.kind == "boss" else 22) * difficulty().xp*rules.xp_rate(profile,int(enemy.zone)))):
			health += rules.stats(profile).hp - before
			effects.append({"kind": "level_up", "p": player, "life": 2.0})
			combat_audio.play_effect("level_up")
			notify("레벨 업! Lv.%d — 야영지에서 능력치를 배분하세요" % profile.level)
		health = minf(rules.stats(profile).hp, health + rules.unique_value(profile, 0))
		roll_drop(enemy)

func update_enemies(delta: float) -> void:
	for e in enemies:
		e.slow_time = maxf(0, float(e.get("slow_time", 0)) - delta)
		var action_delta: float = delta * enemy_action_rate(e)
		e.chains = maxf(0, float(e.get("chains", 0)) - delta)
		e.frailty = maxf(0, float(e.get("frailty", 0)) - delta)
		e.curse = maxf(0, float(e.get("curse", 0.0)) - delta)
		if e.dead:
			e.death_time = maxf(0, e.death_time - delta)
			continue
		e.hit = maxf(0, e.hit - delta)
		e.stagger = maxf(0, e.stagger - delta)
		e.cd = maxf(0, e.cd - action_delta)
		if e.stagger > 0: continue
		var focus: Vector2 = battle_extras.enemy_focus(e)
		var dist: float = e.p.distance_to(focus)
		if e.zone > mini(profile.cleared.size(), zone_count() - 1) or dist > 650: continue
		e.aura_fx_cd=maxf(0,float(e.get("aura_fx_cd",0))-delta)
		if e.kind=="boss":boss_combat.update(e,delta,focus);continue
		if e.windup > 0:
			e.windup -= action_delta
			if e.windup <= 0:
				if e.kind == "archer":
					bolts.append({"p": e.p, "v": (e.target - e.p).normalized() * 300, "life": 2.0, "damage": 12.0 * difficulty().damage * enemy_damage_rate(e), "friendly": false, "attack": -1})
					if int(profile.tier) >= 8:
						for angle in [-0.26, 0.26]: bolts.append({"p": e.p, "v": (e.target - e.p).normalized().rotated(angle) * 300, "life": 2.0, "damage": 12.0 * difficulty().damage * enemy_damage_rate(e), "friendly": false, "attack": -1})
				else: battle_extras.enemy_strike(e, (35 if e.kind == "boss" else 10) * difficulty().damage * enemy_damage_rate(e))
				if e.get("elite", false) or (e.kind == "boss" and e.get("model", "cyclops") != "cyclops"): battle_extras.special_attack(e)
				e.cd = (1.6 if e.kind == "boss" else 0.9) / difficulty().speed
				if e.kind == "boss" and (int(profile.stage_id) >= 3 or int(profile.tier) > 0):
					for ray in range(8):
						bolts.append({"p": e.p, "v": Vector2.from_angle(ray * TAU / 8) * 230, "life": 2.5, "damage": 14 * difficulty().damage * enemy_damage_rate(e), "friendly": false, "attack": -1})
			continue
		var range_: float = 340 if e.kind == "archer" else (140 if e.kind == "boss" else 65)
		if dist < range_ and e.cd <= 0:
			e.windup = 1.05 if e.kind == "boss" else 0.65
			e.target = focus
		elif dist > range_ * 0.7 and e.cd < 0.65:
			var speed: float = (70.0 if e.kind == "boss" else 93.0) * difficulty().speed * enemy_action_rate(e)
			if float(e.get("slow_time", 0)) > 0: speed *= 1.0 - float(e.get("slow", 0.3))
			var destination: Vector2 = e.p + (focus - e.p).normalized() * speed * delta
			var blocked := false
			for rock in rocks:
				if destination.distance_to(rock.p) < rock.r + 15: blocked = true
			if world.walkable(destination) and not blocked: e.p = destination
			else:
				for angle in [0.8, -0.8, 1.5, -1.5]:
					var alternative: Vector2 = e.p + (focus - e.p).normalized().rotated(angle) * speed * delta
					var free: bool = world.walkable(alternative)
					for rock in rocks:
						if alternative.distance_to(rock.p) < rock.r + 15: free = false
					if free: e.p = alternative; break

func update_bolts(delta: float) -> void:
	for i in range(bolts.size() - 1, -1, -1):
		var b := bolts[i]
		combat_procs.guide(b,delta)
		var old: Vector2 = b.p
		if b.get("returning", false):
			b.v = (player - b.p).normalized() * 800
			if b.p.distance_to(player) < 24: bolts.remove_at(i); continue
		b.p += b.v * delta
		b.life -= delta
		var wall := false
		for rock in rocks:
			if Math.segment_hits(old, b.p, rock.p, rock.r): wall = true; b.life = 0
		if b.life > 0:
			if b.friendly and not b.get("turning", false):
				for e in enemies:
					if e.dead or int(e.id) in b.get("hits", []): continue
					if not Math.segment_hits(old, b.p, e.p, 65 if b.get("wave", false) else (32 if e.kind == "boss" else 19)): continue
					var leg := "last_return_attack" if b.get("returning", false) else "last_attack"
					if int(e.get(leg, -1)) != int(b.attack):
						e[leg] = b.attack
						hit_enemy(e, b.damage, b.get("wave", false), battle_extras.element(str(b.get("skill_id", ""))), b.get("knockback", 0))
						if not b.get("returning", false): elemental_hit(b, e)
					if not b.has("hits"): b.hits = []
					b.hits.append(int(e.id))
					b.pierce = int(b.get("pierce", 1)) - 1
					if b.pierce <= 0:
						b.turning = float(b.get("return_multiplier", 0)) > 0 and not b.get("returning", false)
						b.life = maxf(b.life,0.55) if b.turning else 0.0
						break
			elif not b.friendly and battle_extras.intercept(old, b.p, b.damage): b.life = 0
			elif not b.friendly and Math.segment_hits(old, b.p, player, 18): hurt(b.damage); b.life = 0
		if b.life <= 0:
			if not wall and float(b.get("return_multiplier", 0)) > 0 and not b.get("returning", false):
				b.returning = true
				b.turning = false
				b.damage *= b.return_multiplier
				b.life = 2.0
				b.pierce = 99
				b.hits = []
			else: bolts.remove_at(i)

func hurt(amount: float) -> void:
	if dodge > 0.05 and dodge < 0.20: return
	if hurt_time > 0: return
	amount*=1.0-rules.stats(profile).armor_reduction
	if "ward" in profile.get("buffs", []): amount *= 1.0 - rules.buff_value(profile,"ward")
	amount *= 1.0 - rules.unique_value(profile, 1)
	health -= amount * (1.0 - rules.data.melee_guard if guard > 0 else 1.0)
	combat_audio.play_effect("hurt")
	hurt_time = 0.18
	if rules.effect_value(profile, "frost") > 0:
		for e in enemies:
			if not e.dead and e.p.distance_to(player) <= 150: e.slow_time = 2.0; e.slow = 0.25
	if health <= 0:
		var earned: int = maxi(0, int(profile.gold - checkpoint.gold))
		var fallen:Dictionary=profile.duplicate(true)
		fallen.gold = checkpoint.gold + int(earned * 0.5)
		var lost_xp:int=rules.death_xp(fallen)
		if commit(fallen):
			show_hub()
			notify("쓰러졌습니다. 구역 골드 절반 손실 · 경험치 -%d (레벨 하락 없음)"%lost_xp)
		else: pause_game()

func roll_drop(e: Dictionary) -> void:
	var local := RandomNumberGenerator.new()
	local.seed = int(e.id) + int(profile.voyages) * 1000 + int(profile.get("stage_id", 0)) * 10000 + 771
	var guaranteed: bool = int(e.id) % 100 == 0 or e.kind == "boss" or e.get("elite", false)
	if guaranteed or local.randf() < 0.12:
		var rarity := rules.weighted(local, rules.loot_weights(profile,e.kind == "boss"))
		drops.append({"p": e.p + Vector2(-16, 0), "kind": "item", "rarity": rarity, "value": rules.item_roll(local, rarity, int(profile.level))})
	if guaranteed or local.randf() < 0.05:
		var rarity := rules.weighted(local, rules.loot_weights(profile,e.kind == "boss"))
		var value := {"id": rules.data.supports.keys()[local.randi_range(0, rules.data.supports.size() - 1)], "rarity": rarity}
		drops.append({"p": e.p + Vector2(16, 0), "kind": "gem", "rarity": rarity, "value": value})
	if local.randf() < (0.25 if e.kind == "boss" else 0.03):
		var keys: Array = rules.data.skills.keys()
		var primary := str(keys[local.randi_range(0, keys.size() - 1)])
		var rarity := rules.weighted(local, rules.data.rarity_weights)
		drops.append({"p": e.p + Vector2(0, 20), "kind": "primary", "rarity": rarity, "value": {"id": primary, "rarity": rarity}})
	if e.kind == "boss" and "whirl" not in profile.skills:
		profile.skills.append("whirl")
		notify("주스킬 젬: 아킬레우스의 선회 획득")

func cast_curse() -> void:
	cast_curse_at(mouse_target())

func cast_curse_at(target: Vector2) -> void:
	var id := str(profile.get("selected_curse", "vulnerability"))
	var spec: Dictionary = rules.data.curses.get(id, rules.data.curses.vulnerability)
	if curse_cd > 0 or mana < spec.mana: return
	mana -= spec.mana
	combat_audio.play_effect("curse")
	target = player + (target - player).limit_length(float(rules.data.curse.range))
	curse_cd = rules.data.curse.cooldown
	for enemy in enemies:
		if not enemy.dead and enemy.p.distance_to(target) <= rules.data.curse.radius:
			enemy.curse = 0.0
			enemy.chains = 0.0
			enemy.frailty = 0.0
			enemy["curse" if id == "vulnerability" else id] = spec.duration
	effects.append({"kind": "curse", "p": target, "life": 0.7, "radius": rules.data.curse.radius, "curse_id": id})
	notify(spec.name + " — " + spec.description)

func pickup(index: int) -> void:
	var d := drops[index]
	if not accepts_drop(d):return
	if d.kind == "item":
		# Preserve field rewards even over capacity. Gacha remains capped at 100.
		profile.items.append(d.value)
		notify("%s %s 획득" % [rules.data.rarity_names[int(d.rarity)], d.value.name])
	elif d.kind == "primary": notify(rules.award_primary(profile, d.value.id, int(d.rarity)))
	else: notify(rules.award_gem(profile, d.value))
	drops.remove_at(index)

func check_zones() -> void:
	if mode != "play": return
	var zone: int = profile.cleared.size()
	if zone >= zone_count(): return
	for e in enemies:
		if int(e.zone) == zone and not e.get("chest_guard",false) and not e.dead and (e.get("elite",false) or e.kind=="boss"): return
	for i in range(drops.size() - 1, -1, -1): pickup(i)
	if drops.any(func(d):return accepts_drop(d)):
		pause_game()
		return
	var next := profile.duplicate(true)
	next.cleared.append(zone)
	var quest_amount:int=rules.campaign_xp(next,zone,zone_count())
	if rules.add_xp(next,roundi(quest_amount*rules.xp_rate(next,zone))):
		effects.append({"kind":"level_up","p":player,"life":2.0})
		combat_audio.play_effect("level_up")
	if zone == zone_count() - 1:
		if int(next.tier) > 0: next.tier_unlocked = maxi(int(next.tier_unlocked), mini(16, int(next.tier) + 1))
		else:
			next.stage_unlocked = maxi(int(next.stage_unlocked), mini(6, int(next.stage_id) + 1))
			if int(next.stage_id) == 6: next.campaign_complete = true
	next.gold += 40
	if not commit(next):
		pause_game()
		return
	health = rules.stats(profile).hp
	notify("목표 처치! +40 골드 · 다음 길 개방 · 일반 몬스터는 선택 파밍")
	if zone == zone_count() - 1:
		if int(profile.stage_id) == 6 and int(profile.tier) == 0:
			show_ending()
			return
		mode = "complete"
		var box := panel("항해의 승리", "%s를 쓰러뜨렸다. 항해사에게서 다음 목적지를 확인하자.\n이타카까지의 여정은 계속된다." % active_stage().boss)
		button(box, "보상을 가지고 야영지로", func():
			var candidate := profile.duplicate(true)
			candidate.cleared = []
			candidate.voyages += 1
			if commit(candidate): show_hub())

func show_destinations() -> void:
	mode = "hub"
	Storage.ensure(profile)
	var box := panel("항해 지도", "이전 항로를 완료하면 다음 목적지가 열립니다. 귀환 후에는 신들의 시험에 도전하세요.")
	for i in range(7):
		var index := i
		var stage: Dictionary = stages[i]
		button(box, "액트 %d · %s — %s" % [stage.act, stage.name, stage.intro], func(): select_stage(index), i > int(profile.stage_unlocked))
	text_line(box, "신들의 시험 · 엔드게임 1–16티어 · 완료할 때마다 다음 티어 개방 · 9개 지도 순환")
	for i in range(1, 17):
		var tier := i
		button(box, "T%d 출항" % tier, func(): select_tier(tier), not profile.campaign_complete or i > int(profile.tier_unlocked))
	button(box, "마을로", show_hub)

func select_stage(index: int) -> void:
	Storage.ensure(profile)
	if index < 0 or index >= stages.size() or index > int(profile.stage_unlocked): return
	var next: Dictionary = profile.duplicate(true)
	next.stage_progress[progress_key()] = next.cleared.duplicate()
	next.stage_id = index
	next.tier = 0
	next.cleared = next.stage_progress.get(str(index), []).duplicate()
	if commit(next): start_run()

var journey_cache:Dictionary={}
func active_stage() -> Dictionary:
	var index := int(profile.get("stage_id", 0))
	if int(profile.get("tier", 0)) > 0:
		index = int(profile.get("map_index", 0)) % stages.size()
		var key:=str(index)+":"+str(int(profile.tier))
		if not journey_cache.has(key):journey_cache[key]=preload("res://src/domain/endgame_journey.gd").build(stages[index],int(profile.tier),index)
		return journey_cache[key]
	return stages[clampi(index, 0, stages.size() - 1)]

func progress_key() -> String:
	return "tier_" + str(int(profile.tier)) if int(profile.tier) > 0 else str(int(profile.stage_id))

func difficulty() -> Dictionary:
	var tier := int(profile.get("tier", 0))
	var stage := int(profile.get("stage_id", 0))
	return {"hp": 3.0 * pow(1.28, tier - 1) if tier > 0 else active_stage().hp_scale,
		"damage": 1.95 * pow(1.13, tier - 1) if tier > 0 else 1.25 + stage * 0.14,
		"speed": 1.4 + tier * 0.025 if tier > 0 else 1.22 + stage * 0.035,
		"reward": 2.0 + tier * 0.3 if tier > 0 else 1.0 + stage * 0.25,
		"xp": 8.0 + tier * 2.5 if tier > 0 else 1.0 + stage * 1.4}

func select_tier(tier: int) -> void:
	if not profile.campaign_complete or tier < 1 or tier > mini(16, int(profile.tier_unlocked)): return
	var next := profile.duplicate(true)
	next.stage_progress[progress_key()] = next.cleared.duplicate()
	next.tier = tier
	next.map_index = int(next.voyages) % stages.size()
	next.cleared = []
	if commit(next): start_run()

func show_ending() -> void:
	mode = "complete"
	var box := panel("이타카 · 귀환", "긴 항해가 끝났다. 오디세우스는 활을 내려놓고 페넬로페의 손을 잡았다.\n그러나 바다에 남겨진 신들의 유산은 아직 그를 부르고 있었다.")
	var art := TextureRect.new()
	art.texture = load("res://assets/story/departure.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.custom_minimum_size = Vector2(870, 280)
	box.add_child(art)
	text_line(box, "신들의 시험이 열렸습니다. 항해 지도에서 T1–T16 파밍을 계속할 수 있습니다.")
	button(box, "고향의 항구로", show_hub)

func use_mana_potion() -> void:
	if mana_potions <= 0 or mana_potion_cd > 0: return
	if mana >= rules.stats(profile).mana: return
	mana_potions -= 1
	mana_potion_cd = 8.0
	mp_recovery=rules.stats(profile).mana*.5
	mp_recovery_rate=mp_recovery/4.0
	notify("마나약 사용")

func cast_field(target: Vector2, spec: Dictionary) -> void:
	if spec.get("follow",false):
		fields=fields.filter(func(f):return f.kind!=profile.skill)
	fields.append({"follow": spec.get("follow",false), "p": player if spec.get("follow",false) else target, "radius": spec.reach, "damage": spec.damage, "knockback": spec.get("knockback", 0), "kind": profile.skill, "life": float(spec.get("duration",3.0 if profile.skill == "blizzard" else (2.0 if profile.skill == "arrow_rain" else 0.31))), "tick": 0.3 if profile.skill == "thunder" else 0.0})

func update_fields(delta: float) -> void:
	for i in range(fields.size() - 1, -1, -1):
		var field := fields[i]
		if field.get("follow",false): field.p=player
		field.tick -= delta
		if field.tick <= 0:
			field.tick += 0.5
			for e in enemies:
				if not e.dead and (not field.get("minion",false) or int(e.zone)<=mini(profile.cleared.size(),zone_count()-1)) and e.p.distance_to(field.p) <= field.radius:
					hit_enemy(e, field.damage, false, battle_extras.element(field.kind), field.get("knockback", 0),not field.get("minion",false))
					if field.kind in ["blizzard", "ice_zone"]: e.slow_time = 1.0; e.slow = 0.3
			if field.kind == "thunder": combat_audio.play_effect("thunder")
			if field.kind == "thunder": effects.append({"kind": "thunder", "p": field.p, "radius": field.radius, "life": 0.35})
		field.life -= delta
		if field.life <= 0: fields.remove_at(i)

func spawn_clear(p: Vector2) -> bool:
	if not can_move(p): return false
	# Reserve walking room in every direction, not just a legal center point.
	for i in range(8):
		if not can_move(p + Vector2.from_angle(i * TAU / 8) * 36): return false
	return true

func safe_spawn(zone: int) -> Vector2:
	var center: Vector2 = world.centers[zone]
	for x in [-220, -180, -120, 0, 120, 180]:
		for y in [0, -60, 60, -120, 120]:
			var candidate := center + Vector2(x, y)
			if spawn_clear(candidate): return candidate
	return center

func _input(event: InputEvent) -> void:
	if controls!=null and controls.capture(event):
		get_viewport().set_input_as_handled()
		return
	# Handle cancel before focused buttons or other GUI controls consume it.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		match mode:
			"hub": show_hub()
			"town": show_town_menu()
			"play": pause_game()
			"pause": resume_game()
			_: return
		get_viewport().set_input_as_handled()

func enemy_action_rate(enemy: Dictionary) -> float:
	return ((0.85 if enemy.kind == "boss" else 0.70) if float(enemy.get("chains", 0)) > 0 else 1.0) * (1.2 if enemy.get("affix", "") == "swift" else 1.0) * (1.2 if enemy.get("elite", false) else 1.0)

func enemy_damage_rate(enemy: Dictionary) -> float:
	return ((0.85 if enemy.kind == "boss" else 0.75) if float(enemy.get("frailty", 0)) > 0 else 1.0) * (1.2 if enemy.get("affix", "") == "fury" else 1.0) * (1.3 if enemy.get("elite", false) else 1.0)

func slot_held(slot: int) -> bool:
	if slot < 2: return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT if slot == 0 else MOUSE_BUTTON_RIGHT)
	return controls.pressed([KEY_Q, KEY_E, KEY_R, KEY_T][slot - 2])

func elemental_hit(b: Dictionary, enemy: Dictionary) -> void:
	var id := str(b.get("skill_id", ""))
	if id in ["ice_arrow","ice_spear","fire_spear"]:
		if fields.size() >= 48: fields.pop_front()
		fields.append({"kind": "fire_zone" if id=="fire_spear" else "ice_zone", "p": enemy.p, "radius": 85.0, "damage": b.damage * 0.2, "life": 2.0, "tick": 0.0})
	elif id in ["lightning_arrow","lightning_spear"] or int(b.get("chain_count",0)) > 0:
		var from: Vector2 = enemy.p
		enemy.last_chain = b.attack
		for chain in range(maxi(3 if id in ["lightning_arrow","lightning_spear"] else 0,int(b.get("chain_count",0)))):
			var nearest: Dictionary = {}
			var distance := 190.0
			for other in enemies:
				if other.dead or int(other.get("last_chain", -1)) == b.attack or int(other.get("last_attack", -1)) == b.attack: continue
				var d: float = from.distance_to(other.p)
				if d < distance: nearest = other; distance = d
			if nearest.is_empty(): break
			nearest.last_chain = b.attack
			combat_audio.play_effect("chain")
			effects.append({"kind": "chain", "p": from, "to": nearest.p, "life": 0.25})
			hit_enemy(nearest, b.damage * (0.65 if id in ["lightning_arrow","lightning_spear"] else 0.6), false, battle_extras.element(id))
			from = nearest.p

func zone_count() -> int:
	return active_stage().centers.size()

func mouse_target() -> Vector2:
	if is_instance_valid(view3d) and view3d.active(): return view3d.mouse_world()
	return get_global_mouse_position()

func clear_support_link(slot: int) -> void:
	var next := profile.duplicate(true)
	Storage.ensure(next)
	if slot < 0 or slot >= next.supports.size(): return
	next.supports.remove_at(slot)
	next.skill_supports[next.skill] = next.supports
	if commit(next): show_skills()

func update_potions(delta:float)->void:
	var hp:float=minf(hp_recovery,hp_recovery_rate*delta)
	var mp:float=minf(mp_recovery,mp_recovery_rate*delta)
	health=minf(rules.stats(profile).hp,health+hp)
	mana=minf(rules.stats(profile).mana,mana+mp)
	hp_recovery=maxf(0,hp_recovery-hp);mp_recovery=maxf(0,mp_recovery-mp)

func recharge_potions(amount:float)->void:
	if potions<2:
		potion_progress+=amount
		while potion_progress>=1 and potions<2:potions+=1;potion_progress-=1
	if mana_potions<2:
		mana_potion_progress+=amount
		while mana_potion_progress>=1 and mana_potions<2:mana_potions+=1;mana_potion_progress-=1
	if potions>=2:potion_progress=0
	if mana_potions>=2:mana_potion_progress=0

func portal_position()->Vector2:
	var pair:Array=active_stage().get("portal_origin",[0,0])
	return Vector2(pair[0],pair[1])
func portal_ready()->bool:
	return active_stage().get("journey",false) and profile.cleared.size()==zone_count()-1
func enter_boss_portal()->bool:
	if not portal_ready() or player.distance_to(portal_position())>180:return false
	player=world.centers.back()+Vector2(-350,0)
	camera.position=player;camera.reset_smoothing()
	bolts.clear();fields.clear();effects.clear();minions.clear()
	view3d.refresh(0)
	save_now()
	notify("진 보스의 투기장 · 보스를 쓰러뜨려 항해를 완료하세요")
	return true

func accepts_drop(drop:Dictionary)->bool:
	if drop.kind!="item":return true
	var threshold:int=int(profile.get("loot_min_rank",-1))
	if threshold<0:threshold=2 if int(profile.get("tier",0))>0 else 0
	return int(drop.rarity)>=threshold
func show_loot_filter(back:Callable)->void:
	var box:=panel("장비 획득 필터","자동: 액트에서는 전체, 엔드게임에서는 희귀 이상. 제외한 장비는 자동 획득과 표시에서 제외합니다. 젬은 모두 유지합니다.")
	for index in range(-1,6):
		var rank:int=index
		var title:String="자동" if rank<0 else ("전체 장비" if rank==0 else rules.data.rarity_names[rank]+" 이상")
		button(box,title+(" ✓" if int(profile.get("loot_min_rank",-1))==rank else ""),func():
			var next:Dictionary=profile.duplicate(true);next.loot_min_rank=rank
			if commit(next):show_loot_filter(back))
	button(box,"돌아가기",back)
