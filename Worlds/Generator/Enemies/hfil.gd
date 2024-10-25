class_name HFILGen

enum HFIL_STRUCTURES_KIND {
	NONE,
	MUSHROOM_POINTED, MUSHROOM_BULB,
	MUSH_ENEMIES, SNOT_ENEMIES, HOT_DRAGONS
}

const HFIL_STRUCTURE = {
	HFIL_STRUCTURES_KIND.NONE: 120,
	HFIL_STRUCTURES_KIND.MUSHROOM_POINTED: 5,
	HFIL_STRUCTURES_KIND.MUSHROOM_BULB: 5,
	HFIL_STRUCTURES_KIND.MUSH_ENEMIES: 1,
	HFIL_STRUCTURES_KIND.SNOT_ENEMIES: 0.5,
	HFIL_STRUCTURES_KIND.HOT_DRAGONS: 0.125,
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
			HFIL_STRUCTURES_KIND.MUSHROOM_POINTED:
				var pos := area[index]
				var p := pop.spawn_foliage(World.Foliage.MUSHROOM_POINTED, state, pos, spacing) as Foliage
				if p != null: result.append(p)
			HFIL_STRUCTURES_KIND.MUSHROOM_BULB:
				var pos := area[index]
				var p := pop.spawn_foliage(World.Foliage.MUSHROOM_BULB, state, pos, spacing) as Foliage
				if p != null: result.append(p)
			HFIL_STRUCTURES_KIND.MUSH_ENEMIES:
				var pos := area[index]
				var king := pop.spawn_enemy(World.Enemy.MUSHKING, state, pos, spacing) as Mushking
				if king != null: result.append(king)
				var minion_count := Rand.entity_from_distribution(rng.randf(), {5: 0.25, 4: 0.125, 3: 0.5, 2: 0.25, 1: 0.125}) as int
				var angle_offset := rng.randf_range(0, 2 * PI)
				var radius_offset := rng.randf_range(5, 10)
				var path := Pathway.new().circle(radius_offset + 5, 0, 1)
				path.apply_transform(Transform3D.IDENTITY.rotated(Vector3.UP, angle_offset))
				for c in path.sample_points_xz(minion_count):
					var minion := pop.spawn_enemy(World.Enemy.MUSHROOM, state, pos + c, spacing) as Mushroom
					if minion != null:
						result.append(minion)
					
			HFIL_STRUCTURES_KIND.SNOT_ENEMIES:
				var pos := area[index]
				var king := pop.spawn_enemy(World.Enemy.SNOT_BLOB, state, pos, spacing) as Mushking
				if king != null: result.append(king)
				var minion_count := Rand.entity_from_distribution(rng.randf(), {5: 0.25, 4: 0.125, 3: 0.5, 2: 0.25, 1: 0.125}) as int
				var angle_offset := rng.randf_range(0, 2 * PI)
				var radius_offset := rng.randf_range(5, 10)
				var path := Pathway.new().circle(radius_offset + 5, 0, 1)
				path.apply_transform(Transform3D.IDENTITY.rotated(Vector3.UP, angle_offset))
				for c in path.sample_points_xz(minion_count):
					var minion := pop.spawn_enemy(World.Enemy.SNOT_SPIKE, state, pos + c, spacing) as Mushroom
					if minion != null:
						result.append(minion)
					
			HFIL_STRUCTURES_KIND.HOT_DRAGONS:
				var pos := area[index]
				var king := pop.spawn_enemy(World.Enemy.DRAGON if rng.randf() < 0.8 else World.Enemy.DRAGOON, state, pos, spacing) as Mushking
				if king != null: result.append(king)
				var minion_count := Rand.roll(8, 3, 0, rng, Rand.Accum.AVG)
				var angle_offset := rng.randf_range(0, 2 * PI)
				var radius_offset := rng.randf_range(5, 10)
				var path := Pathway.new() \
					.line_to(Vector3(radius_offset * 0.5, 0, radius_offset), 1) \
					.line_to(Vector3(radius_offset, 0, 0), 1) \
					.line_to(Vector3(0, 0, 0), 1)
				path.apply_transform(Transform3D.IDENTITY.rotated(Vector3.UP, angle_offset))
				for c in path.sample_points_xz(minion_count):
					var minion := pop.spawn_enemy(World.Enemy.SNOT_SPIKE, state, pos + c, spacing) as Mushroom
					if minion != null:
						result.append(minion)
				
				
		index += 1
	return result
					
