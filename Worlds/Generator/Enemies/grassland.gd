class_name GrasslandGen
extends BiomeGenerator

enum GrasslandStructuresKind {
	NONE,
	TREE_ROUND, TREE_BRANCHED,
	VILLAGE,
	ABANDONED_VILLAGE,
	TARGET_PUZZLE,
	HIVE, SLIMY, FLOCK, PETS, FISH
}

var grassland_structure := {
	GrasslandStructuresKind.NONE: 160,
	GrasslandStructuresKind.TREE_ROUND: 5,
	GrasslandStructuresKind.TREE_BRANCHED: 0.5,
	GrasslandStructuresKind.HIVE: 0.1,
	GrasslandStructuresKind.SLIMY: 0.05,
	GrasslandStructuresKind.FLOCK: 0.1,
	GrasslandStructuresKind.PETS: 0.05,
	GrasslandStructuresKind.FISH: 0.1,
	#GrasslandStructuresKind.TARGET_PUZZLE: 0.01
}

func setup_state(pop: Population) -> void:
	Rand.normalise_distribution(grassland_structure)

func populate(pop: Population, area: PackedVector2Array, from: Globals.Ref, limit: int, rng: RandomNumberGenerator, spacing: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var index := from.data as int
	while index < area.size() and pop.current_spawn_duration_ms < limit:
		if exclusion.has(index):
			index += 1
			continue
		var struct := Rand.entity_from_non_relative_distribution(rng.randf(), grassland_structure) as GrasslandStructuresKind
		match struct:
			GrasslandStructuresKind.NONE:
				pass
			GrasslandStructuresKind.TREE_ROUND:
				var pos := area[index] as Vector2
				pop.spawn_foliage(World.Foliage.TREE_ROUND, pos, spacing)
			GrasslandStructuresKind.TREE_BRANCHED:
				var pos := area[index] as Vector2
				pop.spawn_foliage(World.Foliage.TREE_BRANCHED, pos, spacing)
					
			GrasslandStructuresKind.FISH:
				var pos := area[index]
				
				if rng.randf() < pop.fit(0.8, 0.2):
					var p := pop.spawn_enemy(World.Enemy.FISH, pos, spacing)
					if p != null: result.append(p)
				else:
					var p := pop.spawn_enemy(World.Enemy.FISHMAN, pos, spacing)
					if p != null: result.append(p)
				
					
			GrasslandStructuresKind.HIVE:
				var pos := area[index]
				var r := Rand.entity_from_distribution(rng.randf(), {3: pop.fit(0.05, 0.5), 2: pop.fit(0.15, 0.5), 1: pop.fit(0.8, 0.5)}) as float
				var bee_count := rng.randi_range(roundi(r * 2), roundi(r * 5))
				var bumble_count := rng.randi_range(roundi(r * 1), roundi(r * 2))
				var art := Artifact.new("", Artifact.Option.make_effect(Artifact.Effect.BOOST_PERCENTAGE, Artifact.Element.FIRE, 2, Artifact.Pattern.TRIANGLE))
				if bee_count <= 0 and bumble_count <= 0:
					continue
					
				var radius := rng.randf_range(15.0, 30.0)
				var tree_path := Pathway.new().circle(radius, 0, 1)
				tree_path.apply_transform(T.rotated(Vector3.UP, 2 * PI * rng.randf()).translated(Vec3.xz(pos)))
				spawn_foliage_randomly(pop, 6, tree_path, {World.Foliage.TREE_BRANCHED: 1}, rng, spacing)
					
				var spawner := pop.spawn_spawner(World.Item.ARTIFACT, pos, art)
				var bee_path := Pathway.new().random_points_in_disc(1, 0, spacing * 2.0, 0, bee_count)
				bee_path.apply_transform(T.rotated(Vector3.UP, rng.randf() * PI).translated(Vec3.xz(pos)))
				spawn_enemies_randomly(result, pop, bee_count, bee_path, {World.Enemy.BEE: 1}, rng, spacing, spawner)
				var bumble_path := Pathway.new().random_points_in_disc(1, 0, spacing * 2.0, 0, bumble_count)
				bumble_path.apply_transform(T.rotated(Vector3.UP, rng.randf() * PI).translated(Vec3.xz(pos)))
				spawn_enemies_randomly(result, pop, bumble_count, bumble_path, {World.Enemy.BUMBLE_BEE: 1}, rng, spacing, spawner)
								
			GrasslandStructuresKind.FLOCK:
				var pos := area[index]
				var r := Rand.entity_from_distribution(rng.randf(), {10: pop.fit(0.05, 0.5), 5: pop.fit(0.15, 0.5), 3: pop.fit(0.8, 0.5)}) as int
				const circle_points = 3
				var angle_offset := rng.randf_range(0, 2 * PI)
				var radius_offset := rng.randf_range(0, float(r))
				var path := Pathway.new().circle(radius_offset + r * 8, 0, 1)
				path.apply_transform(T.rotated(Vector3.UP, angle_offset).translated(Vec3.xz(pos)))
				spawn_foliage_randomly(pop, r * circle_points, path, {World.Foliage.ROCK_TALL: pop.fit(1, 10), World.Foliage.ROCK_EGG: pop.fit(1, 2), World.Foliage.TREE_ROUND: pop.fit(1, 10)}, rng, spacing)
					
				var mini_count := rng.randi_range(1, r)
				var boss := pop.spawn_enemy(World.Enemy.BIRDMAN, pos, spacing)
				if boss != null:
					result.append(boss)
				var mini_path := Pathway.new().circle(r * 4, 0, 1)
				mini_path.apply_transform(T.rotated(Vector3.UP, angle_offset).translated(Vec3.xz(pos)))
				spawn_enemies_randomly(result, pop, mini_count, mini_path, {World.Enemy.BIRD: 1}, rng, spacing)
						
			GrasslandStructuresKind.PETS:
				var pos := area[index]
				var r := Rand.entity_from_distribution(rng.randf(), {5: pop.fit(0.05, 0.5), 3: pop.fit(0.15, 0.5), 1: pop.fit(0.8, 0.5)}) as int
				const circle_points = 3
				var angle_offset := rng.randf_range(0, 2 * PI)
				var radius_offset := rng.randf_range(0, float(r))
				var path := Pathway.new().circle(radius_offset + r * 8, 0, 1)
				path.apply_transform(T.rotated(Vector3.UP, angle_offset).translated(Vec3.xz(pos)))
				spawn_foliage_randomly(pop, r * circle_points, path, {World.Foliage.ROCK_TALL: pop.fit(1, 10), World.Foliage.ROCK_EGG: pop.fit(1, 2), World.Foliage.TREE_ROUND: pop.fit(1, 10)}, rng, spacing)
					
				var mini_count := rng.randi_range(1, r)
				for i in mini_count:
					var boss := pop.spawn_enemy(World.Enemy.RABBIT, pos + Rand.point_in_circle_2d(r * 4, rng), spacing)
					if boss != null:
						result.append(boss)
					var p := pop.spawn_enemy(World.Enemy.BIRD, pos + Rand.point_in_circle_2d(r * 4, rng), spacing)
					if p != null:
						result.append(p)
						 
			GrasslandStructuresKind.TARGET_PUZZLE:
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
		
		index += 1
					
	from.data = index
	return result
					
