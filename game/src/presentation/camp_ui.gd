extends Node
const Storage = preload("res://src/domain/storage_rules.gd")
var game
var settings:Button
var bar: PanelContainer
var meters: Array[Label] = []
var hp_bar: ProgressBar
var mp_bar: ProgressBar
var rarity_filter := -1
var xp_bar: ProgressBar
var shortcuts: VBoxContainer
var use_shards := false
var stash_gems := false
var scroll_positions := {}
var equipment_layout
var skill_panel
var codex_tab:=0
var selected_slot := 0
var selected_support := 0
var gem_filter := -1
var buff_row: HBoxContainer
var buff_signature := ""
var action_bar: HBoxContainer
var action_buttons: Array[Button] = []

func setup(owner_game) -> void:
	ProjectSettings.set_setting("gui/timers/tooltip_delay_sec",.12)
	game = owner_game
	var combat_hud:=preload("res://src/presentation/combat_hud.gd").new()
	combat_hud.name="EdgeHUD"
	combat_hud.game=game
	game.ui.add_child(combat_hud)
	var map := preload("res://src/presentation/dungeon_map.gd").new()
	map.game = game
	game.ui.add_child(map)
	action_bar = HBoxContainer.new()
	action_bar.position = Vector2(480, 590)
	action_bar.add_theme_constant_override("separation", 8)
	game.ui.add_child(action_bar)
	for slot in range(6):
		var index := slot
		var entry := card(action_bar, "", Color("dfc38a"), func(): game.actions.use_slot(index))
		entry.custom_minimum_size = Vector2(96, 56)
		action_buttons.append(entry)
	buff_row = HBoxContainer.new()
	buff_row.position = Vector2(24, 125)
	game.ui.add_child(buff_row)
	bar = PanelContainer.new()
	bar.position = Vector2(16, 10)
	bar.size = Vector2(1248, 78)
	bar.add_theme_stylebox_override("panel", style(Color("151519"), Color("92764b")))
	game.ui.add_child(bar)
	var content := VBoxContainer.new()
	bar.add_child(content)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	content.add_child(row)
	for i in range(5):
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		meters.append(label)
	var resources := HBoxContainer.new()
	content.add_child(resources)
	hp_bar = resource_bar(resources, Color("b23e43"))
	mp_bar = resource_bar(resources, Color("66acfa"))
	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size.y = 7
	xp_bar.show_percentage = false
	content.add_child(xp_bar)
	settings=Button.new()
	settings.text="설정"
	settings.position=Vector2(1190,15)
	settings.pressed.connect(func():
		if game.mode=="play": game.pause_game()
		var back:Callable=game.pause_game if game.mode=="pause" else game.show_hub
		game.mode="pause" if game.mode=="pause" else "hub"
		game.display_settings.show_panel(back))
	game.ui.add_child(settings)
	shortcuts = VBoxContainer.new()
	shortcuts.position = Vector2(220, 530)
	shortcuts.add_theme_constant_override("separation", 12)
	game.ui.add_child(shortcuts)
	for spec in [["가방 · 장비 [I]", "inventory"], ["주스킬 · 젬 [K]", "skills"], ["조작 안내 · 키 설정", "help"]]:
		var action: String = spec[1]
		var b := card(shortcuts, spec[0], Color("b9a675"), func():
			if action == "inventory": game.show_inventory()
			elif action == "skills": game.show_skills()
			else: game.controls.show_panel(game.show_hub))
		b.custom_minimum_size = Vector2(210, 42)
		b.add_theme_stylebox_override("normal",style(Color(0.04,0.05,0.07,.55),Color(0.65,0.58,0.4,.6)))

