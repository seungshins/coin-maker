extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.profile=g.rules.new_profile();g.profile.tier=12;g.profile.map_index=1;g.profile.level=80
 g.start_run();g.set_physics_process(false)
 while g.view3d.loading_models:await process_frame
 print("loading_finished mode=",g.mode)
 g.enemies.clear()
 for i in range(60):g.spawn_enemy(g.player+Vector2((i%10-5)*70,(i/10-3)*65),0,"satyr",1000,i)
 for i in range(45):await process_frame
 g.health=1000000;g.set_physics_process(true)
 var times:Array=[]
 for i in range(120):
  var start:int=Time.get_ticks_usec();await process_frame;times.append((Time.get_ticks_usec()-start)/1000.0)
 times.sort();print("60 enemy active frame ms median=",times[60]," p95=",times[114]," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("E:/workspace/.runtime/v20-crowd.png")
 g.enemies.clear();g.spawn_enemy(g.player+Vector2(150,0),0,"boss",10000,99);g.enemies[0].model="empusa";g.boss_combat.prepare(g.enemies[0],g.player)
 for i in range(6):await process_frame
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("E:/workspace/.runtime/v20-empusa.png")
 g.queue_free();await process_frame;quit()
