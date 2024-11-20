class_name ForestGen
extends BiomeGenerator

enum ForestStructuresKind {
	NONE, 
	TREE_CHRISTMAS, TREE_PYRAMID,
	
	UNDEAD_HORDE, BAT_HORDE, BAT, MOLE, UNDEAD,
	
	DENSE_BATTLEFIELD
}

var forest_structures := {
	ForestStructuresKind.NONE: 15.0,
	ForestStructuresKind.TREE_CHRISTMAS: 0.125,
	ForestStructuresKind.TREE_PYRAMID: 0.25,
	ForestStructuresKind.UNDEAD_HORDE: 0.0001,
	ForestStructuresKind.BAT_HORDE: 0.0001,
	ForestStructuresKind.BAT: 0.1,
	ForestStructuresKind.MOLE: 0.005,
	ForestStructuresKind.UNDEAD: 0.05,
	ForestStructuresKind.DENSE_BATTLEFIELD: 0.0005,
}

func setup_state(pop: Population) -> void:
	forest_structures[ForestStructuresKind.TREE_PYRAMID] = pop.fit(0.25, 0.5)
	forest_structures[ForestStructuresKind.TREE_CHRISTMAS] = pop.fit(0.125, 0.25)
	Rand.normalise_distribution(forest_structures)

func populate(pop: Population, area: PackedVector2Array, from: Globals.Ref, limit: int, rng: RandomNumberGenerator, spacing: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var index := from.data as int
	
	while index < area.size() and pop.current_spawn_duration_ms < limit:
		var struct := Rand.entity_from_non_relative_distribution(rng.randf(), forest_structures) as ForestStructuresKind
		match struct:
			ForestStructuresKind.NONE:
				pass
			ForestStructuresKind.TREE_CHRISTMAS:
				var pos := area[index] as Vector2
				pop.spawn_foliage(World.Foliage.TREE_CHRISTMAS, pos, spacing)
			ForestStructuresKind.TREE_PYRAMID:
				var pos := area[index] as Vector2
				pop.spawn_foliage(World.Foliage.TREE_PYRAMID, pos, spacing)
			ForestStructuresKind.BAT:
				var pos := area[index] as Vector2
				var elite_prob := pop.fit(0.2, 0.8)
				var p := pop.spawn_enemy(World.Enemy.BATTY if rng.randf() < elite_prob else World.Enemy.BAT, pos, spacing)
				if p != null:
					result.append(p)
			ForestStructuresKind.MOLE:
				var pos := area[index]
				var p := pop.spawn_enemy(World.Enemy.MOLE, pos, spacing)
				if p != null:
					result.append(p)
			ForestStructuresKind.UNDEAD:
				var pos := area[index] as Vector2
				var elite_prob := pop.fit(0.2, 0.8)
				var p := pop.spawn_enemy(World.Enemy.UNDEAD if rng.randf() < elite_prob else World.Enemy.UNDEAD_HEAD, pos, spacing)
				if p != null:
					result.append(p)	
			ForestStructuresKind.UNDEAD_HORDE:
				var pos := area[index]
				var count := rng.randi_range(4, pop.fiti(6, 10))
				var path := Pathway.new().random_points_in_disc(1, spacing * 0.5, spacing * 2, 0, count, Easing.linear, rng)
				path.apply_transform(Transform3D.IDENTITY.translated(Vec3.xz(pos)))
				var elite_prob := pop.fit(0.1, 0.5)
				for ppos in path.sample_points_xz(count):
					var p := pop.spawn_enemy(World.Enemy.UNDEAD if rng.randf() < elite_prob else World.Enemy.UNDEAD_HEAD, ppos, spacing)
					if p != null:
						result.append(p)
			ForestStructuresKind.BAT_HORDE:
				var pos := area[index]
				var count := rng.randi_range(2, pop.fiti(4, 12))
				var path := Pathway.new().random_points_in_sphere(1, 0, spacing / 2.0, count, Easing.linear, rng)
				path.apply_transform(T.translated(Vec3.xz(pos)))
				var elite_prob := pop.fit(0.1, 0.9)
				for ppos in path.sample_points_xz(count):
					var p := pop.spawn_enemy(World.Enemy.BATTY if rng.randf() < elite_prob else World.Enemy.BAT, ppos, spacing)
					if p != null:
						result.append(p)
					
			ForestStructuresKind.DENSE_BATTLEFIELD:
				if area.size() - index < 100:
					index += 1
					continue
				var count_tree := pop.rng.randi_range(10, pop.fiti(20, 30))
				var pos := area[index]
				for i in range(count_tree):
					index += 1
					pos = area[index]
					var count := pop.rng.randi_range(5, pop.fiti(5, 15))
					var path := Pathway.new().circle(rng.randf_range(spacing, spacing * 2), 0, 1)
					path.apply_transform(T.translated(Vec3.xz(pos)))
					for ppos in path.sample_points_xz(count):
						var p: Node3D
						var tree_prob := pop.fit(0.95, 0.7)
						var enemy_prob := {
							World.Enemy.UNDEAD: rng.randf_range(1, pop.fit(2, 10)), 
							World.Enemy.UNDEAD_HEAD: rng.randf_range(5, pop.fit(7.5, 1)),
							World.Enemy.BATTY: rng.randf_range(2, pop.fit(2.5, 8)),
							World.Enemy.BAT: rng.randf_range(7, pop.fit(6, 2)),
						}
						if rng.randf() < tree_prob:
							pop.spawn_foliage(World.Foliage.TREE_PYRAMID if rng.randf() < 0.5 else World.Foliage.TREE_CHRISTMAS, ppos, spacing)
						else:
							p = pop.spawn_enemy(Rand.entity_from_distribution(rng.randf(), enemy_prob) as World.Enemy, ppos, spacing)
						if p != null:
							result.append(p)
		index += 1
		
	from.data = index
	return result
			