func style(background: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = background
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(2)
	s.set_content_margin_all(10)
	return s

func card(parent: Node, text: String, color: Color, callback: Callable, disabled: bool = false) -> Button:
	var b := preload("res://src/presentation/icon_card.gd").new()
	b.ink = color
	b.text = text
	b.icon=preload("res://src/presentation/ui_symbols.gd").for_text(text)
	b.add_theme_constant_override("icon_max_width",22)
	b.add_theme_font_size_override("font_size", 14)
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.custom_minimum_size = Vector2(140, 68)
	b.add_theme_stylebox_override("normal", style(Color("1b1b20"), color))
	b.add_theme_stylebox_override("hover", style(Color("323039"), color.lightened(0.3)))
	b.add_theme_stylebox_override("disabled", style(Color("17171b"), color.darkened(0.25)))
	b.add_theme_color_override("font_disabled_color", color.darkened(0.15))
	b.add_theme_color_override("font_color", color)
	b.disabled = disabled
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _process(_delta: float) -> void:
	if game == null: return
	game.display_settings.apply_ui()
	settings.visible=game.mode in ["play","pause","town","hub"]
	update_buff_icons()
	var screen_scale:float=game.display_settings.ui_scale
	action_bar.position=(Vector2(1145,704)-game.ui.position)/screen_scale-Vector2(action_bar.size.x,action_bar.size.y)
	buff_row.position=(Vector2(8,6)-game.ui.position)/screen_scale
	shortcuts.position=(Vector2(1272,350)-game.ui.position)/screen_scale-Vector2(shortcuts.size.x,0)
	shortcuts.get_child(0).text="가방 · 장비 ["+game.controls.label(KEY_I)+"]"
	shortcuts.get_child(1).text="주스킬 · 젬 ["+game.controls.label(KEY_K)+"]"
	action_bar.visible = game.mode in ["play", "pause"]
	if action_bar.visible:
		for slot in range(6):
			var id: String = game.profile.loadout[slot]
			var info: Dictionary = game.rules.ability_info(id)
			var remaining: float = game.ability_cooldowns.get(id, 0)
			if game.rules.data.skills.has(id) and not game.rules.data.skills[id].get("summon",false) and not game.rules.data.skills[id].get("area",false):remaining=0
			if id.begins_with("curse:"): remaining = maxf(remaining, game.curse_cd)
			var state := ""
			action_buttons[slot].cooldown_remaining=remaining
			action_buttons[slot].cooldown_ratio=clampf(remaining/maxf(.01,float(game.cooldown_totals.get(id,info.get("cooldown",remaining)))),0,1)
			if id.begins_with("aura:") and id.trim_prefix("aura:") in game.profile.buffs: state = " · ON"

			iconify(action_buttons[slot], id if not id.is_empty() else "empty", game.controls.slot_label(slot) + state)
			if game.rules.data.skills.has(id):
				var rank:int=game.rules.skill_rank(game.profile,id)
				action_buttons[slot].set("ink",game.rarity_color(maxi(0,rank)))
				state += " · "+(game.rules.data.rarity_names[rank] if rank>=0 else "잠김")
				iconify(action_buttons[slot],id,["좌클릭","우클릭","Q","E","R","T"][slot]+state)
			action_buttons[slot].lock_reason="필요: "+game.rules.weapon_name(game.rules.required_weapon(id)) if game.rules.data.skills.has(id) and not game.rules.weapon_allows(game.profile,id) else ""
			action_buttons[slot].tooltip_text = str(info.get("name", "빈 슬롯")) + "\n" + str(info.get("description", "마을의 스킬 창에서 배치하세요."))
	bar.visible = game.mode in ["town", "hub", "play", "pause", "complete"]
	shortcuts.visible = game.mode == "town"
	if not bar.visible: return
	var p: Dictionary = game.profile
	meters[0].text = "골드  %d" % p.gold
	meters[1].text = "Lv.%d   경험치 %d / %d" % [p.level, p.xp, game.rules.xp_needed(int(p.level))]
	meters[2].text = "젬 %d · 조각 %d · 버프 %d/2" % [p.gems.size(), p.shards, p.get("buffs", []).size()]
	meters[3].text = "체력 %d / %d" % [maxf(0, game.health), game.rules.stats(p).hp]
	meters[4].text = "%s  %s" % [game.active_stage().name, "●".repeat(p.cleared.size()) + "○".repeat(maxi(0, game.zone_count() - p.cleared.size()))]
	hp_bar.max_value = game.rules.stats(p).hp
	hp_bar.value = game.health
	hp_bar.tooltip_text = "체력 %d / %d" % [game.health, hp_bar.max_value]
	mp_bar.max_value = game.rules.stats(p).mana
	mp_bar.value = game.mana
	mp_bar.tooltip_text = "마나 %d / %d · 재생 %.1f/초" % [game.mana, mp_bar.max_value, game.rules.stats(p).mana_regen]
	meters[3].text = "HP %d · MP %d" % [maxf(0, game.health), game.mana]
	if int(p.tier) > 0: meters[4].text = "T%d · %s" % [p.tier, game.active_stage().name]
	xp_bar.max_value = game.rules.xp_needed(int(p.level))
	xp_bar.value = p.xp
	bar.hide()
	game.hud.visible=false

func begin(title: String, subtitle: String) -> VBoxContainer:
	if is_instance_valid(game.modal) and game.modal.has_meta("scroll_page"):
		scroll_positions[game.modal.get_meta("scroll_page")] = game.modal.get_child(0).scroll_vertical
	game.mode = "hub"
	var box: VBoxContainer = game.panel(title, subtitle)
	game.modal.set_meta("scroll_page", title)
	restore_scroll(game.modal, int(scroll_positions.get(title, 0)))
	game.modal.position.y = 100
	game.modal.size.y = 550
	return box

func grid(parent: Node, columns: int = 6) -> GridContainer:
	var g := GridContainer.new()
	g.columns = columns
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	parent.add_child(g)
	return g

func item_text(item: Dictionary) -> String:
	return "%s\n%s · %s" % [item.name, game.rules.weapon_name(str(item.get("weapon_type","sword"))) if int(item.slot)==0 else game.rules.slot_name(int(item.slot)), game.rules.data.rarity_names[int(item.rarity)]]

func item_details(item: Dictionary) -> String:
	return "%s\n%s\n%s" % [item_text(item),game.rules.slot_stat(item),game.rules.effect_description(item)]

func show_inventory() -> void:
	var p: Dictionary = game.profile
	var box := begin(str(p.get("character_name", "오디세우스")) + " · 장비와 가방", "슬롯을 눌러 장착 해제 · 가방의 장비를 눌러 장착 · 마을 보관함은 별도 공간입니다.")
	if equipment_layout == null: equipment_layout = preload("res://src/presentation/equipment_layout.gd").new(self)
	equipment_layout.paperdoll(box)
	game.text_line(box, "캐릭터 가방  %d / 100    ·    클릭하여 장착" % p.items.size())
	add_filter(box, show_inventory)
	equipment_layout.bag(box,p.items)
	equipment_skills(box)
	game.button(box, "마을로 돌아가기", game.show_hub)

func show_skills() -> void:
	if skill_panel == null: skill_panel = preload("res://src/presentation/skill_panel.gd").new(self)
	skill_panel.show_panel()

func show_stash() -> void:
	Storage.ensure(game.profile)
	var box := begin("마을 보관함", "가방과 보관함은 별도 저장됩니다. 장착/연결 중인 물건은 먼저 해제하세요.")
	var tabs := grid(box, 2)
	card(tabs, "장비 보관", Color("e2c182"), func(): stash_gems = false; show_stash())
	card(tabs, "보조 젬 보관", Color("85bdcb"), func(): stash_gems = true; show_stash())
	add_filter(box, show_stash)
	for deposit in [true, false]:
		var key: String = ("gems" if stash_gems else "items") if deposit else ("stash_gems" if stash_gems else "stash_items")
		var contents: Array = game.profile[key]
		game.text_line(box, "%s  %d / 100 — %s" % ["캐릭터 가방" if deposit else "마을 보관함", contents.size(), "클릭하여 보관" if deposit else "클릭하여 꺼내기"])
		if not stash_gems:
			if equipment_layout == null: equipment_layout = preload("res://src/presentation/equipment_layout.gd").new(self)
			equipment_layout.bag(box,contents,deposit,true)
			continue
		var cells := grid(box)
		if contents.is_empty(): game.text_line(box, "비어 있습니다.")
		for i in ordered(contents):
			var index: int = i
			var entry: Dictionary = contents[i]
			var text: String = "%s\n%s" % [game.rules.data.rarity_names[int(entry.rarity)], game.rules.data.supports[entry.id].name] if stash_gems else item_text(entry)
			var equipped: bool = deposit and index in (Storage.linked_indices(game.profile) if stash_gems else game.profile.equipment)
			var cell := card(cells, text + ("\n장착 중" if equipped else ("\n→ 보관" if deposit else "\n← 꺼내기")), game.rarity_color(int(entry.rarity)), func(): transfer(stash_gems, deposit, index), equipped)
			cell.tooltip_text = game.rules.data.supports[entry.id].name + " · " + game.rules.data.rarity_names[int(entry.rarity)] + "\n" + game.rules.support_numbers(entry) if stash_gems else item_details(entry)
			iconify(cell, entry.id if stash_gems else game.rules.item_icon(entry), "장착 중" if equipped else ("보관" if deposit else "꺼내기"))
	game.button(box, "마을로 돌아가기", game.show_hub)

func transfer(gems: bool, deposit: bool, index: int) -> void:
	var next: Dictionary = game.profile.duplicate(true)
	var error := Storage.transfer(next, gems, deposit, index)
	if not error.is_empty(): game.notify(error); return
	if game.commit(next): show_stash()

func resource_bar(parent: Node, color: Color) -> ProgressBar:
	var progress := ProgressBar.new()
	progress.custom_minimum_size = Vector2(300, 12)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	progress.add_theme_stylebox_override("fill", fill)
	parent.add_child(progress)
	return progress

func add_filter(parent: Node, refresh: Callable) -> void:
	var option := OptionButton.new()
	option.add_item("모든 희귀도", 0)
	for name in game.rules.data.rarity_names: option.add_item(name)
	option.select(rarity_filter + 1)
	option.item_selected.connect(func(index): rarity_filter = index - 1; refresh.call())
	parent.add_child(option)

func ordered(entries: Array) -> Array:
	var indices: Array = []
	for i in range(entries.size()):
		if rarity_filter < 0 or int(entries[i].rarity) == rarity_filter: indices.append(i)
	indices.sort_custom(func(a, b):
		if int(entries[a].rarity) != int(entries[b].rarity): return int(entries[a].rarity) > int(entries[b].rarity)
		return str(entries[a].get("name", entries[a].get("id", ""))) < str(entries[b].get("name", entries[b].get("id", ""))))
	return indices

func show_shop() -> void:
	Storage.ensure(game.profile)
	var p: Dictionary = game.profile
	var box := begin("헤르메스의 시장", "골드 %d · 카드를 선택하세요. 구매 즉시 저장됩니다." % p.gold)
	var tabs := grid(box, 3)
	card(tabs, "운명의 뽑기\n가차", Color("d4a9f3"), func(): game.shop_tab = 0; show_shop())
	card(tabs, "원하는 권능\n확정 구매", Color("aadba2"), func(): game.shop_tab = 1; show_shop())
	card(tabs, "장비 판매", Color("dfc38a"), func(): game.shop_tab = 2; show_shop())
	if game.shop_tab == 0:
		var currency:=grid(box,2)
		card(currency,"%d 골드"%game.rules.gacha_cost(p)+(" · 선택됨" if not use_shards else ""),Color("dfbe82"),func():use_shards=false;show_shop())
		card(currency,"조각 %d개"%game.rules.gacha_cost(p,true)+(" · 선택됨" if use_shards else ""),Color("aadbef"),func():use_shards=true;show_shop())
		var weights:Array=game.rules.gacha_weights(p)
		var total:float=0
		for weight in weights:total+=weight
		var odds:="현재 획득 확률 · "
		for i in range(6):odds+=game.rules.data.rarity_names[i]+" %.2f%%  "%(weights[i]/total*100)
		game.text_line(box,"이번 레벨 뽑기 기회: %d / %d · 10레벨마다 한도 +1 (최대12) · 레벨업 시 충전, 이월 없음 · Lv100 최종 보스 +1회\n"%[int(p.get("gacha_left",3)),preload("res://src/domain/storage_rules.gd").gacha_limit(int(p.level))]+odds+"\n레벨·엔드게임 티어에 따라 상승 · 50회 보장: Lv1~19 마법+, Lv20~39 희귀+, Lv40+ 영웅+. 고등급도 필요 레벨 전까지 보관할 수 있습니다.")
		var cells := grid(box, 3)
		for kind in range(3):
			var index := kind
			card(cells, ("%s\n" + ("조각 %d개"%game.rules.gacha_cost(p,true) if use_shards else "%d 골드"%game.rules.gacha_cost(p)) + "\n보장까지 %d회") % [["장비 가차", "보조 젬 가차", "주스킬 가차"][kind], 50 - int(p.pity[kind])], Color("dfbe82"), func(): game.gacha(index,use_shards), (p.shards < game.rules.gacha_cost(p,true) if use_shards else p.gold < game.rules.gacha_cost(p)) or int(p.get("gacha_left",3))<=0 or (kind == 0 and p.items.size() >= 100))

		game.text_line(box,"무기 지정 가차 · 장비 가차와 비용/확률/보장 횟수 공유")
		var weapon_cells:=grid(box,4)
		for type in ["sword","spear","wand","bow"]:
			var weapon:String=type
			var entry:=card(weapon_cells,"",Color("dfbe82"),func():game.gacha(0,use_shards,weapon),(p.shards<game.rules.gacha_cost(p,true) if use_shards else p.gold<game.rules.gacha_cost(p)) or p.items.size()>=100 or int(p.get("gacha_left",3))<=0)
			iconify(entry,{"sword":"slash","spear":"spear_throw","wand":"wand","bow":"bow"}[weapon],game.rules.weapon_name(weapon)+" 가차")
	elif game.shop_tab == 1:
		game.text_line(box, "일반 등급 · 주스킬 150 골드 · 보조 젬 80 골드")
		var weapons:=grid(box,4)
		for kind in ["sword","spear","wand","bow"]:
			var type:String=kind
			card(weapons,game.rules.weapon_name(type)+" · 60 골드",Color("cdbfa4"),func():
				var next:Dictionary=p.duplicate(true);next.gold-=60
				next.items.append({"name":"연습용 "+game.rules.weapon_name(type),"slot":0,"rarity":0,"value":3,"unique":false,"weapon_type":type})
				if game.commit(next):show_shop(),p.gold<60 or p.items.size()>=100)
		var cells := grid(box,3)
		for id in game.rules.data.skills:
			var key := str(id)
			var cell := card(cells, game.rules.data.skills[key].name + "\n150 골드", game.rarity_color(0), func(): buy(key, true), key in p.skills or p.gold < 150)
			cell.tooltip_text = game.rules.data.skills[key].description
			shop_row(cell,key,game.rules.data.skills[key].name,"150 골드","보유 중 · 구매 불가" if key in p.skills else ("골드 부족 · %d 필요"%(150-p.gold) if p.gold<150 else ""))
		for id in game.rules.data.supports:
			var key := str(id)
			var cell := card(cells, game.rules.data.supports[key].name + "\n80 골드", game.rarity_color(0), func(): buy(key, false), p.gold < 80)
			cell.tooltip_text = game.rules.support_numbers({"id": key, "rarity": 0})
			shop_row(cell,key,game.rules.data.supports[key].name,"80 골드","골드 부족 · %d 필요"%(80-p.gold) if p.gold<80 else "")
	elif game.shop_tab == 2:
		game.text_line(box, "장착 장비 제외 · 일반~영웅 즉시 판매 · 전설/신화 확인 팝업")
		var bulk:=grid(box,3)
		for rank in range(6):
			var rarity:int=rank
			var amount:=0
			for i in range(p.items.size()):
				if i not in p.equipment and int(p.items[i].rarity)==rank:amount+=1
			card(bulk,"%s 일괄 판매\n%d개 · %d 골드"%[game.rules.data.rarity_names[rank],amount,amount*(12+rank*8)],game.rarity_color(rank),func():sell_rarity(rarity),amount==0)
		add_filter(box, show_shop)
		var cells := grid(box, 3)
		for i in ordered(p.items):
			var index:int=i
			var item:Dictionary=p.items[index]
			var cell := card(cells, str(item.name)+"\n%d 골드" % (12+int(item.rarity)*8), game.rarity_color(item.rarity), func(): confirm_sale(index), index in p.equipment)
			cell.tooltip_text=item_details(item)
			shop_row(cell,game.rules.item_icon(item),str(item.name),"%s · %d 골드"%[game.rules.data.rarity_names[int(item.rarity)],12+int(item.rarity)*8],"장착 중 · 판매 불가" if index in p.equipment else "")
	game.button(box, "미장착 일반·마법 장비 일괄 판매", game.sell_items)
	game.button(box, "마을로", game.show_hub)

func buy(id: String, primary: bool) -> void:
	var price := 150 if primary else 80
	if game.profile.gold < price or (primary and id in game.profile.skills): return
	var next: Dictionary = game.profile.duplicate(true)
	next.gold -= price
	if primary: game.rules.award_primary(next, id, 0)
	else: game.rules.award_gem(next, {"id": id, "rarity": 0})
	if game.commit(next): show_shop()

func restore_scroll(panel: Control, position: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(panel) and panel == game.modal:
		panel.get_child(0).scroll_vertical = position

func iconify(button: Button, key: String, status: String) -> void:
	button.text = ""
	button.icon=null
	button.icon_key = key
	button.badge = status
	button.custom_minimum_size.y = 60 if button.get("compact") else 92
	button.queue_redraw()

func equipment_skills(box: VBoxContainer) -> void:
	Storage.ensure(game.profile)
	game.text_line(box, "전투 스킬 — 아이콘을 눌러 배치와 보조 연결 변경")
	var slots := grid(box)
	for slot in range(6):
		var index := slot
		var id: String = game.profile.loadout[slot]
		var info: Dictionary = game.rules.ability_info(id)
		var rank:int=game.rules.skill_rank(game.profile,id) if game.rules.data.skills.has(id) else 0
		var b := card(slots, "", game.rarity_color(maxi(rank,0)), func(): selected_slot = index; show_skills())
		iconify(b, id if not id.is_empty() else "empty", ["좌클릭", "우클릭", "Q", "E", "R", "T"][slot]+(" · "+game.rules.data.rarity_names[rank] if game.rules.data.skills.has(id) and rank>=0 else ""))
		b.tooltip_text = str(info.get("name", "빈 슬롯")) + "\n" + str(info.get("description", "클릭하여 스킬 배치"))
	game.text_line(box, "유지형 버프 — 클릭하여 켜기 / 끄기 · 최대 2개 · 키 슬롯을 쓰지 않습니다.")
	var buffs := grid(box)
	for key in game.rules.data.buffs:
		var id := str(key)
		var info: Dictionary = game.rules.data.buffs[id]
		var b := card(buffs, "", Color("f4d17d"), func():
			var next: Dictionary = game.profile.duplicate(true)
			var error: String = game.rules.toggle_buff(next, id)
			if not error.is_empty(): game.notify(error); return
			if game.commit(next): show_inventory())
		iconify(b, "aura:" + id, "ON" if id in game.profile.buffs else "OFF")
		b.tooltip_text = info.name + "\n" + info.description + "\n현재 효과 %.1f%%"%(game.rules.buff_value(game.profile,id)*100)

func update_buff_icons() -> void:
	buff_row.visible = game.mode in ["town", "play", "pause"]
	var active_bursts:Array=[]
	for id in game.burst_timers:
		if game.burst_timers[id]>0:active_bursts.append(id)
	var signature := str(game.profile.get("buffs", [])) + str(game.stolen_affixes.keys())+str(active_bursts)
	if signature == buff_signature:
		for b in buff_row.get_children():
			if b.has_meta("burst"):b.badge="%.0fs"%game.burst_timers.get(b.get_meta("burst"),0);b.queue_redraw()
			if b.has_meta("affix"): b.badge = "%.0fs" % game.stolen_affixes.get(b.get_meta("affix"), 0); b.queue_redraw()
		return
	buff_signature = signature
	for child in buff_row.get_children(): buff_row.remove_child(child); child.queue_free()
	for id in game.profile.get("buffs", []):
		var b := card(buff_row, "", Color("ffe09c"), func(): pass)
		b.compact=true
		iconify(b, "aura:" + id, "ON")
		b.custom_minimum_size.x = 58
		b.tooltip_text = game.rules.data.buffs[id].name + "\n" + game.rules.data.buffs[id].description+"\n현재 효과 %.1f%%"%(game.rules.buff_value(game.profile,id)*100)
	for id in active_bursts:
		var b:=card(buff_row,"",Color("9cdfff"),func():pass)
		b.compact=true
		iconify(b,id,"%.0fs"%game.burst_timers[id])
		b.custom_minimum_size=Vector2(58,60)
		b.set_meta("burst",id)
		var info:Dictionary=game.rules.ability_info(id)
		b.tooltip_text=str(info.get("name",id))+"\n"+str(info.get("description",""))
	for id in game.stolen_affixes:
		var b := card(buff_row, "", Color("b2f3bc"), func(): pass)
		b.compact=true
		iconify(b, "burst:" + id, "12s")
		b.custom_minimum_size.x = 58
		b.set_meta("affix", id)
		b.tooltip_text = "탈취한 권능\n" + game.battle_extras.affix_name(id)

func ordered_gems(entries: Array) -> Array:
	var original := rarity_filter
	rarity_filter = gem_filter
	var result := ordered(entries)
	rarity_filter = original
	return result

func sale_popup(text:String,action:Callable)->void:
	var popup:=ConfirmationDialog.new()
	game.get_window().gui_embed_subwindows=true
	popup.title="판매 확인"
	popup.dialog_text=text
	popup.ok_button_text="판매"
	popup.cancel_button_text="취소"
	game.ui.add_child(popup)
	popup.confirmed.connect(func():action.call();popup.queue_free())
	popup.canceled.connect(popup.queue_free)
	popup.popup_centered(Vector2i(480,210))

func confirm_sale(index:int)->void:
	if index<0 or index>=game.profile.items.size():return
	var item:Dictionary=game.profile.items[index]
	var sell:=func():
		if game.sell_item(index):show_shop()
	if int(item.rarity)<4:sell.call()
	else:sale_popup(item_details(item)+"\n%d 골드에 판매하시겠습니까?"%(12+int(item.rarity)*8),sell)

func sell_rarity(rarity:int)->void:
	var amount:=0
	for i in range(game.profile.items.size()):
		if i not in game.profile.equipment and int(game.profile.items[i].rarity)==rarity:amount+=1
	if amount==0:return
	if rarity<4:game.sell_items(rarity)
	else:sale_popup("%s %d개를 %d 골드에 일괄 판매하시겠습니까?"%[game.rules.data.rarity_names[rarity],amount,amount*(12+rarity*8)],func():game.sell_items(rarity))

func show_codex()->void:
	var box:=begin("아테나의 권능 도감","미획득 권능도 확인할 수 있습니다. 주스킬은 레벨당 기본 대비 피해 +1.8%. 장비 등급 배율: 1 / 1.15 / 1.4 / 1.8 / 2.5 / 3.3")
	game.button(box,"스킬 배치로 돌아가기",show_skills)
	var tabs:=grid(box,3)
	for i in range(3):
		var index:int=i
		card(tabs,["주스킬","보조 젬","고유 장비"][i],Color("d5bb8c"),func():codex_tab=index;show_codex())
	var cells:=grid(box,6)
	if codex_tab==0:
		for id in game.rules.data.skills:
			var info:Dictionary=game.rules.data.skills[id]
			var cell:=card(cells,"",Color("d5bb8c"),func():pass)
			iconify(cell,id,"보유" if id in game.profile.skills else "미획득")
			cell.tooltip_text="%s\n%s\n기본 피해 %.0f → 레벨 %d 기준 %.0f (장비·능력치·젬 적용 전)"%[info.name,info.description,info.damage,game.profile.level,info.damage*(1+float(game.rules.data.progression.skill_per_level)*(game.profile.level-1))]
	elif codex_tab==1:
		for id in game.rules.data.supports:
			var cell:=card(cells,"",Color("9fc5d5"),func():pass)
			iconify(cell,id,"보유" if game.profile.gems.any(func(g):return g.id==id) else "미획득")
			cell.tooltip_text=str(game.rules.data.supports[id].name)+"\n"+str(game.rules.data.supports[id].description)
			for rarity in range(6):cell.tooltip_text+="\n"+game.rules.data.rarity_names[rarity]+" · "+game.rules.support_numbers({"id":id,"rarity":rarity})
	else:
		var names:Dictionary={"curse_hit":"하데스의 심판","shockwave_hit":"포세이돈의 진동","random_boon":"티케의 변덕","strength_damage":"헤라클레스의 맹세","intelligence_damage":"헤카테의 지혜","insight":"아테나의 통찰","gauntlet_impact":"헤라클레스의 주먹","precision":"아르테미스의 손길","wrath":"아레스의 전쟁창","heal":"아레스의 유산","area":"포세이돈의 창","double_projectiles":"히드라의 송곳니","guard":"아킬레우스의 갑주","frost":"보레아스의 외투","giant":"아틀라스의 어깨","dodge":"헤르메스의 날개","mana_regen":"아테나의 부엉이","headhunter":"프로테우스의 사슬"}
		for effect in names:
			var cell:=card(cells,str(names[effect]),Color("df9c52"),func():pass)
			cell.tooltip_text=str(names[effect])+" · "+("보유" if game.profile.items.any(func(i):return game.rules.item_effect(i)==effect) else "미획득")+"\n"+game.rules.effect_description({"unique":true,"effect":effect,"slot":0})+"\n장비 가차 / 몬스터 전리품"

func shop_row(button: Button,key: String,title: String,price: String,reason: String) -> void:
	button.text=""
	button.icon_key=key
	button.row_layout=true
	button.custom_minimum_size=Vector2(240,78)
	var labels:=VBoxContainer.new()
	labels.mouse_filter=Control.MOUSE_FILTER_IGNORE
	button.add_child(labels)
	labels.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	labels.offset_left=57;labels.offset_right=-8;labels.offset_top=8;labels.offset_bottom=-6
	for line in [title,price,reason]:
		if line.is_empty():continue
		var label:=Label.new()
		label.text=line
		label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		label.add_theme_font_size_override("font_size",14 if line==title else 12)
		label.add_theme_color_override("font_color",Color("ffb89d") if line==reason else (Color("eee2ce") if line==title else Color("c7b790")))
		labels.add_child(label)
	if not reason.is_empty():
		button.add_theme_stylebox_override("disabled",style(Color("302024"),Color("a86a59")))
		button.tooltip_text+="\n"+reason
	button.queue_redraw()

func attribute_label(parent:VBoxContainer,value:String)->void:
	var label:=Label.new()
	label.text=value
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)

func attribute_panel(parent:VBoxContainer)->void:
	attribute_label(parent,"능력치 · 남은 포인트 %d"%game.rules.free_attributes(game.profile))
	for i in range(3):
		var index:int=i
		attribute_label(parent,["힘","민첩","지능"][i]+" %d"%(10+int(game.profile.attributes[i])))
		var row:=HBoxContainer.new();parent.add_child(row)
		for value in [1,5,10]:
			var amount:int=value
			var b:Button=game.button(row,"+%d"%amount,func():
				var next:Dictionary=game.profile.duplicate(true)
				if game.rules.allocate_attributes(next,index,amount)>0 and game.commit(next):show_inventory(),game.rules.free_attributes(game.profile)==0)
			b.tooltip_text=game.rules.attribute_text(game.profile,index)+"\n남은 포인트만큼 배분합니다."
	var cost:int=game.rules.reset_attributes_cost(game.profile)
	game.button(parent,"스탯 초기화 · %d 골드"%cost,func():
		var next:Dictionary=game.profile.duplicate(true)
		if game.rules.reset_attributes(next) and game.commit(next):
			game.health=minf(game.health,game.rules.stats(game.profile).hp)
			game.mana=minf(game.mana,game.rules.stats(game.profile).mana)
			show_inventory(),game.profile.gold<cost or game.rules.free_attributes(game.profile)==(game.profile.level-1)*2)
