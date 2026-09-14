extends RefCounted
var view
func _init(v)->void: view=v
func ellipsoid(parent:Node,p:Vector3,size_:Vector3,color:Color)->MeshInstance3D:
	var shape:=SphereMesh.new()
	shape.radius=1
	shape.height=2
	shape.radial_segments=40
	shape.rings=20
	var node:MeshInstance3D=view.mesh(parent,shape,p,color)
	node.scale=size_
	return node
func build(parent:Node3D)->void:
	parent.set_meta("model_kind","hero")
	var body:=Node3D.new()
	body.name="Model"
	parent.add_child(body)
	var skin:=Color("a66e50")
	var bronze:=Color("a47b35")
	var leather:=Color("422d27")
	ellipsoid(body,Vector3(0,.87,0),Vector3(.21,.29,.12),skin)
	for side in [-1,1]:
		ellipsoid(body,Vector3(side*.11,1.01,.055),Vector3(.125,.11,.11),skin)
		for j in range(3): ellipsoid(body,Vector3(side*.065,.88-j*.065,.105),Vector3(.068,.044,.028),skin.darkened(.08))
		var arm:=Node3D.new()
		arm.name="Arm%d"%side
		arm.position=Vector3(side*.245,1.04,0)
		body.add_child(arm)
		ellipsoid(arm,Vector3.ZERO,Vector3(.115,.115,.11),skin)
		ellipsoid(arm,Vector3(side*.025,-.14,0),Vector3(.085,.16,.082),skin)
		var elbow:=Node3D.new();elbow.name="Elbow";elbow.position=Vector3(side*.025,-.24,0);arm.add_child(elbow)
		ellipsoid(elbow,Vector3(0,-.08,.055),Vector3(.067,.14,.066),bronze)
		ellipsoid(elbow,Vector3(0,-.20,.09),Vector3(.065,.065,.065),skin)
		var leg:=Node3D.new()
		leg.name="LeftLeg" if side<0 else "RightLeg"
		leg.position=Vector3(side*.12,.61,0)
		body.add_child(leg)
		ellipsoid(leg,Vector3(0,-.135,0),Vector3(.105,.185,.105),skin)
		var knee:=Node3D.new()
		knee.name="Knee"
		knee.position.y=-.28
		leg.add_child(knee)
		ellipsoid(knee,Vector3(0,-.135,0),Vector3(.075,.17,.078),bronze)
		ellipsoid(knee,Vector3(0,-.275,.06),Vector3(.08,.045,.14),leather)
		for strip in range(5):
			var angle:float=(strip/5.0)*PI+side*PI/2
			var tile:MeshInstance3D=view.box(body,Vector3(cos(angle)*.2,.59,sin(angle)*.14),Vector3(.075,.22,.04),leather)
			tile.rotation.y=-angle+PI/2
			ellipsoid(body,tile.position+Vector3(0,.075,.025),Vector3(.014,.014,.014),bronze)
	ellipsoid(body,Vector3(0,.69,0),Vector3(.215,.052,.15),bronze)
	ellipsoid(body,Vector3(0,1.2,0),Vector3(.065,.10,.07),skin)
	ellipsoid(body,Vector3(0,1.32,0),Vector3(.102,.125,.098),skin)
	ellipsoid(body,Vector3(0,1.37,-.015),Vector3(.126,.125,.12),bronze)
	for side in [-1,1]:
		view.box(body,Vector3(side*.09,1.28,.06),Vector3(.03,.13,.085),bronze)
		view.box(body,Vector3(side*.041,1.335,.098),Vector3(.038,.015,.012),Color("241b19"))
	view.box(body,Vector3(0,1.31,.116),Vector3(.025,.10,.025),bronze)
	for i in range(13):
		ellipsoid(body,Vector3(0,1.50+sin(i/12.0*PI)*.09,-.14+i*.023),Vector3(.022,.075,.025),Color("782f30"))

	# Hammered bronze trim, leather straps and bracer bands.
	for side in [-1,1]:
		for j in range(3):
			ellipsoid(body.get_node("Arm%d/Elbow"%side),Vector3(0,-.02-j*.055,.055),Vector3(.068,.012,.068),Color("c2a06a"))
		for j in range(5):ellipsoid(body,Vector3(side*.16,.96-j*.055,.113),Vector3(.018,.025,.018),bronze)
	var strap:MeshInstance3D=view.box(body,Vector3(0,.96,.15),Vector3(.055,.32,.018),leather)
	strap.rotation.z=-.6
	for side in [-1,1]:
		ellipsoid(body,Vector3(side*.22,1.075,-.015),Vector3(.095,.06,.12),bronze)
		view.box(body,Vector3(side*.045,1.348,.103),Vector3(.057,.019,.019),Color("1c1310"))
	# Jaw, nose, beard, collarbones and back muscles give the silhouette anatomy.
	ellipsoid(body,Vector3(0,1.245,.075),Vector3(.088,.063,.065),skin.darkened(.16))
	ellipsoid(body,Vector3(0,1.23,.104),Vector3(.075,.045,.025),Color("30221b"))
	for side in [-1,1]:
		ellipsoid(body,Vector3(side*.115,1.07,-.065),Vector3(.12,.05,.095),skin)
		ellipsoid(body,Vector3(side*.13,.91,-.075),Vector3(.085,.18,.075),skin.darkened(.12))
		for finger in range(4):ellipsoid(body.get_node("Arm%d/Elbow"%side),Vector3(-.033+finger*.022,-.227,.12),Vector3(.012,.034,.018),skin.darkened(.08))
	var cape:=SurfaceTool.new()
	cape.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(12):
		var x:float=-.23+i*.04
		for vertex in [Vector3(x,1.08,-.10),Vector3(x+.04,1.08,-.10),Vector3(x,.41,-.25+sin(i)*.025),Vector3(x+.04,1.08,-.10),Vector3(x+.04,.41,-.25+sin(i+1)*.025),Vector3(x,.41,-.25+sin(i)*.025)]: cape.add_vertex(vertex)
	cape.generate_normals()
	var cloth:MeshInstance3D=view.mesh(body,cape.commit(),Vector3.ZERO,Color("4e1018"))
	var mat:StandardMaterial3D=cloth.material_override.duplicate()
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	cloth.material_override=mat
	cloth.name="Cape"
	var weapon:=Node3D.new()
	weapon.name="Weapon"
	weapon.position=Vector3(.29,.65,.12)
	body.add_child(weapon)
	view.box(weapon,Vector3(0,0,.08),Vector3(.04,.045,.2),leather)
	view.box(weapon,Vector3(0,0,.19),Vector3(.19,.04,.035),bronze)
	var blade:=PrismMesh.new()
	blade.size=Vector3(.065,.68,.022)
	var sword:MeshInstance3D=view.mesh(weapon,blade,Vector3(0,0,.53),Color("c8c8be"))
	sword.rotation.x=PI/2
	var bow:=Node3D.new()
	bow.name="Bow"
	weapon.add_child(bow)
	for i in range(16):
		var a:float=-1.2+i*.15
		var stick:MeshInstance3D=view.box(bow,Vector3(.20*cos(a),.46*sin(a),.14),Vector3(.04,.09,.035),bronze)
		stick.rotation.z=-a*.5
	for side in [-1,1]:
		var string_part:MeshInstance3D=view.box(bow,Vector3(.07,side*.217,.14),Vector3(.007,.435,.007),Color("c6b79a"));string_part.name="String%d"%side
	sword.name="Blade"
	bow.visible=false
	var spear:=Node3D.new()
	spear.name="Spear"
	weapon.add_child(spear)
	view.box(spear,Vector3(0,0,.2),Vector3(.035,.035,1.35),Color("8f7050"))
	var tip:=PrismMesh.new()
	tip.size=Vector3(.11,.28,.025)
	var point_:MeshInstance3D=view.mesh(spear,tip,Vector3(0,0,.96),Color("d6d3c4"))
	point_.rotation.x=PI/2
	spear.visible=false
	var wand:=Node3D.new();wand.name="Wand";weapon.add_child(wand)
	view.box(wand,Vector3(0,0,.25),Vector3(.045,.045,.65),bronze)
	var crystal:=SphereMesh.new();crystal.radius=.13;crystal.height=.28
	view.mesh(wand,crystal,Vector3(0,0,.65),Color("8dc6ff"))
	preload("res://src/presentation/anatomy.gd").new(view).detail(parent,"hero")
