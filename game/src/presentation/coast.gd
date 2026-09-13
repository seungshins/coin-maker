extends Node2D
var game: Node2D
var hero: Texture2D
var satyr: Texture2D
var cyclops: Texture2D
var font := SystemFont.new()
var scenery: Array[Dictionary] = []
const CENTERS = [Vector2(470, 1000), Vector2(1320, 690), Vector2(2210, 1050)]
var centers: Array[Vector2] = [Vector2(470, 1000), Vector2(1320, 690), Vector2(2210, 1050)]
var stage: Dictionary

func configure() -> void:
	stage = game.active_stage()
	centers.clear()
	for pair in stage.centers: centers.append(Vector2(pair[0], pair[1]))
	queue_redraw()

func _ready() -> void:
	configure()
	font.font_names = PackedStringArray(["Malgun Gothic", "Apple SD Gothic Neo", "Noto Sans CJK KR", "Noto Sans CJK KR"])
	hero = load("res://assets/characters/odysseus.png")
	satyr = load("res://assets/characters/satyr.png")
	cyclops = load("res://assets/characters/cyclops.png")
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260910
	for i in range(220):
		var p := Vector2(rng.randf_range(100, 2700), rng.randf_range(400, 1500))
		if walkable(p): scenery.append({"p": p, "r": rng.randf_range(2, 6)})

func walkable(p: Vector2, through_zone: int = -1) -> bool:
	for zone in range(stage.polygons.size()):
		if through_zone >= 0 and zone > through_zone: continue
		var polygon: Array = stage.polygons[zone]
		var points := PackedVector2Array()
		for pair in polygon: points.append(Vector2(pair[0], pair[1]))
		if Geometry2D.is_point_in_polygon(p, points): return true
	for road_index in range(stage.roads.size()):
		if through_zone >= 0 and maxi(stage.connections[road_index][0], stage.connections[road_index][1]) > through_zone: continue
		var road: Array = stage.roads[road_index]
		for i in range(road.size() - 1):
			var a := Vector2(road[i][0], road[i][1])
			var b := Vector2(road[i + 1][0], road[i + 1][1])
			if Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p) < stage.road_width: return true
	return false

