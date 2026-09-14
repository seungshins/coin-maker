extends SceneTree
const Storage=preload("res://src/domain/storage_rules.gd")
var failures:=0
func check(ok:bool,msg:String):
 if not ok:failures+=1;printerr(msg)
func old_walkable(stage:Dictionary,p:Vector2,through:int)->bool:
 for z in range(stage.polygons.size()):
  if through>=0 and z>through:continue
  var points:=PackedVector2Array()
  for pair in stage.polygons[z]:points.append(Vector2(pair[0],pair[1]))
  if Geometry2D.is_point_in_polygon(p,points):return true
 for index in range(stage.roads.size()):
  if through>=0 and maxi(stage.connections[index][0],stage.connections[index][1])>through:continue
  var road:Array=stage.roads[index]
  for i in range(road.size()-1):
   if Geometry2D.get_closest_point_to_segment(p,Vector2(road[i][0],road[i][1]),Vector2(road[i+1][0],road[i+1][1])).distance_to(p)<stage.road_width:return true
 return false
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);await process_frame
 g.view3d.set_process(false);g.profile=g.rules.new_profile()
 for level in [1,10,30,60,90,100]:
  var p:Dictionary=g.rules.new_profile();p.level=level;p.gacha_level=level;p.gacha_left=1;p.erase("gacha_capacity")
  Storage.ensure(p);check(p.gacha_left==Storage.gacha_limit(level)-2,"preserve spent opportunities")
  var left:int=p.gacha_left;Storage.ensure(p);check(p.gacha_left==left,"no refill on repeated ensure")
  p.gacha_left=0;p.level+=1;Storage.ensure(p);check(p.gacha_left==Storage.gacha_limit(p.level),"level refill")
 var rng:=RandomNumberGenerator.new();rng.seed=20
 for variant in range(6):
  g.profile.tier=12;g.profile.map_index=variant;g.world.configure()
  for i in range(400):
   var p:=Vector2(rng.randf_range(-500,11000),rng.randf_range(-500,7000));var through:int=i%7-1
   check(g.world.walkable(p,through)==old_walkable(g.world.stage,p,through),"collision parity")
 g.enemies.clear();g.profile.stage_id=1
 g.spawn_enemy(Vector2.ZERO,0,"satyr",100,3);g.spawn_enemy(Vector2.ZERO,0,"satyr",100,7)
 check(g.enemies[0].model=="shade" and g.enemies[1].model=="ember_priest" and g.enemies[1].kind=="archer","new enemy roster")
 var e:Dictionary={"p":Vector2.ZERO,"model":"empusa"};g.boss_combat.prepare(e,Vector2(100,0))
 check(e.boss_attack=="flame_fan" and e.windup>=1,"boss readable fire fan")
 g.bolts.clear();g.boss_combat.strike(e);check(g.bolts.size()==5 and g.bolts[0].skill_id=="fire_arrow","boss fire projectiles")
 g.boss_combat.prepare(e,Vector2(100,0));check(e.boss_attack=="slam" and not g.boss_combat.contains(e,Vector2(400,0)),"boss slam can be dodged")
 for kind in ["satyr","shade","ember_priest","empusa"]:
  var actor:Node3D=g.view3d.actor("enemy_test_"+kind,Color.WHITE,kind=="empusa",kind);g.view3d.pose(actor,.5,false)
  check(actor.has_node("Model/Arm1/Elbow/Hand"),"batch preserves hand joints")
 g.queue_free();await process_frame
 if failures==0:print("PASS v20: collision parity, gacha migration/refill, new enemies, boss patterns, merged joints")
 quit(failures)