func pose(parent:Node3D,phase:float,spin:bool)->void:
	var body:Node3D=parent.get_node("Model")
	body.position.y=absf(sin(phase))*.025
	for side in [-1,1]:
		var stride:float=sin(phase)*side
		var leg:Node3D=body.get_node("LeftLeg" if side<0 else "RightLeg")
		leg.rotation.x=stride*.55
		leg.get_node("Knee").rotation.x=maxf(0,-stride)*.7
		body.get_node("Arm%d"%side).rotation=Vector3(-stride*.32,0,side*.12)
		body.get_node("Arm%d/Elbow"%side).rotation.x=-.22-maxf(0,stride)*.35
	var weapon:Node3D=body.get_node("Weapon")
	weapon.rotation.y=sin(view.game.attack_flash*12)*1.3
	var type:String=str(view.game.profile.get("primary_weapon","sword"))
	var bow:bool=type=="bow"
	weapon.get_node("Bow").visible=bow
	var spear:bool=type=="spear"
	weapon.get_node("Spear").visible=spear
	weapon.get_node("Blade").visible=type=="sword"
	weapon.get_node("Wand").visible=type=="wand"
	var attack:float=sin(clampf(view.game.attack_flash/.22,0,1)*PI) if view.game.mode=="play" else 0.0
	body.get_node("Arm1").rotation.x-=attack*.8
	body.rotation.y=attack*-.28
	body.get_node("Cape").rotation.x=sin(view.clock*4)*.025+absf(sin(phase))*.06
	body.get_node("Arm1/Elbow").rotation.x-=attack*.7
	weapon.position.z=.12+attack*(.3 if spear else .1)
	
	# Overarm throw and diagonal sword cut use the shoulder and elbow chain.
	var right:Node3D=body.get_node("Arm1");var elbow:Node3D=right.get_node("Elbow")
	right.rotation.z=0;right.rotation.y=0
	if attack>0:
		var progress:float=1-clampf(view.game.attack_flash/.22,0,1)
		if spear:
			right.rotation.x=lerpf(-2.5,-1.25,progress);elbow.rotation.x=lerpf(-1.1,-.05,progress)
			body.rotation.y=lerpf(-.45,.25,progress)
		elif not bow:
			right.rotation.x=lerpf(-1.8,-.5,progress);right.rotation.z=lerpf(-.9,.7,progress)
			right.rotation.y=lerpf(-.6,.8,progress);elbow.rotation.x=-.35
	preload("res://src/presentation/anatomy.gd").new(view).attach_weapon(body)
	if bow and attack>0:
		# Bow hand extends while the drawing elbow pulls the string toward the cheek.
		right.rotation.x=-1.3;elbow.rotation.x=-.12
		body.get_node("Arm-1").rotation.x=-1.1-attack*.45
		body.get_node("Arm-1/Elbow").rotation.x=-1.0-attack*.6
		preload("res://src/presentation/anatomy.gd").new(view).attach_weapon(body)
		weapon.rotate_object_local(Vector3.RIGHT,-PI/2)
		for side in [-1,1]:
			var string_part:Node3D=weapon.get_node("Bow/String%d"%side);string_part.position.z=.14-attack*.10;string_part.rotation.x=side*atan2(attack*.20,.435);string_part.scale.y=sqrt(.435*.435+pow(attack*.20,2))/.435
	elif type=="wand" and attack>0:
		for side in [-1,1]:
			body.get_node("Arm%d"%side).rotation.x=-1.05
			body.get_node("Arm%d"%side).rotation.z=side*-.08
			body.get_node("Arm%d/Elbow"%side).rotation.x=-.7-attack*.4
		preload("res://src/presentation/anatomy.gd").new(view).attach_weapon(body)
	if spin: parent.rotation.y=view.clock*18