func _draw() -> void:
	if game == null: return
	draw_rect(Rect2(-1000, -1000, 5000, 4000), Color(stage.sea))
	for i in range(65):
		var y := 300.0 + i * 24
		var x := fmod(i * 137.0 + game.clock * 9, 3000) - 100
		draw_line(Vector2(x, y), Vector2(x + 50, y - 5), Color(0.35, 0.64, 0.64, 0.22), 2)
	for road in stage.roads:
		var points := PackedVector2Array()
		for pair in road: points.append(Vector2(pair[0], pair[1]))
		draw_polyline(points, Color(stage.sand), stage.road_width * 2, true)
		for point in points: draw_circle(point, stage.road_width, Color(stage.sand))
		draw_polyline(points, Color(stage.ground), 38, true)
	for polygon in stage.polygons:
		var points := PackedVector2Array()
		for pair in polygon: points.append(Vector2(pair[0], pair[1]))
		draw_colored_polygon(points, Color(stage.ground))
		points.append(points[0])
		draw_polyline(points, Color(stage.sand), 12, true)
	for s in scenery:
		if walkable(s.p): draw_circle(s.p, s.r, Color(0.3, 0.35, 0.23, 0.23))
	# Broken marble court, laid in offset diamond slabs rather than a checkerboard.
	for u in range(-4, 5):
		for v in range(-3, 4):
			var p := centers[1] + Vector2((u - v) * 32, (u + v) * 16)
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -14), p + Vector2(29, 0), p + Vector2(0, 14), p + Vector2(-29, 0)]), Color("d5c9a7"))
	for zone in range(centers.size()):
		draw_string(font, centers[zone] + Vector2(-110, -220), "%02d  %s" % [zone + 1, stage.zones[zone]], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("514831"))
	for index in range(stage.roads.size()):
		var last: int = maxi(stage.connections[index][0], stage.connections[index][1])
		if last > game.profile.cleared.size():
			var road: Array = stage.roads[index]
			var middle: Array = road[int(road.size() / 2)]
			var p := Vector2(middle[0], middle[1])
			draw_arc(p, 30, 0, TAU, 28, Color("e8a568"), 4)
			draw_string(font, p + Vector2(-60, -38), "이전 구역 정리", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ffe1b5"))
	# Beached wooden ship.
	var ship := Vector2(220, 1060)
	draw_colored_polygon(PackedVector2Array([ship + Vector2(-100, -25), ship + Vector2(65, -45), ship + Vector2(120, -10), ship + Vector2(55, 25), ship + Vector2(-90, 15)]), Color("674832"))
	for i in range(7): draw_line(ship + Vector2(-70 + i * 24, -20), ship + Vector2(-70 + i * 24, 15), Color("bd9360"), 3)
	draw_line(ship, ship + Vector2(0, -140), Color("533924"), 7)
	draw_colored_polygon(PackedVector2Array([ship + Vector2(0, -135), ship + Vector2(70, -70), ship + Vector2(4, -60)]), Color("e2d4ac"))
	for zone in game.profile.cleared:
		var c: Vector2 = centers[int(zone)]
		draw_arc(c, 55, 0, TAU, 40, Color("6ae2b5"), 3)
	for e in game.enemies:
		if e.dead: continue
		if e.windup > 0:
			var radius: float = 115 if e.kind == "boss" else (80 if e.kind == "archer" else 58)
			var target: Vector2 = e.target
			ellipse(target, Vector2(radius, radius * 0.7), Color(0.85, 0.16, 0.09, 0.22))
			draw_arc(target, radius, 0, TAU, 42, Color("f7a15b"), 3)
	var sorted: Array[Dictionary] = []
	for rock in game.rocks: sorted.append({"p": rock.p, "kind": "rock", "r": rock.r})
	for e in game.enemies: sorted.append({"p": e.p, "kind": "enemy", "e": e})
	for m in game.minions: sorted.append({"p": m.p, "kind": "minion", "m": m})
	sorted.append({"p": game.player, "kind": "hero"})
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.p.y < b.p.y)
	for a in sorted:
		match a.kind:
			"rock": rock_art(a.p, a.r)
			"hero": hero_art(a.p)
			"minion": minion_art(a.m)
			"enemy": enemy_art(a.e)
	for drop in game.drops:
		var color: Color = game.rarity_color(int(drop.rarity))
		var p: Vector2 = drop.p
		draw_circle(p, 11, Color(0.1, 0.1, 0.1, 0.5))
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -22), p + Vector2(8, -12), p + Vector2(0, -2), p + Vector2(-8, -12)]), color)
		draw_string(font, p + Vector2(-30, -28), "장비" if drop.kind == "item" else "스킬 젬", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
	for bolt in game.bolts:
		var p: Vector2 = bolt.p + Vector2(0, -28)
		if bolt.get("wave", false):
			var side: Vector2 = bolt.v.normalized().orthogonal()
			for flame in range(9):
				var base: Vector2 = bolt.p + side * (flame - 4) * 13
				draw_colored_polygon(PackedVector2Array([base - Vector2(9, 0), base + Vector2(sin(game.clock * 20 + flame) * 9, -28 - flame % 3 * 12), base + Vector2(9, 0)]), Color("ff9e36"))
			continue
		if bolt.get("returning", false): draw_arc(p, 12, 0, TAU, 16, Color("bde8ff"), 2)
		if bolt.friendly and not bolt.get("arrow", false):
			var direction: Vector2 = bolt.v.normalized()
			var normal := direction.orthogonal()
			var trail := PackedVector2Array()
			for segment in range(6): trail.append(p - direction * segment * 9 + normal * sin(segment * 2.7 + game.clock * 45) * 7)
			draw_polyline(trail, Color(0.25, 0.6, 1, 0.35), 12, true)
			draw_polyline(trail, Color("d2f8ff"), 3, true)
		if bolt.get("arrow", false):
			var direction: Vector2 = bolt.v.normalized()
			var tint: Color = {"ice_arrow": Color("99eaff"), "lightning_arrow": Color("b8acff"), "fire_arrow": Color("ff873a")}.get(bolt.get("skill_id", ""), Color("e0b873"))
			draw_line(p - direction * 40, p, Color(tint, 0.3), 9)
			draw_line(p - direction * 32, p, tint, 3)
			draw_line(p - direction.rotated(0.6) * 12, p, Color("fff0c2"), 3)
			draw_line(p - direction.rotated(-0.6) * 12, p, Color("fff0c2"), 3)
			continue
		draw_line(p - bolt.v.normalized() * 28, p, Color("8ce9ff") if bolt.friendly else Color("ee9a6b"), 4)
		draw_circle(p, 5, Color("f0f3dc"))
	for field in game.fields:
		var color := Color(0.5, 0.8, 1.0, 0.3) if field.kind in ["blizzard", "ice_zone"] else Color(1, 0.9, 0.4, 0.35)
		draw_circle(field.p, field.radius, color)
		draw_arc(field.p, field.radius, 0, TAU, 48, color.lightened(0.5), 3)
		if field.kind in ["blizzard", "ice_zone", "arrow_rain"]:
			for flake in range(22):
				var offset := Vector2.from_angle(flake * 2.4 + game.clock * 0.8) * (20 + fmod(flake * 31, field.radius - 20))
				var fall := fmod(game.clock * 1.7 + flake * 0.17, 1.0)
				var landing: Vector2 = field.p + offset
				var snow: Vector2 = landing + Vector2(35 * (1 - fall), -170 * (1 - fall))
				draw_line(snow + Vector2(4, -17), snow, Color(0.8, 0.94, 1.0, 0.8), 3)
				if field.kind == "arrow_rain":
					draw_line(snow, snow + Vector2(-9, -26), Color("ffe0a3"), 3)
					draw_line(snow + Vector2(-7, -6), snow, Color("ffffff"), 2)
				else: draw_circle(snow, 2.5, Color("effaff"))
				if fall > 0.8: draw_arc(landing, (fall - 0.8) * 55, 0, TAU, 12, Color(0.65, 0.88, 1, (1 - fall) * 4), 2)
			for ring in range(3):
				draw_arc(field.p, field.radius * (0.5 + ring * 0.2), game.clock * (1 + ring * 0.4), game.clock * (1 + ring * 0.4) + PI, 32, Color(0.65, 0.88, 1.0, 0.4), 3)
	for fx in game.effects:
		var alpha: float = clampf(fx.life * 4, 0, 1)
		if fx.kind == "level_up":
			var progress: float = 1.0 - fx.life / 2.0
			var origin: Vector2 = game.player
			draw_arc(origin, 25 + progress * 120, 0, TAU, 64, Color(1, 0.86, 0.25, 1 - progress), 6)
			for ray in range(12):
				var offset := Vector2.from_angle(ray * TAU / 12) * 40
				draw_line(origin + offset, origin + offset + Vector2(0, -90 * progress), Color(1, 0.95, 0.6, 1 - progress), 3)
			draw_string(font, origin + Vector2(-70, -140), "LEVEL UP!", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("ffe284"))
		elif fx.kind == "death":
			death_art(fx)
		elif fx.kind == "chain":
			var points := PackedVector2Array()
			for step in range(9): points.append(fx.p.lerp(fx.to, step / 8.0) + Vector2(sin(step * 3.4) * 12, -28))
			draw_polyline(points, Color(0.6, 0.8, 1, alpha), 4, true)
		elif fx.kind == "travel":
			var t: float = 1.0 - fx.life / 0.3
			var p: Vector2 = fx.p.lerp(fx.to, t) + Vector2(0, -sin(t * PI) * 75 if fx.leap else -15)
			draw_line(fx.p, p, Color(0.5, 0.85, 1, alpha * 0.4), 9)
			draw_arc(p, 23, 0, TAU, 20, Color(0.8, 0.95, 1, alpha), 4)
		elif fx.kind == "slash":
			var progress := clampf(1.0 - float(fx.life) / 0.23, 0, 1)
			var spin: bool = fx.arc >= 360
			var sweep: float = TAU if spin else deg_to_rad(fx.arc)
			var angle: float = fx.angle - sweep * 0.5 + sweep * progress
			var origin: Vector2 = fx.p + Vector2(0, -18)
			var ribbon := PackedVector2Array()
			var span := 2.4 if spin else 1.35
			for i in range(25):
				var f := i / 24.0
				ribbon.append(origin + Vector2.from_angle(angle - span + f * span) * fx.radius)
			for i in range(24, -1, -1):
				var f := i / 24.0
				ribbon.append(origin + Vector2.from_angle(angle - span + f * span) * (fx.radius - 7 - 22 * f))
			draw_colored_polygon(ribbon, Color(1.0, 0.65, 0.18, alpha * 0.55))
			draw_arc(origin, fx.radius, angle - span, angle, 40, Color(1, 0.65, 0.15, alpha * 0.3), 19)
			draw_arc(origin, fx.radius, angle - span * 0.7, angle, 32, Color(1, 0.96, 0.7, alpha), 5)
			blade_art(origin, angle, fx.radius, alpha)
			if spin:
				blade_art(origin, angle + PI, fx.radius * 0.85, alpha * 0.75)
				draw_arc(fx.p, fx.radius * 0.7, angle, angle + PI * 1.5, 38, Color(1, 0.88, 0.45, alpha * 0.6), 3)
		elif fx.kind == "cut":
			var origin: Vector2 = fx.p + Vector2(0, -38)
			var reach: float = (1.0 - fx.life / 0.22) * 42
			for angle in [-0.7, 1.0]:
				var direction := Vector2.from_angle(angle)
				draw_line(origin - direction * reach, origin + direction * reach, Color(1, 0.55, 0.15, alpha * 0.35), 12)
				draw_line(origin - direction * reach, origin + direction * reach, Color(1, 0.97, 0.82, alpha), 3)
		elif fx.kind == "thunder":
			var points := PackedVector2Array([fx.p + Vector2(0, -300), fx.p + Vector2(-30, -170), fx.p + Vector2(25, -135), fx.p])
			draw_polyline(points, Color(0.7, 0.9, 1, alpha), 9, true)
			draw_arc(fx.p, fx.radius, 0, TAU, 48, Color(1, 1, 0.7, alpha), 5)
		elif fx.kind == "curse":
			var tint: Color = {"vulnerability": Color("c578ff"), "chains": Color("77d7ff"), "frailty": Color("b9d27b")}.get(fx.get("curse_id", "vulnerability"), Color("c578ff"))
			tint.a = alpha
			draw_arc(fx.p, fx.radius, 0, TAU, 64, tint, 4)
			draw_arc(fx.p, fx.radius * 0.85, 0, TAU, 64, Color(0.6, 0.2, 0.8, alpha * 0.5), 10)
		elif fx.kind == "impact":
			for ray in range(7):
				var direction := Vector2.from_angle(ray * TAU / 7)
				var length_: float = (0.2 - fx.life) * 160
				draw_line(fx.p + direction * length_ * 0.4, fx.p + direction * length_, Color(1, 0.9, 0.5, alpha), 3)
		else:
			draw_string(font, fx.p + Vector2(-12, -45 - (1 - fx.life) * 30), fx.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.88, 0.6, alpha))

