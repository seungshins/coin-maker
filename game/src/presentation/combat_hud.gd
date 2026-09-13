extends Control
var game
var hp_button:Button
var mp_button:Button
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in range(2):
		var b:=preload("res://src/presentation/potion_button.gd").new()
		b.position=Vector2(143+i*64,624)
		b.size=Vector2(58,80)
		b.tint=Color("b63b4b") if i==0 else Color("387eca")
		b.key_label=str(i+1)
		b.tooltip_text="체력 포션 [1]" if i==0 else "마나 포션 [2]"
		if i==0: hp_button=b;b.pressed.connect(game.use_potion)
		else: mp_button=b;b.pressed.connect(game.use_mana_potion)
		add_child(b)
func _process(_delta:float)->void:
	visible=game.mode in ["play","pause","town","hub","complete"]
	if not visible:return
	hp_button.key_label=game.controls.label(KEY_1)
	mp_button.key_label=game.controls.label(KEY_2)
	hp_button.set("charges",game.potions)
	hp_button.set("progress",game.potion_progress)
	hp_button.tooltip_text="체력 40%를 4초간 회복 · 처치로 충전 · 10초 재사용"
	hp_button.queue_redraw()
	mp_button.set("charges",game.mana_potions)
	mp_button.set("progress",game.mana_potion_progress)
	mp_button.tooltip_text="마나 50%를 4초간 회복 · 처치로 충전 · 8초 재사용"
	mp_button.queue_redraw()
	hp_button.disabled=game.mode!="play" or game.potions<=0 or game.potion_cd>0
	mp_button.disabled=game.mode!="play" or game.mana_potions<=0 or game.mana_potion_cd>0
	queue_redraw()
func globe(c:Vector2,ratio:float,color:Color)->void:
	draw_circle(c,61,Color("9d8258"))
	draw_circle(c,57,Color("131218"))
	var polygon:=PackedVector2Array()
	var cut:=55-110*clampf(ratio,0,1)
	for i in range(129):
		var p:=Vector2.from_angle(i*TAU/128)*54
		if p.y>=cut:polygon.append(c+p)
	if polygon.size()>=3:draw_colored_polygon(polygon,color)
	draw_arc(c,51,PI*1.05,PI*1.55,24,color.lightened(.4),3)
func _draw()->void:
	if game.profile.is_empty():return
	var font:=get_theme_default_font()
	var p:Dictionary=game.profile
	var stats:Dictionary=game.rules.stats(p)
	draw_rect(Rect2(275,68,730,34),Color(0.035,0.045,0.06,0.68))
	globe(Vector2(65,649),game.health/stats.hp,Color("a32939"))
	globe(Vector2(1215,649),game.mana/stats.mana,Color("285daa"))
	draw_string(font,Vector2(5,654),"%d / %d"%[maxf(game.health,0),stats.hp],HORIZONTAL_ALIGNMENT_CENTER,120,16)
	draw_string(font,Vector2(1155,654),"%d / %d"%[game.mana,stats.mana],HORIZONTAL_ALIGNMENT_CENTER,120,16)
	draw_string(font,Vector2(280,91),"Lv.%d · 골드 %d · 조각 %d    %s"%[p.level,p.gold,p.shards,game.active_stage().name],HORIZONTAL_ALIGNMENT_CENTER,720,16,Color("dacbaa"))
	draw_rect(Rect2(0,712,1280,7),Color("302b22"))
	draw_rect(Rect2(0,712,1280*clampf(float(p.xp)/game.rules.xp_needed(p.level),0,1),7),Color("b59b59"))
	draw_string(font,Vector2(275,700),"경험치 %d / %d"%[p.xp,game.rules.xp_needed(p.level)],HORIZONTAL_ALIGNMENT_CENTER,240,12,Color("ccbda0"))

	if game.mode=="play":
		var rare:=0;var bosses:=0
		for enemy in game.enemies:
			if enemy.dead or enemy.get("chest_guard",false) or int(enemy.zone)!=game.profile.cleared.size():continue
			if enemy.kind=="boss":bosses+=1
			elif enemy.get("elite",false):rare+=1
		var objective:="지역 Lv.%d · 경험치 %d%% · 희귀 %d · 보스 %d"%[game.rules.area_level(p,p.cleared.size()),roundi(game.rules.xp_rate(p,p.cleared.size())*100),rare,bosses]
		if game.portal_ready() and game.player.x<9000:objective="구역 완료 · 보라색 포탈로 진 보스에게 이동 ["+game.controls.label(KEY_F)+"]"
		draw_string(font,Vector2(300,116),objective,HORIZONTAL_ALIGNMENT_CENTER,680,14,Color("ffd38d"))
