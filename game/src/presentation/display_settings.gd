extends RefCounted
var game
const SIZES=[Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080),Vector2i(2560,1440)]
var selected:=0
var display_mode:=0
var ui_scale:=1.0
var zoom_factor:=1.0
var path:="user://display.cfg"
func _init(g)->void:game=g
func apply(index:int,save:bool=true)->void:
	selected=clampi(index,0,SIZES.size()-1)
	var window:Window=game.get_window()
	window.mode=Window.MODE_WINDOWED
	window.borderless=display_mode==1
	if display_mode==1:
		var area:=DisplayServer.screen_get_usable_rect(window.current_screen)
		window.position=area.position
		window.size=area.size
	elif display_mode==2:
		window.size=SIZES[selected]
		window.mode=Window.MODE_EXCLUSIVE_FULLSCREEN
	else:window.size=SIZES[selected]
	var height:float=float(window.size.y)
	ui_scale=clampf(1.0-(height-720.0)/3600.0,.8,1.0)
	zoom_factor=clampf(1.0+(height-720.0)/1800.0,1.0,1.4)
	window.content_scale_size=Vector2i(1280,720)
	window.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	apply_ui()
	if save:save_config()
func apply_ui()->void:
	if is_instance_valid(game.ui):
		game.ui.scale=Vector2.ONE*ui_scale
		game.ui.position=Vector2(640,360)*(1-ui_scale)
		var hud=game.ui.get_node_or_null("EdgeHUD")
		if hud!=null:
			hud.scale=Vector2.ONE/ui_scale
			hud.position=-game.ui.position/ui_scale
func save_config()->void:
	var config:=ConfigFile.new()
	config.set_value("display","resolution",selected)
	config.set_value("display","mode",display_mode)
	config.set_value("display","ui_scale",ui_scale)
	config.set_value("display","zoom",zoom_factor)
	var error:int=config.save(path)
	if error!=OK and is_instance_valid(game.toast):game.notify("화면 설정 저장 실패: %s"%error_string(error))
func restore()->void:
	var config:=ConfigFile.new()
	if config.load(path)!=OK:return
	display_mode=clampi(int(config.get_value("display","mode",0)),0,2)
	ui_scale=clampf(float(config.get_value("display","ui_scale",1)),.8,1.1)
	zoom_factor=clampf(float(config.get_value("display","zoom",1)),.85,1.5)
	apply(int(config.get_value("display","resolution",0)),false)
func choose_resolution(index:int)->void:
	apply(index)
func show_panel(back:Callable)->void:
	var box:VBoxContainer=game.panel("화면 설정","화면 크기에 맞춰 UI와 전장 범위를 자동 조정합니다. QHD: UI 80% · 전장 140%.")
	var modes:=HBoxContainer.new()
	box.add_child(modes)
	for index in range(3):
		var i:=index
		game.button(modes,["창 모드","전체 창 (테두리 없음)","전체 화면"][i]+(" ✓" if display_mode==i else ""),func():display_mode=i;apply(selected);show_panel(back))
	var sizes:=HBoxContainer.new()
	box.add_child(sizes)
	for index in range(SIZES.size()):
		var i:=index
		game.button(sizes,"%d × %d%s"%[SIZES[i].x,SIZES[i].y," ✓" if i==selected else ""],func():choose_resolution(i);show_panel(back))
	game.text_line(box,"전체 창은 작업 표시줄을 남기는 테두리 없는 창입니다. 전장 배율은 캐릭터·적·스킬에 함께 적용됩니다.")
	game.button(box,"장비 획득 필터",func():game.show_loot_filter(func():show_panel(back)))
	game.button(box,"조작 안내 · 키 설정",func():game.controls.show_panel(func():show_panel(back)))
	game.button(box,"돌아가기",back)
