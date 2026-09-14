extends SceneTree
var failures:=0
func check(ok:bool,msg:String):
 if not ok:failures+=1;printerr(msg)
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false);await process_frame
 g.profile=g.rules.new_profile();g.profile.level=60;g.profile.buffs=[];g.minions.clear()
 var combat=g.battle_extras.minion_combat
 combat.summon({"id":"summon","damage":100,"duration":15})
 var m:Dictionary=g.minions[0];var hp:float=m.hp
 check(is_equal_approx(hp,g.rules.stats(g.profile).hp*1.25),"base summon health")
 combat.receive_damage(m,100);check(is_equal_approx(hp-m.hp,75),"base reduction")
 m.hp=hp;g.profile.buffs=["ward"];combat.receive_damage(m,100);check(hp-m.hp<75,"ward shared")
 g.profile.buffs=["wind"];check(combat.move_multiplier()>1,"wind shared")
 g.profile.buffs=["might"];check(combat.attack_damage(m)>100,"live might applied")
 g.profile.buffs=[];check(is_equal_approx(combat.attack_damage(m),100),"might removal no stacking")
 m.hp=hp;g.battle_extras.intercept(m.p-Vector2(20,0),m.p+Vector2(20,0),100);check(is_equal_approx(hp-m.hp,75),"projectile respects reduction")
 g.minions.clear();combat.summon({"id":"summon","damage":100,"minion_hp":3.3,"minion_dr":.4})
 var guarded:Dictionary=g.minions[0];check(guarded.max_hp>hp*3 and guarded.dr>.5,"guard strong survival")
 var map=preload("res://src/presentation/dungeon_map.gd").new();map.game=g;g.ui.add_child(map)
 for variant in range(6):
  g.profile.tier=12;g.profile.map_index=variant
  for arena in [false,true]:
   g.player=Vector2(10000,10000) if arena else Vector2.ZERO
   var data:Dictionary=map.layout_data()
   for i in data.indices:
    for pair in g.active_stage().polygons[i]:check(Rect2(Vector2(19,19),map.size-Vector2(38,38)).has_point(map.project_point(Vector2(pair[0],pair[1]),data)),"minimap all terrain inside")
 g.queue_free();await process_frame
 if failures==0:print("PASS minions: health/DR/projectiles/live buffs/guard; minimap six layouts and arena bounds")
 quit(failures)
