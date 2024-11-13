class_name HFILGen
extends BiomeGenerator

enum HFIL_STRUCTURES_KIND {
	NONE,
	MUSHROOM_FIELD,
	ENEMY_MIX,
	MUSH_ENEMIES, SNOT_ENEMIES, HOT_DRAGONS
}

const HFIL_STRUCTURE = {
	HFIL_STRUCTURES_KIND.NONE: 120,
	HFIL_STRUCTURES_KIND.MUSHROOM_FIELD: 10,
	HFIL_STRUCTURES_KIND.MUSH_ENEMIES: 0.1,
	HFIL_STRUCTURES_KIND.SNOT_ENEMIES: 0.05,
	HFIL_STRUCTURES_KIND.HOT_DRAGONS: 0.0125,
	HFIL_STRUCTURES_KIND.ENEMY_MIX: 0.0125,
}

func populate(pop: Population, area: PackedVector2Array, from: Globals.Ref, limit: int, rng: RandomNumberGenerator, spacing: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var index := from.data as int
	while index < area.size() and pop.current_iteration_spawn_count < limit:
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
						pop.spawn_foliage(kind, pos + Rand.point_in_circle_2d(radius, rng), spacing)
				else:
					var w := rng.randf_range(5, 15)
					var h := rng.randf_range(5, 15)
					var r := rng.randf_range(-PI, PI)
					for i in Rand.roll(8, 4, 2, rng, Rand.Accum.AVG):
						var kind := World.Foliage.MUSHROOM_POINTED if rng.randf() < ratio else World.Foliage.MUSHROOM_BULB
						pop.spawn_foliage(kind, pos + Rand.point_in_rect_2d(w, h, r, rng), spacing)
						
			HFIL_STRUCTURES_KIND.MUSH_ENEMIES:
				var pos := area[index]
				var king := pop.spawn_enemy(World.Enemy.MUSHKING, pos, spacing) as Mushking
				if king != null: result.append(king)
				var minion_count := Rand.entity_from_distribution(rng.randf(), {5: pop.fit(0.25, 0.5), 4: pop.fit(0.125, 0.5), 3: pop.fit(0.5, 0.25), 2: pop.fit(0.25, 0.25), 1: pop.fit(0.125, 0)}) as int
				var angle_offset := rng.randf_range(0, 2 * PI)
				var radius_offset := rng.randf_range(10, 20)
				var path := Pathway.new().circle(radius_offset + 5, 0, 1)
				path.apply_transform(T.rotated(Vector3.UP, angle_offset))
				for c in path.sample_points_xz(minion_count):
					var minion := pop.spawn_enemy(World.Enemy.MUSHROOM if rng.randf() < 0.5 else World.Enemy.FUNGI, pos + c, spacing) as Mushroom
					if minion != null:
						result.append(minion)
					
			HFIL_STRUCTURES_KIND.SNOT_ENEMIES:
				var pos := area[index]
				var king := pop.spawn_enemy(World.Enemy.SNOT_BLOB, pos, spacing) as SnotBlob
				if king != null: result.append(king)
				var minion_count := Rand.entity_from_distribution(rng.randf(), {5: pop.fit(0.25, 0.5), 4: pop.fit(0.125, 0.5), 3: pop.fit(0.5, 0.25), 2: pop.fit(0.25, 0.25), 1: pop.fit(0.125, 0)}) as int
				var angle_offset := rng.randf_range(0, 2 * PI)
				var radius_offset := rng.randf_range(10, 20)
				var path := Pathway.new().circle(radius_offset + 5, 0, 1)
				path.apply_transform(T.rotated(Vector3.UP, angle_offset))
				for c in path.sample_points_xz(minion_count):
					var minion := pop.spawn_enemy(World.Enemy.SNOT_SPIKE, pos + c, spacing) as SnotSpike
					if minion != null:
						result.append(minion)
					
			HFIL_STRUCTURES_KIND.HOT_DRAGONS:
				var pos := area[index]
				var king := pop.spawn_enemy(World.Enemy.DRAGON if rng.randf() < pop.fit(0.8, 0.2) else World.Enemy.DRAGOON, pos, spacing) as Enemy
				if king != null: result.append(king)
				var minion_count := Rand.roll(8, 3, 0, rng, Rand.Accum.AVG)
				var angle_offset := rng.randf_range(0, 2 * PI)
				var radius_offset := rng.randf_range(10, 20)
				var path := Pathway.new().ngon(1, 3, radius_offset, Easing.linear, rng).apply_transform(T.rotated(Vector3.UP, angle_offset))
				for c in path.sample_points_xz(minion_count):
					var minion := pop.spawn_enemy(World.Enemy.HOT_BLOB, pos + c, spacing) as HotBlob
					if minion != null:
						result.append(minion)
						
			HFIL_STRUCTURES_KIND.ENEMY_MIX:
				var pos := area[index]
				var king_count := Rand.entity_from_distribution(rng.randf(), { 4: pop.fit(1, 8), 3: pop.fit(2, 4), 2: pop.fit(4, 2), 1: pop.fit(8, 1)  }) as int
				var radius := rng.randf_range(10.0, 15.0)
				var king_path := Pathway.new().ngon(1, king_count, radius, Easing.linear, rng).apply_transform(T.rotated(Vector3.UP, rng.randf() * 2 * PI))
				var king_ratio := { World.Enemy.SNOT_SPIKE: rng.randf(), World.Enemy.MUSHKING: rng.randf(), World.Enemy.DRAGOON: rng.randf() }
				for c in king_path.sample_points_xz(king_count):
					var king := pop.spawn_enemy(Rand.entity_from_distribution(rng.randf(), king_ratio) as World.Enemy, pos + c, spacing)
					if king != null: result.append(king)
					
				var minion_layers := Rand.entity_from_distribution(rng.randf(), { 1: pop.fit(20, 5), 2: 10, 3: pop.fit(5, 20)}) as int
				
				for layer in minion_layers:
					var minion_count := king_count + Rand.entity_from_distribution(rng.randf(), { 6: 1, 5: 2, 4: 4, 3: 8, 2: 16, 1: 32  }) as int
					radius += rng.randf_range(10.0, 15.0)
					var minion_path := Pathway.new().random_points_in_disc(1, radius, radius + rng.randf_range(10, 15), 0, 8, Easing.linear, rng)
					var minion_ratio := { World.Enemy.SNOT_BLOB: rng.randf(), World.Enemy.MUSHROOM: rng.randf(), World.Enemy.DRAGON: rng.randf(), World.Enemy.FUNGI: rng.randf() }
					for c in minion_path.sample_points_xz(minion_count):
						var minion := pop.spawn_enemy(Rand.entity_from_distribution(rng.randf(), minion_ratio) as World.Enemy, pos + c, spacing)
						if minion != null: result.append(minion)
				
				
		index += 1
		
	from.data = index
	return result
					
