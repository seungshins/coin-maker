extends Button
var progress:=0.0
var charges:=2
var tint:=Color("b63b4b")
var key_label:="1"
func _draw()->void:
	var c:=size.x/2
	draw_style_box(get_theme_stylebox("normal"),Rect2(Vector2.ZERO,size))
	draw_rect(Rect2(c-8,5,16,9),Color("a18a62"))
	var outline:=PackedVector2Array([Vector2(c-7,14),Vector2(c+7,14),Vector2(c+7,24),Vector2(c+16,32),Vector2(c+16,57),Vector2(c-16,57),Vector2(c-16,32),Vector2(c-7,24),Vector2(c-7,14)])
	draw_colored_polygon(outline,Color("15232e"))
	var amount:=clampf((charges+progress)/2.0,0,1)*29
	if amount>0:draw_rect(Rect2(c-13,55-amount,26,amount),tint)
	draw_polyline(outline,Color("c8c8b9"),2,true)
	draw_line(Vector2(c-10,35),Vector2(c-10,50),Color(1,1,1,.5),2)
	draw_string(get_theme_font("font"),Vector2(0,76),"[%s] %d/2"%[key_label,charges],HORIZONTAL_ALIGNMENT_CENTER,size.x,13,Color("e8dcc6"))
