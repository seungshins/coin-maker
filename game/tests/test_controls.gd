extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_physics_process(false)
	var c=preload("res://src/presentation/controls.gd").new(g,"user://test_keys.cfg")
	c.mapping.clear()
	assert(c.assign(KEY_Q,KEY_U))
	assert(not c.assign(KEY_E,KEY_U))
	assert(not c.assign(KEY_E,KEY_ESCAPE))
	var loaded=preload("res://src/presentation/controls.gd").new(g,"user://test_keys.cfg")
	assert(loaded.key(KEY_Q)==KEY_U)
	var event:=InputEventKey.new();event.physical_keycode=KEY_U;event.pressed=true
	assert(loaded.matches(event,KEY_Q) and not loaded.matches(event,KEY_E))
	g.controls=loaded;g.profile=g.rules.new_profile();g.start_run()
	g.profile.loadout[2]="slash"
	var mana:float=g.mana;g._unhandled_input(event)
	assert(g.mana<mana)
	loaded.show_panel(g.show_hub)
	assert(g.mode=="pause")
	print("PASS: key persistence, duplicate/reserved rejection, remapped skill dispatch, paused capture UI")
	g.queue_free();await process_frame;quit()
