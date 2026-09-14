extends SceneTree
func _initialize():call_deferred("run")
func meshes(n:Node)->int:
 var count:int=1 if n is MeshInstance3D and n.visible else 0
 for c in n.get_children():count+=meshes(c)
 return count
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);await process_frame;g.view3d.set_process(false)
 g.profile=g.rules.new_profile();g.profile.tier=12;g.profile.map_index=2;g.world.configure()
 var t=Time.get_ticks_usec()
 for i in range(10000):g.world.walkable(Vector2(1800+i%1000,1200+i%1600))
 print("walkable_10000_ms=",(Time.get_ticks_usec()-t)/1000.0)
 t=Time.get_ticks_usec();var a=g.view3d.actor("enemy_benchmark",Color.WHITE,false,"satyr")
 print("satyr_meshes=",meshes(a)," build_ms=",(Time.get_ticks_usec()-t)/1000.0)
 g.queue_free();await process_frame;quit()