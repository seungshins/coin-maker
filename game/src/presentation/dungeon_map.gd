extends Control
var game
func _ready() -> void:
	position = Vector2(1060, 100)
	size = Vector2(204, 150)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(_delta: float) -> void:
	visible = game.mode in ["play", "pause"]
	if visible: queue_redraw()
func _draw() -> void:
	if not visible: return
	var stage: Dictionary = game.active_stage()
	var centers:Array=stage.centers
	var roads:Array=stage.roads
	if stage.get("journey",false):
		centers=[stage.centers.back()] if game.player.x>9000 else stage.centers.slice(0,stage.centers.size()-1)
		if game.player.x>9000:roads=[]
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for pair in centers:
		var p := Vector2(pair[0], pair[1])
		low = low.min(p)
		high = high.max(p)
	var scale_ := minf(164.0 / maxf(1, high.x - low.x), 110.0 / maxf(1, high.y - low.y))
	var origin := Vector2(20, 20)
	draw_style_box(game.camp_ui.style(Color(0.025, 0.06, 0.09, 0.90), Color("9b875e")), Rect2(Vector2.ZERO, size))
	for road in roads:
		var points := PackedVector2Array()
		for pair in road: points.append(origin + (Vector2(pair[0], pair[1]) - low) * scale_)
		draw_polyline(points, Color("76848a"), 2)
	for i in range(centers.size()):
		var p := origin + (Vector2(centers[i][0], stage.centers[i][1]) - low) * scale_
		var tint := Color("64d3a3") if i in game.profile.cleared else (Color("ffd77e") if i == game.profile.cleared.size() else Color("77818a"))
		draw_circle(p, 7, tint)
		draw_string(game.ui.theme.default_font, p + Vector2(-4, -10), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, tint)
	draw_circle(origin + (game.player - low) * scale_, 4, Color("ffffff"))
