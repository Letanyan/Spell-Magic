class_name GrasslandGen
extends BiomeGenerator

enum GRASSLAND_STRUCTURES_KIND {
	NONE,
	TREE_ROUND, TREE_BRANCHED,
	VILLAGE,
	UNDEAD, MOLE,
	ABANDONED_VILLAGE,
	TARGET_PUZZLE,
	HIVE, SLIMY, FLOCK, PETS, FISH
}

const GRASSLAND_STRUCTURE = {
	GRASSLAND_STRUCTURES_KIND.NONE: 160,
	GRASSLAND_STRUCTURES_KIND.TREE_ROUND: 5,
	GRASSLAND_STRUCTURES_KIND.TREE_BRANCHED: 0.5,
	GRASSLAND_STRUCTURES_KIND.VILLAGE: 0.5,
	GRASSLAND_STRUCTURES_KIND.ABANDONED_VILLAGE: 0.05,
	GRASSLAND_STRUCTURES_KIND.HIVE: 0.1,
	GRASSLAND_STRUCTURES_KIND.SLIMY: 0.05,
	GRASSLAND_STRUCTURES_KIND.FLOCK: 0.1,
	GRASSLAND_STRUCTURES_KIND.PETS: 0.05,
	GRASSLAND_STRUCTURES_KIND.FISH: 0.1,
	#GRASSLAND_STRUCTURES_KIND.TARGET_PUZZLE: 0.01
}


