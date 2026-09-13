extends Node3D
# Presentation adapter: persisted gameplay coordinates remain Vector2(x,z)*100.
var game
var sun: DirectionalLight3D
var environment: Environment
var lighting_state := -1
var camera: Camera3D
var terrain: Node3D
var actors := {}
var ornaments := {}
var materials := {}
var character_textures := {}
var elements = preload("res://src/presentation/elemental_art.gd").new(self)
var models = preload("res://src/presentation/actor_models.gd").new(self)
var natural = preload("res://src/presentation/natural_terrain.gd").new(self)
var landscapes = preload("res://src/presentation/landscapes.gd").new(self)
var health_markers: Array[Dictionary] = []
var layout := ""
var enabled := true
var clock := 0.0
var font := SystemFont.new()

func _ready() -> void:
	font.font_names = PackedStringArray(["Malgun Gothic", "Apple SD Gothic Neo", "Noto Sans CJK KR"])
	terrain = Node3D.new()
	add_child(terrain)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 10.0
	camera.far = 150
	add_child(camera)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_color = Color("bdc9dd")
	sun.light_energy = 0.52
	sun.shadow_enabled = true
	add_child(sun)
	var world_env := WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("111a22")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("718599")
	environment.ambient_light_energy = 0.24
	world_env.environment = environment
	add_child(world_env)
	var bars := preload("res://src/presentation/health_overlay.gd").new()
	bars.view = self
	game.ui.add_child(bars)
	refresh(0)

func active() -> bool:
	return enabled and (game.town.visible or game.world.visible)

func point(p: Vector2, height: float = 0.0) -> Vector3:
	return Vector3(p.x * 0.01, height + landscapes.height_at(p), p.y * 0.01)

func mouse_world() -> Vector2:
	return screen_to_world(get_viewport().get_mouse_position())

func screen_to_world(pixel: Vector2) -> Vector2:
	var origin := camera.project_ray_origin(pixel)
	var direction := camera.project_ray_normal(pixel)
	var low := 0.0
	var high := 100.0
	for i in range(24):
		var middle := (low + high) * 0.5
		var at := origin + direction * middle
		if at.y > landscapes.height_at(Vector2(at.x, at.z) * 100): low = middle
		else: high = middle
	var hit := origin + direction * ((low + high) * 0.5)
	return Vector2(hit.x, hit.z) * 100

func _process(delta: float) -> void: refresh(delta)

