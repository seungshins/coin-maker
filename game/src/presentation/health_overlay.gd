extends Control
var view
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _process(_delta: float) -> void: queue_redraw()
func _draw() -> void:
	if view == null or not view.active() or view.game.mode != "play": return
	for marker in view.health_markers:
		if view.camera.is_position_behind(marker.p): continue
		var p: Vector2 = view.camera.unproject_position(marker.p)
		if p.x < 0 or p.x > size.x or p.y < 105 or p.y > size.y - 125: continue
		if p.x > size.x - 230 and p.y < 265: continue
		if p.x < 255 and p.y < 225: continue
		var boss: bool = marker.key.begins_with("boss")
		var width := 84.0 if boss else 46.0
		var height := 9.0 if boss else 7.0
		var rect := Rect2(p - Vector2(width / 2, height / 2), Vector2(width, height))
		draw_rect(rect.grow(2), Color("09151b"))
		draw_rect(rect, Color("522e2a"))
		draw_rect(Rect2(rect.position, Vector2(width * marker.ratio, height)), marker.color)
		draw_rect(rect.grow(1), Color("eee0ba") if boss else Color("cbbfa7"), false, 1.0)
