extends Node2D
## Disposable P1 arena harness. Domain calculations are kept separate.
const Math = preload("res://src/domain/combat_math.gd")
var player := Vector2(640, 370)
var enemies: Array[Dictionary] = []
var bolts: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var health := 100.0
var gold := 0
var kills := 0
var fire_time := 0.0
var dodge_time := 0.0
var dodge_cooldown := 0.0
var dodge_direction := Vector2.RIGHT
var time := 0.0
var paused := false
var label: Label

func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	label = Label.new()
	label.position = Vector2(28, 20)
	label.add_theme_font_size_override("font_size", 21)
	layer.add_child(label)
	reset_arena()

func reset_arena() -> void:
	player = Vector2(640, 370)
	health = 100.0
	paused = false
	fire_time = 0.0
	dodge_time = 0.0
	dodge_cooldown = 0.0
	gold = 0
	kills = 0
	bolts.clear()
	effects.clear()
	enemies.clear()
	for i in range(12):
		var angle := float(i) * TAU / 12.0
		enemies.append({"pos": Vector2(640, 380) + Vector2(cos(angle) * 380, sin(angle) * 190), "hp": 60.0, "hit": 0.0, "cooldown": 0.0, "dead": false})

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			paused = not paused
		if event.keycode == KEY_R:
			reset_arena()
		if event.keycode == KEY_SPACE and dodge_cooldown <= 0.0 and not paused and health > 0:
			dodge_direction = (get_global_mouse_position() - player).normalized()
			dodge_time = 0.25
			dodge_cooldown = 1.5

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		paused = true

func _physics_process(delta: float) -> void:
	label.text = "ITHACA / THE FIRST SHORE\nHP %d   GOLD %d   DEFEATED %d / 12\nWASD Move  |  Mouse + LMB Cast  |  Space Dodge  |  ESC Pause  |  R Restart" % [int(health), gold, kills]
	if paused:
		label.text += "\nPAUSED - ESC to resume"
	if health <= 0:
		label.text += "\nThe voyage is not over. Press R to retry."
	if kills == 12:
		label.text += "\nSHORE CLEARED - Press R to sail again."
	if paused or health <= 0 or kills == 12:
		queue_redraw()
		return
	time += delta
	fire_time = maxf(0, fire_time - delta)
	dodge_cooldown = maxf(0, dodge_cooldown - delta)
	dodge_time = maxf(0, dodge_time - delta)
	var move := Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))).normalized()
	if dodge_time > 0:
		move = dodge_direction * 3.0
	player += move * 210.0 * delta
	player.x = clampf(player.x, 170, 1110)
	player.y = clampf(player.y, 190, 630)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and fire_time <= 0:
		var direction := (get_global_mouse_position() - player).normalized()
		bolts.append({"pos": player, "velocity": direction * 700.0, "life": 1.4})
		fire_time = 0.23
	for enemy in enemies:
		if enemy.dead:
			continue
		enemy.hit = maxf(0, enemy.hit - delta)
		enemy.cooldown = maxf(0, enemy.cooldown - delta)
		var distance: float = enemy.pos.distance_to(player)
		if distance > 26:
			enemy.pos += (player - enemy.pos).normalized() * 65.0 * delta
		elif enemy.cooldown <= 0:
			enemy.cooldown = 0.85
			if dodge_time <= 0:
				health = maxf(0, health - 8)
	for index in range(bolts.size() - 1, -1, -1):
		var bolt := bolts[index]
		var old: Vector2 = bolt.pos
		bolt.pos += bolt.velocity * delta
		bolt.life -= delta
		for enemy in enemies:
			if not enemy.dead and Math.segment_hits(old, bolt.pos, enemy.pos, 19):
				enemy.hp -= Math.hit_damage(25, 0, 1, 0)
				enemy.hit = 0.12
				bolt.life = 0
				effects.append({"pos": enemy.pos, "life": 0.25, "death": false})
				if enemy.hp <= 0:
					enemy.dead = true
					gold += 10
					kills += 1
					effects.append({"pos": enemy.pos, "life": 0.7, "death": true})
				break
		if bolt.life <= 0:
			bolts.remove_at(index)
	for index in range(effects.size() - 1, -1, -1):
		effects[index].life -= delta
		if effects[index].life <= 0:
			effects.remove_at(index)
	queue_redraw()

func draw_actor(point: Vector2, color: Color, phase: float, is_player: bool) -> void:
	draw_ellipse_shadow(point)
	var bob := sin(phase) * 2.0
	draw_line(point + Vector2(-6, -8), point + Vector2(-7 + sin(phase) * 3, 0), color.darkened(0.3), 5)
	draw_line(point + Vector2(6, -8), point + Vector2(7 - sin(phase) * 3, 0), color.darkened(0.3), 5)
	draw_colored_polygon(PackedVector2Array([point + Vector2(-11, -31 + bob), point + Vector2(8, -34 + bob), point + Vector2(13, -10), point + Vector2(-12, -10)]), color)
	draw_circle(point + Vector2(0, -40 + bob), 9, Color("ddba88"))
	if is_player:
		draw_line(point + Vector2(8, -25), point + (get_global_mouse_position() - point).normalized() * 32 + Vector2(0, -22), Color("a5ecff"), 4)

func draw_ellipse_shadow(point: Vector2) -> void:
	draw_set_transform(point, 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 17, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	for u in range(-12, 13):
		for v in range(-12, 13):
			var origin := Vector2(640, 390) + Math.tile_to_world(Vector2(u, v))
			var tile := PackedVector2Array([origin + Vector2(0, -16), origin + Vector2(32, 0), origin + Vector2(0, 16), origin + Vector2(-32, 0)])
			var color := Color("5b665e") if (u + v) % 2 == 0 else Color("536159")
			draw_colored_polygon(tile, color)
	var actors: Array[Dictionary] = [{"pos": player, "player": true}]
	for enemy in enemies:
		if not enemy.dead:
			actors.append({"pos": enemy.pos, "player": false, "hit": enemy.hit})
	actors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.pos.y < b.pos.y)
	for actor in actors:
		var color := Color("55c9df") if actor.player else Color("bd674b")
		if not actor.player and actor.hit > 0:
			color = Color.WHITE
		draw_actor(actor.pos, color, time * 12.0, actor.player)
	for bolt in bolts:
		draw_line(bolt.pos - bolt.velocity.normalized() * 20 + Vector2(0, -22), bolt.pos + Vector2(0, -22), Color("a6edff"), 4)
	for effect in effects:
		var radius: float = (0.7 - effect.life) * 35 if effect.death else (0.25 - effect.life) * 65
		draw_arc(effect.pos + Vector2(0, -20), maxf(1, radius), 0, TAU, 20, Color(1, 0.8, 0.35, minf(1, effect.life * 4)), 2)
