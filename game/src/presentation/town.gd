extends Node2D
var game
var position_in_town := Vector2(640, 450)
var font := SystemFont.new()
var hero: Texture2D
var phase := 0.0
var direction := 1.0
var places := [
	{"p": Vector2(340, 310), "name": "헤르메스", "role": "시장 · 가차", "action": "shop", "color": Color("d6ac61")},
	{"p": Vector2(890, 280), "name": "아테나의 사제", "role": "스킬 · 보조 젬", "action": "skills", "color": Color("7bbdbc")},
	{"p": Vector2(320, 520), "name": "마을 보관함", "role": "장비 · 젬 보관", "action": "stash", "color": Color("bc9460")},
	{"p": Vector2(970, 535), "name": "항해사", "role": "해안으로 출항", "action": "sail", "color": Color("c98976")}
]

func _ready() -> void:
	font.font_names = PackedStringArray(["Malgun Gothic", "Apple SD Gothic Neo", "Noto Sans CJK KR"])
	hero = load("res://assets/characters/odysseus.png")

func nearby() -> int:
	var best := -1
	var distance := 105.0
	for i in range(places.size()):
		var d := position_in_town.distance_to(places[i].p)
		if d < distance:
			distance = d
			best = i
	return best

func interact() -> void:
	var index := nearby()
	if index < 0: return
	match places[index].action:
		"shop": game.show_shop()
		"skills": game.show_skills()
		"stash": game.camp_ui.show_stash()
		"sail": game.show_destinations()

func _physics_process(delta: float) -> void:
	if not visible or game.mode != "town": return
	var move := Vector2(float(game.controls.pressed(KEY_D)) - float(game.controls.pressed(KEY_A)), float(game.controls.pressed(KEY_S)) - float(game.controls.pressed(KEY_W))).normalized()
	position_in_town += move * 310 * delta
	position_in_town = position_in_town.clamp(Vector2(100, 80), Vector2(1200, 760))
	if move.length_squared() > 0:
		phase += delta * 12
		if move.x != 0: direction = signf(move.x)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-1000, -1000, 4000, 3000), Color("163e48"))
	draw_colored_polygon(PackedVector2Array([Vector2(130, 300), Vector2(650, 95), Vector2(1190, 290), Vector2(1110, 640), Vector2(420, 700), Vector2(155, 545)]), Color("a69b76"))
	draw_line(Vector2(250, 490), Vector2(1010, 380), Color("c3b592"), 115)
	draw_line(Vector2(635, 250), Vector2(655, 610), Color("c3b592"), 110)
	# Market canopy and small marble shrine.
	draw_rect(Rect2(255, 180, 160, 74), Color("765945"))
	draw_colored_polygon(PackedVector2Array([Vector2(230, 205), Vector2(340, 135), Vector2(450, 205), Vector2(410, 235), Vector2(255, 235)]), Color("a65a43"))
	for x in [805, 855, 905, 955]:
		draw_rect(Rect2(x, 160, 17, 75), Color("ddd0aa"))
	draw_colored_polygon(PackedVector2Array([Vector2(780, 165), Vector2(887, 102), Vector2(985, 165)]), Color("c4b591"))
	# Fountain and dock.
	draw_set_transform(Vector2(640, 310), 0, Vector2(1, 0.5))
	draw_circle(Vector2.ZERO, 48, Color("d8c9a1"))
	draw_circle(Vector2.ZERO, 36, Color("4b8d98"))
	draw_set_transform(Vector2.ZERO)
	for x in range(1050, 1230, 22): draw_line(Vector2(x, 470), Vector2(x, 565), Color("876748"), 19)
	for place in places:
		var p: Vector2 = place.p
		if place.action == "stash":
			draw_rect(Rect2(p + Vector2(-29, -34), Vector2(58, 34)), Color("6e4e31"))
			draw_rect(Rect2(p + Vector2(-29, -37), Vector2(58, 10)), Color("b38b4f"))
			draw_rect(Rect2(p + Vector2(-5, -24), Vector2(10, 12)), Color("e3c978"))
		else:
			draw_circle(p + Vector2(0, -48), 10, Color("cba478"))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-13, -37), p + Vector2(12, -37), p + Vector2(20, 0), p + Vector2(-20, 0)]), place.color)
		draw_string(font, p + Vector2(-52, 25), place.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("fff1cc"))
		draw_string(font, p + Vector2(-58, 46), place.role, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e1d4af"))
	draw_set_transform(position_in_town + Vector2(0, sin(phase) * 2), 0, Vector2(direction, 1))
	draw_texture_rect(hero, Rect2(-34, -88, 68, 98), false)
	draw_set_transform(Vector2.ZERO)
	var near := nearby()
	if near >= 0:
		var p: Vector2 = places[near].p
		draw_arc(p, 38, 0, TAU, 32, Color("f9d880"), 2)
		draw_string(font, position_in_town + Vector2(-42, -110), "[F] 상호작용", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("fff1aa"))
