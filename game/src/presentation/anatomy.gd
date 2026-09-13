extends RefCounted
# Continuous ring lofts, rather than intersecting primitives, shape the anatomy.
var view
func _init(v)->void:view=v
func loft(parent:Node3D,rings:Array,color:Color,segments:int=32)->MeshInstance3D:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(rings.size()-1):
		for i in range(segments):
			for corner in [[row,i],[row+1,i],[row,i+1],[row,i+1],[row+1,i],[row+1,i+1]]:
				var ring:Vector4=rings[corner[0]];var angle:float=TAU*corner[1]/segments
				st.set_uv(Vector2(float(corner[1])/segments,float(corner[0])/(rings.size()-1)))
				st.add_vertex(Vector3(cos(angle)*ring.y,ring.x,sin(angle)*ring.z+ring.w))
	st.generate_normals();st.index()
	var result:MeshInstance3D=view.mesh(parent,st.commit(),Vector3.ZERO,color)
	var mat:StandardMaterial3D=result.material_override.duplicate();mat.cull_mode=BaseMaterial3D.CULL_DISABLED;result.material_override=mat
	return result
func attach_weapon(body:Node3D)->void:
	var hand:Node3D=body.get_node("Arm1/Elbow/Hand")
	var weapon:Node3D=body.get_node("Weapon")
	# Keep the existing public node path; drive its transform from the actual hand.
	weapon.transform=body.global_transform.affine_inverse()*hand.global_transform
	weapon.rotate_object_local(Vector3.RIGHT,PI/2)
func add_hand(elbow:Node3D,length:float)->void:
	var hand:=Node3D.new();hand.name="Hand";hand.position=Vector3(0,-length,.065);elbow.add_child(hand)
func detail(parent:Node3D,kind:String)->void:
	var body:Node3D=parent.get_node("Model")
	var sculpt=load("res://src/presentation/warrior.gd").new(view)
	if kind=="hero":
		# Raise the torso above longer thigh/shin chains; head is about one eighth of height.
		for part in body.get_children():
			if part is Node3D and part.name!="Cape":part.position.y+=.22
		body.get_node("Cape").position.y=.22
		for side in [-1,1]:
			var leg:Node3D=body.get_node("LeftLeg" if side<0 else "RightLeg")
			leg.scale.y=1.38
			var arm:Node3D=body.get_node("Arm%d"%side);arm.scale.y=1.28
			add_hand(arm.get_node("Elbow"),.20)
		# Remove intersecting primitive chest/abdominal layers before the continuous cuirass.
		for part in body.get_children():
			if part is MeshInstance3D and part.position.y>.94 and part.position.y<1.29 and absf(part.position.x)<.20 and part.mesh is SphereMesh:part.visible=false
		# Forged muscle cuirass, raised edge strips, matching the original portrait.
		loft(body,[Vector4(.92,.16,.105,0),Vector4(1.02,.17,.12,0),Vector4(1.16,.235,.145,0),Vector4(1.25,.245,.13,0),Vector4(1.30,.17,.09,0)],Color("75603b"),40)
		for side in [-1,1]:
			sculpt.ellipsoid(body,Vector3(side*.115,1.205,.11),Vector3(.11,.07,.035),Color("8c713f"))
			for row in range(3):sculpt.ellipsoid(body,Vector3(side*.063,1.10-row*.055,.12),Vector3(.063,.027,.012),Color("927544"))
			var clasp:MeshInstance3D=sculpt.ellipsoid(body,Vector3(side*.19,1.29,.03),Vector3(.045,.045,.018),Color("b29757"))
			clasp.rotation.x=-.4
		# Long red mantle draped over the shoulders.
		loft(body,[Vector4(1.24,.27,.13,-.035),Vector4(1.29,.28,.135,-.025),Vector4(1.33,.18,.095,-.025)],Color("581d20"))
	else:
		for side in [-1,1]:add_hand(body.get_node("Arm%d/Elbow"%side),.20)
		if kind in ["satyr","cyclops"]:
			var skin:=Color("805d43") if kind=="cyclops" else Color("75513e")
			for part in body.get_children():
				if part is MeshInstance3D and part.position.y>.54 and part.position.y<1.04 and absf(part.position.x)<.28:part.visible=false
			# Longer digitigrade legs and hanging arms, not a squat toy silhouette.
			for part in body.get_children():
				if part is Node3D and part.name in ["LeftLeg","RightLeg"]:part.position.y+=.18
			for side in [-1,1]:body.get_node("LeftLeg" if side<0 else "RightLeg").scale.y=1.4
			loft(body,[Vector4(.55,.20,.15,0),Vector4(.66,.19,.14,0),Vector4(.82,.26,.18,0),Vector4(.94,.30,.18,0),Vector4(1.04,.22,.13,0)],skin)
			for side in [-1,1]:
				var arm:Node3D=body.get_node("Arm%d"%side);arm.scale=Vector3(1.15,1.25,1.15)
				# Beard locks/hair strands create a ragged silhouette instead of a smooth ball.
				for strand in range(9):
					var p:=Vector3(side*(.015+strand*.018),1.15+sin(strand)*.03,.165)
					sculpt.ellipsoid(body,p,Vector3(.027,.09+(strand%3)*.015,.037),Color("302820"))
				for strand in range(8):sculpt.ellipsoid(body,Vector3(side*(.04+strand*.019),1.39-(strand%3)*.025,-.02),Vector3(.04,.065,.13),Color("302820"))
			if kind=="satyr":
				for side in [-1,1]:
					for section in range(16):
						var angle:float=section*.18
						sculpt.ellipsoid(body,Vector3(side*(.20+sin(angle)*.12),1.41+sin(angle+.3)*.23,-.04-cos(angle)*.09),Vector3(.055-section*.002,.055-section*.002,.055-section*.002),Color("8b7754"))
			else:
				sculpt.ellipsoid(body,Vector3(0,1.27,.195),Vector3(.062,.037,.025),Color("d3b073"))
				sculpt.ellipsoid(body,Vector3(0,1.27,.219),Vector3(.021,.027,.01),Color("312318"))

			for part in body.get_children():
				if part is Node3D and part.name not in ["LeftLeg","RightLeg"]:part.position.y+=.18