func refresh(delta: float) -> void:
	health_markers.clear()
	clock += delta
	visible = active()
	game.world.modulate.a = 0.0 if visible else 1.0
	game.town.modulate.a = 0.0 if visible else 1.0
	if not visible: return
	camera.make_current()
	var town: bool = game.town.visible
	var lighting:int=1 if town else game.ambience
	if lighting != lighting_state:
		lighting_state=lighting
		sun.light_color=[Color("a5bada"),Color("ffc48c"),Color("e3e4d6")][lighting]
		sun.light_energy=[.3,.65,.85][lighting]
		sun.rotation_degrees.x=[-55,-22,-60][lighting]
		environment.ambient_light_energy=[.22,.29,.36][lighting]
		environment.background_color=[Color("111923"),Color("302526"),Color("39454d")][lighting]
	var current: String = "town" if town else str(game.active_stage().name)
	if current != layout:
		layout = current
		for child in terrain.get_children(): terrain.remove_child(child); child.queue_free()
		# Map changes must invalidate pooled enemy appearances as well as terrain.
		for node in actors.values(): remove_child(node); node.queue_free()
		actors.clear()
		build_town() if town else build_coast()
	for node in actors.values(): node.visible = false
	for node in ornaments.values(): node.visible = false
	var focus: Vector2 = game.town.position_in_town if town else game.player
	camera.size = (9.2 if town else 12.0) * game.display_settings.zoom_factor
	camera.position = point(focus) + Vector3(0, 13, 10)
	camera.look_at(point(focus), Vector3.UP)
	var hero: Node3D = actor("hero", Color("b45e39"), false)
	hero.position = point(game.town.position_in_town if town else game.player)
	var direction: Vector2 = Vector2(game.town.direction, 0) if town else game.aim
	hero.rotation.y = atan2(direction.x, direction.y)
	hero.scale = Vector3.ONE * (1.0 if town else game.battle_extras.hero_scale())
	pose(hero, game.town.phase if town else (clock * 12 if game.moving else 0), not town and game.channeling)
	if not town: health_bar("hero_hp", hero.position + Vector3(0, 1.27 * hero.scale.x, 0), game.health / game.rules.stats(game.profile).hp, Color("5fe6a1"))
	if town:
		for i in range(game.town.places.size()):
			var place: Dictionary = game.town.places[i]
			var npc := actor("npc%d" % i, place.color, false)
			npc.position = point(place.p)
			text3d("npc_label%d" % i, place.name + "\n" + place.role + (" ["+game.controls.label(KEY_F)+"]" if game.town.nearby() == i else ""), npc.position + Vector3(0, 1.9, 0), Color("fff0cc"))
		return
	if game.portal_ready():
		ring("boss_portal",point(game.portal_position(),.15),.85,Color("9f8cff"))
		text3d("boss_portal_label","진 보스 투기장 · 클릭 / ["+game.controls.label(KEY_F)+"]",point(game.portal_position(),1.8),Color("c9b8ff"))
	for i in range(game.chests.size()):
		var chest:Dictionary=game.chests[i]
		if chest.state=="claimed":continue
		var chest_key:="treasure%d"%i
		if not ornaments.has(chest_key):
			var model:=Node3D.new();add_child(model)
			box(model,Vector3.ZERO,Vector3(.8,.45,.5),Color("72502e"))
			box(model,Vector3(0,.25,0),Vector3(.84,.1,.54),Color("aa8243"))
			box(model,Vector3(0,.05,.27),Vector3(.12,.18,.04),Color("ebc875"))
			ornaments[chest_key]=model
		var box_:Node3D=ornaments[chest_key];box_.visible=true;box_.position=point(chest.p,.3)
		text3d("treasure_label%d"%i,"봉인된 보물 ["+game.controls.label(KEY_F)+"]" if chest.state=="sealed" else "수호자 처치",point(chest.p,1.1),Color("ffdc88"))
	for e in game.enemies:
		if e.dead and e.death_time <= 0: continue
		var color: Color = {"swift": Color("67ac84"), "fury": Color("bc614b"), "titan": Color("8975ad")}.get(e.get("affix", ""), Color("96715a"))
		var enemy := actor("enemy%d" % e.id, color, e.kind == "boss", e.get("model", "satyr"))
		enemy.position = point(e.p)
		enemy.rotation.y = atan2(game.player.x - e.p.x, game.player.y - e.p.y)
		enemy.scale = Vector3.ONE * (1.75 if e.kind == "boss" else (1.2 if e.get("elite", false) else 1.0))
		pose(enemy, clock * 8 + e.id, false)
		if enemy.has_node("Art"): enemy.get_node("Art").modulate = Color(1.45, 1.2, 1.1) if e.hit > 0 else Color.WHITE
		if e.dead:
			enemy.scale.y *= maxf(0.05, e.death_time / 0.8)
			continue
		health_bar("boss%d" % e.id if e.kind == "boss" else "hp%d" % e.id, enemy.position + Vector3(0, 1.30 * enemy.scale.x, 0), e.hp / e.max_hp, Color("ffcf65") if e.get("elite", false) else Color("ff7969"))
		if e.kind=="boss":text3d("boss_name%d"%e.id,("중간 보스" if e.get("miniboss",false) else "최종 보스")+" · "+game.battle_extras.affix_name(e.get("affix","")),point(e.p,2.7),Color("ffd18b"))
		if e.get("elite", false):
			ring("elite%d" % e.id, point(e.p,.07),.4,Color("ffc85c"))
			text3d("elite_name%d" % e.id,"희귀 · " + game.battle_extras.affix_name(e.get("affix","")),point(e.p,1.7),Color("ffdb82"))
		if e.windup > 0: ring("warn%d" % e.id, point(e.target, 0.05), 1.15 if e.kind == "boss" else 0.58, Color("ff674a"))
		if float(e.get("curse", 0)) > 0 or float(e.get("chains", 0)) > 0 or float(e.get("frailty", 0)) > 0: ring("curse%d" % e.id, point(e.p, 0.07), 0.38, Color("ba93ff"))
	for i in range(game.minions.size()):
		var m: Dictionary = game.minions[i]
		var spirit := actor("minion%d" % i, Color("69c8d4"), false)
		spirit.position = point(m.p)
		spirit.scale = Vector3.ONE * 0.75
		pose(spirit, clock * 9, false)
		health_bar("minionhp%d" % i, spirit.position + Vector3(0, 1.3, 0), m.hp / m.max_hp, Color("75dcfa"))
	for i in range(game.bolts.size()):
		var bolt: Dictionary = game.bolts[i]
		var tint: Color = {"fire": Color("ff7934"), "ice": Color("97e9ff"), "lightning": Color("b9b4ff")}.get(game.battle_extras.element(bolt.get("skill_id", "")), Color("f4d898"))
		var node := orb("bolt%d" % i, point(bolt.p, 0.5), tint)
		node.scale = Vector3(0.13, 0.13, 0.5) if bolt.get("arrow", false) else Vector3.ONE * 0.23
		node.rotation.y = atan2(bolt.v.x, bolt.v.y)
		var element: String = game.battle_extras.element(bolt.get("skill_id", ""))
		if element != "physical":
			node.visible = false
			elements.draw("bolt%d" % i,point(bolt.p,.55),element,Vector2(.65,.85))
		if bolt.get("arrow", false):
			node.visible=false
			var key:="arrow_geometry%d"%i
			if not ornaments.has(key):
				var arrow:=Node3D.new()
				add_child(arrow)
				ornaments[key]=arrow
				box(arrow,Vector3.ZERO,Vector3(.025,.025,.65),Color("b3986d"))
				var tip:=PrismMesh.new()
				tip.size=Vector3(.12,.18,.025)
				var head:=mesh(arrow,tip,Vector3(0,0,.37),Color("d4d5cc"))
				head.rotation.x=PI/2
				for side in [-1,1]: box(arrow,Vector3(side*.045,0,-.25),Vector3(.075,.012,.14),Color("adada1"))
			var arrow:Node3D=ornaments[key]
			arrow.visible=true
			arrow.position=point(bolt.p,.55)
			arrow.rotation.y=atan2(bolt.v.x,bolt.v.y)
			arrow.scale=Vector3(1.3,1.3,1.8) if str(bolt.get("skill_id","")).contains("spear") else Vector3.ONE
			for trail in range(3):
				var w:=orb("wind%d-%d"%[i,trail],point(bolt.p-bolt.v.normalized()*(trail+1)*22,.55),Color("b9ddd7"))
				w.scale=Vector3(.02,.02,.15)
				w.rotation.y=arrow.rotation.y
		if bolt.get("wave", false):
			node.visible = false
			for flame in range(0 if bolt.get("skill_id","")=="sword_wave" else 5): elements.draw("wave%d-%d" % [i,flame],point(bolt.p+bolt.v.normalized().orthogonal()*(flame-2)*26,.5),"fire",Vector2(.5,1.1))
	for index in range(game.bolts.size()):
		var bolt:Dictionary=game.bolts[index]
		if bolt.get("skill_id","")=="sword_wave":sword_arc(index,bolt)
	for i in range(game.fields.size()):
		var field: Dictionary = game.fields[i]
		var tint := Color("8cdeff") if field.kind in ["blizzard", "ice_zone"] else Color("ffe090")
		ring("field%d" % i, point(field.p, 0.06), field.radius * 0.01, tint)
		if field.kind=="blade_orbit":
			for blade in range(5):
				var angle:float=clock*5+blade*TAU/5
				var blade_p:Vector2=field.p+Vector2.from_angle(angle)*field.radius*.8
				var blade_key:="orbit%d-%d"%[i,blade]
				if not ornaments.has(blade_key):
					var shape:=PrismMesh.new()
					shape.size=Vector3(.12,.7,.04)
					ornaments[blade_key]=mesh(self,shape,Vector3.ZERO,Color("e2d7b1"))
				var blade_node:MeshInstance3D=ornaments[blade_key]
				blade_node.visible=true
				blade_node.position=point(blade_p,.6)
				blade_node.rotation=Vector3(PI/2,-angle,0)
			continue
		if field.kind=="fire_zone":
			for flame in range(7):elements.draw("burn%d-%d"%[i,flame],point(field.p+Vector2.from_angle(flame*2.4)*field.radius*.6,.4),"fire",Vector2(.55,.9))
			continue
		if field.kind=="tidal_aura":
			for wave in range(8):elements.draw("tide%d-%d"%[i,wave],point(field.p+Vector2.from_angle(clock+wave*TAU/8)*field.radius*.7,.35),"water",Vector2(.9,.7))
			continue
		for flake in range(9):
			var offset: Vector2 = Vector2.from_angle(flake * 2.4 + clock) * (field.radius * (0.2 + flake * 0.07))
			var node := orb("flake%d-%d" % [i, flake], point(field.p + offset, fposmod(2.0 - clock * 3 + flake * 0.3, 2.0)), tint)
			node.scale = Vector3(0.045, 0.25, 0.045)
			if field.kind in ["blizzard","ice_zone"]:
				node.visible=false
				elements.draw("snow%d-%d" % [i,flake],node.position,"ice",Vector2(.35,.35))
	for i in range(game.drops.size()):
		var drop: Dictionary = game.drops[i]
		if not game.accepts_drop(drop):continue
		var node := orb("drop%d" % i, point(drop.p, 0.2), game.rarity_color(drop.rarity))
		node.scale = Vector3(0.23, 0.45, 0.23)
		ring("loot_ring%d"%i,point(drop.p,.06),.35,game.rarity_color(drop.rarity))
		if int(drop.rarity)>=3:
			var beam:=orb("loot_beam%d"%i,point(drop.p,1.1),game.rarity_color(drop.rarity))
			beam.scale=Vector3(.04,1.1,.04)
		text3d("droptext%d" % i, game.rules.data.rarity_names[int(drop.rarity)]+" · "+str(drop.value.name) if drop.kind == "item" else "젬", point(drop.p, 0.65), game.rarity_color(drop.rarity))
	for i in range(game.effects.size()): draw_effect(game.effects[i], i)
	for i in range(game.active_stage().roads.size()):
		var stage: Dictionary = game.active_stage()
		if maxi(stage.connections[i][0], stage.connections[i][1]) <= game.profile.cleared.size(): continue
		var road: Array = stage.roads[i]
		var p: Array = road[int(road.size() / 2)]
		ring("gate%d" % i, point(Vector2(p[0], p[1]), 0.1), 0.5, Color("ffc17a"))
		text3d("gate_text%d" % i, "이전 구역 정리", point(Vector2(p[0], p[1]), 1.0), Color("ffc17a"))