func ellipse(p: Vector2, size: Vector2, color: Color) -> void:
	draw_set_transform(p, 0, size)
	draw_circle(Vector2.ZERO, 1, color)
	draw_set_transform(Vector2.ZERO)

func rock_art(p: Vector2, radius: float) -> void:
	ellipse(p, Vector2(radius, radius * 0.5), Color(0, 0, 0, 0.25))
	var alpha := 0.4 if game.player.distance_to(p + Vector2(0, -40)) < 60 else 1.0
	draw_colored_polygon(PackedVector2Array([p + Vector2(-radius, 0), p + Vector2(-radius * 0.6, -55), p + Vector2(radius * 0.25, -70), p + Vector2(radius, -15), p + Vector2(radius * 0.6, 10)]), Color(0.43, 0.44, 0.36, alpha))
	draw_line(p + Vector2(-radius * 0.5, -50), p + Vector2(radius * 0.2, -65), Color(0.78, 0.74, 0.6, alpha), 4)

func hero_art(p: Vector2) -> void:
	ellipse(p, Vector2(23, 10), Color(0, 0, 0, 0.28))
	var bob: float = sin(game.clock * 14) * 2.5 if game.moving else 0.0
	var scale_x := -1.0 if game.aim.x < 0 else 1.0
	var growth: float = game.battle_extras.hero_scale()
	if game.channeling: scale_x = cos(game.clock * 18) * 0.85
	var recoil: Vector2 = game.aim * sin(game.attack_flash * 14) * 7
	draw_set_transform(p + Vector2(0, bob) + recoil, sin(game.attack_flash * 12) * 0.14, Vector2(scale_x, 1 + game.attack_flash * 0.08) * growth)
	if hero:
		draw_texture_rect(hero, Rect2(-39, -104, 78, 112), false, Color(1.4, 1.2, 1.0) if game.hurt_time > 0 else Color.WHITE)
	draw_set_transform(Vector2.ZERO)
	var stats: Dictionary = game.rules.stats(game.profile)
	draw_rect(Rect2(p + Vector2(-26, -120 * growth), Vector2(52, 6)), Color("183e31"))
	draw_rect(Rect2(p + Vector2(-26, -120), Vector2(52 * clampf(game.health / stats.hp, 0, 1), 6)), Color("59e5a1"))
	draw_rect(Rect2(p + Vector2(-26, -120 * growth + 8), Vector2(52 * clampf(game.mana / stats.mana, 0, 1), 3)), Color("65baff"))
	if game.channeling:
		for blade in range(3):
			var angle: float = game.clock * 18 + blade * TAU / 3
			blade_art(p + Vector2(0, -23), angle, 87 * growth, 0.85)
			draw_arc(p + Vector2(0, -23), 80 * growth, angle - 1.3, angle, 24, Color(1, 0.88, 0.55, 0.65), 6)
	if game.guard > 0: draw_arc(p, 29, 0, TAU, 32, Color("f1d08c"), 2)

