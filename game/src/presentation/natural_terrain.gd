extends RefCounted
var view
func _init(v)->void:view=v
func material(tint:Color)->ShaderMaterial:
	var shader:=Shader.new()
	shader.code="shader_type spatial; render_mode cull_disabled; uniform vec4 tint:source_color; varying vec3 p; float hash(vec2 x){return fract(sin(dot(x,vec2(127.1,311.7)))*43758.5453);} float noise(vec2 x){vec2 i=floor(x);vec2 f=fract(x);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);} void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;} void fragment(){float n=noise(p.xz*1.7)*.6+noise(p.xz*8.)*.25+noise(p.xz*45.)*.15; ALBEDO=tint.rgb*mix(.65,1.15,n); ROUGHNESS=.96;}"
	var mat:=ShaderMaterial.new()
	mat.shader=shader
	mat.set_shader_parameter("tint",tint)
	return mat
func town()->void:
	var corners:=PackedVector2Array([Vector2(0,-1.3),Vector2(3,-1.8),Vector2(8,-1.5),Vector2(12.8,-1),Vector2(14,2),Vector2(13.6,6),Vector2(13,9),Vector2(9,9.6),Vector2(3,9.5),Vector2(-1,7),Vector2(-1.7,3),Vector2(-.8,1)])
	var points:=PackedVector2Array()
	for i in range(corners.size()):
		var a:=corners[i]
		var b:=corners[(i+1)%corners.size()]
		for j in range(5):points.append(a.lerp(b,j/5.0)+(b-a).normalized().orthogonal()*sin(i*4+j*2.1)*.16)
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var indices:=Geometry2D.triangulate_polygon(points)
	for index in indices:surface.add_vertex(Vector3(points[index].x,-.05,points[index].y))
	surface.generate_normals()
	var ground:MeshInstance3D=view.mesh(view.terrain,surface.commit(),Vector3.ZERO,Color("77725e"))
	ground.material_override=material(Color("77725e"))
	for i in range(points.size()):
		var a:=points[i]
		var b:=points[(i+1)%points.size()]
		var p:Vector2=(a+b)*.5
		var edge:MeshInstance3D=view.box(view.terrain,Vector3(p.x,-.28,p.y),Vector3(.28,.46,a.distance_to(b)+.08),Color("625e4c"))
		edge.rotation.y=atan2(b.x-a.x,b.y-a.y)
		if i%3==0:
			var rock:=SphereMesh.new()
			rock.radius=.22;rock.height=.3;rock.radial_segments=12;rock.rings=6
			view.mesh(view.terrain,rock,Vector3(p.x,-.07,p.y),Color("79796c"))
	shore_detail(points)
	volcano()
func volcano(origin:Vector3=Vector3(-2.0,-.4,.1),size_factor:float=1.0)->void:
	# Background landmark beyond the walkable northwestern shore.
	var original_parent:Node3D=view.terrain
	var mountain_root:=Node3D.new()
	original_parent.add_child(mountain_root)
	mountain_root.position=origin
	mountain_root.scale=Vector3.ONE*size_factor
	origin=Vector3.ZERO
	var mountain:=CylinderMesh.new()
	mountain.bottom_radius=2.1
	mountain.top_radius=.65
	mountain.height=2.5
	mountain.radial_segments=32
	var mountain_node:MeshInstance3D=view.mesh(mountain_root,mountain,origin+Vector3(0,1.25,0),Color("484641"))
	mountain_node.material_override=material(Color("484641"))
	var crater:=TorusMesh.new()
	crater.inner_radius=.45;crater.outer_radius=.8
	view.mesh(mountain_root,crater,origin+Vector3(0,2.5,0),Color("352d2a"))
	var lava:=CylinderMesh.new()
	lava.top_radius=.49;lava.bottom_radius=.49;lava.height=.025
	var glow:MeshInstance3D=view.mesh(mountain_root,lava,origin+Vector3(0,2.38,0),Color("cb673e"))
	var mat:=StandardMaterial3D.new()
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color=Color("cb673e")
	glow.material_override=mat
	for i in range(4):
		var smoke:=SphereMesh.new()
		smoke.radius=.23+i*.07;smoke.height=.3+i*.08
		view.mesh(mountain_root,smoke,origin+Vector3(i*.14,2.7+i*.35,0),Color("62615e"))

func island_foundation(stage:Dictionary={})->void:
	var extent:=29.5
	for polygon in stage.get("polygons",[]):
		for pair in polygon:
			if pair[0]<8000:extent=maxf(extent,Vector2(pair[0]*.01-30,pair[1]*.01-30).length()+1.5)
	var points:=PackedVector2Array()
	for i in range(96):
		var angle:float=i*TAU/96
		var radius:float=extent+sin(angle*7)*.8+sin(angle*13)*.35
		points.append(Vector2(30,30)+Vector2.from_angle(angle)*radius)
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in Geometry2D.triangulate_polygon(points):surface.add_vertex(Vector3(points[index].x,-.2,points[index].y))
	surface.generate_normals()
	var node:MeshInstance3D=view.mesh(view.terrain,surface.commit(),Vector3.ZERO,Color("4e4a40"))
	node.material_override=material(Color("4e4a40"))
	for i in range(0,96,3):
		var rock:=SphereMesh.new()
		rock.radius=.65;rock.height=.5;rock.radial_segments=12;rock.rings=6
		view.mesh(view.terrain,rock,Vector3(points[i].x,-.1,points[i].y),Color("635f52"))
	shore_detail(points)

func shore_detail(points:PackedVector2Array)->void:
	for i in range(0,points.size(),2):
		var p:=points[i]
		for j in range(3):
			var shape:=SphereMesh.new();shape.radius=1;shape.height=2;shape.radial_segments=12;shape.rings=6
			var rock:MeshInstance3D=view.mesh(view.terrain,shape,Vector3(p.x+sin(i+j)*.22,-.18,p.y+cos(i*2+j)*.25),Color("666151"))
			rock.scale=Vector3(.18+j*.08,.12+j*.07,.25)
			rock.rotation=Vector3(i*.2,j*.9,i*.13)

func journey_scenery(stage:Dictionary)->void:
	var theme:int=stage.journey_theme
	for zone in range(stage.centers.size()):
		var c:=Vector3(float(stage.centers[zone][0])*.01,0,float(stage.centers[zone][1])*.01)
		if theme==5 and zone<stage.centers.size()-1:
			view.box(view.terrain,c+Vector3(0,-.18,0),Vector3(9.8,.35,7.6),Color("533d29"))
			for side in [-1,1]:
				view.box(view.terrain,c+Vector3(0,.28,side*3.7),Vector3(9.7,.55,.12),Color("6f4c2e"))
				view.cylinder(view.terrain,c+Vector3(side*3,1.5,2.5),.09,3.0,Color("80603d"))
				view.box(view.terrain,c+Vector3(side*3,2.2,2.5),Vector3(1.5,1.1,.03),Color("9a8c74"))
		elif theme in [3,4] or zone==stage.centers.size()-1:
			for side in [-1,1]:
				for end in [-1,1]:
					var p:Vector3=c+Vector3(side*4.9,0,end*3.9)
					view.cylinder(view.terrain,p+Vector3(0,1.1,0),.5 if theme==4 else .24,2.2,Color("777268"))
					view.box(view.terrain,p+Vector3(0,2.3,0),Vector3(.85,.18,.85),Color("8c8370"))
				if theme==4:
					view.box(view.terrain,c+Vector3(side*4.9,.65,0),Vector3(.2,1.3,6),Color("69685d"))
