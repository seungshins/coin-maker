extends RefCounted

static func hit_damage(base: float, increased: float, more: float, resistance: float) -> float:
	return maxf(0.0, base * (1.0 + increased) * more * (1.0 - clampf(resistance, -0.5, 0.75)))

static func tile_to_world(tile: Vector2) -> Vector2:
	return Vector2((tile.x - tile.y) * 32.0, (tile.x + tile.y) * 16.0)

static func world_to_tile(point: Vector2) -> Vector2:
	return Vector2(point.x / 64.0 + point.y / 32.0, point.y / 32.0 - point.x / 64.0)

static func segment_hits(start: Vector2, finish: Vector2, target: Vector2, radius: float) -> bool:
	return Geometry2D.get_closest_point_to_segment(target, start, finish).distance_squared_to(target) <= radius * radius
