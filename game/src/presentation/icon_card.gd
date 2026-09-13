extends Button
var cooldown_remaining:=0.0
var cooldown_ratio:=0.0
var required_level:=0
var lock_reason:=""
var row_layout:=false
var compact:=false
var icon_key := ""
var badge := ""
var ink := Color.WHITE

func _make_custom_tooltip(for_text: String) -> Object:
	var panel := PanelContainer.new()
	var border := StyleBoxFlat.new()
	border.bg_color = Color("07151f")
	border.border_color = ink
	border.set_border_width_all(2)
	border.set_corner_radius_all(6)
	border.set_content_margin_all(16)
	border.shadow_color = Color(0, 0, 0, 0.65)
	border.shadow_size = 7
	panel.add_theme_stylebox_override("panel", border)
	var label := Label.new()
	label.text = for_text
	label.custom_minimum_size.x = 340
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 19)
	label.add_theme_color_override("font_color", Color("fff3dc"))
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Malgun Gothic", "Apple SD Gothic Neo", "Noto Sans CJK KR"])
	label.add_theme_font_override("font", font)
	panel.add_child(label)
	return panel

func _draw() -> void:
	if icon_key.is_empty(): return
	if compact and not row_layout:draw_set_transform(Vector2(size.x*.15,0),0,Vector2(.7,.7))
	var c := Vector2(size.x / 2, 45 if required_level>0 or not lock_reason.is_empty() else 31)
	if row_layout:
		c = Vector2.ZERO
		draw_set_transform(Vector2(29,size.y/2),0,Vector2(.58,.58))
	var color := ink if not disabled else ink.darkened(0.25)
	var glyph := icon_key.get_slice(":", 0)
	if icon_key=="aura:fire":glyph="flame"
	elif icon_key=="aura:ice":glyph="snowflake"
	elif icon_key=="aura:lightning":glyph="bolt"
	elif icon_key=="aura:might":glyph="weapon"
	elif icon_key=="aura:ward":glyph="armor"
	elif icon_key in ["aura:wind","burst:haste","burst:swift"]:glyph="move"
	elif icon_key in ["burst:rage","burst:fury"]:glyph="weapon"
	elif icon_key=="burst:volley":glyph="split"
	elif icon_key=="burst:titan":glyph="armor"
	if icon_key in ["siren_summon","hydra_summon"]:glyph="summon"
	elif icon_key=="trinity_spear":glyph="spear_thrust"
	elif icon_key=="minion_guard":glyph="armor"
	elif icon_key=="minion_haste":glyph="move"
	elif icon_key=="minion_blast":glyph="burst"
	elif icon_key=="minion_splash":glyph="area"
	match glyph:

		"flame":
			draw_colored_polygon(PackedVector2Array([c+Vector2(0,-28),c+Vector2(7,-8),c+Vector2(17,-16),c+Vector2(23,7),c+Vector2(11,24),c+Vector2(-9,25),c+Vector2(-22,11),c+Vector2(-15,-8),c+Vector2(-7,3)]),Color("ff9d48"))
			draw_colored_polygon(PackedVector2Array([c+Vector2(0,-7),c+Vector2(9,13),c+Vector2(0,23),c+Vector2(-9,13)]),Color("ffe99f"))
		"snowflake":
			for i in range(6):
				var direction:=Vector2.from_angle(i*TAU/6)
				draw_line(c,c+direction*26,Color("9adfff"),3)
				for side in [-1,1]:draw_line(c+direction*17,c+direction*17-direction.rotated(side*.8)*9,Color("9adfff"),2)
		"aura":
			draw_arc(c, 19, 0, TAU, 32, color, 3)
			for i in range(8):
				var v := Vector2.from_angle(i * TAU / 8)
				draw_line(c + v * 23, c + v * 28, color, 3)
			draw_circle(c, 8, color)
		"curse":
			draw_arc(c, 23, 0, PI, 20, color, 4)
			draw_arc(c, 23, PI, TAU, 20, color, 4)
			draw_circle(c, 9, color)
			for x in [-16, 0, 16]: draw_line(c + Vector2(x, 17), c + Vector2(x, 28), color, 3)
		"move":
			for i in range(3):
				draw_line(c + Vector2(-26, i * 12 - 17), c + Vector2(8, i * 6 - 6), color, 3)
			draw_polyline(PackedVector2Array([c + Vector2(5, -22), c + Vector2(26, 0), c + Vector2(5, 22)]), color, 5)
		"burst", "impact":
			for i in range(8):
				var v := Vector2.from_angle(i * TAU / 8)
				draw_line(c + v * 9, c + v * (27 if i % 2 == 0 else 19), color, 5)
		"summon":
			draw_circle(c + Vector2(0, -12), 13, color)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-11, 2), c + Vector2(11, 2), c + Vector2(24, 27), c + Vector2(-24, 27)]), color)
			for x in [-5, 5]: draw_circle(c + Vector2(x, -14), 3, Color("15373e"))
		"spell_echo", "melee_echo":
			for x in [-10, 10]: draw_arc(c + Vector2(x, 0), 17, -PI * 0.8, PI * 0.8, 24, color, 4)
		"pierce":
			draw_line(c + Vector2(0, 27), c + Vector2(0, -26), color, 4)
			for y in [-14, 0, 14]: draw_line(c + Vector2(-20, y), c + Vector2(20, y), color, 2)
		"empty":
			draw_line(c - Vector2(15, 0), c + Vector2(15, 0), color, 3)
			draw_line(c - Vector2(0, 15), c + Vector2(0, 15), color, 3)
		"slash", "knives", "weapon","sword_wave":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-13, 13), c + Vector2(11, -21), c + Vector2(20, -25), c + Vector2(18, -12), c + Vector2(-5, 18)]), color)
			draw_line(c + Vector2(-17, 6), c + Vector2(0, 23), Color("fff3cd"), 3)
			draw_line(c + Vector2(-10, 15), c + Vector2(-18, 25), color, 5)
			if icon_key == "knives":
				draw_line(c + Vector2(-24, 15), c + Vector2(0, -20), color, 4)
				draw_line(c + Vector2(3, 24), c + Vector2(27, -11), color, 4)

		"wand":
			draw_line(c+Vector2(-13,24),c+Vector2(10,-16),Color("bd9c66"),6)
			draw_colored_polygon(PackedVector2Array([c+Vector2(10,-29),c+Vector2(18,-15),c+Vector2(10,-5),c+Vector2(2,-15)]),Color("8fdcff"))
		"helmet":
			draw_arc(c,22,PI,TAU,24,color,8);draw_line(c+Vector2(-19,0),c+Vector2(-19,21),color,6);draw_line(c,c+Vector2(0,17),color,5)
		"gloves":
			draw_rect(Rect2(c+Vector2(-17,-2),Vector2(34,26)),color)
			for i in range(4):draw_line(c+Vector2(-13+i*8,1),c+Vector2(-13+i*8,-22),color,6)
		"boots":
			for side in [-1,1]:draw_line(c+Vector2(side*12,-22),c+Vector2(side*12,18),color,12);draw_line(c+Vector2(side*12,18),c+Vector2(side*12+8,18),color,12)
		"ring","necklace":
			draw_arc(c,19,0,TAU,28,color,4);draw_circle(c+Vector2(0,-19 if glyph=="ring" else 19),7,Color("91d8ed"))
		"armor":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-21, -20), c + Vector2(21, -20), c + Vector2(17, 10), c + Vector2(0, 25), c + Vector2(-17, 10)]), color)
			draw_line(c + Vector2(0, -15), c + Vector2(0, 17), Color("152632"), 4)
		"bow", "ice_arrow", "lightning_arrow", "fire_arrow", "arrow_rain":
			draw_arc(c + Vector2(-8, 0), 24, -PI / 2, PI / 2, 24, color, 4)
			draw_line(c + Vector2(-8, -24), c + Vector2(-8, 24), color, 2)
			draw_line(c + Vector2(-23, 0), c + Vector2(28, 0), Color("fff3cd"), 3)
		"bolt", "thunder":
			draw_colored_polygon(PackedVector2Array([c + Vector2(9, -26), c + Vector2(-18, 3), c + Vector2(-2, 3), c + Vector2(-10, 27), c + Vector2(21, -8), c + Vector2(5, -8)]), color)
			if icon_key == "thunder":
				draw_arc(c + Vector2(0, 20), 24, 0, PI, 24, color, 2)
		"blizzard":
			for ray in range(6):
				var v := Vector2.from_angle(ray * TAU / 6)
				draw_line(c, c + v * 25, color, 3)
				draw_line(c + v * 16, c + v * 11 + v.orthogonal() * 7, color, 2)
		"spear_thrust", "spear_throw","lightning_spear","fire_spear","ice_spear":
			draw_line(c+Vector2(-19,25),c+Vector2(15,-20),color,4)
			draw_colored_polygon(PackedVector2Array([c+Vector2(24,-29),c+Vector2(8,-19),c+Vector2(18,-12)]),color)
		"returning":
			draw_arc(c, 23, -PI * 0.7, PI * 0.7, 30, color, 4)
			draw_polyline(PackedVector2Array([c + Vector2(-20, 4), c + Vector2(-15, 20), c + Vector2(1, 16)]), color, 4)
		"whirl", "area", "lava_wave", "blade_orbit", "tidal_aura", "duration":
			for ring in range(3): draw_arc(c, 9 + ring * 8, ring, ring + PI * 1.6, 30, color, 3)
		"split", "fan", "chain":
			for ray in [-1, 0, 1]:
				var end := c + Vector2(ray * 22, -22)
				draw_line(c + Vector2(0, 22), end, color, 3)
				draw_circle(end, 4, color)
		_:
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -25), c + Vector2(22, -5), c + Vector2(12, 21), c + Vector2(-12, 21), c + Vector2(-22, -5)]), color)
			draw_line(c + Vector2(0, -18), c + Vector2(-7, 12), Color("fff3cd"), 3)
	var mark: String = {"aura:fire":"화","aura:ice":"냉","aura:lightning":"뇌","aura:might": "힘", "aura:ward": "방", "aura:wind": "속", "curse:vulnerability": "피", "curse:chains": "쇄", "curse:frailty": "약", "move:blink": "점", "move:leap": "도", "burst:rage": "격", "burst:haste": "속", "burst:volley": "산", "burst:swift": "속", "burst:fury": "격", "burst:titan": "거"}.get(icon_key, "")
	if not mark.is_empty() and not row_layout: draw_string(get_theme_font("font"), Vector2(size.x - 22, 18), mark, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)
	draw_set_transform(Vector2.ZERO)
	if required_level>0 or not lock_reason.is_empty():
		draw_rect(Rect2(1,1,size.x-2,18),Color("843c35"))
		draw_string(get_theme_font("font"),Vector2(0,14),((lock_reason+" · " if not lock_reason.is_empty() else "장착 불가 · ")+"Lv.%d"%required_level) if required_level>0 else lock_reason,HORIZONTAL_ALIGNMENT_CENTER,size.x,11,Color("fff0d6"))
	if cooldown_remaining>0:
		var center:=Vector2(size.x*.5,31)
		var fan:=PackedVector2Array([center])
		for step in range(33):fan.append(center+Vector2.from_angle(-PI/2+TAU*cooldown_ratio*step/32.0)*27)
		draw_colored_polygon(fan,Color(0,0,0,.78))
		draw_arc(center,27,-PI/2,-PI/2+TAU*cooldown_ratio,40,Color("e3be77"),3)
		draw_string(get_theme_font("font"),center+Vector2(-25,6),str(ceili(cooldown_remaining)),HORIZONTAL_ALIGNMENT_CENTER,50,22,Color.WHITE)
	if row_layout:return
	draw_string(get_theme_font("font"), Vector2(0, 74 if required_level>0 or not lock_reason.is_empty() else (55 if compact else 80)), badge, HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, color)
