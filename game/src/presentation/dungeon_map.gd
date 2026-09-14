extends Control
var game
var cached_key:=""
var cached_layout:Dictionary={}
func _ready()->void:
	position=Vector2(1060,100);size=Vector2(204,150)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=true
func _process(_delta:float)->void:
	visible=game.mode in ["play","pause"]
	if visible:queue_redraw()
func layout_data()->Dictionary:
	var stage:Dictionary=game.active_stage()
	var arena:bool=stage.get("journey",false) and game.player.x>9000
	var key:String=str(stage.name)+str(arena)+str(size)
	if key==cached_key:return cached_layout
	cached_key=key
	var indices:Array=[]
	for i in range(stage.centers.size()):
		if stage.get("journey",false) and (i==stage.centers.size()-1)!=arena:continue
		indices.append(i)
	var roads:Array=[] if arena else stage.roads
	var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
	for i in indices:
		for pair in stage.polygons[i]:
			var p:=Vector2(pair[0],pair[1]);low=low.min(p);high=high.max(p)
	for road in roads:
		for pair in road:
			var p:=Vector2(pair[0],pair[1]);low=low.min(p);high=high.max(p)
	var available:Vector2=(size-Vector2(40,40)).max(Vector2.ONE)
	var span:Vector2=(high-low).max(Vector2.ONE)
	var scale_:float=minf(available.x/span.x,available.y/span.y)
	cached_layout={"indices":indices,"roads":roads,"low":low,"scale":scale_,"origin":size*.5-span*scale_*.5}
	return cached_layout
func project_point(p:Vector2,data:Dictionary)->Vector2:
	return data.origin+(p-data.low)*data.scale
func _draw()->void:
	if not visible:return
	var stage:Dictionary=game.active_stage();var data:Dictionary=layout_data()
	draw_style_box(game.camp_ui.style(Color(.025,.06,.09,.9),Color("9b875e")),Rect2(Vector2.ZERO,size))
	for index in data.indices:
		var outline:=PackedVector2Array()
		for pair in stage.polygons[index]:outline.append(project_point(Vector2(pair[0],pair[1]),data))
		if outline.size()>2:
			outline.append(outline[0]);draw_polyline(outline,Color("344851"),1)
	for road in data.roads:
		var points:=PackedVector2Array()
		for pair in road:points.append(project_point(Vector2(pair[0],pair[1]),data))
		if points.size()>1:draw_polyline(points,Color("76848a"),2)
	for i in data.indices:
		var p:=project_point(Vector2(stage.centers[i][0],stage.centers[i][1]),data)
		var tint:=Color("64d3a3") if i in game.profile.cleared else (Color("ffd77e") if i==game.profile.cleared.size() else Color("77818a"))
		draw_circle(p,5,tint)
		draw_string(game.ui.theme.default_font,p+Vector2(-4,-8),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,12,tint)
	var player:Vector2=project_point(game.player,data).clamp(Vector2(7,7),size-Vector2(7,7))
	draw_circle(player,4,Color.WHITE)
