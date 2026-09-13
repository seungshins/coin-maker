extends RefCounted
var view
var materials:Dictionary={}
func _init(owner_view)->void: view=owner_view
func material(element:String)->ShaderMaterial:
	if materials.has(element): return materials[element]
	var shader:=Shader.new()
	var common:="shader_type spatial; render_mode unshaded, cull_disabled, blend_add, depth_draw_never; void fragment(){ vec2 p=UV-vec2(0.5); float a=0.; vec3 c=vec3(1.); "
	if element=="fire":
		common+="float wobble=0.035*sin(UV.y*22.-TIME*9.)+0.02*sin(UV.y*41.+TIME*13.); float w=0.035+0.35*UV.y; a=(1.-smoothstep(w-0.12,w,abs(p.x+wobble)))*(1.-smoothstep(0.83,1.,UV.y)); c=mix(vec3(1.,0.11,0.005),vec3(1.,0.92,0.22),clamp(1.-abs(p.x)/max(w,0.01),0.,1.));"
	elif element=="water":
		common+="float r=length(p); float wave=0.3+0.055*sin(atan(p.y,p.x)*7.-TIME*5.); a=(1.-smoothstep(0.015,0.08,abs(r-wave)))*0.8; c=vec3(0.12,0.65,0.92);"
	elif element=="ice":
		common+="float r=length(p); float angle=atan(p.y,p.x); float ray=pow(abs(cos(angle*3.)),18.); a=(ray*0.8+0.15)*(1.-smoothstep(0.32,0.48,r)); c=vec3(0.35,0.82,1.);"
	else:
		common+="float segment=UV.y*16.; float tick=floor(TIME*16.); float x=0.16*mix(sin(floor(segment)*9.7+tick),sin((floor(segment)+1.)*9.7+tick),fract(segment)); float d=abs(p.x-x); a=(1.-smoothstep(0.009,0.027,d))+(1.-smoothstep(0.02,0.10,d))*0.22; c=vec3(0.5,0.72,1.);"
	shader.code=common+" ALBEDO=c; EMISSION=c*1.3; ALPHA=clamp(a,0.,1.); }"
	var result:=ShaderMaterial.new()
	result.shader=shader
	materials[element]=result
	return result
func draw(key:String,p:Vector3,element:String,scale_:Vector2)->void:
	if element=="lightning":
		lightning(key,p-Vector3.UP*scale_.y*.5,p+Vector3.UP*scale_.y*.5,scale_.x)
		return
	var id:="element_"+key
	if not view.ornaments.has(id):
		var quad:=QuadMesh.new()
		quad.size=Vector2.ONE
		var node:=MeshInstance3D.new()
		node.mesh=quad
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		view.add_child(node)
		view.ornaments[id]=node
	var node:MeshInstance3D=view.ornaments[id]
	node.visible=true
	node.position=p
	node.scale=Vector3(scale_.x,scale_.y,1)
	node.material_override=material(element)
	node.look_at(view.camera.position,Vector3.UP)

func lightning(key:String,a:Vector3,b:Vector3,width:float=0.5)->void:
	var id:="lightning_mesh_"+key
	if not view.ornaments.has(id):
		var node:=MeshInstance3D.new()
		var mat:=StandardMaterial3D.new()
		mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color=Color("b9dcff")
		mat.emission_enabled=true;mat.emission=Color("568dff");mat.emission_energy_multiplier=2.2
		mat.cull_mode=BaseMaterial3D.CULL_DISABLED
		node.material_override=mat
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		view.add_child(node);view.ornaments[id]=node
	var node:MeshInstance3D=view.ornaments[id]
	node.visible=true
	var tick:int=int(view.clock*14)
	if node.get_meta("tick",-1)==tick and node.get_meta("a",Vector3.INF)==a and node.get_meta("b",Vector3.INF)==b:return
	node.set_meta("tick",tick);node.set_meta("a",a);node.set_meta("b",b)
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points:Array[Vector3]=[]
	for i in range(13):
		var t:float=i/12.0
		var jitter:=Vector3(sin(i*17.3+tick*7.1),sin(i*8.2+tick),cos(i*13.4+tick*3.7))*width*.3*sin(t*PI)
		points.append(a.lerp(b,t)+jitter)
	for i in range(12):
		lightning_segment(st,points[i],points[i+1],.022)
		if i in [3,6,9]:
			var fork:Vector3=points[i]+Vector3(sin(i+tick),.25,cos(i*3+tick))*.4
			lightning_segment(st,points[i],fork,.012)
			lightning_segment(st,fork,fork+(b-a).normalized()*.3+Vector3(.12,0,-.1),.006)
	node.mesh=st.commit()
func lightning_segment(st:SurfaceTool,a:Vector3,b:Vector3,r:float)->void:
	for axis in [Vector3.RIGHT,Vector3.FORWARD,Vector3.UP]:
		var d:Vector3=(b-a).cross(axis).normalized()*r
		for v in [a-d,a+d,b+d,a-d,b+d,b-d]:st.add_vertex(v)