func enemy_art(e: Dictionary) -> void:
	var p: Vector2 = e.p
	var affix: String = e.get("affix", "")
	var big: bool = e.kind == "boss"
	var texture: Texture2D = cyclops if big else satyr
	var size := Vector2(145, 155) if big else Vector2(65, 98)
	if e.dead:
		if e.death_time > 0:
			draw_set_transform(p, (0.8 - e.death_time) * 1.2, Vector2(1, maxf(0.2, e.death_time / 0.8)))
			draw_texture_rect(texture, Rect2(Vector2(-size.x / 2, -size.y + 8), size), false, Color(0.7, 0.6, 0.5, e.death_time / 0.8))
			draw_set_transform(Vector2.ZERO)
		return
	if not affix.is_empty():
		var tint: Color = {"swift": Color("76f0d0"), "fury": Color("ff9970"), "titan": Color("ceb4ff")}.get(affix, Color.WHITE)
		draw_arc(p, 26, 0, TAU, 28, tint, 3)
		draw_string(font, p + Vector2(-20, -119), {"swift": "질주", "fury": "격노", "titan": "거인"}.get(affix, ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, tint)
	var scale := 2.0 if big else 1.0
	if float(e.get("curse", 0)) > 0:
		draw_arc(p, 27 * scale, 0, TAU, 32, Color("b368e8"), 2)
	if float(e.get("chains", 0)) > 0:
		draw_arc(p, 29 * scale, 0, TAU, 32, Color("77d7ff"), 3)
		for link in range(6):
			draw_arc(p + Vector2.from_angle(link * TAU / 6) * 29 * scale, 5, 0, TAU, 10, Color("ccf1ff"), 2)
	if float(e.get("frailty", 0)) > 0: draw_arc(p, 30 * scale, 0, TAU, 32, Color("b9d27b"), 3)
	ellipse(p, Vector2(21, 9) * scale, Color(0, 0, 0, 0.25))
	var bob: float = sin(game.clock * 8 + e.id) * 2 if e.windup <= 0 else -4
	var facing := -1.0 if game.player.x > p.x else 1.0
	draw_set_transform(p + Vector2(0, bob), -0.07 if e.windup > 0 else 0.0, Vector2(facing, 1))
	draw_texture_rect(texture, Rect2(Vector2(-size.x / 2, -size.y + 8), size), false, Color(1.8, 1.4, 1.1) if e.hit > 0 else Color.WHITE)
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(p + Vector2(-22 * scale, -size.y - 3), Vector2(44 * scale, 4)), Color("392d26"))
	draw_rect(Rect2(p + Vector2(-22 * scale, -size.y - 3), Vector2(44 * scale * maxf(0, e.hp / e.max_hp), 4)), Color("b64636"))