func material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if materials.has(key): return materials[key]
	var result := StandardMaterial3D.new()
	result.albedo_color = color.lerp(Color(color.v, color.v, color.v, color.a), 0.18).darkened(0.12)
	result.roughness = 0.85
	materials[key] = result
	return result

func mesh(parent: Node3D, shape: Mesh, position_: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = shape
	node.position = position_
	node.material_override = material(color)
	parent.add_child(node)
	return node

func box(parent: Node3D, position_: Vector3, size_: Vector3, color: Color) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size_
	return mesh(parent, shape, position_, color)

func cylinder(parent: Node3D, position_: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 10
	return mesh(parent, shape, position_, color)

func actor(key: String, color: Color, boss: bool, model: String = "") -> Node3D:
	if actors.has(key): actors[key].visible = true; return actors[key]
	var node := Node3D.new()
	add_child(node)
	actors[key] = node
	if key == "hero" or key.begins_with("enemy"):
		models.build(node, "hero" if key == "hero" else (model if not model.is_empty() else ("cyclops" if boss else "satyr")))
		return node
	box(node, Vector3(0, 0.77, 0), Vector3(0.46, 0.5, 0.28), color)
	var head := SphereMesh.new()
	head.radius = 0.2
	head.height = 0.4
	head.radial_segments = 10
	head.rings = 5
	mesh(node, head, Vector3(0, 1.22, 0), Color("c3946c"))
	if boss: box(node, Vector3(0, 1.24, 0.19), Vector3(0.15, 0.06, 0.04), Color("352d25"))
	elif key.begins_with("enemy"):
		for side in [-1, 1]:
			var horn := CylinderMesh.new()
			horn.top_radius = 0
			horn.bottom_radius = 0.08
			horn.height = 0.28
			horn.radial_segments = 6
			mesh(node, horn, Vector3(side * 0.16, 1.45, 0), Color("e1cf9d"))
	else:
		cylinder(node, Vector3(0, 1.37, 0), 0.215, 0.12, Color("b69752"))
		if key == "hero": box(node, Vector3(0, 1.52, 0), Vector3(0.07, 0.22, 0.38), Color("a53b2f"))
	for side in [-1, 1]:
		var leg := box(node, Vector3(side * 0.13, 0.3, 0), Vector3(0.16, 0.55, 0.18), Color("6d5440"))
		leg.name = "LeftLeg" if side == -1 else "RightLeg"
		box(node, Vector3(side * 0.32, 0.8, 0), Vector3(0.14, 0.43, 0.16), Color("be946e"))
	var weapon := Node3D.new()
	weapon.name = "Weapon"
	node.add_child(weapon)
	box(weapon, Vector3(0.42, 0.65, 0.37), Vector3(0.075, 0.07, 0.75), Color("eee2bd"))
	box(weapon, Vector3(0.42, 0.65, 0.06), Vector3(0.26, 0.08, 0.06), Color("9e713d"))
	return node

func pose(node: Node3D, phase: float, spin: bool) -> void:
	if node.has_node("Model"):
		models.pose(node,phase,spin)
		return
	if node.has_node("Art"):
		var art: Sprite3D = node.get_node("Art")
		art.flip_h = sin(node.rotation.y) < 0
		art.position.y = 0.58 + sin(phase) * 0.025
		art.scale = Vector3(1.0 + sin(phase) * 0.018, 1.0, 1.0)
		if spin: art.scale.x = 0.65 + absf(cos(clock * 18)) * 0.35
		node.rotation.y = 0
		return
	node.get_node("LeftLeg").rotation.x = sin(phase) * 0.4
	node.get_node("RightLeg").rotation.x = -sin(phase) * 0.4
	node.get_node("Weapon").rotation.y = clock * 20 if spin else sin(game.attack_flash * 12) * 0.8
	if spin: node.rotation.y = clock * 18

func orb(key: String, position_: Vector3, color: Color) -> MeshInstance3D:
	if not ornaments.has(key):
		var shape := SphereMesh.new()
		shape.radius = 0.5
		shape.height = 1
		shape.radial_segments = 8
		shape.rings = 4
		ornaments[key] = mesh(self, shape, position_, color)
	var node: MeshInstance3D = ornaments[key]
	node.visible = true
	node.position = position_
	node.material_override = material(color)
	return node

func ring(key: String, position_: Vector3, radius: float, color: Color) -> void:
	if not ornaments.has(key):
		var shape := TorusMesh.new()
		shape.inner_radius = 0.94
		shape.outer_radius = 1.0
		shape.rings = 32
		shape.ring_segments = 6
		ornaments[key] = mesh(self, shape, position_, color)
	var node: MeshInstance3D = ornaments[key]
	node.visible = true
	node.position = position_
	node.scale = Vector3(radius, 0.7, radius)
	node.material_override = material(color)

func text3d(key: String, text: String, position_: Vector3, color: Color) -> void:
	if not ornaments.has(key):
		var label := Label3D.new()
		label.font = font
		label.font_size = 40
		label.pixel_size = 0.005
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		add_child(label)
		ornaments[key] = label
	var node: Label3D = ornaments[key]
	node.visible = true
	node.text = text
	node.position = position_
	node.modulate = color

func health_bar(key: String, position_: Vector3, ratio: float, color: Color) -> void:
	health_markers.append({"key": key, "p": position_, "ratio": clampf(ratio, 0, 1), "color": color})

func add_character_art(node: Node3D, id: String) -> void:
	if not character_textures.has(id): character_textures[id] = load("res://assets/characters/" + id + ".png")
	var texture: Texture2D = character_textures[id]
	var art := Sprite3D.new()
	art.name = "Art"
	art.texture = texture
	art.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	art.pixel_size = 1.16 / texture.get_height()
	art.position.y = 0.58
	art.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	art.alpha_scissor_threshold = 0.15
	art.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(art)
	var shadow := CylinderMesh.new()
	shadow.top_radius = 0.19
	shadow.bottom_radius = 0.19
	shadow.height = 0.008
	shadow.radial_segments = 20
	mesh(node, shadow, Vector3(0, 0.012, 0), Color("665f4f"))

func draw_effect(fx: Dictionary, i: int) -> void:
	var key := "fx%d" % i
	if fx.kind == "number":
		text3d(key + "text", fx.text, point(fx.p, 1.1 + (0.55 - fx.life)), Color("ffe1a1"))
	elif fx.kind == "level_up":
		ring(key + "ring", point(game.player, 0.1), 0.3 + (2 - fx.life) * 0.8, Color("ffe56d"))
		text3d(key + "text", "LEVEL UP!", point(game.player, 2.0), Color("ffe56d"))
		for ray in range(10):
			var v := orb(key + str(ray), point(game.player + Vector2.from_angle(ray * TAU / 10) * 40, (2 - fx.life) * 1.5), Color("fff1a5"))
			v.scale = Vector3(0.06, 0.35, 0.06)
	elif fx.kind == "slash":
		var blade_key:=key+"solid_blade"
		if not ornaments.has(blade_key):
			var shape:=PrismMesh.new();shape.size=Vector3(.12,1.0,.055)
			ornaments[blade_key]=mesh(self,shape,Vector3.ZERO,Color("dceafa"))
		var blade:MeshInstance3D=ornaments[blade_key]
		var phase:float=clampf(1-float(fx.life)/.23,0,1)
		var sweep:float=float(fx.get("angle",0))+deg_to_rad(float(fx.get("arc",150)))*(phase-.5)
		blade.visible=true;blade.position=point(fx.p+Vector2.from_angle(sweep)*float(fx.radius)*.65,.7)
		blade.rotation=Vector3(PI/2,-sweep+PI/2,0)
		blade.scale=Vector3(1,1.5 if game.visual_weapon=="spear" else 1,1)
		var key_:String=key+"blade_arc"
		if not ornaments.has(key_):
			var ribbon:=SurfaceTool.new()
			ribbon.begin(Mesh.PRIMITIVE_TRIANGLES)
			for step in range(36):
				var a:float=float(step)/36*TAU
				var b:float=float(step+1)/36*TAU
				for v in [Vector3(cos(a)*.82,0,sin(a)*.82),Vector3(cos(a),0,sin(a)),Vector3(cos(b),0,sin(b)),Vector3(cos(a)*.82,0,sin(a)*.82),Vector3(cos(b),0,sin(b)),Vector3(cos(b)*.82,0,sin(b)*.82)]: ribbon.add_vertex(v)
			ribbon.generate_normals()
			var arc_node:=mesh(self,ribbon.commit(),Vector3.ZERO,Color("fff1c8"))
			var shader:=Shader.new()
			shader.code="shader_type spatial; render_mode unshaded,cull_disabled,blend_add; uniform float sweep=2.6; uniform float fade=1.0; varying vec3 pos; void vertex(){pos=VERTEX;} void fragment(){float angle=atan(pos.z,pos.x); float a=1.0-smoothstep(sweep*.4,sweep*.5,abs(angle)); ALBEDO=vec3(1.0,.85,.55); ALPHA=a*fade;}"
			var sm:=ShaderMaterial.new()
			sm.shader=shader
			arc_node.material_override=sm
			ornaments[key_]=arc_node
		var arc_node:MeshInstance3D=ornaments[key_]
		arc_node.visible=true
		arc_node.position=point(fx.p,.65)
		arc_node.scale=Vector3.ONE*float(fx.radius)*.01
		arc_node.rotation.y=-float(fx.get("angle",0))
		arc_node.material_override.set_shader_parameter("sweep",deg_to_rad(float(fx.get("arc",150))))
		arc_node.material_override.set_shader_parameter("fade",clampf(float(fx.life)/.23,0,1))
	elif fx.kind in ["curse", "thunder"]:
		ring(key + "ring", point(fx.p, 0.4 if fx.kind == "slash" else 0.1), float(fx.get("radius", 50)) * 0.01, Color("ffdf91") if fx.kind == "slash" else Color("abcfff"))
		if fx.kind == "thunder":
			var bolt := orb(key + "beam", point(fx.p, 2), Color("ecf6ff"))
			bolt.visible = false
			elements.draw(key+"thunder",point(fx.p,1.7),"lightning",Vector2(.8,3.5))
	elif fx.kind == "chain":
		elements.lightning(key+"chain",point(fx.p,.7),point(fx.to,.7),.7)
	elif fx.kind == "travel":
		for step in range(8):
			var v := orb(key + str(step), point(fx.p.lerp(fx.to, step / 7.0), 0.7), Color("b1e6ff"))
			v.scale = Vector3.ONE * 0.13
	else:
		var element: String = fx.get("element", "physical")
		var color: Color = {"fire": Color("ff803e"), "ice": Color("a5eaff"), "lightning": Color("cbb3ff")}.get(element, Color("eed7ad"))
		for ray in range(8):
			var offset: Vector2 = Vector2.from_angle(ray * TAU / 8) * (1.0 - fx.life) * 50
			var v := orb(key + str(ray), point(fx.p + offset, 0.6), color)
			v.scale = Vector3(0.1, 0.24, 0.1) if element == "ice" else Vector3.ONE * 0.12
			if element != "physical":
				v.visible=false
				elements.draw(key+str(ray),v.position,element,Vector2(.35,.5))

func build_town() -> void:
	natural.town()
	box(terrain, Vector3(6.4, -0.65, 4), Vector3(80, 0.3, 80), Color("246071"))
	box(terrain, Vector3(6.4, -0.035, 4.6), Vector3(8.5, 0.08, 0.8), Color("d0bd91"))
	box(terrain, Vector3(3.4, 0.45, 2.2), Vector3(1.9, 0.9, 1.15), Color("936546"))
	box(terrain, Vector3(3.4, 1.8, 2.2), Vector3(2.3, 0.12, 1.7), Color("a6503e"))
	for x in [2.4, 4.4]: cylinder(terrain, Vector3(x, 0.9, 2.7), 0.055, 1.8, Color("765437"))
	for x in [8.0, 8.5, 9.0, 9.5]: cylinder(terrain, Vector3(x, 0.85, 1.8), 0.13, 1.7, Color("e2d8b8"))
	box(terrain, Vector3(8.75, 1.8, 1.8), Vector3(2.15, 0.22, 1.0), Color("dbcca9"))
	cylinder(terrain, Vector3(6.4, 0.15, 3.1), 0.6, 0.3, Color("dbd0ae"))
	cylinder(terrain, Vector3(6.4, 0.32, 3.1), 0.48, 0.03, Color("4d9da6"))
	box(terrain, Vector3(3.2, 0.3, 5.65), Vector3(0.85, 0.6, 0.5), Color("895738"))
	for i in range(10): box(terrain, Vector3(10.2 + i * 0.22, -0.01, 5.4), Vector3(0.2, 0.15, 1.2), Color("9b7850"))
	decorate_town()

func build_coast() -> void:
	landscapes.build()
	decorate_stage(game.active_stage())

func vase(p: Vector3, color: Color) -> void:
	var shape := SphereMesh.new()
	shape.radius = 0.18
	shape.height = 0.46
	shape.radial_segments = 10
	shape.rings = 5
	mesh(terrain, shape, p + Vector3(0, 0.25, 0), color)
	cylinder(terrain, p + Vector3(0, 0.51, 0), 0.075, 0.15, color)
	cylinder(terrain, p + Vector3(0, 0.59, 0), 0.09, 0.035, Color("4b332c"))
	for side in [-1, 1]:
		var handle := TorusMesh.new()
		handle.inner_radius = 0.06
		handle.outer_radius = 0.09
		handle.rings = 12
		handle.ring_segments = 5
		var node := mesh(terrain, handle, p + Vector3(side * 0.13, 0.43, 0), color)
		node.rotation.x = PI / 2

func column(p: Vector3, height: float, color: Color) -> void:
	box(terrain, p + Vector3(0, 0.1, 0), Vector3(0.62, 0.2, 0.62), color)
	cylinder(terrain, p + Vector3(0, height / 2, 0), 0.19, height, color)
	box(terrain, p + Vector3(0, height, 0), Vector3(0.52, 0.16, 0.52), color)
	for angle in range(8):
		var offset := Vector3(cos(angle * TAU / 8), 0, sin(angle * TAU / 8)) * 0.18
		cylinder(terrain, p + offset + Vector3(0, height / 2, 0), 0.025, height * 0.85, color.darkened(0.12))

func olive(p: Vector3, scale_: float) -> void:
	cylinder(terrain, p + Vector3(0, scale_ * 0.6, 0), 0.12 * scale_, scale_ * 1.2, Color("675640"))
	for i in range(3):
		var leaf := SphereMesh.new()
		leaf.radius = 0.48 * scale_
		leaf.height = 0.8 * scale_
		leaf.radial_segments = 8
		leaf.rings = 4
		mesh(terrain, leaf, p + Vector3((i - 1) * 0.3, 1.25 + i % 2 * 0.25, 0) * scale_, Color("71805a"))

func gable(p: Vector3, width: float, depth: float) -> void:
	var vertices := [Vector3(-width/2, 0, -depth/2), Vector3(width/2, 0, -depth/2), Vector3(0, 0.55, -depth/2), Vector3(-width/2, 0, depth/2), Vector3(width/2, 0, depth/2), Vector3(0, 0.55, depth/2)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in [0,2,1,3,4,5,0,3,5,0,5,2,1,2,5,1,5,4]: surface.add_vertex(vertices[index])
	surface.generate_normals()
	var node := mesh(terrain, surface.commit(), p, Color("b37451"))
	var roof_material := material(Color("b37451")).duplicate()
	roof_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = roof_material

func decorate_town() -> void:
	# Tall village props stay beyond the existing walking rectangle.
	gable(Vector3(8.75, 1.94, 1.8), 2.4, 1.4)
	for i in range(3):
		box(terrain, Vector3(8.75, 0.03 + i * 0.04, 2.15 - i * 0.15), Vector3(2.3 - i * 0.12, 0.08, 0.45), Color("d6c6a2"))
	for p in [Vector3(1.7, 0, 3.1), Vector3(10.9, 0, 2.8), Vector3(2.0, 0, 6.2)]: olive(p, 0.9)
	for i in range(4): vase(Vector3(2.55 + i * 0.3, 0, 1.45), Color("b57d4a"))
	for x in [4.7, 5.6]:
		box(terrain, Vector3(x, 0.5, 1.45), Vector3(0.7, 1.0, 0.8), Color("d3c6a8"))
		gable(Vector3(x, 1.0, 1.45), 0.9, 1.0)
	for i in range(18):
		var tile := box(terrain, Vector3(4.9 + i * 0.17, 0.022, 4.6), Vector3(0.09, 0.025, 0.7), Color("aa9265"))
		tile.rotation.y = PI / 6
	box(terrain, Vector3(12.2, -0.08, 6.3), Vector3(2.4, 0.55, 0.85), Color("6c4934"))
	cylinder(terrain, Vector3(12.2, 1.2, 6.3), 0.045, 2.5, Color("735132"))
	box(terrain, Vector3(12.6, 1.8, 6.3), Vector3(0.8, 1.1, 0.035), Color("e6d5ad"))

func decorate_stage(stage: Dictionary) -> void:
	var theme: int = game.stages.find(stage)
	var stone := Color(stage.sand)
	# Major props use existing blocked rock footprints, never new invisible obstacles.
	for i in range(stage.rocks.size()):
		var rock: Array = stage.rocks[i]
		var p := point(Vector2(rock[0], rock[1]), 0.15)
		match theme:
			2, 6: olive(p, 0.85)
			3:
				box(terrain, p + Vector3(0, 0.55, 0), Vector3(0.4, 1.1, 0.22), Color("82778b"))
				cylinder(terrain, p + Vector3(0, 1.2, 0), 0.12, 0.15, Color("87bac2"))
			5, 8:
				var spire := CylinderMesh.new()
				spire.top_radius = 0.02
				spire.bottom_radius = 0.28
				spire.height = 1.5
				spire.radial_segments = 5
				mesh(terrain, spire, p + Vector3(0, 0.4, 0), Color("536f79"))
			_: column(p, 0.8 + (i % 3) * 0.4, stone)
	for zone in range(stage.centers.size()):
		var center := Vector2(stage.centers[zone][0], stage.centers[zone][1])
		# Ground mosaics do not obstruct movement or cover hit telegraphs.
		for i in range(16):
			var angle := i * TAU / 16
			var p := center + Vector2.from_angle(angle) * 105
			if not game.world.walkable(p): continue
			var tile := box(terrain, point(p, 0.012), Vector3(0.12, 0.024, 0.3), stone.darkened(0.15))
			tile.rotation.y = -angle
		# War-worn standards flank the outskirts, leaving the route clear.
		var standard := point(center + Vector2(300, 125))
		cylinder(terrain, standard + Vector3(0,.8,0), .035, 1.6, Color("514638"))
		box(terrain,standard+Vector3(.22,1.25,0),Vector3(.42,.55,.025),Color("652b2b"))
		var shield := cylinder(terrain,standard+Vector3(-.25,.12,.2),.22,.08,Color("796344"))
		shield.rotation.z = .65
		for offset in [Vector2(-260,125),Vector2(250,-130)]:
			var torch_p:=point(center+offset)
			cylinder(terrain,torch_p+Vector3(0,.5,0),.065,1.0,Color("514132"))
			var flame:=OmniLight3D.new()
			flame.position=torch_p+Vector3(0,1.1,0)
			flame.light_color=Color("ffb461")
			flame.light_energy=0.9
			flame.omni_range=2.7
			terrain.add_child(flame)
			var fire_mesh:=SphereMesh.new()
			fire_mesh.radius=.09
			fire_mesh.height=.32
			var fire:=mesh(terrain,fire_mesh,flame.position,Color("ffb452"))
			var fire_mat:=StandardMaterial3D.new()
			fire_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
			fire_mat.albedo_color=Color("ffd28a")
			fire.material_override=fire_mat
		var sign := Label3D.new()
		sign.font = font
		sign.text = stage.zones[zone]
		sign.font_size = 36
		sign.pixel_size = 0.006
		sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sign.position = point(center + Vector2(0, -170), 0.15)
		sign.modulate = Color("e3ce9e")
		terrain.add_child(sign)
	# Sea details follow map bounds; underworld gets a quieter dark river.
	if theme == 3: return
	for i in range(40):
		var center: Array = stage.centers[i % stage.centers.size()]
		var p := Vector2(center[0], center[1]) + Vector2.from_angle(i * 2.4) * (330 + i % 5 * 35)
		if game.world.walkable(p): continue
		box(terrain, point(p, -0.33), Vector3(0.55 + i % 3 * 0.25, 0.015, 0.025), Color(stage.sea).lightened(0.17))

func sword_arc(index:int,bolt:Dictionary)->void:
	var key:="sword_arc%d"%index
	if not ornaments.has(key):
		var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(20):
			var a:float=-1.35+i*2.7/20;var b:float=a+2.7/20
			var v:Array=[]
			for pair in [[a,.85],[a,.68],[b,.85],[b,.68]]:v.append(Vector3(sin(pair[0])*pair[1],0,cos(pair[0])*pair[1]))
			for n in [0,1,2,2,1,3]:surface.add_vertex(v[n])
		surface.generate_normals()
		ornaments[key]=mesh(self,surface.commit(),Vector3.ZERO,Color("c8eafa"))
	var node:MeshInstance3D=ornaments[key]
	node.visible=true;node.position=point(bolt.p,.5);node.rotation.y=atan2(bolt.v.x,bolt.v.y)
