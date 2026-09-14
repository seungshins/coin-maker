extends SceneTree
var failures:=0
func check(ok:bool,msg:String)->void:
	if not ok:failures+=1;printerr(msg)
func _initialize()->void:call_deferred("run")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);await process_frame
	g.view3d.set_process(false);g.profile=g.rules.new_profile();preload("res://src/domain/storage_rules.gd").ensure(g.profile)
	g.mode="play";g.town.visible=false;g.world.visible=true;g.world.configure();g.player=g.world.centers[0];g.aim=Vector2.RIGHT;g.mana=1000;g.dodge=0
	g.enemies.clear();g.spawn_enemy(g.player+Vector2(40,0),0,"satyr",10000,1)
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;event.position=Vector2.ZERO
	var started:int=Time.get_ticks_usec();g._unhandled_input(event);var elapsed:int=Time.get_ticks_usec()-started
	check(g.enemies[0].hp<10000 and g.attack_flash>0,"click applies melee damage and pose immediately")
	check(not Input.use_accumulated_input,"input not accumulated until next render frame")
	var fx:Dictionary={"kind":"slash","p":g.player,"life":.2,"radius":120,"arc":150,"angle":0}
	g.view3d.draw_effect(fx,100);g.view3d.draw_effect(fx,101)
	var a:MeshInstance3D=g.view3d.ornaments.fx100blade_arc;var b:MeshInstance3D=g.view3d.ornaments.fx101blade_arc
	check(a.mesh==b.mesh,"slash geometry shared across effect indices")
	check(a.material_override.shader==b.material_override.shader,"slash shader shared")
	a.material_override.set_shader_parameter("fade",.3);b.material_override.set_shader_parameter("fade",.8)
	check(a.material_override.get_shader_parameter("fade")!=b.material_override.get_shader_parameter("fade"),"each effect keeps independent fade")
	print("Melee input handler CPU microseconds=",elapsed)
	g.queue_free();await process_frame
	if failures==0:print("PASS latency21: immediate input damage, shared resources, independent animation")
	quit(failures)