func blade_art(origin: Vector2, angle: float, length_: float, alpha: float) -> void:
	var direction := Vector2.from_angle(angle)
	var side := direction.orthogonal()
	var grip := origin + direction * 23
	var shoulder := origin + direction * 43
	var tip := origin + direction * length_
	draw_line(origin + direction * 13, shoulder, Color(0.65, 0.36, 0.14, alpha), 7)
	draw_line(grip - side * 13, grip + side * 13, Color(1, 0.8, 0.38, alpha), 5)
	draw_colored_polygon(PackedVector2Array([shoulder - side * 6, tip, shoulder + side * 6, grip]), Color(0.85, 0.93, 1, alpha))
	draw_line(shoulder, tip, Color(1, 1, 1, alpha), 2)

func minion_art(m: Dictionary) -> void:
	var p: Vector2 = m.p + Vector2(0, sin(game.clock * 5 + m.life) * 3)
	var alpha := minf(0.85, m.life)
	ellipse(p, Vector2(18, 8), Color(0.3, 0.8, 0.9, 0.25))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-14, -34), p + Vector2(14, -34), p + Vector2(22, 0), p + Vector2(-22, 0)]), Color(0.35, 0.8, 0.85, alpha))
	draw_circle(p + Vector2(0, -46), 12, Color(0.7, 1, 1, alpha))
	for x in [-5, 5]: draw_circle(p + Vector2(x, -48), 2, Color("14343b"))
	draw_line(p + Vector2(23, 0), p + Vector2(23, -65), Color(0.85, 1, 1, alpha), 3)
	draw_line(p + Vector2(17, -53), p + Vector2(23, -65), Color(0.85, 1, 1, alpha), 3)
	draw_rect(Rect2(p + Vector2(-20, -70), Vector2(40, 4)), Color("15343f"))
	draw_rect(Rect2(p + Vector2(-20, -70), Vector2(40 * maxf(0, m.hp / m.max_hp), 4)), Color("6cdcec"))

func death_art(fx: Dictionary) -> void:
	var t := clampf(1.0 - float(fx.life) / 0.65, 0, 1)
	var alpha := 1.0 - t
	var p: Vector2 = fx.p
	var color: Color = {"physical": Color("e8c1a0"), "fire": Color("ff883e"), "ice": Color("a0e9ff"), "lightning": Color("d7c0ff")}.get(fx.element, Color.WHITE)
	color.a = alpha
	if fx.element == "fire":
		draw_circle(p, 12 + t * 38, Color(1, 0.4, 0.12, alpha * 0.38))
		draw_arc(p, 12 + t * 60, 0, TAU, 36, color, 5)
	for i in range(10):
		var direction := Vector2.from_angle(i * TAU / 10)
		var point := p + direction * (8 + t * 65)
		if fx.element == "ice":
			draw_colored_polygon(PackedVector2Array([point + direction * 12, point + direction.orthogonal() * 5, point - direction * 7, point - direction.orthogonal() * 5]), color)
		elif fx.element == "lightning":
			draw_polyline(PackedVector2Array([p + direction * 9, point + direction.orthogonal() * 11, point - direction.orthogonal() * 7, point + direction * 15]), color, 3)
		else: draw_line(point, point + direction * 13, color, 3)
