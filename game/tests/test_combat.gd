extends SceneTree
const Math = preload("res://src/domain/combat_math.gd")

func _initialize() -> void:
	assert(is_equal_approx(Math.hit_damage(120, 0.5, 1.4, 0.25), 189.0))
	assert(Math.hit_damage(100, 0, 1, 2) == 25.0)
	assert(Math.segment_hits(Vector2.ZERO, Vector2(1000, 0), Vector2(500, 5), 10))
	assert(not Math.segment_hits(Vector2.ZERO, Vector2(1000, 0), Vector2(500, 20), 10))
	for point in [Vector2.ZERO, Vector2(3, -4), Vector2(-9.5, 8.5)]:
		assert(Math.world_to_tile(Math.tile_to_world(point)).is_equal_approx(point))
	print("PASS: damage, resistance cap, swept hit, isometric round trip")
	quit()
