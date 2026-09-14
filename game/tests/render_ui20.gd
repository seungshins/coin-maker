extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.profile=g.rules.new_profile();g.profile.tier=12;g.profile.map_index=3;g.profile.level=60
 g.start_run();g.set_physics_process(false)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("E:/workspace/.runtime/v20-loading.png")
 while g.view3d.loading_models:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("E:/workspace/.runtime/v20-map.png")
 g.queue_free();await process_frame;quit()