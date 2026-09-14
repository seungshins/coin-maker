extends SceneTree
var failures:=0
func check(ok:bool,msg:String)->void:
	if not ok:failures+=1;printerr(msg)
func _initialize()->void:call_deferred("run")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);await process_frame
	g.profile=g.rules.new_profile();g.profile.level=100;g.profile.skills=g.rules.data.skills.keys();preload("res://src/domain/storage_rules.gd").ensure(g.profile);g.store.path="user://v19-test.json";g.save_blocked=false
	g.profile.gems=[{"id":"trigger","rarity":0}];g.profile.skill_supports.slash=[0];g.profile.loadout[0]="slash";g.camp_ui.selected_slot=0;g.show_skills()
	g.camp_ui.skill_panel.show_trigger_picker("slash");g.camp_ui.skill_panel.set_trigger("slash","bolt")
	check(g.profile.trigger_skills.slash=="bolt","cross weapon primary slot selection")
	check(g.store.load_profile().trigger_skills.slash=="bolt","trigger choice persists")
	g.camp_ui.skill_panel.set_trigger("slash","");check(g.profile.trigger_skills.slash.is_empty(),"clear primary trigger slot")
	g.camp_ui.show_inventory()
	var board:=Control.new();g.ui.add_child(board)
	var tile:Button=g.camp_ui.equipment_layout.tile(board,{"slot":0,"weapon_type":"sword","name":"test","value":10,"rarity":2,"unique":false},func():pass)
	var tooltip:Control=tile._make_custom_tooltip(tile.tooltip_text)
	check(tooltip.get_child_count()==2 and tooltip.get_child(0) is PanelContainer and tooltip.get_child(1) is PanelContainer,"two comparison cards")
	tooltip.free()
	g.mode="town";g.town.visible=true;g.view3d.refresh(0);var hero:Node3D=g.view3d.actors.hero
	for weapon in ["sword","spear","wand","bow"]:
		g.profile.primary_weapon=weapon;g.attack_flash=.12
		g.view3d.models.pose(hero,0,false)
		var left:Node3D=hero.get_node("Model/Arm-1");var right:Node3D=hero.get_node("Model/Arm1")
		check(absf(left.rotation.x)<.1 and absf(right.rotation.x)<.1,"town idle is not attacking: "+weapon)
		check(left.rotation.z<=0 and right.rotation.z>=0,"idle arms point outward: "+weapon)
	g.queue_free();await process_frame
	if failures==0:print("PASS v19: trigger picker/save/clear, two comparison cards, four weapon idle poses")
	quit(failures)
