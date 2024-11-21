class_name HFILGen
extends BiomeGenerator

enum HFILStructuresKind {
	NONE,
	MUSHROOM_FIELD,
	ENEMY_MIX,
	MUSH_ENEMIES, SNOT_ENEMIES, HOT_DRAGONS
}

var HFIL_structure := {
	HFILStructuresKind.NONE: 120,
	HFILStructuresKind.MUSHROOM_FIELD: 10,
	HFILStructuresKind.MUSH_ENEMIES: 0.1,
	HFILStructuresKind.SNOT_ENEMIES: 0.05,
	HFILStructuresKind.HOT_DRAGONS: 0.0125,
	HFILStructuresKind.ENEMY_MIX: 0.0125,
}

func setup_state(pop: Population) -> void:
	Rand.normalise_distribution(HFIL_structure)

func populate(pop: Population, area: PackedVector2Array, from: Globals.Ref, limit: int, rng: RandomNumberGenerator, spacing: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var index := from.data as int
	while index < area.size() and pop.current_spawn_duration_ms < limit:
		if exclusion.has(index):
			index += 1
			continue
		var struct := Rand.entity_from_non_relative_distribution(rng.randf(), HFIL_structure) as HFILStructuresKind
		
		match struct:
			HFILStructuresKind.NONE:
				pass
			HFILStructuresKind.MUSHROOM_FIELD:
				var pos := area[index]
				var ratio := rng.randf()
				if rng.randf() < 0.5:
					var radius := rng.randf_range(5, 15)
					var point_count := Rand.roll(8, 4, 2, rng, Rand.Accum.AVG)
					var path := Pathway.new().random_points_in_disc(1, 0, radius, 0, point_count)
					path.apply_transform(T.translated(Vec3.xz(pos)))
					spawn_foliage_randomly(pop, point_count, path, {World.Foliage.MUSHROOM_POINTED: 1 - ratio, World.Foliage.MUSHROOM_BULB: ratio}, rng, spacing)
				else:
					var w := rng.randf_range(5, 15)
					var h := rng.randf_range(5, 15)
					var r := rng.randf_range(-PI, PI)
					var point_count := Rand.roll(8, 4, 2, rng, Rand.Accum.AVG)
					var path := Pathway.new().random_points_in_rect(1, w, 0, h, point_count)
					path.apply_transform(T.rotated(Vector3.UP, r).translated(Vec3.xz(pos)))
					spawn_foliage_randomly(pop, point_count, path, {World.Foliage.MUSHROOM_POINTED: 1 - ratio, World.Foliage.MUSHROOM_BULB: ratio}, rng, spacing)
						
			HFILStructuresKind.MUSH_ENEMIES:
				var pos := area[index]
				var king := pop.spawn_enemy(World.Enemy.MUSHKING, pos, spacing) as Mushking
				if king != null: result.append(king)
				var minion_count := Rand.entity_from_distribution(rng.randf(), {5: pop.fit(0.25, 0.5), 4: pop.fit(0.125, 0.5), 3: pop.fit(0.5, 0.25), 2: pop.fit(0.25, 0.25), 1: pop.fit(0.125, 0)}) as int
				var angle_offset := rng.randf_range(0, 2 * PI)
				var radius_offset := rng.randf_range(10, 20)
				var path := Pathway.new().circle(radius_offset + 5, 0, 1)
				path.apply_transform(T.rotated(Vector3.UP, angle_offset).translated(Vec3.xz(pos)))
				spawn_enemies_randomly(result, pop, minion_count, path, {World.Enemy.MUSHROOM: 1, World.Enemy.FUNGI: 1}, rng, spacing)
					
			HFILStructuresKind.SNOT_ENEMIES:
				var pos := area[index]
				var king := pop.spawn_enemy(World.Enemy.SNOT_BLOB, pos, spacing) as SnotBlob
				if king != null: result.append(king)
				var minion_count := Rand.entity_from_distribution(rng.randf(), {5: pop.fit(0.25, 0.5), 4: pop.fit(0.125, 0.5), 3: pop.fit(0.5, 0.25), 2: pop.fit(0.25, 0.25), 1: pop.fit(0.125, 0)}) as int
				var angle_offset := rng.randf_range(0, 2 * PI)
				var radius_offset := rng.randf_range(10, 20)
				var path := Pathway.new().circle(radius_offset + 5, 0, 1)
				path.apply_transform(T.rotated(Vector3.UP, angle_offset).translated(Vec3.xz(pos)))
				spawn_enemies_randomly(result, pop, minion_count, path, {World.Enemy.SNOT_SPIKE: 1}, rng, spacing)
					
			HFILStructuresKind.HOT_DRAGONS:
				var pos := area[index]
				var king := pop.spawn_enemy(World.Enemy.DRAGON if rng.randf() < pop.fit(0.8, 0.2) else World.Enemy.DRAGOON, pos, spacing) as Enemy
				if king != null: result.append(king)
				var minion_count := Rand.roll(8, 3, 0, rng, Rand.Accum.AVG)
				var angle_offset := rng.randf_range(0, 2 * PI)
				var radius_offset := rng.randf_range(10, 20)
				var path := Pathway.new().ngon(1, 3, radius_offset, Easing.linear, rng)
				path.apply_transform(T.rotated(Vector3.UP, angle_offset).translated(Vec3.xz(pos)))
				spawn_enemies_randomly(result, pop, minion_count, path, {World.Enemy.HOT_BLOB: 1}, rng, spacing)
						
			HFILStructuresKind.ENEMY_MIX:
				var pos := area[index]
				var king_count := Rand.entity_from_distribution(rng.randf(), { 4: pop.fit(1, 8), 3: pop.fit(2, 4), 2: pop.fit(4, 2), 1: pop.fit(8, 1)  }) as int
				var radius := rng.randf_range(10.0, 15.0)
				var king_path := Pathway.new().ngon(1, king_count, radius, Easing.linear, rng)
				king_path.apply_transform(T.rotated(Vector3.UP, rng.randf() * 2 * PI).translated(Vec3.xz(pos)))
				var king_ratio := { World.Enemy.SNOT_SPIKE: rng.randf(), World.Enemy.MUSHKING: rng.randf(), World.Enemy.DRAGOON: rng.randf() }
				spawn_enemies_randomly(result, pop, king_count, king_path, king_ratio, rng, spacing)
					
				var minion_layers := Rand.entity_from_distribution(rng.randf(), { 1: pop.fit(20, 5), 2: 10, 3: pop.fit(5, 20)}) as int
				
				for layer in minion_layers:
					var minion_count := king_count + Rand.entity_from_distribution(rng.randf(), { 6: 1, 5: 2, 4: 4, 3: 8, 2: 16, 1: 32  }) as int
					radius += rng.randf_range(10.0, 15.0)
					var minion_path := Pathway.new().random_points_in_disc(1, radius, radius + rng.randf_range(10, 15), 0, 8, Easing.linear, rng)
					minion_path.apply_transform(T.translated(Vec3.xz(pos)))
					var minion_ratio := { World.Enemy.SNOT_BLOB: rng.randf(), World.Enemy.MUSHROOM: rng.randf(), World.Enemy.DRAGON: rng.randf(), World.Enemy.FUNGI: rng.randf() }
					spawn_enemies_randomly(result, pop, minion_count, minion_path, minion_ratio, rng, spacing)
				
				
		index += 1
		
	from.data = index
	return result
					
