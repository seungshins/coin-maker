extends SceneTree
var failures:=0
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;printerr(message)
func _initialize()->void:call_deferred("run")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);await process_frame
	g.profile=g.rules.new_profile();g.start_run();g.clear_modal()
	var journey=load("res://src/domain/endgame_journey.gd")
	for theme in [1,2]:
		for tier in [1,6,12,16]:
			var stage:Dictionary=journey.build(g.stages[0],tier,theme)
			for zone in range(1,stage.centers.size()-1):
				var populated:Array=[false,false,false,false]
				for i in range(stage.counts[zone]):
					var p:Vector2=journey.enemy_position(stage,zone,i,stage.counts[zone])
					var closest:=INF;var nearest_index:=0
					for j in range(stage.roads[zone-1].size()):
						var pair:Array=stage.roads[zone-1][j];var next:Array=stage.roads[zone-1][mini(j+1,stage.roads[zone-1].size()-1)];var distance:float=p.distance_to(Geometry2D.get_closest_point_to_segment(p,Vector2(pair[0],pair[1]),Vector2(next[0],next[1])))
						if distance<closest:closest=distance;nearest_index=j
					check(closest<110,"enemy must stay inside road width")
					populated[mini(3,nearest_index/12)]=true
				check(not populated.has(false),"C/S road must contain enemies throughout all four quarters")
	g.enemies.clear();g.effects.clear();g.view3d.refresh(0)
	for kind in ["hero","satyr","cyclops"]:
		var actor:Node3D=g.view3d.actor("hero" if kind=="hero" else "enemy_verify_"+kind,Color.WHITE,false,kind)
		g.view3d.models.pose(actor,0,false)
		var knee:Node3D=actor.get_node("Model/LeftLeg/Knee")
		var before:float=knee.rotation.x
		g.view3d.models.pose(actor,PI/2,false)
		check(absf(knee.rotation.x-before)>.1,"knee articulation: "+kind)
		check(actor.has_node("Model/Arm1/Elbow"),"elbow articulation: "+kind)
	var hero:Node3D=g.view3d.actors.hero
	g.profile.items.append({"slot":0,"weapon_type":"spear","rarity":0,"value":1,"name":"spear"});g.profile.equipment[9]=g.profile.items.size()-1
	g.visual_weapon="spear";g.attack_flash=.1;g.view3d.models.pose(hero,0,false)
	check(hero.get_node("Model/Weapon/Spear").visible,"spear uses its weapon model")
	check(hero.get_node("Model/Weapon").global_position.distance_to(hero.get_node("Model/Arm1/Elbow/Hand").global_position)<.001,"weapon grip stays attached to hand during throw")
	g.queue_free();await process_frame
	if failures==0:print("PASS: C/S road coverage T1/6/12/16 and hero/satyr/cyclops joint motion")
	quit(failures)
