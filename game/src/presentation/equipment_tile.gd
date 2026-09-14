extends "res://src/presentation/icon_card.gd"
var comparison_cards:Array=[]
var slot := 0
var weapon_type:="sword"
var equipped := false
func _draw() -> void:
	var c:=size*Vector2(.5,.45)
	var color:=ink
	var scale_:float=minf(size.x/65,size.y/100)

	if slot==0 and weapon_type=="bow":
		var length_:float=minf(size.y*.32,46)
		draw_arc(c+Vector2(-13,0),length_,-PI/2,PI/2,32,Color("b18c55"),5)
		draw_line(c+Vector2(-13,-length_),c+Vector2(-13,length_),Color("dfd5ad"),2)
		draw_line(c+Vector2(-24,0),c+Vector2(28,0),color,3)
		draw_colored_polygon(PackedVector2Array([c+Vector2(33,0),c+Vector2(23,-5),c+Vector2(23,5)]),color)
	elif slot==0 and weapon_type=="wand":
		draw_line(c+Vector2(-11,27),c+Vector2(8,-12),Color("b99562"),7)
		draw_arc(c+Vector2(10,-17),12,0,TAU,20,color,3)
		draw_colored_polygon(PackedVector2Array([c+Vector2(10,-35),c+Vector2(18,-18),c+Vector2(10,-5),c+Vector2(2,-18)]),Color("7dcaff"))
	elif slot==0 and weapon_type=="spear":
		var length_:float=size.y*.34
		draw_line(c+Vector2(0,length_),c+Vector2(0,-length_+15),Color("ac8853"),5)
		draw_colored_polygon(PackedVector2Array([c+Vector2(0,-length_-8),c+Vector2(-8,-length_+19),c+Vector2(0,-length_+14),c+Vector2(8,-length_+19)]),Color("d6e4df"))
	elif slot==0:
		var length_:float=size.y*.32
		draw_colored_polygon(PackedVector2Array([c+Vector2(-5,length_),c+Vector2(-5,-length_),c+Vector2(0,-length_-13),c+Vector2(7,-length_),c+Vector2(5,length_)]),Color("d2d6cb"))
		draw_line(c+Vector2(0,-length_),c+Vector2(0,length_),Color("faf1cb"),2)
		draw_line(c+Vector2(-18,length_-3),c+Vector2(18,length_-3),color,5)
		draw_line(c+Vector2(0,length_),c+Vector2(0,length_+24),Color("875c3b"),7)
	elif slot==1:
		var points:=PackedVector2Array([Vector2(-18,-30),Vector2(-32,-18),Vector2(-25,0),Vector2(-19,28),Vector2(19,28),Vector2(25,0),Vector2(32,-18),Vector2(18,-30),Vector2(8,-20),Vector2(-8,-20)])
		for i in range(points.size()): points[i]=points[i]*scale_+c
		draw_colored_polygon(points,color.darkened(.22))
		draw_line(c+Vector2(0,-18)*scale_,c+Vector2(0,23)*scale_,color,4)
		for side in [-1,1]: draw_arc(c+Vector2(side*11,-1)*scale_,13*scale_,0,PI,20,Color("e4ca8f"),3)

	elif slot==3:
		draw_arc(c,22,PI,TAU,24,color,9);draw_line(c+Vector2(-19,0),c+Vector2(-19,20),color,7);draw_line(c+Vector2(19,0),c+Vector2(19,20),color,7);draw_line(c,c+Vector2(0,18),color,5)
	elif slot==4:
		draw_style_box(get_theme_stylebox("normal"),Rect2(c+Vector2(-17,-5),Vector2(34,28)))
		for i in range(4):draw_line(c+Vector2(-13+i*8,2),c+Vector2(-13+i*8,-22),color,6)
	elif slot==5:
		for side in [-1,1]:
			draw_line(c+Vector2(side*12,-22),c+Vector2(side*12,18),color,13);draw_line(c+Vector2(side*12,18),c+Vector2(side*12+9,18),color,12)
	elif slot in [6,7,8]:
		draw_arc(c,18,0,TAU,32,color,4);draw_circle(c+Vector2(0,-18 if slot!=8 else 18),7,Color("83cddd"))
	else:
		draw_arc(c,18,0,TAU,30,Color("c6a365"),3)
		for side in [-1,1]:
			for feather in range(4): draw_line(c+Vector2(side*8,0),c+Vector2(side*(20+feather*5),-14+feather*7),color,3)
		draw_circle(c,6,color)
	if slot>0:draw_string(get_theme_font("font"),Vector2(2,size.y-5),["","흉갑","유물","투구","장갑","신발","반지","반지","목걸이"][slot],HORIZONTAL_ALIGNMENT_CENTER,size.x-4,11,color)
	if equipped: draw_string(get_theme_font("font"),Vector2(4,17),"장착",HORIZONTAL_ALIGNMENT_LEFT,-1,12,color)

func _make_custom_tooltip(for_text:String)->Object:
	if comparison_cards.is_empty():return super._make_custom_tooltip(for_text)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12)
	for text in comparison_cards:
		var card:=PanelContainer.new();var border:=StyleBoxFlat.new();border.bg_color=Color("0b131d");border.border_color=ink;border.set_border_width_all(2);border.set_content_margin_all(14);card.add_theme_stylebox_override("panel",border)
		var label:=Label.new();label.text=text;label.custom_minimum_size.x=280;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",16);label.add_theme_color_override("font_color",Color("fff0d2"));card.add_child(label);row.add_child(card)
	return row
