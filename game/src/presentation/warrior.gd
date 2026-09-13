extends RefCounted
var view
func _init(v)->void: view=v
func ellipsoid(parent:Node,p:Vector3,size_:Vector3,color:Color)->MeshInstance3D:
	var shape:=SphereMesh.new()
	shape.radius=1
	shape.height=2
	shape.radial_segments=32
	shape.rings=16
	var node:MeshInstance3D=view.mesh(parent,shape,p,color)
	node.scale=size_
	return node
func build(parent:Node3D)->void:
	parent.set_meta("model_kind","hero")
	var body:=Node3D.new()
	body.name="Model"
	parent.add_child(body)
	var skin:=Color("b28c73")
	var bronze:=Color("947344")
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
		ellipsoid(arm,Vector3(side*.025,-.32,.055),Vector3(.062,.14,.062),bronze)
		ellipsoid(arm,Vector3(side*.025,-.44,.09),Vector3(.065,.065,.065),skin)
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
	ellipsoid(body,Vector3(0,1.32,0),Vector3(.115,.155,.105),skin)
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
			ellipsoid(body.get_node("Arm%d"%side),Vector3(side*.025,-.26-j*.055,.055),Vector3(.068,.012,.068),Color("c2a06a"))
		for j in range(5):ellipsoid(body,Vector3(side*.16,.96-j*.055,.113),Vector3(.018,.025,.018),bronze)
	var strap:MeshInstance3D=view.box(body,Vector3(0,.96,.15),Vector3(.055,.32,.018),leather)
	strap.rotation.z=-.6
	var cape:=SurfaceTool.new()
	cape.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(12):
		var x:float=-.23+i*.04
		for vertex in [Vector3(x,1.08,-.10),Vector3(x+.04,1.08,-.10),Vector3(x,.41,-.25+sin(i)*.025),Vector3(x+.04,1.08,-.10),Vector3(x+.04,.41,-.25+sin(i+1)*.025),Vector3(x,.41,-.25+sin(i)*.025)]: cape.add_vertex(vertex)
	cape.generate_normals()
	var cloth:MeshInstance3D=view.mesh(body,cape.commit(),Vector3.ZERO,Color("65292c"))
	var mat:StandardMaterial3D=cloth.material_override.duplicate()
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	cloth.material_override=mat
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
	view.box(bow,Vector3(.07,0,.14),Vector3(.007,.87,.007),Color("c6b79a"))
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
func pose(parent:Node3D,phase:float,spin:bool)->void:
	var body:Node3D=parent.get_node("Model")
	body.position.y=absf(sin(phase))*.025
	for side in [-1,1]:
		var stride:float=sin(phase)*side
		var leg:Node3D=body.get_node("LeftLeg" if side<0 else "RightLeg")
		leg.rotation.x=stride*.55
		leg.get_node("Knee").rotation.x=maxf(0,-stride)*.7
		body.get_node("Arm%d"%side).rotation.x=-stride*.22
	var weapon:Node3D=body.get_node("Weapon")
	weapon.rotation.y=sin(view.game.attack_flash*12)*1.3
	var type:String=view.game.visual_weapon if view.game.rules.weapon_index(view.game.profile,view.game.visual_weapon)>=0 else view.game.rules.equipped_weapon(view.game.profile)
	var bow:bool=type=="bow"
	weapon.get_node("Bow").visible=bow
	var spear:bool=type=="spear"
	weapon.get_node("Spear").visible=spear
	weapon.get_node("Blade").visible=type=="sword"
	weapon.get_node("Wand").visible=type=="wand"
	var attack:float=sin(clampf(view.game.attack_flash/.22,0,1)*PI)
	body.get_node("Arm1").rotation.x-=attack*.8
	weapon.position.z=.12+attack*(.3 if spear else .1)
	if bow: body.get_node("Arm-1").rotation.x=-.8;body.get_node("Arm1").rotation.x=-.4-attack*.5
	if spin: parent.rotation.y=view.clock*18
