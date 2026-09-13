extends RefCounted
var game
var mapping:Dictionary={}
var pending:=0
var back:Callable
var path:="user://controls.cfg"
const KEYS=[KEY_W,KEY_A,KEY_S,KEY_D,KEY_F,KEY_I,KEY_K,KEY_Q,KEY_E,KEY_R,KEY_T,KEY_SPACE,KEY_1,KEY_2,KEY_M]
const NAMES=["앞으로 이동","왼쪽 이동","뒤로 이동","오른쪽 이동","NPC 상호작용","가방 · 장비","주스킬 · 보조 젬","스킬 3","스킬 4","스킬 5","스킬 6","회피","체력 포션","마나 포션","효과음 켜기/끄기"]
func _init(g,config_path:String="user://controls.cfg")->void:
	game=g
	path=config_path
	var cfg:=ConfigFile.new()
	if cfg.load(path)==OK:
		var used:Array=[]
		for original in KEYS:
			var value:int=int(cfg.get_value("keys",str(original),original))
			if value<=0 or value==KEY_ESCAPE or value in used:mapping.clear();return
			mapping[original]=value;used.append(value)
func key(original:int)->int:return int(mapping.get(original,original))
func label(original:int)->String:return OS.get_keycode_string(key(original))
func slot_label(slot:int)->String:return ["좌클릭","우클릭"][slot] if slot<2 else label(KEYS[7+slot-2])
func matches(event:InputEventKey,original:int)->bool:return (event.physical_keycode if event.physical_keycode!=0 else event.keycode)==key(original)
func pressed(original:int)->bool:return Input.is_physical_key_pressed(key(original))
func save()->void:
	var cfg:=ConfigFile.new()
	for original in KEYS:cfg.set_value("keys",str(original),key(original))
	cfg.save(path)
func assign(original:int,value:int)->bool:
	if value<=0 or value==KEY_ESCAPE:return false
	for other in KEYS:
		if other!=original and key(other)==value:return false
	mapping[original]=value;save();return true
func capture(event:InputEvent)->bool:
	if pending==0:return false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:pending=0;show_panel(back)
		elif assign(pending,event.physical_keycode if event.physical_keycode!=0 else event.keycode):pending=0;show_panel(back)
		else:game.notify("이미 사용 중이거나 지정할 수 없는 키입니다. 다른 키를 누르세요.")
	return true
func show_panel(return_to:Callable)->void:
	back=return_to
	if game.mode=="town":game.mode="hub"
	elif game.mode=="play":game.mode="pause"
	var box=game.panel("조작 안내 · 키 설정","변경할 항목을 누른 뒤 새 키를 누르세요. Esc: 변경 취소 / 메뉴 닫기 · 좌/우클릭: 스킬 1/2 (고정)")
	var grid:=GridContainer.new();grid.columns=3;box.add_child(grid)
	for i in range(KEYS.size()):
		var original:int=KEYS[i]
		game.button(grid,NAMES[i]+" ["+label(original)+"]",func():pending=original;game.notify("새 키를 누르세요 · Esc 취소"))
	game.button(box,"기본 키로 초기화",func():mapping.clear();save();show_panel(back))
	game.button(box,"돌아가기",func():pending=0;back.call())
