extends RefCounted
const Storage = preload("res://src/domain/storage_rules.gd")
var camp
var game
var category := 0
var list_scroll: ScrollContainer
var scroll_positions := {}
var displayed_category := 0
func _init(owner_camp) -> void:
	camp = owner_camp
	game = camp.game

func label(parent: Node, text: String) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", 16)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(node)
	return node

func select_slot(slot: int) -> void:
	camp.selected_slot = slot
	camp.selected_support = 0
	category = 4 if game.rules.data.skills.has(game.profile.loadout[slot]) else 0
	show_panel()

func show_panel() -> void:
	if is_instance_valid(list_scroll): scroll_positions[displayed_category] = list_scroll.scroll_vertical
	var p: Dictionary = game.profile
	Storage.ensure(p)
	var selected: String = p.loadout[camp.selected_slot]
	var primary: bool = game.rules.data.skills.has(selected)
	if primary: p.skill = selected; Storage.ensure(p)
	var box: VBoxContainer = camp.begin("아테나의 전당 · 스킬과 보조 젬", "")
	game.button(box,"권능 도감 · 미획득 스킬과 고유 장비",camp.show_codex)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 22)
	box.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(402, 435)
	columns.add_child(left)
	label(left, "① 장착된 키 선택 → 오른쪽에서 교체 / 보조 연결")
	var slots: GridContainer = camp.grid(left, 3)
	for slot in range(6):
		var index := slot
		var id: String = p.loadout[slot]
		var info: Dictionary = game.rules.ability_info(id)
		var rank:int=game.rules.skill_rank(p,id) if game.rules.data.skills.has(id) else 0
		var entry: Button = camp.card(slots, "", game.rarity_color(maxi(0,rank)), func(): select_slot(index))
		entry.custom_minimum_size.x = 124
		camp.iconify(entry, id if not id.is_empty() else "empty", game.controls.slot_label(slot) + " · "+(game.rules.data.rarity_names[rank] if rank>=0 else "잠김") + (" ✓" if slot == camp.selected_slot else ""))
		entry.tooltip_text = str(info.get("name", "빈 슬롯")) + " · "+(game.rules.data.rarity_names[rank] if rank>=0 else "레벨 부족")+ "\n" + str(info.get("description", "오른쪽 목록에서 스킬을 배치하세요."))
		if game.rules.data.skills.has(id) and not game.rules.weapon_allows(p,id):
			entry.lock_reason="필요: "+game.rules.weapon_name(game.rules.required_weapon(id))
			entry.custom_minimum_size.y=92
	var clear: Button = game.button(left, "선택한 키 슬롯 비우기", func():
		if game.actions.assign(camp.selected_slot, ""): category = 0; show_panel())
	clear.custom_minimum_size.y = 30
	label(left, "② " + (game.rules.data.skills[selected].name + " · 보조 연결" if primary else "주스킬을 장착한 키에서 보조 연결 가능"))
	var links: GridContainer = camp.grid(left, 2)
	for slot in range(6):
		var index := slot
		var unlocked: bool = primary and slot < game.rules.slots(p)
		var text := "보조 %d · " % (slot + 1)
		var tooltip := "주스킬 전용 보조 연결"
		if not unlocked: text += "Lv.%d" % [1, 5, 15, 30, 60, 85][slot] if primary else "주스킬 전용"
		elif slot < p.supports.size():
			var gem: Dictionary = p.gems[int(p.supports[slot])]
			text += game.rules.data.supports[gem.id].name
			tooltip = text + "\n" + game.rules.support_numbers(gem)
		else: text += "빈 연결"
		var link: Button = camp.card(links, text + (" ✓" if camp.selected_support == slot else ""), Color("9bd5cc"), func(): camp.selected_support = index; category = 4; show_panel(), not unlocked)
		link.set("compact",true)
		var gem_id:String="empty"
		if unlocked and slot<p.supports.size():
			gem_id=str(p.gems[int(p.supports[slot])].id)
			link.set("ink",game.rarity_color(int(p.gems[int(p.supports[slot])].rarity)))
		camp.iconify(link,gem_id,text)
		link.custom_minimum_size = Vector2(191, 60)
		link.tooltip_text = tooltip
	var unlink: Button = game.button(left, "선택한 보조 연결 비우기", func(): game.clear_support_link(camp.selected_support), not primary or camp.selected_support >= p.supports.size())
	unlink.custom_minimum_size.y = 30
	var unlink_all:Button=game.button(left,"이 주스킬의 보조 젬 모두 해제",func():
		var next:Dictionary=game.profile.duplicate(true)
		next.skill_supports[selected]=[]
		Storage.ensure(next)
		if game.commit(next):show_panel(),not primary or p.supports.is_empty())
	unlink_all.custom_minimum_size.y=30
	if primary:
		var spec: Dictionary = game.rules.skill_spec(p)
		label(left, "피해 %.1f · 간격 %.2f초 · 투사체 %d" % [spec.damage, spec.interval, spec.projectiles])
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(458, 435)
	columns.add_child(right)
	var tabs := OptionButton.new()
	for title in ["주스킬 · 선택한 키에 장착", "저주", "이동기", "즉발 버프", "보조 젬 · 선택한 주스킬에 연결"]: tabs.add_item(title)
	tabs.select(category)
	tabs.item_selected.connect(func(index): category = index; show_panel())
	right.add_child(tabs)
	var filter := OptionButton.new()
	filter.add_item("모든 희귀도")
	for rarity in game.rules.data.rarity_names: filter.add_item(rarity)
	filter.select((camp.gem_filter if category == 4 else camp.rarity_filter) + 1)
	filter.disabled = category in [1, 2, 3]
	filter.item_selected.connect(func(index):
		if category == 4: camp.gem_filter = index - 1
		else: camp.rarity_filter = index - 1
		show_panel())
	right.add_child(filter)
	list_scroll = ScrollContainer.new()
	list_scroll.custom_minimum_size = Vector2(458, 345)
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(list_scroll)
	var library: GridContainer = camp.grid(list_scroll, 4)
	library.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if category == 4:
		var candidates: Array = []
		var incompatible: Array = []
		for i in camp.ordered_gems(p.gems):
			if primary and (i in p.supports or game.rules.support_compatible(p.gems[i].id, selected)): candidates.append(i)
			else: incompatible.append(i)
		candidates.append_array(incompatible)
		candidates.sort_custom(func(a,b):return int(p.gems[a].rarity)>int(p.gems[b].rarity) if int(p.gems[a].rarity)!=int(p.gems[b].rarity) else int(a)<int(b))
		for i in candidates:
			var index: int = i
			var gem: Dictionary = p.gems[i]
			var linked: bool = primary and i in p.supports
			var compatible: bool = primary and game.rules.support_compatible(gem.id, selected)
			var entry: Button = camp.card(library, "", game.rarity_color(gem.rarity), func(): game.toggle_support(index), not linked and (not compatible or p.level<game.rules.gem_level(gem.rarity)))
			entry.set("compact",true)
			entry.custom_minimum_size.x=100
			camp.iconify(entry, gem.id, game.rules.data.supports[gem.id].name + (" ✓" if linked else "") + (" 잠김" if p.level<game.rules.gem_level(gem.rarity) else ""))
			if p.level<game.rules.gem_level(gem.rarity):
				entry.required_level=game.rules.gem_level(gem.rarity)
				entry.custom_minimum_size.y=82
				entry.add_theme_stylebox_override("disabled",camp.style(Color("302024"),Color("de937c")))
			if not compatible:
				entry.lock_reason="연결 불가" if primary else "주 스킬 선택 필요"
				entry.custom_minimum_size.y=82
				entry.add_theme_stylebox_override("disabled",camp.style(Color("302024"),Color("de937c")))
			entry.tooltip_text = game.rules.data.supports[gem.id].name + " · " + game.rules.data.rarity_names[int(gem.rarity)] + "\n" + game.rules.support_numbers(gem) + "\n필요 Lv.%d"%game.rules.gem_level(gem.rarity) + ("\n클릭하여 연결 / 해제" if compatible else "\n선택한 키의 스킬에 연결할 수 없습니다.")
	else:
		var keys: Array = []
		if category==0:
			for id in p.skills:
				for rank in p.skill_versions.get(id,[0]):keys.append({"id":id,"rarity":int(rank)})
		if category == 1:
			for key in game.rules.data.curses: keys.append("curse:" + key)
		elif category in [2, 3]:
			for key in game.rules.data.utility:
				if key.begins_with("move:" if category == 2 else "burst:"): keys.append(key)
		if category==0:keys.sort_custom(func(a,b):return int(a.rarity)>int(b.rarity) if int(a.rarity)!=int(b.rarity) else str(a.id)<str(b.id))
		for key in keys:
			var id:String=str(key.id) if key is Dictionary else str(key)
			var rarity:int=int(key.rarity) if key is Dictionary else 0
			if category == 0 and camp.rarity_filter >= 0 and rarity != camp.rarity_filter: continue
			var info: Dictionary = game.rules.ability_info(id)
			var entry: Button = camp.card(library, "", game.rarity_color(rarity), func():
				if category==0:
					var next:Dictionary=game.profile.duplicate(true)
					next.selected_skill_rarities[id]=rarity
					if not game.commit(next):return
				if game.actions.assign(camp.selected_slot, id):
					if game.rules.data.skills.has(id): category = 4
					show_panel(), category==0 and (p.level<game.rules.gem_level(rarity) or not game.rules.weapon_allows(p,id)))
			entry.set("compact",true)
			entry.custom_minimum_size.x=100
			camp.iconify(entry, id, info.name.substr(0, 9) + ("…" if info.name.length() > 9 else ""))
			if category==0 and p.level<game.rules.gem_level(rarity):
				entry.required_level=game.rules.gem_level(rarity)
				entry.custom_minimum_size.y=82
				entry.add_theme_stylebox_override("disabled",camp.style(Color("302024"),Color("de937c")))
			if category==0 and not game.rules.weapon_allows(p,id):
				entry.lock_reason="필요: "+game.rules.weapon_name(game.rules.required_weapon(id))
				entry.custom_minimum_size.y=82
				entry.add_theme_stylebox_override("disabled",camp.style(Color("302024"),Color("de937c")))
			entry.tooltip_text = ("필요 무기: "+game.rules.weapon_name(game.rules.required_weapon(id))+"\n" if category==0 else "")+info.name + " · "+game.rules.data.rarity_names[rarity]+"\n" + info.description + "\n필요 Lv.%d · 선택한 키에 장착"%game.rules.gem_level(rarity)
	displayed_category = category
	restore_list(list_scroll, int(scroll_positions.get(category, 0)))
	game.button(box, "마을로 돌아가기", game.show_hub)

func restore_list(scroll: ScrollContainer, offset: int) -> void:
	await camp.get_tree().process_frame
	await camp.get_tree().process_frame
	if is_instance_valid(scroll) and scroll == list_scroll: scroll.scroll_vertical = offset
