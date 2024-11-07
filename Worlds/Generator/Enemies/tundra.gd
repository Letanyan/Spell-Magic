class_name TundraGen

enum TUNDRA_STRUCTURES_KIND {
	NONE
}

const TUNDRA_STRUCTURE = {
	TUNDRA_STRUCTURES_KIND.NONE: 120
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
		var struct := Rand.entity_from_distribution(rng.randf(), TUNDRA_STRUCTURE) as TUNDRA_STRUCTURES_KIND
		
		match struct:
			TUNDRA_STRUCTURES_KIND.NONE:
				pass
			#HFIL_STRUCTURES_KIND.MUSHROOM_FIELD:
				#var pos := area[index]
				#var ratio := rng.randf()
				#if rng.randf() < 0.5:
					#var radius := rng.randf_range(5, 15)
					#for i in Rand.roll(8, 4, 2, rng, Rand.Accum.AVG):
						#var kind := World.Foliage.MUSHROOM_POINTED if rng.randf() < ratio else World.Foliage.MUSHROOM_BULB
						#var p := pop.spawn_foliage(kind, state, pos + Rand.point_in_circle_2d(radius, rng), spacing) as Foliage
						#if p != null: result.append(p)
				#else:
					#var w := rng.randf_range(5, 15)
					#var h := rng.randf_range(5, 15)
					#var r := rng.randf_range(-PI, PI)
					#for i in Rand.roll(8, 4, 2, rng, Rand.Accum.AVG):
						#var kind := World.Foliage.MUSHROOM_POINTED if rng.randf() < ratio else World.Foliage.MUSHROOM_BULB
						#var p := pop.spawn_foliage(kind, state, pos + Rand.point_in_rect_2d(w, h, r, rng), spacing) as Foliage
						#if p != null: result.append(p)
			#HFIL_STRUCTURES_KIND.MUSH_ENEMIES:
				#var pos := area[index]
				#var king := pop.spawn_enemy(World.Enemy.MUSHKING, state, pos, spacing) as Mushking
				#if king != null: result.append(king)
				#var minion_count := Rand.entity_from_distribution(rng.randf(), {5: 0.25, 4: 0.125, 3: 0.5, 2: 0.25, 1: 0.125}) as int
				#var angle_offset := rng.randf_range(0, 2 * PI)
				#var radius_offset := rng.randf_range(10, 20)
				#var path := Pathway.new().circle(radius_offset + 5, 0, 1)
				#path.apply_transform(T.rotated(Vector3.UP, angle_offset))
				#for c in path.sample_points_xz(minion_count):
					#var minion := pop.spawn_enemy(World.Enemy.MUSHROOM, state, pos + c, spacing) as Mushroom
					#if minion != null:
						#result.append(minion)
					#
			#HFIL_STRUCTURES_KIND.SNOT_ENEMIES:
				#var pos := area[index]
				#var king := pop.spawn_enemy(World.Enemy.SNOT_BLOB, state, pos, spacing) as SnotBlob
				#if king != null: result.append(king)
				#var minion_count := Rand.entity_from_distribution(rng.randf(), {5: 0.25, 4: 0.125, 3: 0.5, 2: 0.25, 1: 0.125}) as int
				#var angle_offset := rng.randf_range(0, 2 * PI)
				#var radius_offset := rng.randf_range(10, 20)
				#var path := Pathway.new().circle(radius_offset + 5, 0, 1)
				#path.apply_transform(T.rotated(Vector3.UP, angle_offset))
				#for c in path.sample_points_xz(minion_count):
					#var minion := pop.spawn_enemy(World.Enemy.SNOT_SPIKE, state, pos + c, spacing) as SnotSpike
					#if minion != null:
						#result.append(minion)
					#
			#HFIL_STRUCTURES_KIND.HOT_DRAGONS:
				#var pos := area[index]
				#var king := pop.spawn_enemy(World.Enemy.DRAGON if rng.randf() < 0.8 else World.Enemy.DRAGOON, state, pos, spacing) as Enemy
				#if king != null: result.append(king)
				#var minion_count := Rand.roll(8, 3, 0, rng, Rand.Accum.AVG)
				#var angle_offset := rng.randf_range(0, 2 * PI)
				#var radius_offset := rng.randf_range(10, 20)
				#var path := Pathway.new().ngon(1, 3, radius_offset, Easing.linear, rng).apply_transform(T.rotated(Vector3.UP, angle_offset))
				#for c in path.sample_points_xz(minion_count):
					#var minion := pop.spawn_enemy(World.Enemy.HOT_BLOB, state, pos + c, spacing) as HotBlob
					#if minion != null:
						#result.append(minion)
						#
			#HFIL_STRUCTURES_KIND.ENEMY_MIX:
				#var pos := area[index]
				#var king_count := Rand.entity_from_distribution(rng.randf(), { 4: 1, 3: 2, 2: 4, 1: 8  }) as int
				#var radius := rng.randf_range(10.0, 15.0)
				#var king_path := Pathway.new().ngon(1, king_count, radius, Easing.linear, rng).apply_transform(T.rotated(Vector3.UP, rng.randf() * 2 * PI))
				#var king_ratio := { World.Enemy.SNOT_SPIKE: rng.randf(), World.Enemy.MUSHKING: rng.randf(), World.Enemy.DRAGOON: rng.randf() }
				#for c in king_path.sample_points_xz(king_count):
					#var king := pop.spawn_enemy(Rand.entity_from_distribution(rng.randf(), king_ratio) as World.Enemy, state, pos + c, spacing)
					#if king != null: result.append(king)
					#
				#var minion_layers := Rand.entity_from_distribution(rng.randf(), { 1: 20, 2: 10, 3: 5}) as int
				#
				#for layer in minion_layers:
					#var minion_count := king_count + Rand.entity_from_distribution(rng.randf(), { 6: 1, 5: 2, 4: 4, 3: 8, 2: 16, 1: 32  }) as int
					#radius += rng.randf_range(10.0, 15.0)
					#var minion_path := Pathway.new().random_points_in_disc(1, radius, radius + rng.randf_range(10, 15), 0, 8, Easing.linear, rng)
					#var minion_ratio := { World.Enemy.SNOT_BLOB: rng.randf(), World.Enemy.MUSHROOM: rng.randf(), World.Enemy.DRAGON: rng.randf() }
					#for c in minion_path.sample_points_xz(minion_count):
						#var minion := pop.spawn_enemy(Rand.entity_from_distribution(rng.randf(), minion_ratio) as World.Enemy, state, pos + c, spacing)
						#if minion != null: result.append(minion)
				
				
		index += 1
	return result
					
