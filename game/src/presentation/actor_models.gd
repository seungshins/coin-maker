extends RefCounted
var warrior
var view
func _init(owner_view) -> void: view = owner_view
func build(parent: Node3D, kind: String) -> void:
	if kind=="hero":
		warrior=preload("res://src/presentation/warrior.gd").new(view)
		warrior.build(parent)
		return
	parent.set_meta("model_kind",kind)
	var bronze := Color("796345")
	var skin:Color = {"satyr":Color("643d39"),"minotaur":Color("513331"),"cyclops":Color("6c6356"),"harpy":Color("5b415d"),"gorgon":Color("29493b"),"hydra":Color("304e36")}.get(kind,Color("75634e"))
	if kind in ["talos","automaton"]: skin = bronze
	if kind in ["gorgon","hydra"]: skin = Color("304d39")
	var body := Node3D.new()
	body.name = "Model"
	body.scale = Vector3.ONE*.8
	parent.add_child(body)
	segment(body,Vector3(0,.8,0),.24,.5,bronze if kind in ["hero","champion","hoplite","talos","automaton"] else skin)
	segment(body,Vector3(0,.54,0),.27,.12,Color("604738"))
	var skirt := CylinderMesh.new()
	skirt.top_radius=.24
	skirt.bottom_radius=.33
	skirt.height=.3
	skirt.radial_segments=10
	var skirt_node:MeshInstance3D=view.mesh(body,skirt,Vector3(0,.4,0),Color("302421"));skirt_node.visible=kind!="gorgon"
	for side in [-1,1]:
		var leg := Node3D.new()
		leg.name = "LeftLeg" if side<0 else "RightLeg"
		leg.position=Vector3(side*.14,.48,0)
		body.add_child(leg)
		segment(leg,Vector3(0,-.10,0),.11,.24,skin)
		var knee:=Node3D.new();knee.name="Knee";knee.position.y=-.20;leg.add_child(knee)
		segment(knee,Vector3(0,-.10,-.035 if kind=="satyr" else 0),.075,.23,skin.darkened(.18))
		for hoof in [-1,1]:view.box(knee,Vector3(hoof*.044,-.22,.06),Vector3(.08,.10,.20),Color("29231f"))
		var arm:=Node3D.new();arm.name="Arm%d"%side;arm.position=Vector3(side*.29,.88,0);body.add_child(arm)
		segment(arm,Vector3.ZERO,.14,.2,bronze)
		segment(arm,Vector3(side*.025,-.09,0),.105,.24,skin)
		var elbow:=Node3D.new();elbow.name="Elbow";elbow.position=Vector3(side*.035,-.20,0);arm.add_child(elbow)
		segment(elbow,Vector3(0,-.095,.04),.075,.23,skin)
		segment(elbow,Vector3(0,-.20,.06),.08,.16,skin.darkened(.1))
	var head:=SphereMesh.new()
	head.radius=.19
	head.height=.4
	head.radial_segments=24
	head.rings=12
	view.mesh(body,head,Vector3(0,1.24,0),skin)
	if kind == "cyclops": view.box(body,Vector3(0,1.26,.185),Vector3(.1,.07,.03),Color("f4c576"))
	else:
		for side in [-1,1]: view.box(body,Vector3(side*.065,1.27,.177),Vector3(.035,.035,.035),Color("342b22"))
	if kind in ["hero","champion","hoplite","talos","automaton"]:
		segment(body,Vector3(0,1.39,0),.2,.12,bronze)
		view.box(body,Vector3(0,1.53,-.03),Vector3(.07,.24,.4),Color("963f36"))
		for side in [-1,1]: view.box(body,Vector3(side*.17,1.23,.09),Vector3(.035,.2,.13),bronze)
		# Cape hangs behind the torso; all directions have real geometry.
		var cape:MeshInstance3D=view.box(body,Vector3(0,.78,-.22),Vector3(.46,.73,.04),Color("883e35"))
		cape.rotation.x=-.15
		var shield:=CylinderMesh.new()
		shield.top_radius=.27
		shield.bottom_radius=.27
		shield.height=.065
		shield.radial_segments=16
		var disk:MeshInstance3D=view.mesh(body,shield,Vector3(-.38,.76,.18),bronze)
		disk.rotation.x=PI/2
	if kind in ["satyr","minotaur"]:
		for side in [-1,1]:
			var horn:=CylinderMesh.new()
			horn.top_radius=0
			horn.bottom_radius=.07
			horn.height=.32 if kind=="satyr" else .55
			horn.radial_segments=6
			var node:MeshInstance3D=view.mesh(body,horn,Vector3(side*.19,1.45,0),Color("ded0a8"))
			node.rotation.z=-side*.5
	if kind == "harpy":
		for side in [-1,1]:
			for feather in range(5):
				var wing:MeshInstance3D=view.box(body,Vector3(side*(.4+feather*.09),.9-feather*.035,-.08),Vector3(.12,.4,.08),Color("8c779b"))
				wing.rotation.z=side*.8
	if kind in ["gorgon","hydra"]:
		for i in range(5):
			segment(body,Vector3((i-2)*.14,1.45+(i%2)*.15,0),.06,.4,skin)
			view.mesh(body,head,Vector3((i-2)*.14,1.68+(i%2)*.15,.06),skin).scale=Vector3.ONE*.4

	# Layered anatomy and armour silhouettes, shared geometry stays inexpensive.
	var detail=preload("res://src/presentation/warrior.gd").new(view)
	for side in [-1,1]:
		detail.ellipsoid(body,Vector3(side*.12,.91,.14),Vector3(.14,.14,.075),skin)
		detail.ellipsoid(body.get_node("Arm%d"%side),Vector3(0,-.075,.015),Vector3(.105,.14,.10),skin)
		for j in range(3):detail.ellipsoid(body,Vector3(side*.065,.78-j*.07,.21),Vector3(.068,.04,.025),skin.darkened(.12))
		for j in range(4):
			view.box(body,Vector3(side*(.07+j*.055),.49,.24-j*.02),Vector3(.043,.22,.04),Color("372921"))
	if kind in ["cyclops","minotaur","talos"]:
		for side in [-1,1]:
			detail.ellipsoid(body,Vector3(side*.31,1.0,0),Vector3(.19,.10,.19),bronze)
			for j in range(3):
				var spike:=CylinderMesh.new();spike.top_radius=0;spike.bottom_radius=.035;spike.height=.15
				view.mesh(body,spike,Vector3(side*(.22+j*.07),1.13,0),Color("cfb78c"))
	if kind=="satyr":
		detail.ellipsoid(body,Vector3(0,1.16,.16),Vector3(.11,.12,.085),Color("302723"))
		for side in [-1,1]:
			detail.ellipsoid(body,Vector3(side*.18,1.26,0),Vector3(.12,.055,.05),skin)
			for tuft in range(5):detail.ellipsoid(body.get_node("LeftLeg" if side<0 else "RightLeg"),Vector3(side*.045,-.035-tuft*.025,-.025),Vector3(.085,.055,.085),Color("372c26"))
	if kind=="cyclops":
		body.scale=Vector3(.96,.85,.9)
		detail.ellipsoid(body,Vector3(0,1.24,.19),Vector3(.045,.08,.06),skin)
		for side in [-1,1]:detail.ellipsoid(body,Vector3(side*.13,1.20,.12),Vector3(.09,.08,.07),skin.darkened(.1))
		detail.ellipsoid(body,Vector3(0,1.16,.15),Vector3(.13,.065,.08),skin.darkened(.25))
		view.box(body,Vector3(0,1.30,.19),Vector3(.17,.035,.035),skin.darkened(.3))

	if kind=="gorgon":
		body.get_node("LeftLeg").visible=false;body.get_node("RightLeg").visible=false
		for i in range(5):
			var coil:=TorusMesh.new();coil.inner_radius=.10;coil.outer_radius=.34-i*.03
			view.mesh(body,coil,Vector3(sin(i*.8)*.10,.10+i*.075,0),skin)
		for i in range(5):
			for side in [-1,1]:view.box(body,Vector3((i-2)*.14+side*.022,1.69+(i%2)*.15,.13),Vector3(.014,.014,.014),Color("e8c65f"))
	if kind in ["satyr","minotaur","cyclops"]:
		for side in [-1,1]:
			var tooth:=CylinderMesh.new();tooth.top_radius=.035;tooth.bottom_radius=0;tooth.height=.12
			view.mesh(body,tooth,Vector3(side*.08,1.13,.19),Color("b7a483"))
	var weapon:=Node3D.new()
	weapon.name="Weapon"
	body.add_child(weapon)
	segment(weapon,Vector3(.4,.68,.2),.04,.28,Color("57412e"))
	var blade:=CylinderMesh.new()
	blade.top_radius=0
	blade.bottom_radius=.065
	blade.height=.65 if kind not in ["hoplite","talos"] else 1.0
	blade.radial_segments=4
	var sword:MeshInstance3D=view.mesh(weapon,blade,Vector3(.4,.68,.52),Color("d7d3bd"))
	sword.rotation.x=PI/2
	view.box(weapon,Vector3(.4,.68,.22),Vector3(.23,.045,.06),bronze)
	var grip:=Vector3(.4,.68,.2)
	for part in weapon.get_children():part.position-=grip
	weapon.position=grip
	weapon.set_meta("rest",grip)
	preload("res://src/presentation/anatomy.gd").new(view).detail(parent,kind)

