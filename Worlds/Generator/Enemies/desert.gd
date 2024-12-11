class_name DesertGen
extends BiomeGenerator

enum DesertStructuresKind {
	NONE,
	OASIS,
	GHOST, GHOSTLY, HOT_BLOB
}

const desert_structure := {
	DesertStructuresKind.NONE: 120,
	DesertStructuresKind.OASIS: 1,
	DesertStructuresKind.GHOST: 0.5,
	DesertStructuresKind.GHOSTLY: 0.25,
	DesertStructuresKind.HOT_BLOB: 0.125,
}

func setup_state(pop: Population) -> void:
	Rand.normalise_distribution(desert_structure)

func populate(pop: Population, area: PackedVector2Array, from: Globals.Ref, limit: int, rng: RandomNumberGenerator, spacing: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var index := from.data as int
	while index < area.size() and pop.current_spawn_duration_ms < limit:
		if exclusion.has(index):
			index += 1
			continue
		var struct := Rand.entity_from_non_relative_distribution(rng.randf(), desert_structure) as DesertStructuresKind
		
		match struct:
			DesertStructuresKind.NONE:
				pass
				
			DesertStructuresKind.OASIS:
				var pos := area[index]
				var count := Rand.roll(9, 2, 0, rng, Rand.Accum.AVG)
				for i in count:
					if rng.randf() < 0.75:
						pop.spawn_foliage(World.Foliage.TREE_PALM, pos + Rand.point_in_circle_2d(10, rng), spacing)
					else:
						pop.spawn_foliage(World.Foliage.ROCK_SQUASHED, pos + Rand.point_in_circle_2d(10, rng), spacing)
						
				
			DesertStructuresKind.GHOST:
				var pos := area[index]
				var p := pop.spawn_enemy(World.Enemy.GHOST, pos, spacing) as WalkerHead
				if p != null: result.append(p)
				
			DesertStructuresKind.GHOSTLY:
				var pos := area[index]
				var p := pop.spawn_enemy(World.Enemy.GHOSTLY, pos, spacing) as Walker
				if p != null: result.append(p)
				
			DesertStructuresKind.HOT_BLOB:
				var pos := area[index]
				var count := Rand.entity_from_distribution(rng.randf(), {1: pop.fit(10, 1), 2: pop.fit(1, 10)}) as int
				for i in count:
					var p := pop.spawn_enemy(World.Enemy.HOT_BLOB, pos + Rand.point_in_circle_2d(10, rng), spacing)
					if p != null: result.append(p)
				
		index += 1
		
	from.data = index
	return result
					
