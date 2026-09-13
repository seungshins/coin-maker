extends RefCounted
var camp
var game
func _init(owner_camp)->void:
	camp=owner_camp
	game=camp.game
func tile(parent:Node,item:Dictionary,callback:Callable,selected:bool=false)->Button:
	var b:=preload("res://src/presentation/equipment_tile.gd").new()
	b.slot=int(item.slot)
	b.weapon_type=str(item.get("weapon_type","sword"))
	b.ink=game.rarity_color(int(item.rarity))
	b.equipped=selected
	b.tooltip_text=camp.item_details(item)
	b.add_theme_stylebox_override("normal",camp.style(Color("0b1320"),b.ink.darkened(.25)))
	b.add_theme_stylebox_override("hover",camp.style(Color("24313e"),b.ink))
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func paperdoll(box:VBoxContainer)->void:
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",16);box.add_child(row)
	var equipment:=PanelContainer.new();equipment.custom_minimum_size.x=530;equipment.add_theme_stylebox_override("panel",camp.style(Color("10171d"),Color("766448")));row.add_child(equipment)
	var left:=VBoxContainer.new();equipment.add_child(left)
	camp.attribute_label(left,"장비 · 슬롯 클릭으로 해제")
	var body:=Control.new();body.custom_minimum_size=Vector2(505,375);left.add_child(body)
	var portrait:=TextureRect.new();portrait.texture=load("res://assets/characters/odysseus.png");portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.position=Vector2(170,25);portrait.size=Vector2(150,230);portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE;body.add_child(portrait)
	var positions:Array=[Vector2(25,72),Vector2(203,92),Vector2(406,180),Vector2(203,0),Vector2(112,95),Vector2(203,192),Vector2(112,192),Vector2(310,192),Vector2(310,15),Vector2(25,285),Vector2(112,285),Vector2(203,285)]
	for slot in range(12):
		var index:int=game.profile.equipment[slot];var selected_slot:int=slot
		var item:Dictionary=game.profile.items[index] if index>=0 else {"slot":0 if slot>=9 else slot,"weapon_type":{9:"spear",10:"wand",11:"bow"}.get(slot,"sword"),"rarity":0,"name":game.rules.slot_name(slot),"value":0,"unique":false}
		var cell:=tile(body,item,func():
			var next:Dictionary=game.profile.duplicate(true);next.equipment[selected_slot]=-1
			if game.commit(next):camp.show_inventory(),index>=0)
		cell.position=positions[slot];cell.size=Vector2(72,82);cell.disabled=index<0
		cell.tooltip_text=game.rules.slot_name(slot)+" · 빈 슬롯" if index<0 else camp.item_details(item)
	var stats:Dictionary=game.rules.stats(game.profile)
	camp.attribute_label(left,"전체 효과 · 선택 스킬 무기 피해 +%.1f\n최대 체력 %.0f · 방어도 %.0f (피해 감소 %.1f%%)\n공격·시전 속도 ×%.2f · 이동 %.0f"%[stats.damage,stats.hp,stats.armor,stats.armor_reduction*100,stats.speed,stats.move])
	var panel:=PanelContainer.new();panel.custom_minimum_size.x=310;panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.add_theme_stylebox_override("panel",camp.style(Color("15171e"),Color("766448")));row.add_child(panel)
	var right:=VBoxContainer.new();panel.add_child(right);camp.attribute_panel(right)

func bag(parent:Node,entries:Array,deposit:bool=true,stash:bool=false)->void:
	var board:=Control.new()
	parent.add_child(board)
	var occupied:Dictionary={}
	var rows:=5
	var columns:=16
	for i in camp.ordered(entries):
		var index:int=i
		var item:Dictionary=entries[index]
		var footprint:Vector2i=[Vector2i(1,3),Vector2i(2,2),Vector2i(1,1),Vector2i(2,2),Vector2i(2,2),Vector2i(2,2),Vector2i(1,1),Vector2i(1,1),Vector2i(1,1)][int(item.slot)]
		var found:=Vector2i.ZERO
		for y in range(400):
			var done:=false
			for x in range(columns-footprint.x+1):
				var free:=true
				for dy in range(footprint.y):
					for dx in range(footprint.x):
						if occupied.has(Vector2i(x+dx,y+dy)): free=false
				if free: found=Vector2i(x,y);done=true;break
			if done: break
		for dy in range(footprint.y):
			for dx in range(footprint.x): occupied[found+Vector2i(dx,dy)]=true
		rows=maxi(rows,found.y+footprint.y)
		var callback:=func():
			if stash: camp.transfer(false,deposit,index)
			else:
				var next:Dictionary=game.profile.duplicate(true)
				next.equipment[game.rules.equip_slot(next,item)]=index
				if game.commit(next): camp.show_inventory()
		var cell:=tile(board,item,callback,deposit and index in game.profile.equipment)
		cell.position=Vector2(found)*52+Vector2.ONE
		cell.size=Vector2(footprint)*52-Vector2.ONE*2
	board.custom_minimum_size=Vector2(columns*52,rows*52)
	board.draw.connect(func():
		board.draw_rect(Rect2(Vector2.ZERO,board.size),Color("090e13"))
		for x in range(columns+1): board.draw_line(Vector2(x*52,0),Vector2(x*52,board.size.y),Color("443e30"))
		for y in range(rows+1): board.draw_line(Vector2(0,y*52),Vector2(board.size.x,y*52),Color("443e30")))
