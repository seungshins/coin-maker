extends Button
var character_name := ""
var character_level := 1
var valid_save := true
var create_new := false
var portrait: Texture2D = preload("res://assets/characters/odysseus.png")
func _ready() -> void:
	custom_minimum_size = Vector2(285, 285)
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var contents := VBoxContainer.new()
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contents.offset_left = 12
	contents.offset_top = 12
	contents.offset_right = -12
	contents.offset_bottom = -12
	contents.add_theme_constant_override("separation", 4)
	add_child(contents)
	var title := Label.new()
	title.text = "새로운 항해" if create_new else character_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_size_override("font_size", 22)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_child(title)
	if create_new:
		var plus := Label.new()
		plus.text = "+"
		plus.custom_minimum_size.y = 170
		plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plus.add_theme_font_size_override("font_size", 68)
		plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.add_child(plus)
	else:
		var image := TextureRect.new()
		image.texture = portrait
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.custom_minimum_size.y = 170
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.add_child(image)
	var footer := Label.new()
	footer.text = "캐릭터 생성" if create_new else "Lv.%d · %s" % [character_level, "항해 이어하기" if valid_save else "저장 확인 필요"]
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 17)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_child(footer)
