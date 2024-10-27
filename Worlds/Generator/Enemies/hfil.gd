class_name HFILGen

enum HFIL_STRUCTURES_KIND {
	NONE,
	MUSHROOM_FIELD,
	MUSH_ENEMIES, SNOT_ENEMIES, HOT_DRAGONS
}

const HFIL_STRUCTURE = {
	HFIL_STRUCTURES_KIND.NONE: 120,
	HFIL_STRUCTURES_KIND.MUSHROOM_FIELD: 10,
	HFIL_STRUCTURES_KIND.MUSH_ENEMIES: 0.1,
	HFIL_STRUCTURES_KIND.SNOT_ENEMIES: 0.05,
	HFIL_STRUCTURES_KIND.HOT_DRAGONS: 0.0125,
}

static func populate(pop: Population, state: PhysicsDirectSpaceState3D, area: PackedVector2Array, spacing: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var index := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(pop.coord)
	var exclusion := {}
	while index < area.size() - 1:
		if exclusion.has(index):
			index += 1
			continue
		var struct := Rand.entity_from_distribution(rng.randf(), HFIL_STRUCTURE) as HFIL_STRUCTURES_KIND
		
		match struct:
			HFIL_STRUCTURES_KIND.NONE:
				pass
			HFIL_STRUCTURES_KIND.MUSHROOM_FIELD:
				var pos := area[index]
				var ratio := rng.randf()
				if rng.randf() < 0.5:
					var radius := rng.randf_range(5, 15)
					for i in Rand.roll(8, 4, 2, rng, Rand.Accum.AVG):
						var kind := World.Foliage.MUSHROOM_POINTED if rng.randf() < ratio else World.Foliage.MUSHROOM_BULB
						var p := pop.spawn_foliage(kind, state, pos + Rand.point_in_circle_2d(radius, rng), spacing) as Foliage
						if p != null: result.append(p)
				else:
					var w := rng.randf_range(5, 15)
					var h := rng.randf_range(5, 15)
					var r := rng.randf_range(-PI, PI)
					for i in Rand.roll(8, 4, 2, rng, Rand.Accum.AVG):
						var kind := World.Foliage.MUSHROOM_POINTED if rng.randf() < ratio else World.Foliage.MUSHROOM_BULB
						var p := pop.spawn_foliage(kind, state, pos + Rand.point_in_rect_2d(w, h, r, rng), spacing) as Foliage
						if p != null: result.append(p)
			HFIL_STRUCTURES_KIND.MUSH_ENEMIES:
				var pos := area[index]
				var king := pop.spawn_enemy(World.Enemy.MUSHKING, state, pos, spacing) as Mushking
				if king != null: result.append(king)
				var minion_count := Rand.entity_from_distribution(rng.randf(), {5: 0.25, 4: 0.125, 3: 0.5, 2: 0.25, 1: 0.125}) as int
				var angle_offset := rng.randf_range(0, 2 * PI)
				var radius_offset := rng.randf_range(10, 20)
				var path := Pathway.new().circle(radius_offset + 5, 0, 1)
				path.apply_transform(Transform3D.IDENTITY.rotated(Vector3.UP, angle_offset))
				for c in path.sample_points_xz(minion_count):
					var minion := pop.spawn_enemy(World.Enemy.MUSHROOM, state, pos + c, spacing) as Mushroom
					if minion != null:
						result.append(minion)
					
			HFIL_STRUCTURES_KIND.SNOT_ENEMIES:
				var pos := area[index]
				var king := pop.spawn_enemy(World.Enemy.SNOT_BLOB, state, pos, spacing) as SnotBlob
				if king != null: result.append(king)
				var minion_count := Rand.entity_from_distribution(rng.randf(), {5: 0.25, 4: 0.125, 3: 0.5, 2: 0.25, 1: 0.125}) as int
				var angle_offset := rng.randf_range(0, 2 * PI)
				var radius_offset := rng.randf_range(10, 20)
				var path := Pathway.new().circle(radius_offset + 5, 0, 1)
				path.apply_transform(Transform3D.IDENTITY.rotated(Vector3.UP, angle_offset))
				for c in path.sample_points_xz(minion_count):
					var minion := pop.spawn_enemy(World.Enemy.SNOT_SPIKE, state, pos + c, spacing) as SnotSpike
					if minion != null:
						result.append(minion)
					
			HFIL_STRUCTURES_KIND.HOT_DRAGONS:
				var pos := area[index]
				var king := pop.spawn_enemy(World.Enemy.DRAGON if rng.randf() < 0.8 else World.Enemy.DRAGOON, state, pos, spacing) as Enemy
				if king != null: result.append(king)
				var minion_count := Rand.roll(8, 3, 0, rng, Rand.Accum.AVG)
				var angle_offset := rng.randf_range(0, 2 * PI)
				var radius_offset := rng.randf_range(10, 20)
				var path := Pathway.new() \
					.line_to(Vector3(radius_offset * 0.5, 0, radius_offset), 1) \
					.line_to(Vector3(radius_offset, 0, 0), 1) \
					.line_to(Vector3(0, 0, 0), 1)
				path.apply_transform(Transform3D.IDENTITY.rotated(Vector3.UP, angle_offset))
				for c in path.sample_points_xz(minion_count):
					var minion := pop.spawn_enemy(World.Enemy.HOT_BLOB, state, pos + c, spacing) as HotBlob
					if minion != null:
						result.append(minion)
				
				
		index += 1
	return result
					
