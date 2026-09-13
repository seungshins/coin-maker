extends RefCounted
var view
func _init(owner_view) -> void: view = owner_view
func height_at(p: Vector2) -> float:
	if view.game.town.visible or not view.game.world.visible: return 0.0
	if view.game.active_stage().get("journey",false) and (p.x>8000 or int(view.game.active_stage().journey_theme)!=0):return 0.0
	if view.game.active_stage().get("journey",false):return clampf((2800-p.distance_to(Vector2(3000,3000)))/550.0,0,4.3)
	var amplitude: float = view.game.active_stage().get("relief", 0)
	return amplitude * (0.5 + 0.28 * sin(p.x / 650.0) + 0.22 * sin(p.y / 720.0))

func triangle(surface: SurfaceTool, a: Vector2, b: Vector2, c: Vector2, depth: int) -> void:
	if depth > 0:
		var ab := (a+b)*0.5
		var bc := (b+c)*0.5
		var ca := (c+a)*0.5
		triangle(surface,a,ab,ca,depth-1)
		triangle(surface,ab,b,bc,depth-1)
		triangle(surface,ca,bc,c,depth-1)
		triangle(surface,ab,bc,ca,depth-1)
		return
	for p in [a,b,c]: surface.add_vertex(view.point(p))

func build() -> void:
	var stage: Dictionary = view.game.active_stage()
	view.box(view.terrain, Vector3(50,-0.7,30), Vector3(250,0.4,180), Color(stage.sea))
	if stage.get("journey",false):
		if int(stage.journey_theme)!=5:view.natural.island_foundation(stage)
		if int(stage.journey_theme)==0:view.natural.volcano(Vector3(30,-.4,30),2.0)
		view.natural.journey_scenery(stage)
	for polygon in stage.polygons:
		var points := PackedVector2Array()
		for p in polygon: points.append(Vector2(p[0],p[1]))
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var indices := Geometry2D.triangulate_polygon(points)
		for i in range(0,indices.size(),3): triangle(surface,points[indices[i]],points[indices[i+1]],points[indices[i+2]],3)
		surface.generate_normals()
		var ground := StandardMaterial3D.new()
		ground.albedo_color = Color(stage.ground)
		ground.cull_mode = BaseMaterial3D.CULL_DISABLED
		var node := MeshInstance3D.new()
		node.mesh = surface.commit()
		node.material_override = view.natural.material(Color(stage.sand).lightened(.1))
		view.terrain.add_child(node)
		# Visible cliff sides run from the sampled coast edge down to sea level.
		for i in range(points.size()):
			var a := points[i]
			var b := points[(i+1)%points.size()]
			var count := maxi(1,ceili(a.distance_to(b)/35))
			for step in range(count):
				var start := a.lerp(b,float(step)/count)
				var end := a.lerp(b,float(step+1)/count)
				var center := (start+end)*0.5
				var height := height_at(center)+0.55
				var side: MeshInstance3D = view.box(view.terrain,Vector3(center.x*.01,height/2-.55,center.y*.01),Vector3(.08,height,start.distance_to(end)*.01+.01),Color(stage.sand).darkened(.2))
				side.rotation.y = atan2(end.x-start.x,end.y-start.y)
	for road in stage.roads:
		for i in range(road.size()-1): bridge(Vector2(road[i][0],road[i][1]),Vector2(road[i+1][0],road[i+1][1]),float(stage.road_width))
	for rock in stage.rocks:
		var shape := SphereMesh.new()
		shape.radius = 1
		shape.height = 2
		shape.radial_segments = 7
		shape.rings = 3
		var node: MeshInstance3D = view.mesh(view.terrain,shape,view.point(Vector2(rock[0],rock[1]),.15),Color("78766a"))
		node.scale = Vector3(rock[2]*.01,.65,rock[2]*.01)

func on_land(p: Vector2) -> bool:
	for polygon in view.game.active_stage().polygons:
		var points := PackedVector2Array()
		for pair in polygon: points.append(Vector2(pair[0],pair[1]))
		if Geometry2D.is_point_in_polygon(p,points): return true
	return false

func bridge(a: Vector2,b: Vector2,width: float) -> void:
	var count := maxi(1,ceili(a.distance_to(b)/24))
	var side := (b-a).normalized().orthogonal()
	for i in range(count):
		var p := a.lerp(b,(i+.5)/count)
		var land:bool = on_land(p) or (view.game.active_stage().get("journey",false) and int(view.game.active_stage().journey_theme)!=5)
		var deck: MeshInstance3D = view.box(view.terrain,view.point(p,.025),Vector3(width*.02,.055,a.distance_to(b)/count*.01+.025),Color(view.game.active_stage().sand) if land else Color("97754e"))
		deck.rotation.y = atan2(b.x-a.x,b.y-a.y)
		if land: continue
		for edge in [-1,1]:
			var rail_p: Vector2 = p + side * (width-3)*edge
			var rail: MeshInstance3D = view.box(view.terrain,view.point(rail_p,.43),Vector3(.035,.065,a.distance_to(b)/count*.01+.025),Color("775839"))
			rail.rotation.y = deck.rotation.y
			if i%3 == 0: view.cylinder(view.terrain,view.point(rail_p,.25),.045,.55,Color("755239"))
		if i%5 == 0:
			var height := height_at(p)+.6
			view.cylinder(view.terrain,Vector3(p.x*.01,height/2-.55,p.y*.01),.12,height,Color("68513b"))