func segment(parent:Node3D,p:Vector3,radius:float,height:float,color:Color)->void:
	var shape:=CapsuleMesh.new()
	shape.radius=radius
	shape.height=maxf(height,radius*2)
	shape.radial_segments=20
	shape.rings=8
	view.mesh(parent,shape,p,color)

func pose(parent:Node3D,phase:float,spin:bool)->void:
	if parent.get_meta("model_kind","")=="hero":
		warrior.pose(parent,phase,spin)
		return
	var body:=parent.get_node("Model")
	body.get_node("LeftLeg").rotation.x=sin(phase)*.4
	body.get_node("RightLeg").rotation.x=-sin(phase)*.4
	body.position.y=absf(sin(phase))*.018
	for side in [-1,1]:
		var stride:float=sin(phase)*side
		body.get_node("LeftLeg/Knee" if side<0 else "RightLeg/Knee").rotation.x=maxf(0,-stride)*.8+(.2 if parent.get_meta("model_kind")=="satyr" else 0)
		body.get_node("Arm%d"%side).rotation.x=-stride*.3
		body.get_node("Arm%d/Elbow"%side).rotation.x=-.25-maxf(0,stride)*.35
	body.get_node("Weapon").rotation.y=view.clock*18 if spin else sin(view.game.attack_flash*12)*.9
	preload("res://src/presentation/anatomy.gd").new(view).attach_weapon(body)
	if spin: parent.rotation.y=view.clock*18