func populate(pop: Population, area: Array[Vector2], from: Globals.Ref, limit: int, rng: RandomNumberGenerator, spacing: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var index := from.data as int
	while index < area.size() and pop.current_iteration_spawn_count < limit:
		if exclusion.has(index):
			index += 1
			continue
		var struct := Rand.entity_from_distribution(rng.randf(), GRASSLAND_STRUCTURE) as GRASSLAND_STRUCTURES_KIND
		match struct:
			GRASSLAND_STRUCTURES_KIND.NONE:
				pass
			GRASSLAND_STRUCTURES_KIND.TREE_ROUND:
				var pos := area[index] as Vector2
				pop.spawn_foliage(World.Foliage.TREE_ROUND, pos, spacing)
			GRASSLAND_STRUCTURES_KIND.TREE_BRANCHED:
				var pos := area[index] as Vector2
				pop.spawn_foliage(World.Foliage.TREE_BRANCHED, pos, spacing)
					
			GRASSLAND_STRUCTURES_KIND.FISH:
				var pos := area[index]
				
				if rng.randf() < pop.fit(0.8, 0.2):
					var p := pop.spawn_enemy(World.Enemy.FISH, pos, spacing)
					if p != null: result.append(p)
				else:
					var p := pop.spawn_enemy(World.Enemy.FISHMAN, pos, spacing)
					if p != null: result.append(p)
				
					
			GRASSLAND_STRUCTURES_KIND.HIVE:
				var pos := area[index]
				var r := Rand.entity_from_distribution(rng.randf(), {3: pop.fit(0.05, 0.5), 2: pop.fit(0.15, 0.5), 1: pop.fit(0.8, 0.5)}) as float
				var bee_count := rng.randi_range(roundi(r * 2), roundi(r * 5))
				var bumble_count := rng.randi_range(roundi(r * 1), roundi(r * 2))
				var art := Artifact.new("", Artifact.Option.make_effect(Artifact.Effect.BOOST_PERCENTAGE, Artifact.Element.FIRE, 2, Artifact.Pattern.TRIANGLE))
				if bee_count <= 0 and bumble_count <= 0:
					continue
					
				var radius := rng.randf_range(15.0, 30.0) 
				var angle_offset := rng.randf_range(0.0, 2 * PI)
				for i in 6:
					var p := pos + Vector2(radius, 0).rotated(PI * 2 * (float(i) / 6.0) + angle_offset)
					pop.spawn_foliage(World.Foliage.TREE_BRANCHED, p, 0.0, pop.always_valid)
					
				var spawner := pop.spawn_spawner(World.Item.ARTIFACT, pos, art)
				for i in bee_count:
					var p := pop.spawn_enemy(World.Enemy.BEE, pos + Rand.point_in_circle_2d(spacing * 2.0, rng), spacing)
					if p != null and spawner != null:
						result.append(p)
						spawner.add_condition(p)
				for i in bumble_count:
					var p := pop.spawn_enemy(World.Enemy.BUMBLE_BEE, pos + Rand.point_in_circle_2d(spacing * 2.0, rng), spacing)
					if p != null and spawner != null:
						result.append(p)
						spawner.add_condition(p)
				
			GRASSLAND_STRUCTURES_KIND.SLIMY:
				var pos := area[index]
				for i in rng.randi_range(5, 15):
					pop.spawn_foliage(World.Foliage.ROCK_EGG, pos + Rand.point_in_circle_2d(spacing * 2.0, rng), spacing)
				
				var r := Rand.entity_from_distribution(rng.randf(), {5: pop.fit(0.05, 0.5), 3: pop.fit(0.15, 0.5), 2: pop.fit(0.8, 0.5)}) as int
				var spike_count := rng.randi_range(1, r)
				var path := Pathway.new().random_points_in_disc(1, 0, spacing / 2.0, 0, spike_count, Easing.linear, rng)
				path.apply_transform(Transform3D.IDENTITY.translated(Vec3.xz(pos)))
				for spike_pos in path.sample_points_xz(spike_count):
					var p := pop.spawn_enemy(World.Enemy.SNOT_SPIKE, spike_pos, spacing)
					if p != null:
						result.append(p)
						var subpath := Pathway.new().random_points_in_disc(1, 0, spacing, 0, rng.randi_range(2,3), Easing.linear, rng)
						subpath.apply_transform(Transform3D.IDENTITY.translated(Vec3.xz(spike_pos)))
						for sp in subpath.sample_points_xz(rng.randi_range(2,3)):
							var q := pop.spawn_enemy(World.Enemy.SNOT_BLOB, sp, spacing)
							if q != null:
								result.append(q)
								
			GRASSLAND_STRUCTURES_KIND.FLOCK:
				var pos := area[index]
				var r := Rand.entity_from_distribution(rng.randf(), {10: pop.fit(0.05, 0.5), 5: pop.fit(0.15, 0.5), 3: pop.fit(0.8, 0.5)}) as int
				const circle_points = 3
				var angle_offset := rng.randf_range(0, 2 * PI)
				var radius_offset := rng.randf_range(0, float(r))
				var path := Pathway.new().circle(radius_offset + r * 8, 0, 1)
				path.apply_transform(Transform3D.IDENTITY.rotated(Vector3.UP, angle_offset).translated(Vec3.xz(pos)))
				for p in path.sample_points_xz(r * circle_points):
					var kind := Rand.entity_from_distribution(rng.randf(), {World.Foliage.ROCK_TALL: 10, World.Foliage.ROCK_EGG: 2, World.Foliage.TREE_ROUND: 10}) as World.Foliage
					pop.spawn_foliage(kind, p, 0, pop.always_valid)
					
				var mini_count := rng.randi_range(1, r)
				var boss := pop.spawn_enemy(World.Enemy.BIRDMAN, pos, spacing)
				if boss != null:
					result.append(boss)
				for i in mini_count:
					var p := pop.spawn_enemy(World.Enemy.BIRD, pos + Rand.point_in_circle_2d(r * 4, rng), spacing)
					if p != null:
						result.append(p)
						
			GRASSLAND_STRUCTURES_KIND.PETS:
				var pos := area[index]
				var r := Rand.entity_from_distribution(rng.randf(), {5: pop.fit(0.05, 0.5), 3: pop.fit(0.15, 0.5), 1: pop.fit(0.8, 0.5)}) as int
				const circle_points = 3
				var angle_offset := rng.randf_range(0, 2 * PI)
				var radius_offset := rng.randf_range(0, float(r))
				var path := Pathway.new().circle(radius_offset + r * 8, 0, 1)
				path.apply_transform(Transform3D.IDENTITY.translated(Vec3.xz(pos)).rotated(Vector3.UP, angle_offset))
				for p in path.sample_points_xz(r * circle_points):
					var kind := Rand.entity_from_distribution(rng.randf(), {World.Foliage.ROCK_TALL: 10, World.Foliage.ROCK_EGG: 2, World.Foliage.TREE_ROUND: 10}) as World.Foliage
					pop.spawn_foliage(kind, p, 0, pop.always_valid)
					
				var mini_count := rng.randi_range(1, r)
				for i in mini_count:
					var boss := pop.spawn_enemy(World.Enemy.RABBIT, pos + Rand.point_in_circle_2d(r * 4, rng), spacing)
					if boss != null:
						result.append(boss)
					var p := pop.spawn_enemy(World.Enemy.BIRD, pos + Rand.point_in_circle_2d(r * 4, rng), spacing)
					if p != null:
						result.append(p)
						 
				
			GRASSLAND_STRUCTURES_KIND.UNDEAD:
				var pos := area[index] as Vector2
				var p := pop.spawn_enemy(World.Enemy.UNDEAD, pos, spacing)
				if p != null:
					p.velocity_movement.current_biome = World.Biome.GRASSLAND
					result.append(p)
			GRASSLAND_STRUCTURES_KIND.MOLE:
				var pos := area[index] as Vector2
				var p := pop.spawn_enemy(World.Enemy.MOLE, pos, spacing)
				if p != null:
					p.velocity_movement.current_biome = World.Biome.GRASSLAND
					result.append(p)
			GRASSLAND_STRUCTURES_KIND.TARGET_PUZZLE:
				var pos := area[index] as Vector2
				
				var pos3 := Vector3.ZERO
				var spawner := pop.spawn_spawner(World.Item.KEY, pos, 2)
				
				for i in pop.fit(3, 8):
					var circle_path := Pathway.new().random_points_in_disc(2, 0, 2, 2, 8)
					var path := PathStyle.new(rng.randi(), pos3).follow_path(circle_path).align_y_to_ground_and_air()
					var config := TargetShape.config_for_damage(Spell.Element.FIRE, spawner, 5, Vitals.Stat.new(100), path)
					var p := pop.spawn_world_item(World.Item.TARGET, pos, spacing, config)
					pos3 = p.position
					path.origin = pos3
					if p != null and spawner != null:
						spawner.add_condition(p)
						result.append(p)				
					
				spawner.position = pos3
					
			#GRASSLAND_STRUCTURES_KIND.VILLAGE:
				#if area.size() - index < 100:
					#index += 1
					#continue
				#var candidates := Population.points_around(area[index], 100.0, index, area, exclusion, rng)
				#
				#var w: Buildings
				#for i in range(0, candidates.size()):
					#var j := candidates[i]
					#var pos := area[j] as Vector2
					#w = pop.spawn_building(World.Building.FANTASY_WELL, pos.x, pos.y, spacing)
					#if w != null:
						#exclusion[j] = true
						#result.append(w)
						#candidates.remove_at(i)
						#break
				#
				#var max_limit := rng.randi_range(1, 10)
				#for i in range(0, candidates.size()):
					#var j := candidates[i]
					#var pos := area[j] as Vector2
					#var p: Node3D
					#if rng.randf() < 0.7:
						#p = pop.spawn_building(World.Building.FANTASY_VALLEY_SINGLE, pos.x, pos.y, spacing)
					#else:
						#p = pop.spawn_building(World.Building.FANTASY_VALLEY_DOUBLE, pos.x, pos.y, spacing)
					#if p != null:
						#max_limit -= 1
						#exclusion[j] = true
						#result.append(p)
					#if max_limit <= 0:
						#break
						#
			#GRASSLAND_STRUCTURES_KIND.ABANDONED_VILLAGE:
				#if area.size() - index < 100:
					#index += 1
					#continue
				#var candidates := Population.points_around(area[index], 100.0, index, area, exclusion, rng)
				#
				#var w: Buildings
				#for i in range(0, candidates.size()):
					#var j := candidates[i]
					#var pos := area[j] as Vector2
					#w = pop.spawn_building(World.Building.FANTASY_WELL, pos.x, pos.y, spacing)
					#if w != null:
						#exclusion[j] = true
						#result.append(w)
						#candidates.remove_at(i)
						#break
				#
				#var max_limit := rng.randi_range(1, 10)
				#for i in range(0, candidates.size()):
					#var j := candidates[i]
					#var pos := area[j] as Vector2
					#var p: Node3D
					#var house_size := 0
					#if rng.randf() < 0.7:
						#p = pop.spawn_building(World.Building.FANTASY_VALLEY_SINGLE, pos.x, pos.y, spacing)
						#house_size = Rand.entity_from_distribution(rng.randf(), {1: 0.4, 2: 0.05})
					#else:
						#p = pop.spawn_building(World.Building.FANTASY_VALLEY_DOUBLE, pos.x, pos.y, spacing)
						#house_size = Rand.entity_from_distribution(rng.randf(), {1: 0.1, 2: 0.3, 3: 0.1, 4: 0.05})
					#if p != null:
						#max_limit -= 1
						#exclusion[j] = true
						#result.append(p)
						#var spawner := pop.spawn_spawner(World.Item.KEY, pos, 2)
						#if spawner != null:
							#SignalBus.enemy_death.connect(spawner.remove_node)
						#for k in house_size:
							#if rng.randf() < 0.2:
								#var n: Bat = pop.spawn_enemy(World.Enemy.BAT, pos.x, pos.y, spacing)
								#if n != null:
									#n.velocity_movement.current_biome = World.Biome.GRASSLAND
									#result.append(n)
									#if spawner != null:
										#spawner.add_condition(n)
							#else:
								#var n: Undead = pop.spawn_enemy(World.Enemy.UNDEAD, pos.x, pos.y, spacing)
								#if n != null:
									#n.velocity_movement.current_biome = World.Biome.GRASSLAND
									#result.append(n)
									#if spawner != null:
										#spawner.add_condition(n)
					#if max_limit <= 0:
						#break
		index += 1
					
	from.data = index
	return result
					
